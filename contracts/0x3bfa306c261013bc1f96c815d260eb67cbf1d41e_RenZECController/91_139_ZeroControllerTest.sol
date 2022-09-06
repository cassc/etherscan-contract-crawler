pragma solidity >=0.6.0;

import { ZeroControllerTemplate } from "../controllers/ZeroControllerTemplate.sol";

contract ZeroControllerTest is ZeroControllerTemplate {
  function approveModule(address module, bool flag) public {
    approvedModules[module] = flag;
  }
}