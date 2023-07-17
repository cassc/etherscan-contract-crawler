// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface InterfaceBabyTigers is IERC721 {

    // Events
    event SaleActivation(bool isActive);
    event HolderSaleActivation(bool isActive);
    event WhitelistSaleActivation(bool isActive);


    // Merkle Proofs
    function setMerkleRoot(bytes32 _root) external;
    
    function isWhitelisted(
        address _account,
        bytes32[] calldata _proof
    ) external view returns (bool);

    //Holder status validation

    function isTypicalTigerAvailable(uint256 _tokenId) external view returns(bool);

    // Minting
    function ownerMint(address _to, uint256 _count) external;

    function holderMint(uint256[] calldata _typicalTigerIds, uint256 _count) external;

    function whitelistMint(
        uint256 _count,
        bytes32[] calldata _proof
    ) external payable;

    function mint(uint256 _count) external payable;


    function toggleHolderSaleStatus() external;

    function toggleWhitelistSaleStatus() external;

    function toggleSaleStatus() external;

    function setMintPrice(uint256 _mintPrice) external;

    function setWhitelistMintPrice(uint256 _mintPrice) external;

    function setMaxPurchase(uint256 _maxPurchase) external;

    function lockMetadata() external;

    function withdraw() external;

    function transferOwnership(address newOwner) external;

    function getWalletOfOwner(address owner) external view returns (uint256[] memory);

    function getTotalSupply() external view returns (uint256);

    function setBaseURI(string memory baseURI) external;
}