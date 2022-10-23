// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/security/PausableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../interface/IBooster.sol";
import "../interface/IPool.sol";
import "../interface/IGauge.sol";
import "../interface/ISwapRouter.sol";
import "../interface/ILendingPool.sol";

abstract contract PbCvxBase is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {

    ISwapRouter constant swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IERC20Upgradeable constant crv = IERC20Upgradeable(0xD533a949740bb3306d119CC777fa900bA034cd52);
    IERC20Upgradeable constant cvx = IERC20Upgradeable(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    IERC20Upgradeable constant wbtc = IERC20Upgradeable(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IERC20Upgradeable constant weth = IERC20Upgradeable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20Upgradeable constant usdc = IERC20Upgradeable(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IBooster constant booster = IBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    IPool public pool;
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

    uint[37] private __gap;
}