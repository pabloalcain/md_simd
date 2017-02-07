#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <time.h>
#define TIMESTEP 0.0005

int lattice(int n_particles, double size, double *position, double *velocity);
int first_step(int n_particles, double size, double *position, double *velocity, double *force);
int newton(int n_particles, double size, double *position, double *velocity, double *force, double *potential);
int last_step(int n_particles, double size, double *position, double *velocity, double *force);
double kinetic_energy(int n_particles, double *velocity);

extern void minimum_images(double size, const double *position, int i, int j, double *dr);

void calculate_force(double *force, double *potential, double phicutoff, int i, int j, double *dr);

int main(int argc, char** argv) {
  double *position, *velocity, *force;
  double size;
  int n_particles;
  int n_steps;
  double potential, kinetic;
  n_particles = 8;
  n_steps = 100000;
  size = 3.0;
  position = (double *)malloc(n_particles*3*sizeof(double));
  velocity = (double *)malloc(n_particles*3*sizeof(double));
  force = (double *)malloc(n_particles*3*sizeof(double));
  lattice(n_particles, size, position, velocity);
  newton(n_particles, size, position, velocity, force, &potential);
  kinetic = kinetic_energy(n_particles, velocity);
  printf("%g, %g, %g\n", potential, kinetic, potential+kinetic);
  for (int i = 0; i < n_steps; i++) {
    first_step(n_particles, size, position, velocity, force);
    newton(n_particles, size, position, velocity, force, &potential);
    last_step(n_particles, size, position, velocity, force);
    kinetic = kinetic_energy(n_particles, velocity);
    printf("%g, %g, %g\n", potential, kinetic, potential+kinetic);
  }

  return 0;
}

int lattice(int n_particles, double size, double *position, double *velocity) {
  srand(time(NULL));
  int number_side = ceil(cbrt(n_particles));
  double distance = size / number_side;
  int index_particle = 0;
  for (int i = 0; i < number_side; i++) {
    for (int j = 0; j < number_side; j++) {
      for (int k = 0; k < number_side; k++) {
        if (index_particle == n_particles) break;
        position[3*index_particle + 0] = i * distance;
        position[3*index_particle + 1] = j * distance;
        position[3*index_particle + 2] = k * distance;
        index_particle++;
      }
    }
  }
  for (int i = 0; i < 3 * n_particles; i++)
    velocity[i] = (double)rand()/RAND_MAX;
  return 0;
}

int first_step(int n_particles, double size, double *position, double *velocity, double *force) {
  for (int i = 0; i < 3 * n_particles; i++) {
    if (position[i] > size)
      position[i] -= size;
    else if (position[i] < 0)
      position[i] += size;
  }
  for (int i = 0; i < 3 * n_particles; i++) {
    position[i] += velocity[i] * TIMESTEP + force[i]/2 * (TIMESTEP * TIMESTEP);
    velocity[i] += force[i]/2 * TIMESTEP;
  }
  return 0;
}

int newton(int n_particles, double size, double *position, double *velocity, double *force, double *potential) {
  double phicutoff = 4.0/pow(2.5, 12) - 4.0/pow(2.5, 6);
  *potential = 0.0;
  for (int i = 0; i < 3 * n_particles; i++)
    force[i] = 0.0;
  for (int i = 0; i < n_particles; i++) {
    for (int j = i + 1; j < n_particles; j++) {
      double dr[3];
      minimum_images(size, position, i, j, dr);
      calculate_force(force, potential, phicutoff, i, j, dr);
    }
  }
  return 0;
}

void calculate_force(double *force, double *potential, double phicutoff, int i, int j, double *dr) {
  double distance = 0.0;
  for (int k = 0; k < 3; k++) {
    distance += dr[k] * dr[k];
  }
  if (distance < 2.5 * 2.5) {
    double rm2 = 1.0/distance;
    double rm6 = rm2 * rm2 * rm2;
    double rm12 = rm6 * rm6;
    double phi  = 4.0 * (rm12 - rm6);
    double dphi = 24.0*rm2*(2.0*rm12 - rm6);
    for (int k = 0; k < 3; k++) {
      force[3*i+k] += dphi * dr[k];
      force[3*j+k] -= dphi * dr[k];
    }
    *potential += phi - phicutoff;
  }
}
//
//void minimum_images(double size, const double *position, int i, int j, double *dr) {
//  for (int k = 0; k < 3; k++) {
//    dr[k] = position[3*i+k] - position[3*j+k];
//    if (dr[k] > 0.5 * size)
//      dr[k] -= size;
//    else if (dr[k] < -0.5 * size)
//      dr[k] += size;
//  }
//}

int last_step(int n_particles, double size, double *position, double *velocity, double *force) {
  for (int i = 0; i < 3 * n_particles; i++) {
    velocity[i] += force[i]/2 * TIMESTEP;
  }
  return 0;
}

double kinetic_energy(int n_particles, double *velocity) {
  double kin = 0.0;
  for (int i = 0; i < 3 * n_particles; i++) {
    kin += velocity[i] * velocity[i] / 2;
  }
  return kin;
}
