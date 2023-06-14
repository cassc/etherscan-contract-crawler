// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9.0;

import 'openzeppelin-contracts/interfaces/IERC165.sol';
import 'openzeppelin-contracts/interfaces/IERC2981.sol';
import 'openzeppelin-contracts/interfaces/IERC721.sol';
import 'openzeppelin-contracts/interfaces/IERC721Enumerable.sol'; 
import 'openzeppelin-contracts/interfaces/IERC721Metadata.sol';

/**
This is an interface that combines the interfaces that should be implemented in the final contract.
The dependency on this file should be removed prior to deployment.
 */
interface INFT is 
  IERC165,
  IERC721,
  IERC2981
  {
  }