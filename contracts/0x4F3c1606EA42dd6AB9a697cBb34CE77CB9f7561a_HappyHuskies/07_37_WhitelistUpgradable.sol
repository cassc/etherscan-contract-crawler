//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../admin-manager/AdminManagerUpgradable.sol";
import "./WhitelistStorage.sol";

contract WhitelistUpgradable is Initializable, AdminManagerUpgradable {
    using WhitelistStorage for WhitelistStorage.Data;

    mapping(uint8 => WhitelistStorage.Data) internal _whitelists;

    function __Whitelist_init() internal onlyInitializing {
        __AdminManager_init_unchained();
        __Whitelist_init_unchained();
    }

    function __Whitelist_init_unchained() internal onlyInitializing {}

    function updateMerkleTreeRoot(uint8 stageId_, bytes32 merkleTreeRoot_)
        public
        onlyAdmin
    {
        _whitelists[stageId_].merkleTreeRoot = merkleTreeRoot_;
    }

    function merkleTreeRoot(uint8 stageId_) external view returns (bytes32) {
        return _whitelists[stageId_].merkleTreeRoot;
    }

    function addToWhitelist(uint8 stageId_, address[] calldata accounts_)
        public
        onlyAdmin
    {
        for (uint256 i; i < accounts_.length; i++) {
            _whitelists[stageId_].accounts[accounts_[i]] = true;
        }
    }

    function removeFromWhitelist(uint8 stageId_, address[] calldata accounts_)
        public
        onlyAdmin
    {
        for (uint256 i; i < accounts_.length; i++) {
            delete _whitelists[stageId_].accounts[accounts_[i]];
        }
    }

    function isWhitelisted(
        uint8 stageId_,
        address account_,
        bytes32[] calldata proof_
    ) public view returns (bool) {
        return _whitelists[stageId_].isWhitelisted(account_, proof_);
    }

    modifier onlyWhitelisted(
        uint8 stageId_,
        address account_,
        bytes32[] calldata proof_
    ) {
        require(isWhitelisted(stageId_, account_, proof_), "Not whitelisted");
        _;
    }
}