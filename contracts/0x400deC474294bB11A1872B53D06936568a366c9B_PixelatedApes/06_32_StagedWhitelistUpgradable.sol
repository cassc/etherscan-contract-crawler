//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./AdminManagerUpgradable.sol";
import "./Whitelist.sol";

contract StagedWhitelistUpgradable is Initializable, AdminManagerUpgradable {
    using Whitelist for Whitelist.Data;

    mapping(uint8 => Whitelist.Data) internal _whitelistConfigs;

    function __StagedWhitelist_init() internal onlyInitializing {
        __AdminManager_init_unchained();
        __StagedWhitelist_init_unchained();
    }

    function __StagedWhitelist_init_unchained() internal onlyInitializing {}

    function updateMerkleTreeRoot(uint8 stageId_, bytes32 merkleTreeRoot_)
        public
        onlyAdmin
    {
        _whitelistConfigs[stageId_].merkleTreeRoot = merkleTreeRoot_;
    }

    function addToWhitelist(uint8 stageId_, address[] calldata accounts_)
        public
        onlyAdmin
    {
        for (uint256 i; i < accounts_.length; i++) {
            _whitelistConfigs[stageId_].accounts[accounts_[i]] = true;
        }
    }

    function removeFromWhitelist(uint8 stageId_, address[] calldata accounts_)
        public
        onlyAdmin
    {
        for (uint256 i; i < accounts_.length; i++) {
            delete _whitelistConfigs[stageId_].accounts[accounts_[i]];
        }
    }

    modifier isWhitelisted(
        uint8 stageId_,
        address account_,
        bytes32[] calldata proof_
    ) {
        require(
            _whitelistConfigs[stageId_].isWhitelisted(account_, proof_),
            "Not whitelisted"
        );
        _;
    }
}