// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

/**
 * Interface to the RoyaltyRegistry responsible for looking payout addresses
 */
abstract contract RoyaltyRegistryInterface {
    function getAddress(address custodial)
        external
        view
        virtual
        returns (address);

    function getMediaCustomPercentage(uint256 mediaId, address tokenAddress)
        external
        view
        virtual
        returns (uint16);

    function getExternalTokenPercentage(uint256 tokenId, address tokenAddress)
        external
        view
        virtual
        returns (uint16, uint16);

    function typeOfContract() public pure virtual returns (string calldata);

    function VERSION() public pure virtual returns (uint8);
}