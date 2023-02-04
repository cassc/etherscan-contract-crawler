// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

interface IKYCToken is IERC721 {
    event Mint(address indexed to, KYCData kycData);
    event Burn(uint256 tokenId, KYCData kycData);
    event UriSet(string oldUri, string newUri);

    struct KYCData {
        address owner;
        bytes32 kycInfo;
    }

    function mint(address to, KYCData calldata kycData) external;

    function burn(uint256 tokenId) external;

    function setUri(string memory newUri) external;

    function getTokenIdCounter() external view returns (uint256);

    function getKycData(uint256 tokenId) external view returns (KYCData memory);
}