clear;
clc;
format longG
% finds the best value for vol
%phase 1 of rocket
%{
summary:
1. z" = rho_w * w_e^2 * Ae/m - (1/2m)*( rho_atm)*Ac*Cd*(z')^2 -g
2.  mf = ms + pa(t0)*Va(t0)/ (R*Ta(t0)) + rho_w*(Vc - Va(t))
3. Va(t) = Va(t0) +Aeint(w_e(t)dt )(t0 to t)
4. w_e = sqrt(2*(pa(t) - patm)/(rho_w))
5. pa(t) = pa(t0)*[(Va(t0)/Va(t)]^gamma
6. z = z(t0) + int(wdt)(t0 to t)
7. w = int(z"dt)(t0 to t)
 
IC: Va(t0), pa(t0), Ta(t0)
Rocket design: Vc, ms, Ae
Fluids props: gamma, R, rho_w
launch conditions: g,z,patm
Ac -  cross-sectional area of the rocket normal to the air flow
 
IC for pc:
Va(n), w(n), we(n)
1. Va'(n+1) = Va(n) +Ae*we(n)*delt
2. pa'(n+1) = pa0*(Va0/Va'(n+1))^gamma          --> Va'(n+1) from 1
3. pavg'(n+1) = (pa(n) + pa'(n+1))/2            --> pa'(n+1) from 2
4. we'(n+1) = sqrt(2*(pavg'(n+1)-patm)/rho_w))  --> pavg'(n+1) from 3
5. wavg'(n+1) = w(n) + z_dd(n) * delt/2
 
Va(n), we'(n+1)
1. Va(n+1) = Va(n) + Ae*we'(n+1)*delt
2. pa(n+1) = pa0*(Va0/Va(n+1))^gamma            --> Va(n+1) from 1
3. we(n+1) = sqrt(2*(pa(n+1)-patm)/rho_w))      --> pa(n+1) from 2
4. m(n+1)) = ms + ma + rho_w*(Vc- Va(n+1))      --> Va(n+1) from 1
 
%}
%% Rocket design
Vc = 0.0005917; %in m3 CHECKED
ms = 23.83/1000; %in kg CHECKED
Ae = pi*(2.5/100)^2/4; %in m3 CHECKED
r = 65.6/2000; % radius of nosecone CHECKED
h = 85/1000; % height of nosecone CHECKED
Ac = pi*r*(r+sqrt(h^2+r^2)) ; %in m3, taking as surface area of nosecone CHECKED
 
%% Initial Conditions:
 
patm = 101325; %CHECKED
pa0 = 5*patm; %CHECKED
Ta0 = 293.76; %where did this value come from
 
%% Fluids props
gamma = 1.4; %CHECKED
R = 287; % in J/kgK CHECKED
rho_w = 1000; % in kg/m3 CHECKED
rho_a = 1.225; % in kg/m3 CHECKED
 
 
%% Launch condtions
g = 9.81; % in m/s2 CHECKED
z0 = 0; % in m CHECKED
patm = 101325; % in Pa CHECKED
 
%% Loop- predictor corrector
size =1000; %CHECKED
 
percent = 0.1:0.05:1;
Vw0 = zeros(1,length(percent));
ztop = zeros(1,length(percent));
wtop = zeros(1,length(percent));
ttop = zeros(1,length(percent));
pa_end = zeros(1,length(percent));
 k=1;
for i=1:length(percent)
 
    %Value to update for results
    Vw0(i) = percent(i)*Vc; %in percentage of rocket chamber 
    %variables
    Va0 = Vc- Vw0(i);%CHECKED
    ma0 = pa0*Va0/ (R*Ta0); %CHECKED
    mw0 = rho_w * Vw0(i); %CHECKED
    
    %Predictor ICs:
    Va_p = Va0; % initial volume of air in chamber based off of inital water volume input
    wavg_p = 0; %initial velocity and acceleration is 0
    pa_p =pa0; %max pressure
    pavg_p = pa0; %avg pressure
    we_p =sqrt(2*(pa0-patm)/rho_w); %initial exit velocity
    
    %Corrector ICs:
    Va = zeros(1,size); % vol of air
    Va(1) = Vc - Vw0(i); 
    pa =zeros(1,size); % pressure of air
    pa(1) = pa0;
    we = zeros(1,size); % exit velocity
    we(1) = sqrt(2*(pa0-patm)/rho_w); %From eq5
    %calculated
    m = zeros(1,size); %total mass
    m0 = ms + ma0 + mw0; %total mass = mass of rocket + mass of air + mass of water
    m(1) = m0; 
    %calculated
    
    %Drag Coefficient ICs
    z_dd = zeros(1,size);
    z_dd(1) = ((rho_w*we(1)^2*Ae)/m(1)) - g; %no second term because inital rocket velocity is zero
    %calculated;
    w = zeros(1,size);
    w(1) = 0; %initial velocity of rocket = 0
    z = zeros(1,size);
    z(1)= 0; %initial altitude is zero
    t = zeros(1,size); % time
    Cd = 0.45; % Estimated Cd for cone+cylinder, considered Re of magnitude 1000 
    delt = 0.001; %CHECKED
    n = 1;
   
    while pa(n)> patm
        if Va(n) >= Vc
            break
        end
        % fprintf("Va(n) %.4f\n Vc %.4f\n pa(n) %.4f\n patm %.4f\n",Va(n),Vc,pa(n),patm);
        % Predictor
        Va_p = Va(n) +Ae*we(n)*delt;
        pa_p = pa0*(Va0/Va_p)^gamma;          
        pavg_p = (pa(n) + pa_p)/2;      
        we_p = sqrt(2*(pavg_p-patm)/rho_w);  
        wavg_p = w(n) + z_dd(n) * delt/2;
    
        % Corrector
        Va(n+1) = Va(n) + Ae*we_p*delt;
        pa(n+1) = pa0*(Va0/Va(n+1))^gamma;
        we(n+1) = sqrt(2*(pa(n+1)-patm)/rho_w);
        m(n+1) = ms + pa0*Va0/ (R*Ta0) + rho_w*(Vc- Va(n+1));
    
        % z" calc
        z_dd(n+1) = ((rho_w*(we(n+1))^2*Ae)/(m(n+1))) - ((rho_a*Ac*Cd*(wavg_p)^2)/(2*m(n+1))) - g;
        w(n+1) = w(n) + delt*(z_dd(n)+z_dd(n+1))/2;
        z(n+1) = z(n) + delt*(w(n)+w(n+1))/2;
        t(n+1) = t(n) + delt;
        
        if ~isreal(we_p)
            % fprintf("complex %.1f we_p", n ); complex at 95
            break;
        end
        n=n+1;
        
    end
    ztop(i) = z(n);
    wtop(i) = w(n);
    ttop(i) = t(n);
    pa_end(i) =pa(n);
%     if mod(percent(i),0.1) == 0
%         figure(k)
%         plot(t(1:n-1),w(1:n-1))
%         xlabel('Time in s')
%         ylabel('velocity of rocket with time')
%         title('Velocity vs time for volume of water = ',percent(i))
%         k=k+1;
%     end
    
end
figure(k)
plot(percent,ztop)
[ztop_max, index] = max(ztop);
xlabel('Percentage of volume of water')
ylabel('Height reached after all water is propelled (in m)')
title('Volume of water vs height') 


clear;
clc;
format longG
% runs through phase 1, 2 and 3 with the best value of vol
%phase 1 of rocket
%{
summary:
1. z" = rho_w * w_e^2 * Ae/m - (1/2m)*( rho_atm)*Ac*Cd*(z')^2 -g
2.  mf = ms + pa(t0)*Va(t0)/ (R*Ta(t0)) + rho_w*(Vc - Va(t))
3. Va(t) = Va(t0) +Aeint(w_e(t)dt )(t0 to t)
4. w_e = sqrt(2*(pa(t) - patm)/(rho_w))
5. pa(t) = pa(t0)*[(Va(t0)/Va(t)]^gamma
6. z = z(t0) + int(wdt)(t0 to t)
7. w = int(z"dt)(t0 to t)
 
IC: Va(t0), pa(t0), Ta(t0)
Rocket design: Vc, ms, Ae
Fluids props: gamma, R, rho_w
launch conditions: g,z,patm
Ac -  cross-sectional area of the rocket normal to the air flow
 
IC for pc:
Va(n), w(n), we(n)
1. Va'(n+1) = Va(n) +Ae*we(n)*delt
2. pa'(n+1) = pa0*(Va0/Va'(n+1))^gamma          --> Va'(n+1) from 1
3. pavg'(n+1) = (pa(n) + pa'(n+1))/2            --> pa'(n+1) from 2
4. we'(n+1) = sqrt(2*(pavg'(n+1)-patm)/rho_w))  --> pavg'(n+1) from 3
5. wavg'(n+1) = w(n) + z_dd(n) * delt/2
 
Va(n), we'(n+1)
1. Va(n+1) = Va(n) + Ae*we'(n+1)*delt
2. pa(n+1) = pa0*(Va0/Va(n+1))^gamma            --> Va(n+1) from 1
3. we(n+1) = sqrt(2*(pa(n+1)-patm)/rho_w))      --> pa(n+1) from 2
4. m(n+1)) = ms + ma + rho_w*(Vc- Va(n+1))      --> Va(n+1) from 1
 
%}
%% Rocket design
Vc = 0.0005917; %in m3 CHECKED
ms = (29.83+4+2)/1000; %in kg CHECKED
Ae = pi*(2.5/100)^2/4; %in m3 CHECKED
r = 65.6/2000; % radius of nosecone CHECKED
h = 85/1000; % height of nosecone CHECKED
Ac = pi*r*(r+sqrt(h^2+r^2)) ; %in m3, taking as surface area of nosecone CHECKED
 
%% Initial Conditions:
%Value to update for results
Vw0 = 0.7 * Vc; %in percentage of rocket chamber 
 
%variables
Va0 = Vc- Vw0;%CHECKED
patm = 101325; %CHECKED
pa0 = 5*patm; %CHECKED
Ta0 = 293.76; %where did this value come from
 
%% Fluids props
gamma = 1.4; %CHECKED
R = 287; % in J/kgK CHECKED
rho_w = 1000; % in kg/m3 CHECKED
rho_a = 1.225; % in kg/m3 CHECKED
ma0 = pa0*Va0/ (R*Ta0); %CHECKED
mw0 = rho_w * Vw0; %CHECKED
 
%% Launch condtions
g = 9.81; % in m/s2 CHECKED
z0 = 0; % in m CHECKED
patm = 101325; % in Pa CHECKED
 
%% for predictor-corrector
delt = 0.001; %CHECKED
 
 
%% Loop
size =1000; %CHECKED
%Predictor ICs:
Va_p = Va0; % initial volume of air in chamber based off of inital water volume input
wavg_p = 0; %initial velocity and acceleration is 0
pa_p =pa0; %max pressure
pavg_p = pa0; %avg pressure
we_p =sqrt(2*(pa0-patm)/rho_w); %initial exit velocity
 
%Corrector ICs:
Va = zeros(1,size); % vol of air
Va(1) = Vc - Vw0; 
pa =zeros(1,size); % pressure of air
pa(1) = pa0;
we = zeros(1,size); % exit velocity
we(1) = sqrt(2*(pa0-patm)/rho_w); %From eq5
%calculated
m = zeros(1,size); %total mass
m0 = ms + ma0 + mw0; %total mass = mass of rocket + mass of air + mass of water
m(1) = m0; 
%calculated
 
%Drag Coefficient ICs
z_dd = zeros(1,size);
z_dd(1) = ((rho_w*we(1)^2*Ae)/m(1)) - g; %no second term because inital rocket velocity is zero
%calculated;
w = zeros(1,size);
w(1) = 0; %initial velocity of rocket = 0
z = zeros(1,size);
z(1)= 0; %initial altitude is zero
t = zeros(1,size); % time
Cd = 0.45; % Estimated Cd for cone+cylinder, considered Re of magnitude 1000 
 
 
%loop business
n = 1;
 
while pa(n)> patm
    if Va(n) >= Vc
        break
    end
    % fprintf("Va(n) %.4f\n Vc %.4f\n pa(n) %.4f\n patm %.4f\n",Va(n),Vc,pa(n),patm);
    % Predictor
    Va_p = Va(n) +Ae*we(n)*delt;
    pa_p = pa0*(Va0/Va_p)^gamma;          
    pavg_p = (pa(n) + pa_p)/2;      
    we_p = sqrt(2*(pavg_p-patm)/rho_w);  
    wavg_p = w(n) + z_dd(n) * delt/2;
 
    % Corrector
    Va(n+1) = Va(n) + Ae*we_p*delt;
    pa(n+1) = pa0*(Va0/Va(n+1))^gamma;
    we(n+1) = sqrt(2*(pa(n+1)-patm)/rho_w);
    m(n+1) = ms + pa0*Va0/ (R*Ta0) + rho_w*(Vc- Va(n+1));
 
    % z" calc
    %z_dd(n+1) = rho_w*(we(n+1))^2*Ae/m(n+1) - rho_a*Ac*Cd(n+1)*(wavg_p(n+1))^2/(2*m(n+1)) -g;
    z_dd(n+1) = ((rho_w*(we(n+1))^2*Ae)/(m(n+1))) - ((rho_a*Ac*Cd*(wavg_p)^2)/(2*m(n+1))) - g;
    w(n+1) = w(n) + delt*(z_dd(n)+z_dd(n+1))/2;
    z(n+1) = z(n) + delt*(w(n)+w(n+1))/2;
    t(n+1) = t(n) + delt;
    n=n+1;
    if ~isreal(we_p)
        % fprintf("complex %.1f we_p", n ); complex at 95
        break;
    end
end
figure(1);
plot(t(1:(n-1)),z(1:n-1))
xlim([0, 0.1]);
hold on;
ylabel('Height (in m)');
xlabel('Time (in s)');
title('Phase 1: Height vs Time')
fprintf("Height reached after all water is propelled: %.3f m \nTime taken for water to propel (in s): %.4f",z(n),t(n))
 
%% Phase 2
m_end = ms;
t_end = t(n); % has to be t_end calc from phase 1
z_end = z(n); % has to be z at t_end calcfrom phase 1
w_end = w(n); %has to be w and t_end calc from phase 1
 
beta = rho_a*Ac*Cd/(2*m_end);
 
% max time going up
t_max = t_end + atan(w_end*sqrt(beta*g))/sqrt(beta*g);
% max height reached
z_max = z_end - log(cos(sqrt(beta*g)*(t_max-t_end)))/beta;
 
fprintf('\nMaximum height reached in phase 2 (in m): %f.\nTime to reach highest spot (in s): %f.\n', z_max,t_max);
 
%% Phase 3
 
% assuming terminal velocity reached
vt = 1:0.1:5; % in m/s
% drag force should balance weight of rocket
% Fdrag = (1/2)*rho_a*Cd*Ap*vt^2 = m*g
 
% Weight of rocket
m0 = ms + rho_a*Vc;
wt = m0*g; 
Area = zeros(1,length(vt));
% Drag force
Cd_parachute = 1.4;
syms Ap
for i = 1:length(vt)
    % Force balance
    Fdrag = (1/2)*rho_a*Cd_parachute*Ap*vt(i)^2;
    eqn = wt == Fdrag;
    % Area of parachute for required terminal velocity
    Area(i) = solve(eqn, Ap);
end
 
[vt_min, index] = min(vt);
fprintf('Area of parachute for minimum terminal velocity (in m^2) : %.3f \n', Area(index))
 
t_descent = z_max/vt(index);
fprintf('Time of descent (in s): %.4f',t_descent)
 
% Define color gradient
figure(3);
colors = jet(length(vt)); % Jet colormap
scatter(vt, Area, 50, colors, 'filled'); % Scatter plot with color gradient
xlabel('Velocity (m/s)');
ylabel('Area (m^2)');
title('Phase 3: Area vs Velocity with Color Gradient');
colorbar; % Add color bar
 
z_total = z(n)+z_max;
t_total = t(n)+t_max+t_descent;
fprintf("\nTotal height of rocket:%.3f m\nTotal time of flight:%.4f s\nLanding velocity: %.3fm/s\n",z_total, t_total,vt_min)