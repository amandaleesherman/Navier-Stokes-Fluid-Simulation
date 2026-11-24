%Navier-Stokes equation: describe how fluids such as air and water move
%Design a MATLAB simulation that can:
%Visualize fluid flowing through a 2D grid
%Show how velocity changes over time
%Model viscosity and pressure
%Display fluid motion using arrows, colors, and animations
%Viscosity: fluid's resistance to flowing (internal friction)

%Incompressible fluid mode
%2 important physical principles:
%1. Conservation of mass
%For an incompressible fluid, the velocity field must satisfy: 
%That means that fluid doesn't spontaneously accumulate or disappear at a
%point
%In fluid mechanics, the amount of fluid entering a region must equal the
%amount leaving it, assuming there is no accumulation or source of fluid
%Continuity equation: spatial derivative * velocity vector (divergence of
%velocity) = 0
%Velocity divergence = measures whether fluid is spreading out from a
%point, converging into a point, or flowing through without accumulating
%Positive, Negative, Zero

%2. Conservation of momentum:
%The Navier-Stokes equation describes how fluid velocity changes:
%Fluid's motion changes because of forces acting on it
%Momentum is the product of mass and velocity
%p = mv
%(Change in velocity over time) + (Change in velocity due to fluid motion)
%= Acceleration caused by pressure + Viscous diffusion + External forces
%In fluid mechanics, momentum changes because of forces such as:
%1. Pressure: Pushes fluid from regions of high pressure towards low
%pressure
%2. Viscosity: Internal friction that resists relative motion between fluid
%layers
%3. External forces: Gravity, fans, pumps, and other applied forces
%These relationships are described by the Navier-Stokes equation
%F = ma
%Force = mass times acceleration
%Tracking motion of fluid through continuous space
%Local acceleration: how velocity changes at a fixed location as time
%passes
%Convective acceleration (advection): how velocity changes because fluid
%moves into regions with different velocities
%Pressure force: fluid accelerates from higher pressure towards lower
%pressure
%Viscous diffusion: viscosity spreads movement between neighboring fluid
%regions
%External forces: Forces acting on the fluid independently of its internal
%pressure and viscosity

%Lid-driven cavity: container where the top wall moves horizontally while
%the other walls remain stationary
%No-slip boundary condition: fluid touching a stationary wall has the same
%velocity as the wall


%2D FLUID SIMULATION
%Problem: Flow inside a lid-driven cavity

%Clear previous variables, command window, and figurines 
clear all;
clc;
close all;

%PROBLEM SETUP

%Dimensions of the fluid container
length = 1; %length of the container (meters)
height = 1; %height of the container (meters)

%Number of grid cells
mesh_x = 50; %number of cells in x direction
mesh_y = 50; %number of cells in y direction

%Size of each grid cell
dx = length / (mesh_x - 1);
dy = height / (mesh_y - 1);

%Kinematic - relating to motion 

%Fluid properties
%Simplified fluid density
rho = 1; %Density of water (kg/m^3)
mu = 0.08; %Dynamic viscosity (Pa*s)
%rho (p): density - how much mass is packed into a given volume (kg/m^3)
%mu (u): dynamic viscosity - how strongly the fluid resists layers sliding
%past each other (Pa*s)
%nu (v): kinematic viscosity - how quickly momentum diffuses through the
%fluid relative to its density (m^2/s)
%kinematic viscosity combines dynamic viscosity and density

%new velocity = old velocity + acceleration * change in time 
%acceleration tells you how quickly velocity changes over time
%accel = velo/time 
%accel * time = velo
%local accel = advection + viscosity

%Calculate kinematic viscosity
nu = mu / rho;
%nu is kinematic viscosity, it measures how quickly momentum spreads
%through the fluid

%Initial Velocity and Pressure

%Horizontal velocity
u = zeros(mesh_y, mesh_x);

%Vertical velocity 
v = zeros(mesh_y, mesh_x);

%Pressure
p = zeros(mesh_y, mesh_x);

%Boundary conditions

%Set the speed of the moving top wall
lid_velocity = 2; %Horizontal velocity (m/s)

%The top wall moves horizontally
u(mesh_y, :) = lid_velocity;

%The remaining walls are stationary
u(1, :) = 0;
u(:, 1) = 0;
u(:, mesh_x) = 0;

%No vertical movement at the walls
v(1, :) = 0;
v(mesh_y, :) = 0;
v(:, 1) = 0;
v(:, mesh_x) = 0;

%Create the computational grid

%Create x and y coordinates for every grid point
x = linspace(0, length, mesh_x);
y = linspace(0, height, mesh_y);

[X, Y] = meshgrid(x, y);

%Time settings

%dt = delta time - represents the amount of simulated time that passes
%during each iteration of your fluid simulation
dt = 0.001; %Size of each time step (seconds)
time_steps = 1000; %Number of simulation steps
%total time = dt x time steps = 0.001 x 200 = 0.2 seconds

%Check that the time step is stable for diffusion
%Calculates diffusion stability limit - if dt becomes too large, the
%numerical solution can become unstable or inaccurate
max_dt = 1 / (2 * nu * (1/dx^2 + 1/dy^2));

if dt > max_dt
    error('Time step is too large. Reduce dt.');
end

%Simulate fluid movement

fig = figure('Name', '2D Fluid Simulation');

X_plot = X(1:6:end, 1:6:end);
Y_plot = Y(1:6:end, 1:6:end);

q = quiver(X_plot, Y_plot, ...
    u(1:6:end, 1:6:end), ...
    v(1:6:end, 1:6:end), 0.1);

titleHandle = title('Initial Fluid Velocity');

xlabel('X Position (m)');
ylabel('Y Position (m)');

axis equal;
xlim([0 length]);
ylim([0 height]);

drawnow;

% Number of iterations used to calculate pressure
pressure_iterations = 100;
%how many times to refine its pressure estimate during each time step

%u = horizontal velocity along the x-axis (left and right)
%v = vertical velocity along the y-axis (up and down)
%together, they describe the fluid's velocity at each grid point

for step = 1:time_steps
    fprintf('Starting time step: %d\n', step);
    %Displays progress of simulation
    if mod(step, 100) == 0
        fprintf('Currently on time step: %d\n', step);
    end

    % Save the current velocity values
    u_old = u;
    v_old = v;

    % Check time-step stability for advection and diffusion

    max_u = max(abs(u_old(:)));
    max_v = max(abs(v_old(:)));

    advection_limit = 0.5 / ...
        (max_u/dx + max_v/dy + eps);

    diffusion_limit = 1 / ...
        (2 * nu * (1/dx^2 + 1/dy^2));

    if dt > min(advection_limit, diffusion_limit)
        error('Time step is too large. Reduce dt.');
    end

    % Create new velocity matrices
    u_new = u_old;
    v_new = v_old;

    %Advection - movement of a quantity because it is carried along by a
    %moving fluid
    %Viscosity - momentum spreads between neighboring fluid layers because
    %of internal friction

    % Calculate horizontal velocity changes
    % Advection moves horizontal momentum with the fluid.
    % Viscosity spreads momentum between neighboring points.

    u_new(2:end-1, 2:end-1) = u_old(2:end-1, 2:end-1) ...
        + dt * ( ...
        - u_old(2:end-1, 2:end-1) .* ...
        (u_old(2:end-1, 3:end) - u_old(2:end-1, 1:end-2)) / (2*dx) ...
        - v_old(2:end-1, 2:end-1) .* ...
        (u_old(3:end, 2:end-1) - u_old(1:end-2, 2:end-1)) / (2*dy) ...
        + nu * ( ...
        (u_old(2:end-1, 3:end) - 2*u_old(2:end-1, 2:end-1) ...
        + u_old(2:end-1, 1:end-2)) / dx^2 ...
        + ...
        (u_old(3:end, 2:end-1) - 2*u_old(2:end-1, 2:end-1) ...
        + u_old(1:end-2, 2:end-1)) / dy^2 ) );

    % Calculate vertical velocity changes
    % Advection moves vertical momentum with the fluid.
    % Viscosity spreads momentum between neighboring points.

    v_new(2:end-1, 2:end-1) = v_old(2:end-1, 2:end-1) ...
        + dt * ( ...
        - u_old(2:end-1, 2:end-1) .* ...
        (v_old(2:end-1, 3:end) - v_old(2:end-1, 1:end-2)) / (2*dx) ...
        - v_old(2:end-1, 2:end-1) .* ...
        (v_old(3:end, 2:end-1) - v_old(1:end-2, 2:end-1)) / (2*dy) ...
        + nu * ( ...
        (v_old(2:end-1, 3:end) - 2*v_old(2:end-1, 2:end-1) ...
        + v_old(2:end-1, 1:end-2)) / dx^2 ...
        + ...
        (v_old(3:end, 2:end-1) - 2*v_old(2:end-1, 2:end-1) ...
        + v_old(1:end-2, 2:end-1)) / dy^2 ) );

    % Apply boundary conditions again
    u_new(1, :) = 0;
    u_new(end, :) = lid_velocity;
    u_new(:, 1) = 0;
    u_new(:, end) = 0;

    v_new(1, :) = 0;
    v_new(end, :) = 0;
    v_new(:, 1) = 0;
    v_new(:, end) = 0;
    
    %Current velocity = fluid's movement at the current time step
    %Have only applied provisional velocities, have not applied the
    %pressure correction yet 
    %Provisional velocity is first estimate of how fluid moves
    %Based on the fluid's current movement and viscosity, where will the
    %fluid move next?
    %1.Advection: moving fluid carries momentum with it
    %2.Viscosity: momentum spreads between neighboring fluid layers
    %Pressure correction adjusts that estimate so fluid obeys conservation
    %of mass

    %Incompressible - density stays constant - amount of fluid entering a
    %tiny region must equal the amount leaving it
    %Violations of incompressibility:
    %If more fluid enters than leaves, numerical simulation behaves as
    %though fluid is accumulating there
    %If more fluid leaves than enters, it behaves as though fluid is
    %disappearing
    %Soln: pressure pushes fluid around
    %High pressure pushes fluid away
    %Low pressure allows fluid to move toward that region
    %Pressure differences accelerate the fluid
    %Calc pressure gradients to determine how the velocity should change
    %Incompressibility follows from COM

    % Calculate how much fluid is expanding or compressing
    %Divergence = measures how much fluid is flowing out of or into a tiny
    %region
    divergence = zeros(mesh_y, mesh_x);

    divergence(2:end-1, 2:end-1) = ...
        (u_new(2:end-1, 3:end) - u_new(2:end-1, 1:end-2)) / (2*dx) ...
        + ...
        (v_new(3:end, 2:end-1) - v_new(1:end-2, 2:end-1)) / (2*dy);

    %Print maximum divergence every 100 steps
    if mod(step, 100) == 0
        fprintf('Maximum divergence: %.6f\n', max(abs(divergence(:))));
    end

    %Pressure Poisson equation - estimate pressure throughout the grid
    %Calculate pressure using the pressure Poisson equation

    % Set pressure solver accuracy
    pressure_tolerance = 1e-6;
    pressure_residual = Inf;

    %Pressure depends on divergence
    %Divergence and pressure depend on velocity
    %Pressure correction makes the fluid behave like an incompressible
    %fluid by adjusting its velocity so that fluid doesn't artificially
    %accumulate or disappear at individual points in simulation
    for iter = 1:pressure_iterations

        p_old = p;

        p(2:end-1, 2:end-1) = ...
            ((p_old(2:end-1, 3:end) + p_old(2:end-1, 1:end-2)) * dy^2 ...
            + (p_old(3:end, 2:end-1) + p_old(1:end-2, 2:end-1)) * dx^2 ...
            - (rho * dx^2 * dy^2 / dt) * divergence(2:end-1, 2:end-1)) ...
            / (2 * (dx^2 + dy^2));

        % Pressure boundary conditions
        p(:,1) = p(:,2);
        p(:,end) = p(:,end-1);
        p(1,:) = p(2,:);
        p(end,:) = p(end-1,:);

        % Calculate the pressure Poisson equation residual

        pressure_laplacian = ...
            (p(2:end-1, 3:end) - 2*p(2:end-1, 2:end-1) ...
            + p(2:end-1, 1:end-2)) / dx^2 ...
            + ...
            (p(3:end, 2:end-1) - 2*p(2:end-1, 2:end-1) ...
            + p(1:end-2, 2:end-1)) / dy^2;

        pressure_rhs = (rho / dt) * divergence(2:end-1, 2:end-1);

        pressure_residual = max(abs(pressure_laplacian(:) - pressure_rhs(:)));

        % Stop if the pressure solution is sufficiently accurate

        if pressure_residual < pressure_tolerance
            break;
        end
    end

    if mod(step, 100) == 0
        fprintf('Pressure residual: %.8e\n', pressure_residual);
    end

    % Correct horizontal velocity using pressure
    u_new(2:end-1, 2:end-1) = ...
        u_new(2:end-1, 2:end-1) ...
        - (dt / rho) * ...
        (p(2:end-1, 3:end) - p(2:end-1, 1:end-2)) / (2*dx);

    % Correct vertical velocity using pressure
    v_new(2:end-1, 2:end-1) = ...
        v_new(2:end-1, 2:end-1) ...
        - (dt / rho) * ...
        (p(3:end, 2:end-1) - p(1:end-2, 2:end-1)) / (2*dy);

    % Reapply boundary conditions
    u_new(1,:) = 0;
    u_new(end,:) = lid_velocity;
    u_new(:,1) = 0;
    u_new(:,end) = 0;

    v_new(1,:) = 0;
    v_new(end,:) = 0;
    v_new(:,1) = 0;
    v_new(:,end) = 0;

    u = u_new;
    v = v_new;

    % Measure how much the velocity changes between time steps

    velocity_change = max([ ...
        max(abs(u(:) - u_old(:))), ...
        max(abs(v(:) - v_old(:))) ]);

    if mod(step, 100) == 0
        fprintf('Velocity change: %.8f\n', velocity_change);
    end

    % Check incompressibility AFTER pressure correction

    divergence_corrected = zeros(mesh_y, mesh_x);

    divergence_corrected(2:end-1, 2:end-1) = ...
        (u(2:end-1, 3:end) - u(2:end-1, 1:end-2)) / (2*dx) ...
        + ...
        (v(3:end, 2:end-1) - v(1:end-2, 2:end-1)) / (2*dy);

    % Display maximum corrected divergence every 100 steps

    if mod(step, 100) == 0
        fprintf('Maximum divergence AFTER pressure correction: %.8f\n', ...
            max(abs(divergence_corrected(:))));
    end
    
    %display the velocity field only after the pressure correction
    % Display the corrected velocity field every 10 time steps
    % Update the animation every simulation step

    % Calculate how far the animation has progressed
    progress = step / time_steps;

    % Create a multiplier based on vertical position
    % Bottom arrows receive a larger multiplier than top arrows
    Y_multiplier = 1 + 5 * (1 - Y_plot / height);

    % Make the bottom arrows grow faster over time
    animation_multiplier = 1 + 2 * progress;

    % Combine the position multiplier and time multiplier
    combined_multiplier = animation_multiplier .* Y_multiplier;

    % Update horizontal and vertical arrow lengths
    q.UData = combined_multiplier .* u(1:6:end, 1:6:end);
    q.VData = combined_multiplier .* v(1:6:end, 1:6:end);

    % Update the animation title
    titleHandle.String = ...
        ['Fluid Velocity - Time Step: ', num2str(step)];

    % Refresh the animation
    drawnow;

    %Pause before displaying the next frame
    pause(0.05);
end 

% FINAL VELOCITY FIELD

figure;

quiver(X(1:6:end,1:6:end), ...
    Y(1:6:end,1:6:end), ...
    u(1:6:end,1:6:end), ...
    v(1:6:end,1:6:end), 0.25); %last param stands for arrow scaling

title('Final Fluid Velocity Field');
xlabel('X Position (m)');
ylabel('Y Position (m)');

axis equal;
xlim([0 length]);
ylim([0 height]);


% FINAL HORIZONTAL VELOCITY

figure;

contourf(X, Y, u, 20, 'LineColor', 'none');

colorbar;

title('Final Horizontal Velocity');
xlabel('X Position (m)');
ylabel('Y Position (m)');

axis equal;

%Velocity field - arrows show the direction and magnitude of fluid velocity
%Horizontal velocity - colors show how quickly fluid moves horizontally
%Vertical velocity - colors show how quickly fluid moves vertically
%Fluid speed - colors show the total speed, regardless of direction

% FINAL VERTICAL VELOCITY

figure;

contourf(X, Y, v, 20, 'LineColor', 'none');

colorbar;

title('Final Vertical Velocity');
xlabel('X Position (m)');
ylabel('Y Position (m)');

axis equal;


% FINAL SPEED FIELD

speed = sqrt(u.^2 + v.^2);

figure;

contourf(X, Y, speed, 20, 'LineColor', 'none');

colorbar;

title('Final Fluid Speed');
xlabel('X Position (m)');
ylabel('Y Position (m)');

axis equal; 

%Lid-driven cavity = simple fluid mechanics experiment where study how
%fluid moves inside a square container when its top wall moves horizontally
%while the other three walls remain stationary
%Fluid touching the walls follows their movement because of a physical
%principle called the no-slip boundary condition
%Fluid mechanics is the branch of physics that studies how liquids and
%gases behave, move, and interact with forces
%Two types of mechanics:
%1. statics: at rest
%2. dynamics: in motion
%this belongs to fluid dynamics, because are modeling how water moves
%inside a container
%Doing computational fluid dynamics (CFD), which uses math, physics, and
%numerical methods to simulate fluid behavior on a computer
%Fluid mechanics gives physics, Navier-Stokes gives math model, and MATLAB
%lets simulate that model computationally

% FINAL STREAMLINE VISUALIZATION

figure;

streamslice(X, Y, u, v);

title('Fluid Streamlines');
xlabel('X Position (m)');
ylabel('Y Position (m)');

axis equal;
xlim([0 length]);
ylim([0 height]);

%Check the final simulation results

%Check the dimensions of the velocity and pressure matrices
disp('Matrix dimensions');

size(u)
size(v)
size(p)

%Check the maximum and minimum horizontal velocity
disp('Horizontal velocity:');

max(u(:))
min(u(:))

% Check the maximum and minimum vertical velocity
disp('Vertical velocity:');

max(v(:))
min(v(:))

%Check the maximum and minimum pressure
disp('Pressure');

max(p(:))
min(p(:))