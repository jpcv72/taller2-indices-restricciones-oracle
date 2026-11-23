-- ============================================================================
-- TRABAJO: ÍNDICES Y RESTRICCIONES EN ORACLE (ESQUEMA HR)
-- Asignatura: Bases de Datos Avanzadas - UNIR
-- Estudiante: Juan Pablo Campo Velasquez
-- Servidor: 192.168.139.50 (lab-ol79-asm19c - Oracle 19c EE + ASM / ORCLPDB)
-- ============================================================================

-- 1. CONSULTA DE ÍNDICES DISPONIBLES EN EMPLOYEES Y DEPARTMENTS
SELECT table_name, index_name, index_type, uniqueness, status
FROM user_indexes
WHERE table_name IN ('EMPLOYEES', 'DEPARTMENTS')
ORDER BY table_name, index_name;

-- 2. DESACTIVACIÓN DE RESTRICCIONES EN EMPLOYEES Y DEPARTMENTS
SELECT table_name, constraint_name, constraint_type, status
FROM user_constraints
WHERE table_name IN ('EMPLOYEES', 'DEPARTMENTS')
ORDER BY table_name, constraint_type;

ALTER TABLE employees DISABLE CONSTRAINT emp_dept_fk;
ALTER TABLE employees DISABLE CONSTRAINT emp_job_fk;
ALTER TABLE employees DISABLE CONSTRAINT emp_manager_fk;
ALTER TABLE departments DISABLE CONSTRAINT dept_mgr_fk;
ALTER TABLE departments DISABLE CONSTRAINT dept_loc_fk;

ALTER TABLE employees DISABLE CONSTRAINT emp_email_uk DROP INDEX;
ALTER TABLE employees DISABLE CONSTRAINT emp_salary_min;
ALTER TABLE employees DISABLE CONSTRAINT emp_last_name_nn;
ALTER TABLE employees DISABLE CONSTRAINT emp_email_nn;
ALTER TABLE employees DISABLE CONSTRAINT emp_hire_date_nn;
ALTER TABLE employees DISABLE CONSTRAINT emp_job_nn;
ALTER TABLE employees DISABLE CONSTRAINT emp_emp_id_pk CASCADE DROP INDEX;

ALTER TABLE departments DISABLE CONSTRAINT dept_name_nn;
ALTER TABLE departments DISABLE CONSTRAINT dept_id_pk CASCADE DROP INDEX;

SELECT table_name, constraint_name, constraint_type, status
FROM user_constraints
WHERE table_name IN ('EMPLOYEES', 'DEPARTMENTS')
ORDER BY table_name, constraint_type;

-- 3. INSERCIÓN DE TUPLAS QUE INCUMPLEN LAS RESTRICCIONES
INSERT INTO departments (department_id, department_name, manager_id, location_id)
VALUES (10, 'Depto Duplicado Lab', 999, 9999);

INSERT INTO employees (employee_id, first_name, last_name, email, hire_date, job_id, salary, department_id)
VALUES (100, 'Carlos', 'Invalido', 'SKING', SYSDATE, 'IT_PROG', -500, 9999);

COMMIT;

SELECT department_id, department_name, location_id FROM departments WHERE department_id = 10;
SELECT employee_id, first_name, last_name, email, salary, department_id FROM employees WHERE employee_id = 100;

-- 4. REACTIVACIÓN DE RESTRICCIONES (PRUEBA DE ERROR Y SANEAMIENTO)
-- Intento fallido (genera error ORA-02437):
-- ALTER TABLE departments ENABLE CONSTRAINT dept_id_pk;

DELETE FROM employees WHERE first_name = 'Carlos' AND last_name = 'Invalido';
DELETE FROM departments WHERE department_name = 'Depto Duplicado Lab';
COMMIT;

ALTER TABLE departments ENABLE CONSTRAINT dept_id_pk;
ALTER TABLE departments ENABLE CONSTRAINT dept_name_nn;
ALTER TABLE employees ENABLE CONSTRAINT emp_emp_id_pk;
ALTER TABLE employees ENABLE CONSTRAINT emp_email_uk;
ALTER TABLE employees ENABLE CONSTRAINT emp_salary_min;
ALTER TABLE employees ENABLE CONSTRAINT emp_last_name_nn;
ALTER TABLE employees ENABLE CONSTRAINT emp_email_nn;
ALTER TABLE employees ENABLE CONSTRAINT emp_hire_date_nn;
ALTER TABLE employees ENABLE CONSTRAINT emp_job_nn;
ALTER TABLE departments ENABLE CONSTRAINT dept_loc_fk;
ALTER TABLE departments ENABLE CONSTRAINT dept_mgr_fk;
ALTER TABLE employees ENABLE CONSTRAINT emp_dept_fk;
ALTER TABLE employees ENABLE CONSTRAINT emp_job_fk;
ALTER TABLE employees ENABLE CONSTRAINT emp_manager_fk;

SELECT table_name, constraint_name, constraint_type, status
FROM user_constraints
WHERE table_name IN ('EMPLOYEES', 'DEPARTMENTS')
ORDER BY table_name, constraint_type;

-- 5. TRANSACCIONES Y SESIONES SOBRE DEPARTMENTS2
CREATE TABLE departments2 AS SELECT * FROM departments;

INSERT INTO departments2 VALUES (300, 'Inteligencia Artificial', 100, 1700);
INSERT INTO departments2 VALUES (310, 'Ciberseguridad', 100, 1700);
INSERT INTO departments2 VALUES (320, 'Big Data', 100, 1700);
-- Cierre de sesión sin COMMIT (ejecuta ROLLBACK implícito)

SELECT * FROM departments2 WHERE department_id >= 300;

-- 6. BLOQUE ANÓNIMO PL/SQL DE CONTROL TRANSACCIONAL
SET SERVEROUTPUT ON;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- INICIO DE LA TRANSACCIÓN SOBRE DEPARTMENTS2 ---');
    INSERT INTO departments2 (department_id, department_name, manager_id, location_id)
    VALUES (400, 'Arquitectura Cloud', 100, 1700);
    UPDATE departments2
    SET department_name = 'Arquitectura Cloud y Datos'
    WHERE department_id = 400;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('--- FIN DE LA TRANSACCIÓN: COMMIT EXITOSO ---');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('--- ERROR: SE EJECUTÓ ROLLBACK ---');
END;
/

SELECT * FROM departments2 WHERE department_id = 400;

-- 7. EJEMPLO PRÁCTICO DE REVERSIÓN (SAVEPOINT Y ROLLBACK)
INSERT INTO departments2 VALUES (500, 'Depto Prueba Rollback', 100, 1700);
SAVEPOINT sp_antes_borrado;
DELETE FROM departments2;
ROLLBACK TO sp_antes_borrado;
ROLLBACK;

-- 8. CONSULTA DE ARCHIVOS REDO LOG (EJECUTADO COMO SYSDBA)
SELECT name, log_mode FROM v$database;
SELECT group#, members, bytes/1024/1024 AS tamano_mb, status FROM v$log;
