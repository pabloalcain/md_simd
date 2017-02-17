void minimum_images(double size, const double *position, int i, int j, double *dr) {
  for (int k = 0; k < 3; k++) {
    dr[k] = position[3*i+k] - position[3*j+k];
    if (dr[k] > 0.5 * size)
      dr[k] -= size;
    else if (dr[k] < -0.5 * size)
      dr[k] += size;
  }
}
