// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../libraries/SaferERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BankBase is Ownable {
    using SaferERC20 for IERC20;

    event Mint(uint256 tokenId, address userAddress, uint256 amount);
    event Burn(uint256 tokenId, address userAddress, uint256 amount, address receiver);
    event Harvest(uint256 tokenId, address userAddress, address receiver);

    address positionsManager;

    constructor(address _positionsManager) {
        positionsManager = _positionsManager;
    }

    modifier onlyAuthorized() {
        require(msg.sender == positionsManager || msg.sender == owner(), "1");
        _;
    }

    function name() external pure virtual returns (string memory);

    function getIdFromLpToken(address lpToken) external view virtual returns (bool, uint256);

    function decodeId(uint256 id) external view virtual returns (address, address, uint256);

    function getUnderlyingForFirstDeposit(
        uint256 tokenId
    ) public view virtual returns (address[] memory underlying, uint256[] memory ratios) {
        underlying = new address[](1);
        underlying[0] = getLPToken(tokenId);
        ratios = new uint256[](1);
        ratios[0] = 1;
    }

    function getUnderlyingForRecurringDeposit(
        uint256 tokenId
    ) external view virtual returns (address[] memory, uint256[] memory ratios) {
        return getUnderlyingForFirstDeposit(tokenId);
    }

    function getLPToken(uint256 tokenId) public view virtual returns (address);

    function getRewards(uint256 tokenId) external view virtual returns (address[] memory rewardsArray) {
        return rewardsArray;
    }

    receive() external payable {}

    function getPendingRewardsForUser(
        uint256 tokenId,
        address user
    ) external view virtual returns (address[] memory rewards, uint256[] memory amounts) {}

    function getPositionTokens(
        uint256 tokenId,
        address user
    ) external view virtual returns (address[] memory tokens, uint256[] memory amounts);

    function mint(
        uint256 tokenId,
        address userAddress,
        address[] memory suppliedTokens,
        uint256[] memory suppliedAmounts
    ) public virtual returns (uint256);

    function mintRecurring(
        uint256 tokenId,
        address userAddress,
        address[] memory suppliedTokens,
        uint256[] memory suppliedAmounts
    ) external virtual returns (uint256) {
        return mint(tokenId, userAddress, suppliedTokens, suppliedAmounts);
    }

    function burn(
        uint256 tokenId,
        address userAddress,
        uint256 amount,
        address receiver
    ) external virtual returns (address[] memory, uint256[] memory);

    function harvest(
        uint256 tokenId,
        address userAddress,
        address receiver
    ) external virtual onlyAuthorized returns (address[] memory rewardAddresses, uint256[] memory rewardAmounts) {
        return (rewardAddresses, rewardAmounts);
    }

    function isUnderlyingERC721() external pure virtual returns (bool) {
        return false;
    }
}