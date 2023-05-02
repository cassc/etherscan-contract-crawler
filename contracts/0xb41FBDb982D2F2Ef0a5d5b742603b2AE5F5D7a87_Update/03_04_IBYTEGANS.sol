// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IBYTEGANS {
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function adminAddress() external view returns (address);
    function approve(address to, uint256 tokenId) external payable;
    function balanceOf(address owner) external view returns (uint256);
    function buildImage(uint256 _tokenId) external view returns (string memory);
    function buildMetadata(uint256 _tokenId) external view returns (string memory);
    function collectionDescription() external view returns (string memory);
    function collectionName() external view returns (string memory);
    function cost() external view returns (uint256);
    function defaultMeta() external view returns (string memory);
    function getApproved(uint256 tokenId) external view returns (address);
    function getTokenInfo(uint256 _tokenId) external view returns (string memory, string memory, string memory);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function maxMintAmountPerTx() external view returns (uint256);
    function maxSupply() external view returns (uint256);
    function merkleRoot() external view returns (bytes32);
    function mint(uint256 _mintAmount) external payable;
    function mintForAddress(uint256 _mintAmount, address _receiver) external;
    function name() external view returns (string memory);
    function owner() external view returns (address);
    function ownerAddress() external view returns (address);
    function ownerMint(uint256 _mintAmount) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function paused() external view returns (bool);
    function renounceOwnership() external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external payable;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external payable;
    function setAdminAddress(address _adminAddress) external;
    function setApprovalForAll(address operator, bool approved) external;
    function setCost(uint256 _cost) external;
    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) external;
    function setMerkleRoot(bytes32 _merkleRoot) external;
    function setPaused(bool _state) external;
    function setTokenInfo(uint256 _tokenId, string memory _name, string memory _GIF, string memory _trait) external;
    function setWhitelistMintEnabled(bool _state) external;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
    function tokens(uint256)
        external
        view
        returns (string memory name, string memory GIF, string memory trait, bool updated);
    function totalSupply() external view returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external payable;
    function transferOwnership(address newOwner) external;
    function walletOfOwner(address _owner) external view returns (uint256[] memory);
    function whitelistClaimed(address) external view returns (bool);
    function whitelistMint(uint256 _mintAmount, bytes32[] memory _merkleProof) external payable;
    function whitelistMintEnabled() external view returns (bool);
    function withdraw() external;
}