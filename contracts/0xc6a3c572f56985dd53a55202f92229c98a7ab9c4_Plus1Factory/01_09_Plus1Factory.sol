// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "openzeppelin/contracts/proxy/Clones.sol";
import "./Plus1.sol";

/// ███╗   ██╗███████╗██████╗ ██╗   ██╗ ██████╗ ██╗   ██╗███████╗
/// ████╗  ██║██╔════╝██╔══██╗██║   ██║██╔═══██╗██║   ██║██╔════╝
/// ██╔██╗ ██║█████╗  ██████╔╝██║   ██║██║   ██║██║   ██║███████╗
/// ██║╚██╗██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██║   ██║██║   ██║╚════██║
/// ██║ ╚████║███████╗██║  ██║ ╚████╔╝ ╚██████╔╝╚██████╔╝███████║
/// ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝  ╚═══╝   ╚═════╝  ╚═════╝ ╚══════╝
/// work with us: nervous.net
///                       __        _
///                      /\ \     /' \
///                      \_\ \___/\_, \
///                     /\___  __\/_/\ \
///                     \/__/\ \_/  \ \ \
///                         \ \_\    \ \_\
///                          \/_/     \/_/
///
/// @title  Plus1Factory
/// @notice Efficently and permissionlessly create Plus1 contracts
/// @author Nervous / [email protected]
contract Plus1Factory {
    /// @notice Emitted when a Plus1 contract is created via factory
    /// @param original The original contract determining Plus1 mint/burn/tranfer approval
    /// @param plus1    The address of the Plus1 contract
    /// @param index    The index of the Plus1 contract
    event CreatePlus1(
        address indexed original,
        address indexed plus1,
        uint256 index
    );

    address[] public originals;
    mapping(address => Plus1[]) private _plus1s;
    Plus1 public impl;

    constructor() {
        impl = new Plus1();
        impl.init(address(this), "", "", ITokenOwner(address(0)), "");
    }

    /// @notice Create a Plus1 ERC-721.
    /// @dev Emits `CreatePlus1` event with the newly created contract's address.
    ///      Adds the new Plus1 to an array that can be looked up via original contract
    /// @param name     Name of the ERC-721 Plus1.
    /// @param symbol   Symbol of the ERC-721 Plus1.
    /// @param original Address of another contract (like an ERC-721) that determines ownership.
    ///                 Must implement `ownerOf(tokenId)`.
    /// @param baseURI  The base of the URI for metadata. ID will be appended in tokenURI(tokenId) calls.
    /// @return p1      The address of the new Plus1 contract.
    function createPlus1(
        string memory name,
        string memory symbol,
        ITokenOwner original,
        string memory baseURI
    ) external returns (Plus1 p1) {
        p1 = Plus1(Clones.clone(address(impl)));
        p1.init(msg.sender, name, symbol, original, baseURI);

        Plus1[] storage p1s = _plus1s[address(original)];
        uint256 index = p1s.length;
        if (index == 0) {
            originals.push(address(original));
        }
        p1s.push(p1);
        emit CreatePlus1(address(original), address(p1), index);
    }

    /// @notice Get the count of original contracts that have been +1'd
    /// @return The current count.
    function originalsCount() external view returns (uint256) {
        return originals.length;
    }

    /// @notice Get slice of the array of original contracts that have been +1'd
    /// @param index Start index of the slice
    /// @param length Length of the slice
    /// @return The current count.
    function originalsSlice(uint256 index, uint256 length)
        external
        view
        returns (address[] memory)
    {
        address[] memory slice = new address[](length);

        for (uint256 i = 0; i < length; ++i) {
            slice[i] = originals[index + i];
        }
        return slice;
    }

    /// @notice Get the count of Plus1 contracts that have been created
    ///         for a given original.
    /// @param original Address of the contract from which this Plus1 was derived
    /// @return The current count of Plus1s for the given original.
    function plus1sCount(address original) external view returns (uint256) {
        return _plus1s[original].length;
    }

    /// @notice Get slice of the array of original contracts that have been +1'd
    /// @param original Address of the contract from which this Plus1 was derived
    /// @param index Start index of the slice
    /// @param length Length of the slice
    /// @return The current count.
    function plus1sSlice(
        address original,
        uint256 index,
        uint256 length
    ) external view returns (Plus1[] memory) {
        Plus1[] storage p1s = _plus1s[original];
        Plus1[] memory slice = new Plus1[](length);
        for (uint256 i = 0; i < length; ++i) {
            slice[i] = p1s[index + i];
        }
        return slice;
    }

    /// @notice Get the address of a Plus1 given its original and the index.
    /// @param original Address of the contract from which this Plus1 was derived
    /// @param index Index of the Plus1
    /// @return The address of the Plus1 contract.
    function plus1AtIndex(address original, uint256 index)
        external
        view
        returns (Plus1)
    {
        return _plus1s[original][index];
    }
}