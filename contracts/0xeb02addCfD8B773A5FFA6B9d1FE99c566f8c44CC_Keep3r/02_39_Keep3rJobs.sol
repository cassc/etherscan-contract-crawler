// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './Keep3rJobDisputable.sol';
import './Keep3rJobWorkable.sol';
import './Keep3rJobManager.sol';

abstract contract Keep3rJobs is Keep3rJobDisputable, Keep3rJobManager, Keep3rJobWorkable {}