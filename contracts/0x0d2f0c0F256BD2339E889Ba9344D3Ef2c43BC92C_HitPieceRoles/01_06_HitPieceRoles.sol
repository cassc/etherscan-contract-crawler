// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../extensions/OwnableUpgradeable.sol";
import "../extensions/IHPRoles.sol";

// import "hardhat/console.sol";

contract HitPieceRoles is Initializable, OwnableUpgradeable, IHPRoles {
  address public adminAddress;
  mapping(address => bool) internal _allowedMarketplaces;

  function initialize(address _adminWallet) initializer public {
    adminAddress = _adminWallet;

    __Ownable_init_unchained();
  }

  function isAdmin(address wallet) public view override returns(bool) {
    return adminAddress == wallet;
  }

  function setAdminAddress(address _adminAddress) external onlyOwner {
    adminAddress = _adminAddress;
  }

  function isApprovedMarketplace(address _marketplaceAddress) public view override returns(bool) {
    return _allowedMarketplaces[_marketplaceAddress];
  }

  function setApprovedMarketplaces(address _marketplaceAddress) external onlyOwner {
    _allowedMarketplaces[_marketplaceAddress] = true;
  }
}