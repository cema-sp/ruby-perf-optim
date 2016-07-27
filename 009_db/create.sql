create table empsalaries(
  department_id integer,
  employee_id integer,
  salary integer
);

insert into empsalaries (
  select
    (1 + round(random()*25)),
    *,
    (50000 + round(random()*250000))
  from
    generate_series(1, 10000)
);

create index empsalaries_department_id_idx on empsalaries (department_id);

