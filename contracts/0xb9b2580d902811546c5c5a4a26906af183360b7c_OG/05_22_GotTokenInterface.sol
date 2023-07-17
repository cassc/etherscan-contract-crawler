// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @title The interface to access the GotToken contract to check if an address owns a given token of a given contract
 * @author nfttank.eth
 */
interface GotTokenInterface {
    function ownsTokenOfContract(address possibleOwner, address contractAddress, uint256 tokenId) external view returns (bool);
    function ownsTokenOfContracts(address possibleOwner, address[] calldata upToTenContractAddresses, uint256 tokenId) external view returns (bool[] memory);
}