/// SPDX-License-Identifier: MIT
/// @author trusttoken team https://github.com/trusttoken/idleFinanceContracts, review and last changes by @bugduino.
/// @title IdleMStableStrategy
/// @notice IIdleCDOStrategy to deploy funds in TrueFi.
pragma solidity ^0.8.10;

import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IIdleCDOStrategy} from "../../interfaces/IIdleCDOStrategy.sol";
import {ITruefiPool, IERC20WithDecimals, ITrueLegacyMultiFarm, ITrueLender, ILoanToken} from "../../interfaces/truefi/ITruefi.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract IdleTruefiStrategy is Initializable, OwnableUpgradeable, ERC20Upgradeable, IIdleCDOStrategy, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for ITruefiPool;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IERC20WithDecimals;

    uint256 private constant PRECISION = 1e30;
    uint256 private constant BASIS_POINTS = 1e4;

    ITruefiPool public _pool;
    ITrueLegacyMultiFarm internal _farm;
    ITrueLender internal _lender;
    IERC20WithDecimals internal _token;
    IERC20WithDecimals internal _rewardToken;
    IERC20Upgradeable[] internal _farmTokens;
    address[] internal _rewardTokens;

    uint256 internal _oneToken;

    address public idleCDO;

    function initialize(ITruefiPool pool, ITrueLegacyMultiFarm farm, address _owner) external initializer {
        ERC20Upgradeable.__ERC20_init(
            string(abi.encodePacked("Idle ", pool.name(), " Strategy")),
            string(abi.encodePacked("idle_", pool.symbol()))
        );
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        _pool = pool;
        _lender = pool.lender();
        _token = pool.token();
        _oneToken = 10**_token.decimals();
        _farm = farm;
        _rewardToken = farm.rewardToken();

        _farmTokens = toArray(IERC20Upgradeable(_pool));
        _rewardTokens = toArray(address(_rewardToken));

        _token.safeApprove(address(_pool), type(uint256).max);
        _pool.safeApprove(address(_farm), type(uint256).max);

        transferOwnership(_owner);
    }

    modifier onlyIdleCDO() {
        require(msg.sender == idleCDO, "Only IdleCDO can call");
        _;
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function token() external view returns (address) {
        return address(_token);
    }

    function strategyToken() external view returns (address) {
        return address(this);
    }

    function tokenDecimals() external view returns (uint256) {
        return _token.decimals();
    }

    function oneToken() external view returns (uint256) {
        return _oneToken;
    }

    function setWhitelistedCDO(address _idleCDO) external onlyOwner {
        require(_idleCDO != address(0), "TruefiPoolStrategy: Address cannot be zero");
        idleCDO = _idleCDO;
    }

    function _redeemRewards() internal returns (uint256[] memory) {
        _farm.claim(_farmTokens);
        uint256 rewards = _rewardToken.balanceOf(address(this));
        if (rewards > 0) {
          _rewardToken.safeTransfer(msg.sender, rewards);
        }
        return _getRewardsArray(rewards);
    }

    function redeemRewards(bytes calldata) external onlyIdleCDO nonReentrant returns (uint256[] memory) {
        return _redeemRewards();
    }

    function _getRewardsArray(uint256 rewards) internal pure returns (uint256[] memory rewardsArray) {
        rewardsArray = new uint256[](1);
        rewardsArray[0] = rewards;
    }

    function pullStkAAVE() external pure returns (uint256) {
        return 0;
    }

    function price() external view returns (uint256) {
        if (_pool.totalSupply() == 0) {
            return _oneToken;
        }
        return (_pool.poolValue() * _oneToken) / _pool.totalSupply();
    }

    function getRewardTokens() external view returns (address[] memory) {
        return _rewardTokens;
    }

    function deposit(uint256 amount) external onlyIdleCDO nonReentrant returns (uint256 tfPoolTokensReceived) {
        if(amount == 0) {
            return 0;
        }

        _token.safeTransferFrom(msg.sender, address(this), amount);
        uint256 tfTokensBalanceBefore = _pool.balanceOf(address(this));
        _pool.join(amount);
        uint256 tfTokensBalanceAfter = _pool.balanceOf(address(this));

        tfPoolTokensReceived = tfTokensBalanceAfter - tfTokensBalanceBefore;
        _mint(msg.sender, tfPoolTokensReceived);

        _farm.stake(_pool, tfPoolTokensReceived);

        uint256 rewardsBalance = _rewardToken.balanceOf(address(this));
        _rewardToken.safeTransfer(msg.sender, rewardsBalance);
    }

    function _redeem(uint256 amount) internal returns (uint256 balance) {
        if(amount == 0) {
            return 0;
        }
        _burn(msg.sender, amount);
        _farm.unstake(_pool, amount);

        _pool.liquidExit(amount);
        balance = _token.balanceOf(address(this));
        _token.safeTransfer(msg.sender, balance);

        _redeemRewards();
    }

    function redeem(uint256 amount) external onlyIdleCDO nonReentrant returns (uint256) {
        return _redeem(amount);
    }

    // Not used in IdleCDOTruefiVariant but kept for reference in case we want to use it in the future
    function redeemUnderlying(uint256 amount) external onlyIdleCDO nonReentrant returns (uint256) {
        // if(amount == 0) {
        //     return 0;
        // }
        // int256 amountInBasisPoints = int256(amount * BASIS_POINTS);

        // uint256 liquidValue = _pool.liquidValue();
        // require(applyPenalty(liquidValue) >= amountInBasisPoints, "TruefiPoolStrategy: Redeem amount is too big");

        // uint256 low = amount;
        // uint256 high = (amount * 11) / 10; // penalty cannot be greater than 10% of amount

        // if (high > liquidValue) {
        //     high = liquidValue;
        // }

        // uint256 oneTokenInBasisPoints = _oneToken * BASIS_POINTS;

        // uint256 x;
        // int256 difference;
        // while (high > low) {
        //     x = (low + high) / 2;
        //     difference = applyPenalty(x) - amountInBasisPoints;
        //     if (abs(difference) <= oneTokenInBasisPoints) {
        //         break;
        //     }
        //     if (difference > 0) {
        //         high = x;
        //     } else {
        //         low = x + 1;
        //     }
        // }

        // uint256 estimatedAmount = (high + low) / 2;
        // uint256 estimatedTfAmount = toTfAmount(estimatedAmount);
        // uint256 senderBalance = balanceOf(msg.sender);

        // if(estimatedTfAmount > senderBalance) {
        //     return _redeem(senderBalance);
        // } else {
        //     return _redeem(estimatedTfAmount);
        // }
    }

    // function applyPenalty(uint256 amount) internal view returns (int256) {
    //     return int256(amount * _pool.liquidExitPenalty(amount));
    // }

    // function toTfAmount(uint256 amount) internal view returns (uint256) {
    //     return (amount * _pool.totalSupply()) / _pool.poolValue();
    // }

    // function abs(int256 x) internal pure returns (uint256) {
    //     return x >= 0 ? uint256(x) : uint256(-x);
    // }

    // may be costly for big loans number
    function getApr() external view returns (uint256) {
        ITruefiPool _truePool = _pool;
        ILoanToken[] memory loans = _lender.loans(_truePool);

        uint256 amountSum;
        uint256 weightedApySum;
        uint256 amount;
        ILoanToken loan;
        for (uint256 i = 0; i < loans.length; ) {
            loan = loans[i];
            amount = loan.amount();
            unchecked {
              amountSum += amount;
              weightedApySum += amount * loan.apy();
              i++;
            }
        }

        amountSum += _truePool.liquidValue();
        if (amountSum == 0) {
            return 0;
        }

        // apy is in the format 100 == 1% so we divide by 100 at the end
        return weightedApySum * 1e18 / amountSum / 100; 
    }

    /// @dev Emergency method
    /// @param erc20 address of the token to transfer
    /// @param value amount of `_token` to transfer
    /// @param to receiver address
    function transferToken(
        address erc20,
        uint256 value,
        address to
    ) external onlyOwner nonReentrant {
        IERC20WithDecimals(erc20).safeTransfer(to, value);
    }

    function toArray(address _address) internal pure returns (address[] memory array) {
        array = new address[](1);
        array[0] = _address;
    }

    function toArray(IERC20Upgradeable _erc20) internal pure returns (IERC20Upgradeable[] memory array) {
        array = new IERC20Upgradeable[](1);
        array[0] = _erc20;
    }
}