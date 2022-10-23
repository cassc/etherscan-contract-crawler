// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/security/PausableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../interface/IBooster.sol";
import "../interface/IGauge.sol";
import "../interface/ILendingPool.sol";
import "../interface/IZap.sol";
import "../interface/IBalancer.sol";

abstract contract PbAuraBase is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {

    IERC20Upgradeable constant bal = IERC20Upgradeable(0xba100000625a3754423978a60c9317c58a424e3D);
    IERC20Upgradeable constant aura = IERC20Upgradeable(0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF);
    IERC20Upgradeable constant wbtc = IERC20Upgradeable(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IERC20Upgradeable constant weth = IERC20Upgradeable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20Upgradeable constant usdc = IERC20Upgradeable(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IBooster constant booster = IBooster(0x7818A1DA7BD1E64c199029E86Ba244a9798eEE10);
    IZap constant zap = IZap(0xB188b1CB84Fb0bA13cb9ee1292769F903A9feC59);
    IBalancer constant balancer = IBalancer(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    IGauge public gauge;
    uint public pid;
    IERC20Upgradeable public lpToken;
    IERC20Upgradeable public rewardToken;
    address public treasury;
    uint public yieldFeePerc;

    ILendingPool constant lendingPool = ILendingPool(0x7937D4799803FbBe595ed57278Bc4cA21f3bFfCB);
    IERC20Upgradeable public aToken;
    uint public lastATokenAmt;
    uint public accRewardPerlpToken;
    uint public accRewardTokenAmt;

    struct User {
        uint lpTokenBalance;
        uint rewardStartAt;
    }
    mapping(address => User) public userInfo;
    mapping(address => uint) internal depositedBlock;

    event Deposit(address indexed account, address indexed tokenDeposit, uint amountToken, uint amountlpToken);
    event Withdraw(address indexed account, address indexed tokenWithdraw, uint amountlpToken, uint amountToken);
    event Harvest(address indexed token, uint amount, uint fee);
    event Claim(address indexed account, uint rewardTokenAmt);
    event SetTreasury(address oldTreasury, address newTreasury);
    event SetYieldFeePerc(uint oldYieldFeePerc, uint newYieldFeePerc);

    function deposit(IERC20Upgradeable token, uint amount, uint amountOutMin) external payable virtual;

    function withdraw(IERC20Upgradeable token, uint lpTokenAmt, uint amountOutMin) external payable virtual;

    function harvest() public virtual;

    function claim() public virtual;

    function setTreasury(address _treasury) external onlyOwner {
        emit SetTreasury(treasury, _treasury);
        treasury = _treasury;
    }

    function setYieldFeePerc(uint _yieldFeePerc) external onlyOwner {
        require(_yieldFeePerc <= 1000, "Fee cannot over 10%");
        emit SetYieldFeePerc(yieldFeePerc, _yieldFeePerc);
        yieldFeePerc = _yieldFeePerc;
    }

    function pauseContract() external onlyOwner {
        _pause();
    }

    function unPauseContract() external onlyOwner {
        _unpause();
    }

    function getPricePerFullShareInUSD() public view virtual returns (uint);

    function getAllPool() public view virtual returns (uint);

    function getAllPoolInUSD() external view virtual returns (uint);

    function getPoolPendingReward() external view virtual returns (uint, uint);

    function getUserPendingReward(address account) external view virtual returns (uint);

    function getUserBalance(address account) external view virtual returns (uint);

    function getUserBalanceInUSD(address account) external view virtual returns (uint);

    function _authorizeUpgrade(address) internal override onlyOwner {}

    uint[38] private __gap;
}