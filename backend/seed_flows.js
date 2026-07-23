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
        name: 'Bonafide Certificate',
        // WORKFLOW STEPS MUST NOT BE CHANGED
        steps: ['tutor', 'hod', 'principal'],
        allowCustomHeading: true,
        includeLetterhead: true,
        includeRefDate: true,
        includeSeal: true,
        isFormBased: true,
        templateTo: 'To Whom It May Concern,',
        templateClosing: 'Principal / Authorized Signatory',
        letterTemplate: `This is to certify that Mr./Ms. {{name}} (KTU Register No: {{registerNo}}) is a bonafide student of Sreepathy Institute of Management and Technology, Vavanoor, Pattambi, affiliated to APJ Abdul Kalam Technological University (KTU), Kerala.

He/She is currently studying in {{course}} (Branch: {{dept}}), {{semester}} (Year {{year}}, Division {{division}}) for the Academic Year {{academic_year}}.

This certificate is issued upon the request of the student for the purpose of {{purpose_of_certificate}}.`,
        elements: [
          {
            id: 'el_1', kind: 'field', label: 'Academic Year', type: 'text',
            required: true, visible: true, placeholder: 'e.g. 2025-2026', hint: 'Current academic year'
          },
          {
            id: 'el_2', kind: 'field', label: 'Course', type: 'select',
            options: ['B.Tech', 'M.Tech', 'Diploma'], required: true, visible: true
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
        // WORKFLOW STEPS MUST NOT BE CHANGED
        steps: ['tutor', 'office', 'principal'],
        allowCustomHeading: true,
        includeLetterhead: true,
        includeRefDate: true,
        includeSeal: true,
        isFormBased: true,
        templateTo: 'To The Admissions Authority / Head of Institution,',
        templateClosing: 'Principal',
        letterTemplate: `This is to certify that Mr./Ms. {{name}} (KTU Register No: {{registerNo}}) was a student of Sreepathy Institute of Management and Technology studying {{course}} in {{dept}} Department under APJ Abdul Kalam Technological University during {{academic_period}}.

Date of Admission: {{admission_date}}
Date of Leaving: {{leaving_date}}
Reason for Leaving: {{reason_for_leaving}}
Character & Conduct during study: {{character_and_conduct}}`,
        elements: [
          {
            id: 'el_1', kind: 'field', label: 'Course', type: 'text',
            required: true, visible: true, placeholder: 'e.g. B.Tech Computer Science & Engineering'
          },
          {
            id: 'el_2', kind: 'field', label: 'Academic Period', type: 'text',
            required: true, visible: true, placeholder: 'e.g. 2021 - 2025'
          },
          {
            id: 'el_3', kind: 'field', label: 'Admission Date', type: 'date',
            required: true, visible: true
          },
          {
            id: 'el_4', kind: 'field', label: 'Leaving Date', type: 'date',
            required: true, visible: true
          },
          {
            id: 'el_5', kind: 'field', label: 'Reason for Leaving', type: 'select',
            options: ['Course Completed', 'Relocation / Migration', 'Higher Studies Admission', 'Personal Reasons'],
            required: true, visible: true
          },
          {
            id: 'el_6', kind: 'field', label: 'Character and Conduct', type: 'select',
            options: ['Exemplary', 'Very Good', 'Good'],
            required: true, visible: true
          }
        ]
      },
      {
        name: 'NOC',
        // WORKFLOW STEPS MUST NOT BE CHANGED
        steps: ['hod', 'principal'],
        allowCustomHeading: true,
        includeLetterhead: true,
        includeRefDate: true,
        includeSeal: true,
        isFormBased: true,
        templateTo: 'To Whom It May Concern,',
        templateClosing: 'Principal / Head of Institution',
        letterTemplate: `This is to certify that Sreepathy Institute of Management and Technology has No Objection to Mr./Ms. {{name}} (KTU Register No: {{registerNo}}), student of {{dept}} department, {{semester}}, attending {{event_or_internship_title}} organized by {{company_or_institution}} at {{location}} during the period from {{start_date}} to {{end_date}}.

The student is granted permission to participate in this academic/technical activity without affecting their KTU curriculum obligations.`,
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
        // WORKFLOW STEPS MUST NOT BE CHANGED
        steps: ['tutor', 'hod', 'office', 'principal'],
        allowCustomHeading: true,
        includeLetterhead: true,
        includeRefDate: true,
        includeSeal: true,
        isFormBased: true,
        templateTo: 'To Whom It May Concern,',
        templateClosing: 'Principal',
        letterTemplate: `This is to certify that Mr./Ms. {{name}} (KTU Register No: {{registerNo}}) has completed the prescribed 4-year course of study in {{dept}} Department at Sreepathy Institute of Management and Technology, Vavanoor, for the degree of Bachelor of Technology (B.Tech) under APJ Abdul Kalam Technological University (KTU), Kerala.

Duration of Study: {{duration_of_study}}.
Overall Character & Conduct: {{overall_conduct}}.`,
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
