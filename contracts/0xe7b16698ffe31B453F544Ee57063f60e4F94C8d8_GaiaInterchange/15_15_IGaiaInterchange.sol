// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC721G.sol";
import "./IERC20G.sol";

interface IGaiaInterchange {
    error LengthNotEqual();
    error Unauthorized();
    error AmountZero();
    error PriceAlreadySettled();
    error Unchanged();
    error AddressZero();
    error OutOfRange();
    error InvalidNFT();

    enum TokenType {
        ERC20,
        ERC721
    }
    enum NFTType {
        MINTABLE,
        UNMINTABLE
    }

    event SetNFTInfo(address indexed nft, NFTInfo info);
    event SetTreasury(address indexed newTreasury);
    event SetFeeRate(uint256 newFeeRate);
    event TrasferFee(address indexed _treasury, uint256 fee);
    event EmergencyWithdraw(TokenType[] tokenTypes, bytes[] data);
    event BuyNFT(address indexed nft, uint256 indexed tokenId, address indexed nftTo, NFTType _type, uint256 price);
    event BuyNFTBatch(
        address indexed nft,
        uint256[] tokenIds,
        address indexed nftTo,
        NFTType _type,
        uint256 totalPrice
    );
    event SellNFT(
        address indexed nft,
        uint256 indexed tokenId,
        address indexed priceTo,
        NFTType _type,
        uint256 totalPrice
    );
    event SellNFTBatch(
        address indexed nft,
        uint256[] tokenIds,
        address indexed priceTo,
        NFTType _type,
        uint256 totalPrice
    );

    struct NFTInfo {
        uint248 price;
        NFTType nftType;
    }

    function GAIA() external view returns (IERC20G);

    function treasury() external view returns (address);

    function feeRate() external view returns (uint256);

    function nftInfo(address nft) external view returns (NFTInfo memory);

    function buyNFT(address nft, uint256 id, address nftTo) external;

    function buyNFTBatch(address nft, uint256[] calldata ids, address nftTo) external;

    function sellNFT(address nft, uint256 id, address priceTo) external;

    function sellNFTBatch(address nft, uint256[] calldata ids, address priceTo) external;
}