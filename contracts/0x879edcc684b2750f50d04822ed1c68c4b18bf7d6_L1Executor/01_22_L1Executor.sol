// SPDX-FileCopyrightText: 2023 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

import {IZkSync} from "@matterlabs/zksync-contracts/l1/contracts/zksync/interfaces/IZkSync.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract L1Executor is Initializable, OwnableUpgradeable {
    IZkSync public zksync;

    /// @dev Contract is expected to be used as proxy implementation.
    /// @dev Disable the initialization to prevent Parity hack.
    constructor() {
        _disableInitializers();
    }

    function initialize(IZkSync _zksync, address _newOwner) external initializer {
        __Ownable_init();
        _transferOwnership(_newOwner);
        zksync = _zksync;
    }

    function callZkSync(
        address contractAddr,
        bytes memory data,
        uint256 gasLimit,
        uint256 gasPerPubdataByteLimit
    ) external payable onlyOwner {
        zksync.requestL2Transaction{value: msg.value}(
            contractAddr,
            0,
            data,
            gasLimit,
            gasPerPubdataByteLimit,
            new bytes[](0),
            msg.sender
        );
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}