// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IWrappedERC721.sol";
import "./IGauge.sol";

interface INFTGauge is IWrappedERC721, IGauge {
    event Wrap(uint256 indexed tokenId, address indexed to);
    event Unwrap(uint256 indexed tokenId, address indexed to);
    event Vote(uint256 indexed tokenId, address indexed user, uint256 weight);
    event DistributeDividend(address indexed token, uint256 indexed tokenId, uint256 amount);
    event ClaimDividends(address indexed token, uint256 indexed tokenId, uint256 amount, address indexed to);

    function initialize(
        address _nftContract,
        address _tokenURIRenderer,
        address _minter
    ) external;

    function controller() external view returns (address);

    function minter() external view returns (address);

    function votingEscrow() external view returns (address);

    function futureEpochTime() external view returns (uint256);

    function dividendRatios(uint256 tokenId) external view returns (uint256);

    function dividends(
        address token,
        uint256 tokenId,
        uint256 id
    ) external view returns (uint64 blockNumber, uint192 amountPerShare);

    function lastDividendClaimed(
        address token,
        uint256 tokenId,
        address user
    ) external view returns (uint256);

    function integrateCheckpoint() external view returns (uint256);

    function period() external view returns (int128);

    function periodTimestamp(int128 period) external view returns (uint256);

    function integrateInvSupply(int128 period) external view returns (uint256);

    function periodOf(uint256 tokenId, address user) external view returns (int128);

    function integrateFraction(uint256 tokenId, address user) external view returns (uint256);

    function inflationRate() external view returns (uint256);

    function isKilled() external view returns (bool);

    function userWeight(address user, uint256 tokenId) external view returns (uint256);

    function userWeightSum(address user) external view returns (uint256);

    function points(uint256 tokenId, address user) external view returns (uint256);

    function pointsAt(
        uint256 tokenId,
        address user,
        uint256 _block
    ) external view returns (uint256);

    function pointsSum(uint256 tokenId) external view returns (uint256);

    function pointsSumAt(uint256 tokenId, uint256 _block) external view returns (uint256);

    function pointsTotal() external view returns (uint256);

    function pointsTotalAt(uint256 _block) external view returns (uint256);

    function dividendsLength(address token, uint256 tokenId) external view returns (uint256);

    function userCheckpoint(uint256 tokenId, address user) external;

    function wrap(
        uint256 tokenId,
        uint256 ratio,
        address to,
        uint256 _userWeight
    ) external;

    function unwrap(uint256 tokenId, address to) external;

    function vote(uint256 tokenId, uint256 _userWeight) external;

    function claimDividends(address token, uint256 tokenId) external;
}