// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICrowdsale {

    struct Vesting {
        address vestingManager;
        uint256 distributionPercentage;
    }

    /**
     * @dev Emitted when `beneficiary` bought `amount` of token.
     */
    event TokenSold(address indexed beneficiary, uint256 indexed amount);

    /**
     * @dev Emitted when vesting wallet `receiver` received `amount` of token.
     */
    event TokenTransferred(address indexed receiver, uint256 indexed amount);

    /**
     * @dev Emitted when vesting wallet `receiver` received `amount` of token.
     */
    event BonusTransferred(address indexed receiver, uint256 indexed amount);

    /**
     * @dev Emitted when `referrer` get his `level`'s reward from his referee (eg referee bought tokens).
     */
    event RewardEarned(address indexed referrer, uint256 indexed amount, uint256 indexed level);

    function price() external view returns (uint256);
    function raise() external view returns (uint256);
    function start() external view returns (uint256);
    function duration() external view returns (uint256);
    function minAmount() external view returns (uint256);
    function maxAmount() external view returns (uint256);
    function getVestingManagersCount() external view returns (uint256);
    function getVestingManager(uint256 index) external view returns (address, uint256);
    function getVestingWallets(address beneficiary) external view returns (address[] memory);

    function totalSold() external view returns (uint256);
    function totalEarned() external view returns (uint256);
    function totalBonus() external view returns (uint256);

    function BUSD() external view returns (address);
    function USDT() external view returns (address);
    function ARTY() external view returns (address);
    function pancakeRouter() external view returns (address);

    function setPrice(uint256) external;
    function setRaise(uint256) external;
    function setStart(uint64) external;
    function setDuration(uint64) external;
    function setMinAmount(uint256 minAmount_) external;
    function setMaxAmount(uint256 maxAmount_) external;
    function addVestingManager(address vestingManager_, uint256 distributionPercentage_) external;
    function removeVestingManager(uint256 index) external;

    function pause() external;
    function unpause() external;

    function withdraw(address) external;

    function buy(address erc20, uint256 amountIn, uint256 minAmountOut, address referrer) external payable;
}

interface IWhitelistedCrowdsale is ICrowdsale {
    function isInWhitelist(address user, bytes32[] memory proof) external view returns (bool);
    function setWhitelist(bytes32 whitelist_) external;
    function buyWithProof(bytes32[] memory proof, address erc20, uint256 amountIn, uint256 minAmountOut, address referrer) external payable;
}