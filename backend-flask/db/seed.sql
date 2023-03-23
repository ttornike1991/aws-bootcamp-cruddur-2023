-- this file was manually created
INSERT INTO public.users (display_name, email, handle, cognito_user_id)
VALUES
  ('Andrew Brown','andrew@exampro.co' , 'andrewbrown' ,'6def1e2d-4217-44a6-8275-06762a2ca101'),
  ('Andrew Bayko','bayko@exampro.co' , 'bayko' ,'6def1e2d-4217-44a6-8275-06762a2ca101'),
  ('Londo Mollari','lmollari@centari.com' ,'londo' ,'6def1e2d-4217-44a6-8275-06762a2ca101');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'andrewbrown' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )