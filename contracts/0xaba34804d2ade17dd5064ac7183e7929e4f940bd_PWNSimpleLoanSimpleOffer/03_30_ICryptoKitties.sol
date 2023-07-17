// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICryptoKitties {
    // Required methods
    function totalSupply() external view returns (uint256 total);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Optional
    function name() external view returns (string memory name);
    function symbol() external view returns (string memory symbol);
    function tokensOfOwner(address _owner) external view returns (uint256[] memory tokenIds);
    function tokenMetadata(uint256 _tokenId, string memory _preferredTransport) external view returns (string memory infoUrl);

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    // Is not part of the interface id
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}