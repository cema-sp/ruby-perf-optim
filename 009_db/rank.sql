\timing

select
  department_id,
  employee_id,
  salary,
  rank() over(partition by department_id order by salary desc)
from
  empsalaries;

