// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../components/SafeOwnableUpgradeable.sol";
import "../libraries/LibSubAccount.sol";
import "../libraries/LibAsset.sol";
import "./Types.sol";
import "./Events.sol";

contract Storage is Initializable, SafeOwnableUpgradeable, Events {
    using LibAsset for Asset;

    LiquidityPoolStorage internal _storage;

    modifier onlyOrderBook() {
        require(_msgSender() == _storage.orderBook, "BOK"); // can only be called by order BOoK
        _;
    }

    modifier onlyLiquidityManager() {
        require(_storage.liquidityManager[_msgSender()], "LQM"); // can only be called by LiQuidity Manager
        _;
    }

    modifier onlyMaintainer() {
        require(_msgSender() == _storage.maintainer || _msgSender() == owner(), "S!M"); // Sender is Not MaiNTainer
        _;
    }

    function _updateSequence() internal {
        unchecked {
            _storage.sequence += 1;
        }
        emit UpdateSequence(_storage.sequence);
    }

    function _updateBrokerTransactions() internal {
        unchecked {
            _storage.brokerTransactions += 1;
        }
    }

    function _blockTimestamp() internal view virtual returns (uint32) {
        return uint32(block.timestamp);
    }

    function _hasAsset(uint8 assetId) internal view returns (bool) {
        return assetId < _storage.assets.length;
    }

    function _isStable(uint8 tokenId) internal view returns (bool) {
        return _storage.assets[tokenId].isStable();
    }

    bytes32[50] internal _gap;
}