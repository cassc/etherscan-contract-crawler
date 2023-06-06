// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "./SynthERC20.sol";
import "./interfaces/IOwnable.sol";
import "./interfaces/IAddressBook.sol";
import "./interfaces/ISynth.sol";


contract SynthFactory is AccessControlEnumerable {

    /// @dev operator role id
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// @dev clp address book
    address public addressBook;

    constructor(address addressBook_) {
        require(addressBook_ != address(0), "SynthFactory: zero address");
        addressBook = addressBook_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setAddressBook(address addressBook_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(addressBook_ != address(0), "SynthFactory: zero address");
        addressBook = addressBook_;
    }

    function getCustomSynth(
        address originalToken_,
        uint8 decimals_,
        string memory name_,
        string memory symbol_,
        uint64 chainIdFrom_,
        string memory chainSymbolFrom_
    ) external view returns (address stoken) {
        stoken = _getSynth(
            originalToken_,
            decimals_,
            name_,
            symbol_,
            chainIdFrom_,
            chainSymbolFrom_,
            ISynthAdapter.SynthType.CustomSynth
        );
    }

    function getDefaultSynth(
        address originalToken_,
        uint8 decimals_,
        string memory originalName_,
        string memory originalSymbol_,
        uint64 chainIdFrom_,
        string memory chainSymbolFrom_
    ) external view returns (address stoken) {
        stoken = _getSynth(
            originalToken_,
            decimals_,
            string(abi.encodePacked("s ", originalName_, " ", chainSymbolFrom_)),
            string(abi.encodePacked("s", originalSymbol_, "_", chainSymbolFrom_)),
            chainIdFrom_,
            chainSymbolFrom_,
            ISynthAdapter.SynthType.DefaultSynth
        );
    }

    function deployCustomSynth(
        address originalToken_,
        uint8 decimals_,
        string memory name_,
        string memory symbol_,
        uint64 chainIdFrom_,
        string memory chainSymbolFrom_
    ) external onlyRole(OPERATOR_ROLE) returns (address stoken) {
        stoken = _deploySynth(
            originalToken_,
            decimals_,
            name_,
            symbol_,
            chainIdFrom_,
            chainSymbolFrom_,
            ISynthAdapter.SynthType.CustomSynth
        );
    }

    function deployDefaultSynth(
        address originalToken_,
        uint8 decimals_,
        string memory originalName_,
        string memory originalSymbol_,
        uint64 chainIdFrom_,
        string memory chainSymbolFrom_
    ) external onlyRole(OPERATOR_ROLE) returns (address stoken) {
        stoken = _deploySynth(
            originalToken_,
            decimals_,
            // TODO add EYWA to name
            string(abi.encodePacked("s ", originalName_, " ", chainSymbolFrom_)),
            string(abi.encodePacked("s", originalSymbol_, "_", chainSymbolFrom_)),
            chainIdFrom_,
            chainSymbolFrom_,
            ISynthAdapter.SynthType.DefaultSynth
        );
    }

    function _getSynth(
        address originalToken_,
        uint8 decimals_,
        string memory name_,
        string memory symbol_,
        uint64 chainIdFrom_,
        string memory chainSymbolFrom_,
        ISynthAdapter.SynthType synthType_
    ) private view returns (address stoken) {
        stoken = Create2.computeAddress(
            keccak256(abi.encodePacked(originalToken_, chainIdFrom_)),
            keccak256(abi.encodePacked(
                type(SynthERC20).creationCode,
                abi.encode(name_, symbol_, decimals_, originalToken_, chainIdFrom_, chainSymbolFrom_, synthType_)
            ))
        );
    }

    function _deploySynth(
        address originalToken_,
        uint8 decimals_,
        string memory name_,
        string memory symbol_,
        uint64 chainIdFrom_,
        string memory chainSymbolFrom_,
        ISynthAdapter.SynthType synthType_
    ) private returns (address stoken) {
        stoken = Create2.deploy(
            0,
            keccak256(abi.encodePacked(originalToken_, chainIdFrom_)),
            abi.encodePacked(
                type(SynthERC20).creationCode,
                abi.encode(name_, symbol_, decimals_, originalToken_, chainIdFrom_, chainSymbolFrom_, synthType_)
            )
        );
        address synthesis = IAddressBook(addressBook).synthesis(uint64(block.chainid));
        // TODO what if synthesis will be redeployed?
        IOwnable(stoken).transferOwnership(synthesis);
    }
}