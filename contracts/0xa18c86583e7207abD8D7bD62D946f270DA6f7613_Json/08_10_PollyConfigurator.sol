//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import './Polly.sol';
import './PollyModule.sol';

abstract contract PollyConfigurator {

  string internal constant ADMIN = 'admin';
  string internal constant MANAGER = 'manager';

  function fee(Polly, address, Polly.Param[] memory) public view virtual returns(uint){return 0;}
  function inputs() external view virtual returns (string[] memory){return new string[](0);}
  function outputs() external view virtual returns (string[] memory){return new string[](0);}
  function run(Polly, address, Polly.Param[] memory) external virtual payable returns(Polly.Param[] memory){return new Polly.Param[](0);}

  function _transfer(address module_, address to_) internal {
    _grantAll(to_, module_);
    _revokeAll(address(this), module_);
  }

  function _grantManager(address to_, address module_) internal {
    PMClone m_ = PMClone(module_);
    m_.grantRole(MANAGER, to_);
  }

  function _grantAdmin(address to_, address module_) internal {
    PMClone m_ = PMClone(module_);
    m_.grantRole(ADMIN, to_);
  }

  function _grantAll(address to_, address module_) internal {
    PMClone m_ = PMClone(module_);
    m_.grantRole(ADMIN, to_);
    m_.grantRole(MANAGER, to_);
  }

  function _revokeManager(address to_, address module_) internal {
    PMClone m_ = PMClone(module_);
    m_.revokeRole(MANAGER, to_);
  }

  function _revokeAdmin(address to_, address module_) internal {
    PMClone m_ = PMClone(module_);
    m_.revokeRole(ADMIN, to_);
  }

  function _revokeAll(address to_, address module_) internal {
    PMClone m_ = PMClone(module_);
    m_.revokeRole(MANAGER, to_);
    m_.revokeRole(ADMIN, to_);
  }

}