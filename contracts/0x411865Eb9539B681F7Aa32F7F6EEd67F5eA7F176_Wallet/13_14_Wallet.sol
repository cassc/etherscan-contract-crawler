// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./IWallet.sol";
import "./libs/Contributors.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Wallet is AccessControl, IWallet, Ownable, ReentrancyGuard {
    using Contributors for Contributors.Set;
    using Address for address payable;
    Contributors.Set private _contributors;

    bytes32 public constant ADMIN = "ADMIN";
    bytes32 public constant ACCOUNTANT = "ACCOUNTANT";

    // 1000 = 10%
    uint256 public chargeRate = 1000;
    // 10000 = 100%
    uint256 public constant MAX_RATE = 10000;

    // ==================================================
    // constractor
    // ==================================================
    constructor() {
        _grantRole(ADMIN, msg.sender);
    }

    function addContributor(Contributors.Contributor memory contributor)
        public
        onlyRole(ADMIN)
    {
        _contributors.add(contributor);
    }

    function updateContributor(Contributors.Contributor memory contributor)
        public
        onlyRole(ADMIN)
    {
        _contributors.update(contributor);
    }

    function removeContributor(address payable contributorAddress)
        public
        onlyRole(ADMIN)
    {
        _contributors.remove(contributorAddress);
    }

    function getContributors()
        public
        view
        returns (Contributors.Contributor[] memory)
    {
        return _contributors.values();
    }

    function account(address payable organizer)
        external
        payable
        onlyRole(ACCOUNTANT)
        nonReentrant
    {
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < _contributors.length(); i++) {
            totalWeight += _contributors.at(i).weight;
        }

        uint256 charge = (msg.value * chargeRate) / MAX_RATE;
        uint256 rest = msg.value;

        for (uint256 i = 0; i < _contributors.length(); i++) {
            uint256 amount = (charge * _contributors.at(i).weight) /
                totalWeight;
            _contributors.at(i).payee.sendValue(amount);
            rest -= amount;
        }

        organizer.sendValue(rest);
    }

    function withdraw() public payable onlyOwner {
        payable(owner()).sendValue(address(this).balance);
    }

    function setChargeRate(uint256 value) external onlyRole(ADMIN) {
        chargeRate = value;
    }

    // ==================================================================
    // operations
    // ==================================================================
    function grantRole(bytes32 role, address target) public override onlyOwner {
        _grantRole(role, target);
    }

    function revokeRole(bytes32 role, address target)
        public
        override
        onlyOwner
    {
        _revokeRole(role, target);
    }
}