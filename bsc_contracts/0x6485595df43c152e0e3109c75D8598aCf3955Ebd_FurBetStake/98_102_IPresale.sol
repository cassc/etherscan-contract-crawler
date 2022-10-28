// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPresale {
    function approve (address to, uint256 tokenId) external;
    function available (address buyer_, uint256 max_, uint256 price_, uint256 value_, uint256 total_) external view returns (uint256);
    function balanceOf (address owner) external view returns (uint256);
    function buy (bytes memory signature_, uint256 quantity_, uint256 max_, uint256 price_, uint256 value_, uint256 total_, uint256 expiration_) external returns (bool);
    function claim () external;
    function claimed (uint256) external view returns (bool);
    function furToken () external view returns (address);
    function getApproved (uint256 tokenId) external view returns (address);
    function isApprovedForAll (address owner, address operator) external view returns (bool);
    function name () external view returns (string memory);
    function owner () external view returns (address);
    function ownerOf (uint256 tokenId) external view returns (address);
    function paymentToken () external view returns (address);
    function renounceOwnership () external;
    function safeTransferFrom (address from, address to, uint256 tokenId) external;
    function safeTransferFrom (address from, address to, uint256 tokenId, bytes memory _data) external;
    function setApprovalForAll (address operator, bool approved) external;
    function setFurToken (address furToken_) external;
    function setPaymentToken (address paymentToken_) external;
    function setTokenUri (string memory uri_) external;
    function setTreasury (address treasury_) external;
    function setVerifier (address verifier_) external;
    function sold (uint256 max_, uint256 price_, uint256 value_, uint256 total_) external view returns (uint256);
    function supportsInterface (bytes4 interfaceId) external view returns (bool);
    function symbol () external view returns (string memory);
    function tokenByIndex (uint256 index) external view returns (uint256);
    function tokenOfOwnerByIndex (address owner, uint256 index) external view returns (uint256);
    function tokenURI (uint256 tokenId_) external view returns (string memory);
    function tokenValue (uint256) external view returns (uint256);
    function totalSupply () external view returns (uint256);
    function transferFrom (address from, address to, uint256 tokenId) external;
    function transferOwnership (address newOwner) external;
    function treasury () external view returns (address);
    function value (address owner_) external view returns (uint256);
}