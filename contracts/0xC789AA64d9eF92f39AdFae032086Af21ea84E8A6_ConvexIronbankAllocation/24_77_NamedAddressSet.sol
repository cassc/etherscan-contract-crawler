// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/EnumerableSet.sol";

import {IAssetAllocation, INameIdentifier} from "contracts/common/Imports.sol";
import {IZap, ISwap} from "contracts/lpaccount/Imports.sol";

/**
 * @notice Stores a set of addresses that can be looked up by name
 * @notice Addresses can be added or removed dynamically
 * @notice Useful for keeping track of unique deployed contracts
 * @dev Each address must be a contract with a `NAME` constant for lookup
 */
// solhint-disable ordering
library NamedAddressSet {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Set {
        EnumerableSet.AddressSet _namedAddresses;
        mapping(string => INameIdentifier) _nameLookup;
    }

    struct AssetAllocationSet {
        Set _inner;
    }

    struct ZapSet {
        Set _inner;
    }

    struct SwapSet {
        Set _inner;
    }

    function _add(Set storage set, INameIdentifier namedAddress) private {
        require(Address.isContract(address(namedAddress)), "INVALID_ADDRESS");
        require(
            !set._namedAddresses.contains(address(namedAddress)),
            "DUPLICATE_ADDRESS"
        );

        string memory name = namedAddress.NAME();
        require(bytes(name).length != 0, "INVALID_NAME");
        require(address(set._nameLookup[name]) == address(0), "DUPLICATE_NAME");

        set._namedAddresses.add(address(namedAddress));
        set._nameLookup[name] = namedAddress;
    }

    function _remove(Set storage set, string memory name) private {
        address namedAddress = address(set._nameLookup[name]);
        require(namedAddress != address(0), "INVALID_NAME");

        set._namedAddresses.remove(namedAddress);
        delete set._nameLookup[name];
    }

    function _contains(Set storage set, INameIdentifier namedAddress)
        private
        view
        returns (bool)
    {
        return set._namedAddresses.contains(address(namedAddress));
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._namedAddresses.length();
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (INameIdentifier)
    {
        return INameIdentifier(set._namedAddresses.at(index));
    }

    function _get(Set storage set, string memory name)
        private
        view
        returns (INameIdentifier)
    {
        return set._nameLookup[name];
    }

    function _names(Set storage set) private view returns (string[] memory) {
        uint256 length_ = set._namedAddresses.length();
        string[] memory names_ = new string[](length_);

        for (uint256 i = 0; i < length_; i++) {
            INameIdentifier namedAddress =
                INameIdentifier(set._namedAddresses.at(i));
            names_[i] = namedAddress.NAME();
        }

        return names_;
    }

    function add(
        AssetAllocationSet storage set,
        IAssetAllocation assetAllocation
    ) internal {
        _add(set._inner, assetAllocation);
    }

    function remove(AssetAllocationSet storage set, string memory name)
        internal
    {
        _remove(set._inner, name);
    }

    function contains(
        AssetAllocationSet storage set,
        IAssetAllocation assetAllocation
    ) internal view returns (bool) {
        return _contains(set._inner, assetAllocation);
    }

    function length(AssetAllocationSet storage set)
        internal
        view
        returns (uint256)
    {
        return _length(set._inner);
    }

    function at(AssetAllocationSet storage set, uint256 index)
        internal
        view
        returns (IAssetAllocation)
    {
        return IAssetAllocation(address(_at(set._inner, index)));
    }

    function get(AssetAllocationSet storage set, string memory name)
        internal
        view
        returns (IAssetAllocation)
    {
        return IAssetAllocation(address(_get(set._inner, name)));
    }

    function names(AssetAllocationSet storage set)
        internal
        view
        returns (string[] memory)
    {
        return _names(set._inner);
    }

    function add(ZapSet storage set, IZap zap) internal {
        _add(set._inner, zap);
    }

    function remove(ZapSet storage set, string memory name) internal {
        _remove(set._inner, name);
    }

    function contains(ZapSet storage set, IZap zap)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, zap);
    }

    function length(ZapSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(ZapSet storage set, uint256 index)
        internal
        view
        returns (IZap)
    {
        return IZap(address(_at(set._inner, index)));
    }

    function get(ZapSet storage set, string memory name)
        internal
        view
        returns (IZap)
    {
        return IZap(address(_get(set._inner, name)));
    }

    function names(ZapSet storage set) internal view returns (string[] memory) {
        return _names(set._inner);
    }

    function add(SwapSet storage set, ISwap swap) internal {
        _add(set._inner, swap);
    }

    function remove(SwapSet storage set, string memory name) internal {
        _remove(set._inner, name);
    }

    function contains(SwapSet storage set, ISwap swap)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, swap);
    }

    function length(SwapSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(SwapSet storage set, uint256 index)
        internal
        view
        returns (ISwap)
    {
        return ISwap(address(_at(set._inner, index)));
    }

    function get(SwapSet storage set, string memory name)
        internal
        view
        returns (ISwap)
    {
        return ISwap(address(_get(set._inner, name)));
    }

    function names(SwapSet storage set)
        internal
        view
        returns (string[] memory)
    {
        return _names(set._inner);
    }
}
// solhint-enable ordering