// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "../tokens/ERC20.sol";
import "../utils/SafeERC20.sol";
import "../utils/SafeMath.sol";
import "../interfaces/IVenusProtocol.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Router.sol";
import "./StrategyBase.sol";

contract StrategyVenusFlashBoost is StrategyBase {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    address allowedPairAddress = address(1);

    address public vtoken;
    address public want;
    address public borrowPool;
    
    address constant public rewardToken = address(0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63);
    address constant public wrappedNative = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address constant public unitroller = address(0xfD36E2c2a6789Db23113685031d7F16329158384);
    address constant public router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    address[] public rewardToWantPath;
    address[] public rewardToWrappedNativePath = [rewardToken, wrappedNative];
    address[] public markets;

    uint256 public depositedBalance;
    uint256 public borrowBasis;

     constructor (
        address newVtoken,
        address newBorrowPool,
        uint256 newBorrowBasis,
        address newManager,
        address newVault,
        address newStrategist,
        address[] memory newMarkets
    ) StrategyBase(newManager, newVault, newStrategist) {
        vtoken = newVtoken;
        want = IVenusToken(vtoken).underlying();
        borrowPool = newBorrowPool;
        borrowBasis = newBorrowBasis;
        markets = newMarkets;
        rewardToWantPath = [rewardToken, wrappedNative, want];
        _giveAllowances();
    }

    struct CallbackData {
        bool minting;
        address pool;
        address vToken;
        address borrowedToken;
        uint256 amount;
    }

    fallback() external {
        (address sender, 
         uint256 amount0, 
         uint256 amount1, 
         bytes memory data) = abi.decode(msg.data[4:], 
            (address, 
             uint256, 
             uint256, 
             bytes));
        _callback(sender, amount0, amount1, data);
    }

    function _callback(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes memory data
    ) internal {
        require(msg.sender == allowedPairAddress, "Not an allowed address");
        require(sender == address(this), "Not from this contract");
        CallbackData memory details = abi.decode(data, (CallbackData));
        uint256 borrowedAmount = amount0 > 0 ? amount0 : amount1;
        uint256 fee = ((borrowedAmount * 3) / 997) + 1;
        uint256 repayAmount = borrowedAmount + fee;
        uint256 mintAmount = borrowedAmount + details.amount - fee;
        if (details.minting) {
            IVenusToken(details.vToken).mint(mintAmount);
            IVenusToken(details.vToken).borrow(borrowedAmount);
        } else {
            IVenusToken(details.vToken).repayBorrow(borrowedAmount);
            IVenusToken(details.vToken).redeem(details.amount);
        }
        IERC20(details.borrowedToken).safeTransfer(details.pool, repayAmount);
        allowedPairAddress = address(1);
    }

    function _setupFlash(
        bool minting,
        address pool, 
        address vToken, 
        address borrowedToken, 
        uint256 borrowAmount, 
        uint256 amount) internal {
            allowedPairAddress = pool;
            CallbackData memory callbackData;
            callbackData.minting = minting;
            callbackData.pool = pool;
            callbackData.vToken = vToken;
            callbackData.borrowedToken = borrowedToken;
            callbackData.amount = amount;
            bytes memory flash = abi.encode(callbackData);
            uint256 amount0Out = borrowedToken == IUniswapV2Pair(pool).token0() ? borrowAmount : 0;
            uint256 amount1Out = borrowedToken == IUniswapV2Pair(pool).token1() ? borrowAmount : 0;
            IUniswapV2Pair(pool).swap(
                amount0Out,
                amount1Out,
                address(this),
                flash
            );
    }

    function deposit() public whenNotPaused {
        uint256 wantBal = availableWant();
        if (wantBal > 0) {
            uint256 borrowAmount = wantBal.mul(borrowBasis).div(DIVISOR);
            _setupFlash(true, borrowPool, vtoken, want, borrowAmount, wantBal);
            updateBalance();
        }
    }

    function harvest() external whenNotPaused {
        _claimRewardsAndPayFees(); 
        uint256 rewardBal = IERC20(rewardToken).balanceOf(address(this));
        IUniswapV2Router01(router).swapExactTokensForTokens(
            rewardBal,
            0,
            rewardToWantPath,
            address(this),
            block.timestamp
        );      
        deposit();
    }

    function withdraw(uint256 amount) external {
        require(msg.sender == vault, "not vault");
        uint256 wantBal = availableWant();
        if (wantBal < amount) {
            uint256 borrowAmount = amount.mul(borrowBasis).div(DIVISOR);
            _setupFlash(false, borrowPool, vtoken, want, borrowAmount, amount);
            wantBal = IERC20(want).balanceOf(address(this));
        }
        if (wantBal > amount) {
            wantBal = amount;
        }
        IERC20(want).safeTransfer(vault, wantBal);
        updateBalance();
    }

    function updateBalance() public {
        uint256 supplyBal = IVenusToken(vtoken).balanceOfUnderlying(address(this));
        uint256 borrowBal = IVenusToken(vtoken).borrowBalanceStored(address(this));
        depositedBalance = supplyBal.sub(borrowBal);
    }

    function balanceOf() public view returns (uint256) {
        return balanceOfStrat().add(depositedBalance);
    }

    /**
     * @notice Balance in strat contract
     * @return how much {want} the contract holds.
     */
    function balanceOfStrat() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    /**
     * @return how much {want} the hontract holds
     */
     function availableWant() public view returns (uint256) {
         return IERC20(want).balanceOf(address(this));
     }

     function retireStrategy() external {
        require(msg.sender == vault, "Not vault");
        panic();
        uint256 wantBal = IERC20(want).balanceOf(address(this));
        if (wantBal > 0) {
            IERC20(want).safeTransfer(vault, wantBal);
        }
        uint256 nativeBal = IERC20(wrappedNative).balanceOf(address(this));
        if (nativeBal > 0) {
            IERC20(wrappedNative).safeTransfer(strategist, nativeBal);
        }
        IVenusUnitroller(unitroller).exitMarket(vtoken);
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public onlyManager {
        pause();
        uint256 supplyBal = IVenusToken(vtoken).balanceOfUnderlying(address(this));
        uint256 borrowBal = IVenusToken(vtoken).borrowBalanceStored(address(this));
        _setupFlash(false, borrowPool, vtoken, want, borrowBal, supplyBal);
        _claimRewardsAndPayFees();
    }

    function pause() public onlyManager {
        _pause();
        _removeAllowances();
    }

    function unpause() external onlyManager {
        _unpause();
        _giveAllowances();
        deposit();
    }

    function setBorrowBasis(uint256 newBorrowBasis) external onlyOwner {
        borrowBasis = newBorrowBasis;
    }

    function _claimRewardsAndPayFees() internal {
        IVenusUnitroller(unitroller).claimVenus(address(this), markets);
        uint256 toNativeBal = IERC20(rewardToken).balanceOf(address(this)).mul(strategistFee + keeperFee).div(DIVISOR);
        IUniswapV2Router01(router).swapExactTokensForTokens(
            toNativeBal,
            0,
            rewardToWrappedNativePath,
            address(this),
            block.timestamp
        );
        uint256 nativeBal = IERC20(wrappedNative).balanceOf(address(this));
        uint256 keeperAmount = nativeBal.mul(keeperFee).div(DIVISOR);
        IERC20(wrappedNative).safeTransfer(tx.origin, keeperAmount);
        uint256 strategistAmount = IERC20(wrappedNative).balanceOf(address(this));
        IERC20(wrappedNative).safeTransfer(strategist, strategistAmount);
    }

    function _giveAllowances() internal {
        IVenusUnitroller(unitroller).enterMarkets(markets);
        IERC20(want).safeApprove(vtoken, type(uint256).max);
        IERC20(rewardToken).safeApprove(router, type(uint256).max);
    }

    function _removeAllowances() internal {
        IERC20(want).safeApprove(vtoken, 0);
        IERC20(rewardToken).safeApprove(router, 0);
    }
}