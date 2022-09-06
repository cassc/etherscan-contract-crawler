/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File contracts/PoRAddressList.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPoRAddressList {
    /// @notice Get total number of addresses in the list.
    function getPoRAddressListLength() external view returns (uint256);

    /**
     * @notice Get a batch of human-readable addresses from the address list.
     * @dev Due to limitations of gas usage in off-chain calls, we need to support fetching the addresses in batches.
     * EVM addresses need to be converted to human-readable strings. The address strings need to be in the same format
     * that would be used when querying the balance of that address.
     * @param startIndex The index of the first address in the batch.
     * @param endIndex The index of the last address in the batch. If `endIndex > getPoRAddressListLength()-1`,
     * endIndex need to default to `getPoRAddressListLength()-1`. If `endIndex < startIndex`, the result would be an
     * empty array.
     * @return Array of addresses as strings.
     */
    function getPoRAddressList(uint256 startIndex, uint256 endIndex)
        external
        view
        returns (string[] memory);
}

contract PoRAddressList is IPoRAddressList {
    string[] private addresses;

    constructor(string[] memory _addresses) {
        addresses = _addresses;
    }

    function getPoRAddressListLength()
        external
        view
        override
        returns (uint256)
    {
        return addresses.length;
    }

    function getPoRAddressList(uint256 startIndex, uint256 endIndex)
        external
        view
        override
        returns (string[] memory)
    {
        if (startIndex > endIndex) {
            return new string[](0);
        }
        endIndex = endIndex > addresses.length - 1
            ? addresses.length - 1
            : endIndex;
        string[] memory stringAddresses = new string[](
            endIndex - startIndex + 1
        );
        uint256 currIdx = startIndex;
        uint256 strAddrIdx = 0;
        while (currIdx <= endIndex) {
            stringAddresses[strAddrIdx] = addresses[currIdx];
            strAddrIdx++;
            currIdx++;
        }
        return stringAddresses;
    }
}