// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

interface ICases {
  /**
   * @dev The Stabilisation Cases
   * Up (Expansion) - Estimated market price >= target price & Basket Factor >= 1.
   * Restock (Expansion) - Estimated market price >= target price & Basket Factor < 1.
   * Confidence (Contraction) - Estimated market price < target price & Basket Factor >= 1.
   * Down (Contraction) - Estimated market price < target price & Basket Factor < 1.
   */
  enum Cases {Up, Restock, Confidence, Down}
}