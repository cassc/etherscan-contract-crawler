// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IWhitelist.sol";

contract WhitelistUpgradeable is Initializable, ContextUpgradeable {
  address private _whitelistAddress;

  event WhitelistChanged(address indexed newOwner);


  function __WhitelistUpgradeable_init(address whitelistAddress_) internal onlyInitializing {
    __WhitelistUpgradeable_init_unchained(whitelistAddress_);
  }

  function __WhitelistUpgradeable_init_unchained(address whitelistAddress_) internal onlyInitializing {
    _whitelistAddress = whitelistAddress_;
  }

  modifier validateAdmin() {
    bytes32 ADMIN_ROLE = IWhitelist(_whitelistAddress).ADMIN_ROLE();
    require (IWhitelist(_whitelistAddress).hasRole(ADMIN_ROLE, msg.sender), "WhitelistWrapper: You don't have admin role");
    _;
  }

  modifier validateGranter() {
    bytes32 GRANT_ROLE = IWhitelist(_whitelistAddress).GRANT_ROLE();
    require (IWhitelist(_whitelistAddress).hasRole(GRANT_ROLE, msg.sender), "WhitelistWrapper: You don't have admin role");
    _;
  }

  modifier validateGranterOnPerson(address _address){
    bytes32 GRANT_ROLE = IWhitelist(_whitelistAddress).GRANT_ROLE();
    require(IWhitelist(_whitelistAddress).hasRole(GRANT_ROLE, _address), "WhitelistWrapper: You don't have grant role");
    _;
  }

  modifier validateAdminOnPerson(address _address){
    bytes32 ADMIN_ROLE = IWhitelist(_whitelistAddress).ADMIN_ROLE();
    require(IWhitelist(_whitelistAddress).hasRole(ADMIN_ROLE, _address), "WhitelistWrapper: You don't have admin role");
    _;
  }



  function setWhitelistAddress(address whitelistAddress_) external virtual validateAdmin {
    _whitelistAddress = whitelistAddress_;
    emit WhitelistChanged(_whitelistAddress);
  }
}