/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [encounter_id]
      ,[patient_nbr]
      ,[race]
      ,[gender]
      ,[age]
      ,[weight]
      ,[admission_type_id]
      ,[discharge_disposition_id]
      ,[admission_source_id]
      ,[time_in_hospital]
      ,[payer_code]
      ,[medical_specialty]
      ,[num_lab_procedures]
      ,[num_procedures]
      ,[num_medications]
      ,[number_outpatient]
      ,[number_emergency]
      ,[number_inpatient]
      ,[diag_1]
      ,[diag_2]
      ,[diag_3]
      ,[number_diagnoses]
      ,[max_glu_serum]
      ,[A1Cresult]
      ,[metformin]
      ,[repaglinide]
      ,[nateglinide]
      ,[chlorpropamide]
      ,[glimepiride]
      ,[acetohexamide]
      ,[glipizide]
      ,[glyburide]
      ,[tolbutamide]
      ,[pioglitazone]
      ,[rosiglitazone]
      ,[acarbose]
      ,[miglitol]
      ,[troglitazone]
      ,[tolazamide]
      ,[examide]
      ,[citoglipton]
      ,[insulin]
      ,[glyburide_metformin]
      ,[glipizide_metformin]
      ,[glimepiride_pioglitazone]
      ,[metformin_rosiglitazone]
      ,[metformin_pioglitazone]
      ,[change]
      ,[diabetesMed]
      ,[readmitted]
  FROM [Diabetic_patients].[dbo].[diabetic_data]

  ----------------------------------------------------------------------

  SELECT TOP 20 *
  FROM diabetic_data;

  ---Find how many patients stay in the hospital for diff lengths

  SELECT ROUND(time_in_hospital,1) as total_days, COUNT(*) as count
FROM diabetic_data
GROUP BY ROUND(time_in_hospital,1)
ORDER BY total_days;

---List all specialties and the avg total no of procedures practiced in the hospital 

SELECT DISTINCT medical_specialty, COUNT(medical_specialty) as total, 
		ROUND(AVG(num_procedures),1) as avg_procedures
FROM diabetic_data
WHERE NOT medical_specialty = '?'
GROUP BY medical_specialty
ORDER BY avg_procedures DESC;

--- Narrow down to specialties w/ at least 50 patients & more than 2.5 procedures on avg

SELECT DISTINCT medical_specialty, COUNT(medical_specialty) as total, 
		ROUND(AVG(num_procedures),1) as avg_procedures
FROM diabetic_data
WHERE NOT medical_specialty = '?'
GROUP BY medical_specialty
HAVING COUNT(medical_specialty) > 50 AND ROUND(AVG(num_procedures),1) > 2.5
ORDER BY avg_procedures DESC;

--- Here only 3 specialties Surgery-Thoracic, Surgery-Cardiovascular/Thoracic & Radiologist
--- met the requirements ---

--- Chief Nurse wants to know if hospital is treating patients of diff races diff, specifically w/ no of lab procedures done.

SELECT race, ROUND(AVG(num_lab_procedures),1) as avg_num_lab_procedure
FROM diabetic_data
GROUP BY race
ORDER BY avg_num_lab_procedure DESC;

--- Here we found out that there is little to no significant diff. in avg_num of lab procedures across the races.
--- Noting that "?" and "Other" have an avg of 43 which would be useful if Identified.

--- Do people need more procedures if they stay longer in the hospital?

SELECT MIN(num_lab_procedures) as minimum, ROUND(AVG(num_lab_procedures),0) as average,
		MAX(num_lab_procedures) as maximum
FROM diabetic_data;

--- Here we divide the nums into 3 categories, then investigate the correlation btwn no of procedures vs length of hospitalization in total.

SELECT ROUND(AVG(time_in_hospital), 0) as days_stay,
	(CASE 
		WHEN num_lab_procedures >= 0 AND num_lab_procedures < 25 THEN 'few'
		WHEN num_lab_procedures >= 25 AND num_lab_procedures < 55 THEN 'average'
		ELSE 'many'
		END) as procedure_freq
FROM diabetic_data
GROUP BY (CASE WHEN num_lab_procedures >= 0 AND num_lab_procedures < 25 THEN 'few'
		WHEN num_lab_procedures >= 25 AND num_lab_procedures < 55 THEN 'average'
		ELSE 'many'
		END)
ORDER BY days_stay;

--- Now, we need to test anyone who is African American OR had an "up" for metformin.


SELECT patient_nbr 
FROM diabetic_data 
WHERE race = 'AfricaAmerican'
UNION
SELECT patient_nbr 
FROM diabetic_data 
WHERE metformin = 'up';

WITH total_patients as 
	(SELECT patient_nbr 
	FROM diabetic_data 
	WHERE race = 'AfricaAmerican'
	UNION
	SELECT patient_nbr 
	FROM diabetic_data 
	WHERE metformin = 'up')
SELECT COUNT(patient_nbr)
FROM total_patients;

--- The hospital wants to highlight some of the biggest success stories.
--- Now, they are looking for opportunities when patients came in on an emergency BUT stayed less than the avg time in the hospital.

WITH avg_hospital_time as(
	SELECT AVG(time_in_hospital) as average
	FROM diabetic_data)
	SELECT COUNT(*) as succesful_cases
	FROM diabetic_data
	WHERE admission_type_id = 1
	AND time_in_hospital < (
	SELECT * 
	FROM avg_hospital_time);

--- Result is 26042 successful cases
--- Time to compare this no w/ total of patients

SELECT DISTINCT COUNT(*) as total_patients
FROM diabetic_data;

--- result is 101766
--- Now we just divide the successful cases from total patients & multiply by 100 to find the percentage
--- 25.6% is what we arrive at, which is pretty reasonable.

--- write a summary for the top 50 medication patients, and break any ties with the number of lab procedures (highest at the top) by following the hospital’s format.

SELECT TOP 50 
	CONCAT('Patient ', patient_nbr, ' was ', race, ' and ',
	CASE 
	WHEN readmitted = 'No' THEN ' was not readmitted. They had '
	ELSE 'was readmitted. They had '
	END, 
	num_medications, ' medications and ',
	num_lab_procedures, ' lab procedures.') as Summary
FROM diabetic_data
ORDER BY num_medications DESC, num_lab_procedures DESC;