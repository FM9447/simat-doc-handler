const mongoose = require('mongoose');
require('dotenv').config();
const DocumentType = require('./models/DocumentType');

const seedFlows = async () => {
  try {
    const dbUri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/smartcampus';
    await mongoose.connect(dbUri);
    console.log('Connected to MongoDB');

    const initialFlows = [
      {
        name: 'Duty Leave Application',
        steps: ['tutor', 'hod', 'tutor'],
        allowCustomHeading: true,
        includeLetterhead: true,
        includeRefDate: true,
        includeSeal: true,
        isFormBased: true,
        templateTo: 'To The Head of Department / Class Tutor,',
        templateClosing: 'Class Tutor / Authorized Signatory',
        letterTemplate: `DUTY LEAVE APPLICATION & OFFICIAL CERTIFICATION\n\nThis is to certify that Mr./Ms. {{name}} (KTU Reg. No: {{registerNo}}), student of {{dept}} Department, Year {{year}} (Division: {{division}}), has officially represented Sreepathy Institute of Management and Technology in activities organized under {{duty_category}} (Event / Activity Title: {{event_name}}).\n\nThe student is hereby granted official Duty Leave for the specific dates, class hours, and academic periods detailed in the schedule below:\n\n{{duty_leave_schedule}}\n\nTotal Hours / Periods Sanctioned: {{total_hours_granted}}\n\nInstruction: The Class Tutor is requested to update official college attendance registers and mark Duty Leave accordingly.`,
        elements: [
          {
            id: 'el_1', kind: 'field', label: 'Duty Category / Club', type: 'select',
            options: ['IEDC (Innovation & Entrepreneurship Cell)', 'NSS (National Service Scheme)', 'MuLearn Campus Chapter', 'IEEE Student Branch', 'College Sports Team', 'Arts & Cultural Event', 'Department Technical Fest', 'Other Official Representation'],
            required: true, visible: true
          },
          {
            id: 'el_2', kind: 'field', label: 'Event or Activity Name', type: 'text',
            required: true, visible: true, placeholder: 'e.g. State Hackathon / Annual NSS Camp'
          },
          {
            id: 'el_3', kind: 'field', label: 'Duty Leave Schedule', type: 'table',
            required: true, visible: true, placeholder: 'Tabular Schedule of Dates & Hours'
          },
          {
            id: 'el_4', kind: 'field', label: 'Total Hours Granted', type: 'text',
            required: true, visible: true, placeholder: 'e.g. 12 Hours / 4 Periods'
          }
        ]
      },
      {
        name: 'Bonafide Certificate',
        steps: ['tutor', 'hod', 'principal'],
        allowCustomHeading: true,
        includeLetterhead: true,
        includeRefDate: true,
        includeSeal: true,
        isFormBased: true,
        templateTo: 'To Whom It May Concern,',
        templateClosing: 'Principal / Authorized Signatory',
        letterTemplate: `BONAFIDE CERTIFICATE\n\nThis is to certify that Mr./Ms. {{name}} (KTU Register No: {{registerNo}}) is a bonafide student of Sreepathy Institute of Management and Technology (SIMAT), Vavanoor, Pattambi, affiliated to APJ Abdul Kalam Technological University (KTU), Kerala.\n\nHe/She is currently pursuing {{course}} in the Department of {{dept}}, {{semester}} (Academic Year {{academic_year}}).\n\nThis certificate is issued upon the request of the student for the purpose of {{purpose_of_certificate}}.`,
        elements: [
          {
            id: 'el_1', kind: 'field', label: 'Academic Year', type: 'text',
            required: true, visible: true, placeholder: 'e.g. 2025-2026', hint: 'Current academic year'
          },
          {
            id: 'el_2', kind: 'field', label: 'Course', type: 'select',
            options: ['B.Tech Computer Science & Engineering', 'B.Tech Electronics & Communication', 'B.Tech Electrical & Electronics', 'B.Tech Mechanical Engineering', 'B.Tech Civil Engineering', 'M.Tech', 'Diploma'],
            required: true, visible: true
          },
          {
            id: 'el_3', kind: 'field', label: 'Semester', type: 'select',
            options: ['Semester 1', 'Semester 2', 'Semester 3', 'Semester 4', 'Semester 5', 'Semester 6', 'Semester 7', 'Semester 8'],
            required: true, visible: true
          },
          {
            id: 'el_4', kind: 'field', label: 'Purpose of Certificate', type: 'select',
            options: ['Passport Application', 'Bank Education Loan', 'Bus / Railway Concession', 'Industrial Internship / Training', 'Scholarship Application', 'External Competition / Hackathon', 'Other Official Purpose'],
            required: true, visible: true
          }
        ]
      },
      {
        name: 'Transfer Certificate',
        steps: ['tutor', 'office', 'principal'],
        allowCustomHeading: true,
        includeLetterhead: true,
        includeRefDate: true,
        includeSeal: true,
        isFormBased: true,
        templateTo: 'To The Admissions Authority / Head of Institution,',
        templateClosing: 'Principal',
        letterTemplate: `TRANSFER CERTIFICATE (T.C.)\n\nThis is to certify that Mr./Ms. {{name}} (KTU Register No / Admission No: {{admission_no_or_reg}}) was a student of Sreepathy Institute of Management and Technology studying {{course}} in the Department of {{dept}} under APJ Abdul Kalam Technological University (KTU).\n\n1. Date of Birth: {{date_of_birth}}\n2. Date of Admission: {{admission_date}}\n3. Date of Leaving: {{leaving_date}}\n4. Reason for Leaving: {{reason_for_leaving}}\n5. Promotion Status: {{promotion_status}}\n6. Character and Conduct: {{character_and_conduct}}`,
        elements: [
          {
            id: 'el_1', kind: 'field', label: 'Admission No or KTU Reg No', type: 'text',
            required: true, visible: true, placeholder: 'e.g. ADM2021-045 / SPT21CS001'
          },
          {
            id: 'el_2', kind: 'field', label: 'Course', type: 'text',
            required: true, visible: true, placeholder: 'e.g. B.Tech Computer Science & Engineering'
          },
          {
            id: 'el_3', kind: 'field', label: 'Date of Birth', type: 'date',
            required: true, visible: true
          },
          {
            id: 'el_4', kind: 'field', label: 'Admission Date', type: 'date',
            required: true, visible: true
          },
          {
            id: 'el_5', kind: 'field', label: 'Leaving Date', type: 'date',
            required: true, visible: true
          },
          {
            id: 'el_6', kind: 'field', label: 'Reason for Leaving', type: 'select',
            options: ['Course Completed', 'Relocation / Migration', 'Higher Studies Admission', 'Personal Reasons'],
            required: true, visible: true
          },
          {
            id: 'el_7', kind: 'field', label: 'Promotion Status', type: 'select',
            options: ['Qualified for Promotion to Next Semester', 'Course Successfully Completed', 'N/A'],
            required: true, visible: true
          },
          {
            id: 'el_8', kind: 'field', label: 'Character and Conduct', type: 'select',
            options: ['Exemplary', 'Very Good', 'Good'],
            required: true, visible: true
          }
        ]
      },
      {
        name: 'NOC',
        steps: ['hod', 'principal'],
        allowCustomHeading: true,
        includeLetterhead: true,
        includeRefDate: true,
        includeSeal: true,
        isFormBased: true,
        templateTo: 'To Whom It May Concern,',
        templateClosing: 'Principal / Head of Institution',
        letterTemplate: `NO OBJECTION CERTIFICATE (N.O.C.)\n\nThis is to certify that Sreepathy Institute of Management and Technology has NO OBJECTION to Mr./Ms. {{name}} (KTU Register No: {{registerNo}}), student of {{dept}} Department, {{semester}}, participating in {{event_or_internship_title}} organized by {{company_or_institution}} at {{location}} during the period from {{start_date}} to {{end_date}}.\n\nThe student is granted permission to undertake this academic/technical activity without detriment to their curriculum requirements under APJ Abdul Kalam Technological University (KTU).`,
        elements: [
          {
            id: 'el_1', kind: 'field', label: 'Event or Internship Title', type: 'text',
            required: true, visible: true, placeholder: 'e.g. Industrial Internship / Workshop on AI'
          },
          {
            id: 'el_2', kind: 'field', label: 'Company or Institution', type: 'text',
            required: true, visible: true, placeholder: 'e.g. KSEB / Keltron / ISRO / Tech Firm'
          },
          {
            id: 'el_3', kind: 'field', label: 'Location', type: 'text',
            required: true, visible: true, placeholder: 'e.g. Trivandrum / Kochi'
          },
          {
            id: 'el_4', kind: 'field', label: 'Semester', type: 'select',
            options: ['Semester 1', 'Semester 2', 'Semester 3', 'Semester 4', 'Semester 5', 'Semester 6', 'Semester 7', 'Semester 8'],
            required: true, visible: true
          },
          {
            id: 'el_5', kind: 'field', label: 'Start Date', type: 'date',
            required: true, visible: true
          },
          {
            id: 'el_6', kind: 'field', label: 'End Date', type: 'date',
            required: true, visible: true
          }
        ]
      },
      {
        name: 'Course Completion',
        steps: ['tutor', 'hod', 'office', 'principal'],
        allowCustomHeading: true,
        includeLetterhead: true,
        includeRefDate: true,
        includeSeal: true,
        isFormBased: true,
        templateTo: 'To Whom It May Concern,',
        templateClosing: 'Principal',
        letterTemplate: `COURSE COMPLETION CERTIFICATE\n\nThis is to certify that Mr./Ms. {{name}} (KTU Register No: {{registerNo}}) has successfully completed the prescribed course of study in {{dept}} Department at Sreepathy Institute of Management and Technology, Vavanoor, for the degree of Bachelor of Technology (B.Tech) affiliated to APJ Abdul Kalam Technological University (KTU), Kerala.\n\nDuration of Study: {{duration_of_study}}\nOverall Academic Conduct & Character: {{overall_conduct}}`,
        elements: [
          {
            id: 'el_1', kind: 'field', label: 'Duration of Study', type: 'text',
            required: true, visible: true, placeholder: 'e.g. August 2021 to May 2025'
          },
          {
            id: 'el_2', kind: 'field', label: 'Overall Conduct', type: 'select',
            options: ['Exemplary', 'Very Good', 'Good'],
            required: true, visible: true
          }
        ]
      }
    ];

    for (const flow of initialFlows) {
      await DocumentType.findOneAndUpdate(
        { name: flow.name },
        flow,
        { upsert: true, new: true }
      );
      console.log(`Updated KTU document template: ${flow.name}`);
    }

    console.log('🎉 KTU Document Templates seeded successfully!');
    await mongoose.disconnect();
    process.exit(0);
  } catch (err) {
    console.error('Seeding error:', err);
    process.exit(1);
  }
};

seedFlows();
