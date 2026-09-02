DECLARE
  v_recipient VARCHAR2(100);
  v_subject VARCHAR2(100) := 'H05_03_Yakymyshyn';
  v_mes VARCHAR2(32767) := 'Dear All,</br>Please find the report</br></br>';
BEGIN

  SELECT email || '@gmail.com' 
  INTO v_recipient
  FROM employees
  WHERE email = 'Yakymyshyn25';
  
  SELECT v_mes || '<!DOCTYPE html>
  <html>...
    <table>
      <thead>
        <tr>
          <th>Department ID</th>
          <th>Number of employees</th>
        </tr>
      </thead>
      <tbody>' || lis_Html || '</tbody>
    </table>
  </html>'
  INTO v_mes
  FROM (
    SELECT LISTAGG('<tr><td>' || department_id || '</td>' ||
                   '<td class="center">' || count_employees || '</td></tr>', '')
           WITHIN GROUP(ORDER BY department_id) AS lis_Html
    FROM (
      SELECT em.department_id,
             COUNT(*) AS count_employees
      FROM employees em
      WHERE em.department_id IN (
        SELECT department_id FROM employees WHERE email = 'Yakymyshyn25'
      )
      group by department_id
    )
  );
  
  v_mes := v_mes || '</br></br>Best regards,</br>Nataliia';
  sys.sendmail(p_recipient => v_recipient, p_subject => v_subject, p_message => v_mes);
EXCEPTION
  WHEN OTHERS THEN RAISE;
END;