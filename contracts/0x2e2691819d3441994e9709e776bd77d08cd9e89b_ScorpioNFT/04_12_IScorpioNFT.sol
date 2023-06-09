// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IScorpioNFT {
    event PreMint(uint indexed projectId_, address indexed to_, uint amount_);
    event WithdrawProceeds(uint indexed projectId_, uint amount_);
    event WithdrawRoyalties(uint indexed projectId_, uint amount_);
    event Mint(
        uint indexed projectId_,
        uint tokenId_,
        uint projectTokenId_,
        uint price_,
        address indexed to_
    );

    function totalSupply() external view returns (uint);
    function internalTokenToProjectId(uint tokenId_) external view returns (uint);
    function internalTokenToProjectTokenId(uint tokenId_) external view returns (uint);
    function projectToCurrentTokenId(uint projectId_) external view returns (uint);
    function projectToMaxTokenId(uint projectId_) external view returns (uint);
    function projectToMintPrice(uint projectId_) external view returns (uint);
    function projectToRoyaltyAddress(uint projectId_) external view returns (address);
    function projectToRoyaltyFee(uint projectId_) external view returns (uint);
    function projectToRoyalties(uint projectId_) external view returns (uint);
    function projectToProceeds(uint projectId_) external view returns (uint);
    function projectToPreMint(uint projectId_) external view returns (bool);
    function owner() external view returns (address);
    function proxyRegistryAddress() external view returns (address);

    function setupProject(
        uint projectId_,
        uint maxTokenId_,
        uint mintPrice_,
        uint royaltyFee_,
        address royaltyAddress_,
        string memory baseURI_
    ) external;
    function disablePreMint(uint projectId_) external;
    function preMint(uint projectId_, uint count_, address to_) external;
    function withdrawProceeds(uint projectId_) external;
    function withdrawRoyalties(uint projectId_) external;
    function mint(uint projectId_, address to_) external payable returns (uint);
}