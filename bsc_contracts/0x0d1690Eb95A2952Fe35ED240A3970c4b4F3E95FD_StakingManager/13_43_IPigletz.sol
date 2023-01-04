// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./IPigletWallet.sol";
import "../boosters/IBooster.sol";

interface IPigletz is IERC721Enumerable {
    enum ZodiacSign {
        Aries,
        Taurus,
        Gemini,
        Cancer,
        Leo,
        Virgo,
        Libra,
        Scorpio,
        Sagittarius,
        Capricorn,
        Aquarius,
        Pisces
    }
    struct TokenData {
        address token;
        uint256 balance;
        uint256 balanceInUSD;
    }

    struct PigletData {
        string uri;
        uint256 tokenId;
        uint8 level;
        uint8 eligibleLevel;
        uint256 pifiBalance;
        uint256 totalValue;
        uint256 dailyMintingRate;
        uint256 boost;
        IPigletWallet wallet;
    }

    event SaleEnded(uint256 totalSold, uint256 totalRevenue);

    event LevelUp(uint256 indexed tokenId, uint8 indexed level, address indexed owner);

    event Materialized(uint256 indexed tokenId);

    event Digitalized(uint256 indexed tokenId);

    function updatePiFiBalance(uint256 tokenId) external;

    function setStaker(address staker) external;

    function setMetaversePortal(address portal) external;

    function materialize(uint256 tokenId) external;

    function digitalize(uint256 tokenId) external;

    function getSign(uint256 tokenId) external view returns (ZodiacSign);

    function getLevel(uint256 tokenId) external view returns (uint8);

    function getWallet(uint256 tokenID) external view returns (IPigletWallet);

    function burn(uint256 tokenId) external;

    function mint(
        address to,
        uint256 amount,
        uint256 probabilityOfSpecial
    ) external;

    function mintCelebrities(address to) external;

    function getStaker() external view returns (address);

   function getMetaversePortal() external view returns (address);

    function maxSupply() external view returns (uint256);

    function tokenCount() external view returns (uint256);

    function isSpecial(uint256 tokenId) external view returns (bool);

    function isCelebrity(uint256 tokenId) external view returns (bool);
}