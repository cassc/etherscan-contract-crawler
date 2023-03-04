// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.15;

interface IAccountImplementation {
  function guard() external returns (address);
}