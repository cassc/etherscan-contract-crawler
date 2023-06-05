// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IGuardedConvexStrategy} from "./interfaces/IGuardedConvexStrategy.sol";
import {GuardedConvexVault} from "./GuardedConvexVault.sol";
import {IConvexBooster} from "./interfaces/IConvexBooster.sol";
import {ICurvePool} from "./interfaces/ICurvePool.sol";
import {ERC20} from "./libs/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import {BasicAccessController as AccessControl} from "./AccessControl.sol";

// User gets to hold the ERC4626 vault shares as a deposit recipt and send them back to this contract for withdrawal
// uses ETC4626 vault to interacto with Curve and Convex

contract Zapper is IGuardedConvexStrategy, AccessControl, Pausable {
    GuardedConvexVault internal vault;
    ICurvePool internal curvePool;
    IConvexBooster internal convexBooster;
    ERC20 internal convexLPToken;
    bool internal _sunset;
    uint256 internal curvePoolPID;
    bool internal initialized;

    constructor() {
        _grantRole(ADMIN_ROLE, _msgSender());
    }

    function initialize(
        address _vaultAddress,
        address _convexBoosterAddress,
        address _curvePoolAddress,
        address _convexLPTokenAddress,
        uint256 _curvePoolPID
    ) external onlyAdmin {
        require(!initialized, "contract already initialized");
        curvePoolPID = _curvePoolPID;
        convexLPToken = ERC20(_convexLPTokenAddress);
        vault = GuardedConvexVault(payable(_vaultAddress));
        curvePool = ICurvePool(_curvePoolAddress);
        convexBooster = IConvexBooster(_convexBoosterAddress);

        curvePool.approve(_convexBoosterAddress, type(uint256).max);
        convexLPToken.approve(_vaultAddress, type(uint256).max);
        vault.approve(_vaultAddress, type(uint256).max);
        _grantRole(EXECUTIVE_ROLE, _vaultAddress);
        initialized = true;
    }

    function _deposit(
        uint256 _ethAmountIn,
        uint256 _minUnderlying,
        address receiver,
        uint256 value
    ) internal returns (uint256) {
        require(value == _ethAmountIn, "value != _ethAmountIn");
        require(value > 0, "no eth sent");
        require(_minUnderlying > 0, "min shares amount is 0");
        (bool balanceCheck, bool ownershipCheck) = vault.isPoolHealthy();
        require(balanceCheck, "pool is not healthy | balance");
        require(ownershipCheck, "pool is not healthy | ownership");
        require(!_sunset, "_sunset is true");

        uint256 curveLPBalance = curvePool.balanceOf(address(this));
        // We got ETH from the user --> Curve LP --> Convex LP
        curvePool.add_liquidity{value: value}(
            [value, 0],
            _minUnderlying // this should be min_mint_amount but test have issues
        );
        // difference between the balance before and after adding liquidity
        uint256 curveLPAmount = curvePool.balanceOf(address(this)) -
            curveLPBalance;

        convexBooster.deposit(curvePoolPID, curveLPAmount, false);
        uint256 convexLPTokenAmount = convexLPToken.balanceOf(address(this));
        require(
            convexLPTokenAmount >= _minUnderlying,
            "not enough assets received"
        );
        // vault reverts if we don't get _minUnderlying (so we don't need to revert here also)
        // Take Convex LP tokens and desposit in the vault and send shares to user
        uint256 shares = vault.depositAndStake(convexLPTokenAmount, receiver);
        emit Deposit(value, receiver, shares, convexLPTokenAmount);
        return shares;
    }

    // user methods
    // user sends eth and gets shares (lp token owneership)
    // despoit checks isPoolHealthy - if false revert
    // if _sunset is true then revert
    // _minUnderlying - we want to make sure we get enough Convex LP tokens. Meaning, we go enough Curve LP tokens. Meaning, we didn't got sandwitched
    function deposit(
        uint256 _ethAmountIn,
        uint256 _minUnderlying
    ) external payable override returns (uint256) {
        return _deposit(_ethAmountIn, _minUnderlying, msg.sender, msg.value);
    }

    function depositToReceiver(
        uint256 _ethAmountIn,
        uint256 _minUnderlying,
        address receiver
    ) external payable override returns (uint256) {
        return _deposit(_ethAmountIn, _minUnderlying, receiver, msg.value);
    }

    function getAmountToWithdrawFromIdleEth(
        uint256 _vaultShareAmount
    ) internal view returns (uint256) {
        uint256 ethAmount = 0;
        uint256 idleETHBalance = address(this).balance;
        if (address(this).balance > 0) {
            // method from the vault so only one contract controls the math (convertToAssets but with a parameter)
            uint256 amountToWithdrawFromIdle = vault.convertToParameterAssets(
                _vaultShareAmount,
                idleETHBalance
            );
            ethAmount += amountToWithdrawFromIdle;
        }
        return ethAmount;
    }

    function withdrawFromVault(
        uint256 _vaultShareAmount,
        address owner
    ) internal {
        //redeem shares from vault get Convex LP tokens
        // gets vault share from the user and redeem them Convex LP tokens
        uint256 convexLPTokenAmount = vault.redeemAndUnstake(
            _vaultShareAmount,
            address(this),
            owner
        );
        // convert Convex LP tokens -> Curve LP  --> ETH (monitor the actual amount of ETH you get)

        convexBooster.withdraw(curvePoolPID, convexLPTokenAmount);

        uint256 curveLPAmount = curvePool.balanceOf(address(this));

        curvePool.remove_liquidity_one_coin(curveLPAmount, 0, 0);
    }

    function _withdraw(
        uint256 _vaultShareAmount,
        uint256 _minETHAmount,
        address owner,
        address receiver
    ) internal returns (uint256) {
        uint256 userShareBalance = vault.balanceOf(owner);
        require(_vaultShareAmount <= userShareBalance, "not enough shares");
        require(_vaultShareAmount > 0, "vault share amount is 0");
        require(_minETHAmount > 0, "min ETH amount is 0");
        uint256 ethAmount = 0;
        // check if there is any idle ETH. If yes give use the same a propotional amount of ETH based on the shares
        // 1. Calculate user's share of idle ETH
        uint256 ethAmountFromIdle = getAmountToWithdrawFromIdleEth(
            _vaultShareAmount
        );
        ethAmount += ethAmountFromIdle;
        uint256 idleETHBalanceBeforeVaultWithdraw = address(this).balance;
        // 2. redeem shares from vault get Convex LP tokens, Convex LP tokens -> Curve LP  --> ETH (monitor the actual amount of ETH you get)
        withdrawFromVault(_vaultShareAmount, owner);

        // 3. send the user the ETH we got from vault Convex LP + what we got from the idle ETH
        uint256 balanceChange = address(this).balance -
            idleETHBalanceBeforeVaultWithdraw;
        ethAmount += balanceChange;
        require(ethAmount >= _minETHAmount, "not enough ETH received");
        payable(receiver).transfer(ethAmount);
        emit Withdraw(ethAmount, owner, _vaultShareAmount);
        return ethAmount;
    }

    // user states amount of shares and gets eth
    // user get ETH from idle in same proportion of the share amount
    function withdraw(
        uint256 _vaultShareAmount,
        uint256 _minETHAmount
    ) external override returns (uint256) {
        return
            _withdraw(_vaultShareAmount, _minETHAmount, msg.sender, msg.sender);
    }

    function withdrawToReceiver(
        uint256 _vaultShareAmount,
        uint256 _minETHAmount,
        address receiver
    ) external override returns (uint256) {
        return
            _withdraw(_vaultShareAmount, _minETHAmount, msg.sender, receiver);
    }

    // preview amount of shares to recieve for amount deposited
    function previewDeposit(
        uint256 _amountETH
    ) external view override returns (uint256) {
        // NOTE estimate how much convex LP i get with the eth amount | convexLP and curveLP are 1:1 thats why we can get away with only calculating the LPs with the curve pool
        uint256 convexLPAmount = curvePool.calc_token_amount(
            [_amountETH, 0],
            true
        );

        return convexLPAmount;
    }

    // preview amount of eth to recieve for amount of shares
    function previewWithdraw(
        uint256 _amountShares
    ) external view override returns (uint256) {
        // get convexLPAmount from vault
        uint256 convexLPAmount = vault.previewRedeem(_amountShares);

        // convexLP -> curveLP -> ETH
        // assuming convexLP and curveLP are 1:1
        uint256 minEthAmount = curvePool.calc_withdraw_one_coin(
            convexLPAmount,
            0
        );

        uint256 ethAmountFromIdle = getAmountToWithdrawFromIdleEth(
            _amountShares
        );
        return minEthAmount + ethAmountFromIdle;
    }

    receive() external payable {
        //
    }

    ////// previlged methods //////

    function sendIdleAmountToVault(
        uint256 _amountEthToSend
    ) external onlyExecutive /**add access control */ {
        // send ETH to vault
        payable(address(vault)).transfer(_amountEthToSend);
    }

    function sunset() external onlyAdmin /**add access control */ {
        // disables deposits
        _pause();
    }

    function unSunset() external onlyAdmin /**add access control */ {
        // enables deposits
        _unpause();
    }

    function getCurvePoolPID() external view returns (uint256) {
        return curvePoolPID;
    }
}