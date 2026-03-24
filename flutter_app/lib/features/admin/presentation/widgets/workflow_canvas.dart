import 'package:flutter/material.dart';
import '../../../../models/workflow_element.dart';
import '../../../../core/constants/app_constants.dart';

class WorkflowCanvas extends StatefulWidget {
  final List<WorkflowElement> elements;
  final Function(List<WorkflowElement>) onElementsChanged;
  final WorkflowElement? selectedElement;
  final Function(WorkflowElement?) onElementSelected;

  const WorkflowCanvas({
    super.key,
    required this.elements,
    required this.onElementsChanged,
    this.selectedElement,
    required this.onElementSelected,
  });

  @override
  State<WorkflowCanvas> createState() => _WorkflowCanvasState();
}

class _WorkflowCanvasState extends State<WorkflowCanvas> {
  static const double canvasWidth = 480;
  static const double canvasHeight = 678.8; // A4 Ratio (480 * 297/210)

  // Local state for smooth dragging/resizing
  late List<WorkflowElement> _localElements;
  String? _draggingId;
  String? _resizingId;

  @override
  void initState() {
    super.initState();
    _localElements = List.from(widget.elements);
  }

  @override
  void didUpdateWidget(WorkflowCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync if elements changed from outside (e.g. added new element)
    if (widget.elements != oldWidget.elements && _draggingId == null && _resizingId == null) {
      setState(() {
        _localElements = List.from(widget.elements);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: canvasWidth,
        height: canvasHeight,
        margin: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppConstants.borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Grid Background
              _buildCanvasGrid(),
              
              // Clear selection area
              GestureDetector(
                onTap: () => widget.onElementSelected(null),
                child: Container(color: Colors.transparent),
              ),
              
              // Elements
              ..._localElements.map((el) => _buildElement(el)),

              // Selection Info Overlay
              if (widget.selectedElement != null)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'X: ${widget.selectedElement!.x.round()} Y: ${widget.selectedElement!.y.round()} W: ${widget.selectedElement!.w.round()} H: ${widget.selectedElement!.h.round()}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCanvasGrid() {
    return Stack(
      children: [
        for (int i = 1; i < (canvasHeight / 40); i++)
          Positioned(
            top: i * 40.0,
            left: 0,
            right: 0,
            child: Container(height: 0.5, color: Colors.grey[200]),
          ),
        for (int i = 1; i < (canvasWidth / 40); i++)
          Positioned(
            left: i * 40.0,
            top: 0,
            bottom: 0,
            child: Container(width: 0.5, color: Colors.grey[200]),
          ),
      ],
    );
  }

  Widget _buildElement(WorkflowElement el) {
    final bool isSelected = widget.selectedElement?.id == el.id;
    final Color color = _getKindColor(el.kind);

    return Positioned(
      left: el.x,
      top: el.y,
      child: GestureDetector(
        onTap: () => widget.onElementSelected(el),
        child: Container(
          width: el.w,
          height: el.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
            border: isSelected 
                ? Border.all(color: color, width: 2)
                : Border.all(color: color.withOpacity(0.3), style: BorderStyle.none),
          ),
          child: Stack(
            children: [
              // Custom Dashed Border (Using a simple painter or styled container)
              if (!isSelected && el.kind != 'divider')
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DashedBorderPainter(color: color.withOpacity(0.5)),
                  ),
                ),
                
              _buildElementContent(el, color),
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElementContent(WorkflowElement el, Color color) {
    switch (el.kind) {
      case 'divider':
        return Center(child: Container(height: 1, color: Colors.grey[300]));
      
      case 'header':
        return Center(
          child: Text(
            el.content ?? 'SECTION TITLE',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        );

      case 'address':
        return Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            el.content ?? 'To\nThe Principal',
            style: const TextStyle(fontSize: 9, color: Colors.black87, height: 1.2),
          ),
        );

      case 'system':
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Text('${el.label}: ', style: const TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.w600)),
              const Text('auto', style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
            ],
          ),
        );

      case 'field':
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Text(
                '${el.label}${el.required ? "*" : ""}: ',
                style: const TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.w600),
              ),
              const Text(
                'input',
                style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        );

      case 'seal':
        return Center(
          child: el.imageUrl != null 
            ? Image.network(el.imageUrl!, fit: BoxFit.contain)
            : Icon(Icons.verified_user_outlined, color: color.withOpacity(0.3), size: 20),
        );

      case 'header_image':
        return Center(
          child: el.imageUrl != null 
            ? Image.network(el.imageUrl!, fit: BoxFit.contain)
            : Icon(Icons.image_outlined, color: color.withOpacity(0.3), size: 20),
        );

      case 'template_body':
        return const Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LETTER BODY TEMPLATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              Divider(),
              Text('The substituted contents of your letter template will appear here.', style: TextStyle(fontSize: 8, color: Colors.grey)),
            ],
          ),
        );

      default:
        return Center(child: Text(el.kind, style: const TextStyle(fontSize: 10)));
    }
  }

  Color _getKindColor(String kind) {
    switch (kind) {
      case 'field':
      case 'system': return const Color(0xFFC084FC); // Purple
      case 'header': return Colors.amber[800]!;
      case 'address': return Colors.teal;
      case 'seal': return Colors.green[700]!;
      case 'header_image': return Colors.indigo;
      default: return const Color(0xFFC084FC);
    }
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 4;
    const dashSpace = 4;

    // Top
    double curX = 0;
    while (curX < size.width) {
      canvas.drawLine(Offset(curX, 0), Offset(curX + dashWidth, 0), paint);
      curX += dashWidth + dashSpace;
    }

    // Bottom
    curX = 0;
    while (curX < size.width) {
      canvas.drawLine(Offset(curX, size.height), Offset(curX + dashWidth, size.height), paint);
      curX += dashWidth + dashSpace;
    }

    // Left
    double curY = 0;
    while (curY < size.height) {
      canvas.drawLine(Offset(0, curY), Offset(0, curY + dashWidth), paint);
      curY += dashWidth + dashSpace;
    }

    // Right
    curY = 0;
    while (curY < size.height) {
      canvas.drawLine(Offset(size.width, curY), Offset(size.width, curY + dashWidth), paint);
      curY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
