// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAddressBook.sol";
import "./interfaces/IGateKeeper.sol";


/**
 * @title Address book with portals, synthesis etc.
 *
 * @notice Controlled by DAO and\or multisig (3 out of 5, Gnosis Safe).
 */
contract AddressBook is IAddressBook, Ownable {

    enum RecordTypes { Portal, Synthesis, Router, CryptoPoolAdapter, StablePoolAdapter }

    struct Record {
        /// @dev chainId chain id
        uint64 chainId;
        /// @dev portal/sinthesis address in chainId chain
        address clpEndPoint;
    }

    /// @dev chainId -> portal address
    mapping(uint64 => address) public portal;
    /// @dev chainId -> synthesis address
    mapping(uint64 => address) public synthesis;
    /// @dev chainId -> router address
    mapping(uint64 => address) public router;
    /// @dev cryptoPoolAdapter address
    mapping(uint64 => address) public cryptoPoolAdapter;
    /// @dev stablePoolAdapter address
    mapping(uint64 => address) public stablePoolAdapter;
    /// @dev treasury address
    address public treasury;
    /// @dev whitelist address
    address public whitelist;
    /// @dev gate keeper address
    address public gateKeeper;

    event PortalSet(address portal, uint64 chainId);
    event SynthesisSet(address synthesis, uint64 chainId);
    event RouterSet(address router, uint64 chainId);
    event CryptoPoolAdapterSet(address cryptoPoolAdapter, uint64 chainId);
    event StablePoolAdapterSet(address stablePoolAdapter, uint64 chainId);
    event TreasurySet(address treasury);
    event WhitelistSet(address whitelist);
    event GateKeeperSet(address gateKeeper);

    function bridge() public view returns (address bridge_) {
        if (gateKeeper != address(0)) {
            bridge_ = IGateKeeper(gateKeeper).bridge();
        }
    }

    function setPortal(Record[] memory records) external onlyOwner {
        _setRecords(portal, records, RecordTypes.Portal);
    }

    function setSynthesis(Record[] memory records) external onlyOwner {
        _setRecords(synthesis, records, RecordTypes.Synthesis);
    }

    function setRouter(Record[] memory records) external onlyOwner {
        _setRecords(router, records, RecordTypes.Router);
    }

    function setCryptoPoolAdapter(Record[] memory records) external onlyOwner {
        _setRecords(cryptoPoolAdapter, records, RecordTypes.CryptoPoolAdapter);
    }

    function setStablePoolAdapter(Record[] memory records) external onlyOwner {
        _setRecords(stablePoolAdapter, records, RecordTypes.StablePoolAdapter);
    }

    function setTreasury(address treasury_) external onlyOwner {
        _checkAddress(treasury_);
        treasury = treasury_;
        emit TreasurySet(treasury);
    }

    function setGateKeeper(address gateKeeper_) external onlyOwner {
        _checkAddress(gateKeeper_);
        gateKeeper = gateKeeper_;
        emit GateKeeperSet(gateKeeper);
    }

    function setWhitelist(address whitelist_) external onlyOwner {
        _checkAddress(whitelist_);
        whitelist = whitelist_;
        emit WhitelistSet(whitelist);
    }

    function _setRecords(mapping(uint64 => address) storage map_, Record[] memory records, RecordTypes rtype) private {
        for (uint256 i = 0; i < records.length; ++i) {
            _checkAddress(records[i].clpEndPoint);
            map_[records[i].chainId] = records[i].clpEndPoint;
            _emitEvent(records[i].clpEndPoint, records[i].chainId, rtype);
        }
    }

    function _emitEvent(address endPoint, uint64 chainId, RecordTypes rtype) private {
        if (rtype == RecordTypes.Portal) {
            emit PortalSet(endPoint, chainId);
        } else if (rtype == RecordTypes.Synthesis) {
            emit SynthesisSet(endPoint, chainId);
        } else if (rtype == RecordTypes.Router) {
            emit RouterSet(endPoint, chainId);
        } else if (rtype == RecordTypes.CryptoPoolAdapter) {
            emit CryptoPoolAdapterSet(endPoint, chainId);
        } else if (rtype == RecordTypes.StablePoolAdapter) {
            emit StablePoolAdapterSet(endPoint, chainId);
        }
    }

    function _checkAddress(address checkingAddress) private pure {
        require(checkingAddress != address(0), "AddressBook: zero address");
    }
}