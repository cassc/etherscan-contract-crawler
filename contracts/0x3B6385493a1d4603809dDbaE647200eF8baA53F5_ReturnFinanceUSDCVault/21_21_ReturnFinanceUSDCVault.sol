// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {IAaveV3Pool} from "./interfaces/IAaveV3Pool.sol";
import {ISwapRouter} from "./interfaces/ISwapRouter.sol";
import {IYearnVault} from "./interfaces/IYearnVault.sol";
import {ICurvePoolV2} from "./interfaces/ICurvePoolV2.sol";
import {IConicOmniPool} from "./interfaces/IConicOmniPool.sol";
import {ICompoundUSDCV3} from "./interfaces/ICompoundUSDCV3.sol";
import {IConicRewardManager} from "./interfaces/IConicRewardManager.sol";
import {IConicLPTokenStaker} from "./interfaces/IConicLPTokenStaker.sol";

/// @title Return Finance USDC Vault
/// @author Stanislav Trenev - <[email protected]>
/// @notice Serves as a vault for generating yield on USDC deposits
/// @dev Inherits the OpenZepplin ERC4626 implentation
contract ReturnFinanceUSDCVault is ERC4626, Ownable, Pausable {
    // Aave, Compound, yEarn, Conic Finance
    mapping(address => uint256) public poolWeight;
    mapping(address => bool) public whitelist;

    string public constant VAULT_NAME = "Return Finance USDC Vault";
    string public constant VAULT_SYMBOL = "rfUSDC";

    // USDC token address
    address public immutable usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    // Wrapped Ether token address
    address public immutable wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // Aave V3 Pool address
    address public immutable aaveV3Pool = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    // Aave yield-bearing USDC token address
    address public immutable aEthUSDC = 0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c;
    // Compound USDC V3 tokena address
    address public immutable cUSDCv3 = 0xc3d688B66703497DAA19211EEdff47f25384cdc3;
    // Yearn USCDC Vault
    address public immutable usdcYVault = 0xa354F35829Ae975e850e23e9615b11Da1B3dC4DE;
    // Conic Finance Omni Pool address
    address public immutable conicPool = 0x07b577f10d4e00f3018542d08a87F255a49175A5;
    // Conic Finance Reward Manager address
    address public immutable conicRewardManager = 0xE976F643d4dc08Aa3CeD55b0CA391B1d11328347;
    // Conic Finance LP Token Staker address
    address public immutable conicLPtokenStaker = 0xeC037423A61B634BFc490dcc215236349999ca3d;
    // CRV (Curve Finance) token address
    address public immutable crvAddress = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    // CVX (Convex Finance) token address
    address public immutable cvxAddress = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    // CNC (Conic Finance) token address
    address public immutable cncAddress = 0x9aE380F0272E2162340a5bB646c354271c0F5cFC;
    // CNC-WETH Curve Pool address
    address public immutable cncWethCurvePool = 0x838af967537350D2C44ABB8c010E49E32673ab94;
    // CVX-WETH Curve Pool address
    address public immutable cvxWethCurvePool = 0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4;
    // CRV-WETH Curve Pool address
    address public immutable crvWethCurvePool = 0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511;
    // Uniswap Swap Router
    address public immutable swapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    error NotInWhitelist(address wrongAddress);
    error UnableToSweep(address token);
    error DepositFailed(address depositor, uint256 amount);
    error WithdrawFailed(address depositor, uint256 amount);
    error IncorrectWeights(uint256 totalWeights);
    error HighSlippage(uint256 minAmountOut, uint256 amountOut);

    modifier onlyWhitelist() {
        if (!whitelist[_msgSender()]) revert NotInWhitelist(_msgSender());
        _;
    }

    receive() external payable {
        emit PoolDonation(_msgSender(), msg.value);
    }

    constructor() ERC4626(IERC20(usdcAddress)) ERC20(VAULT_NAME, VAULT_SYMBOL) {
        poolWeight[conicPool] = 10000;
    }

    function depositToVault(
        uint256 amount,
        address receiver,
        bytes32 proof,
        uint256 minAmountLpConic,
        uint256 minAmountUSDCAfterSwap
    ) external returns (uint256 shares) {
        if (amount == 0) revert DepositFailed(_msgSender(), amount);

        harvestConicRewardsAndSwapForUnderlying(minAmountUSDCAfterSwap);
        shares = deposit(amount, receiver);
        _depositToPools(amount, minAmountLpConic);

        emit DepositToVault(_msgSender(), amount, proof, block.timestamp);
    }

    function withdrawFromVault(uint256 amount, address receiver, address owner, uint256 minAmountUSDCAfterSwap)
        external
        returns (uint256 shares)
    {
        if (amount == 0) revert WithdrawFailed(_msgSender(), amount);

        harvestConicRewardsAndSwapForUnderlying(minAmountUSDCAfterSwap);
        uint256 underlyingTokenBalance = IERC20(usdcAddress).balanceOf(address(this));

        // If there is not enough underlying token(USDC) available, we have to withdraw from the pools
        if (underlyingTokenBalance < amount) {
            _withdrawFromPools(amount);
        }

        shares = withdraw(amount, receiver, owner);

        emit WithdrawFromVault(_msgSender(), amount, block.timestamp);
    }

    function redeemFromVault(uint256 shares, address receiver, address owner, uint256 minAmountUSDCAfterSwap)
        external
        returns (uint256 amount)
    {
        harvestConicRewardsAndSwapForUnderlying(minAmountUSDCAfterSwap);
        uint256 previewAmount = previewRedeem(shares);
        if (previewAmount == 0) revert WithdrawFailed(_msgSender(), amount);
        uint256 underlyingTokenBalance = IERC20(usdcAddress).balanceOf(address(this));

        // If there is not enough underlying token(USDC) available, we have to withdraw from the pools
        if (underlyingTokenBalance < previewAmount) {
            _withdrawFromPools(previewAmount);
        }

        amount = redeem(shares, receiver, owner);

        emit RedeemFromVault(_msgSender(), amount, block.timestamp);
    }

    function deposit(uint256 amount, address receiver)
        public
        override
        onlyWhitelist
        whenNotPaused
        returns (uint256 shares)
    {
        shares = super.deposit(amount, receiver);
    }

    function withdraw(uint256 amount, address receiver, address owner)
        public
        override
        onlyWhitelist
        whenNotPaused
        returns (uint256 shares)
    {
        shares = super.withdraw(amount, receiver, owner);
    }

    function redeem(uint256 shares, address receiver, address owner)
        public
        override
        onlyWhitelist
        whenNotPaused
        returns (uint256 assets)
    {
        assets = super.redeem(shares, receiver, owner);
    }

    function mint(uint256 shares, address receiver)
        public
        override
        onlyWhitelist
        whenNotPaused
        returns (uint256 assets)
    {
        // TODO: Check if needed
        assets = super.mint(shares, receiver);
    }

    function _depositToPools(uint256 amount, uint256 minAmountLpConic) internal {
        // Deposit to Aave protocol
        uint256 aavePoolWeightBps = poolWeight[aaveV3Pool];
        uint256 amountToDepositAave = (amount * aavePoolWeightBps) / 10000;

        if (aavePoolWeightBps > 0) {
            IERC20(usdcAddress).approve(aaveV3Pool, amountToDepositAave);
            IAaveV3Pool(aaveV3Pool).supply(usdcAddress, amountToDepositAave, address(this), 0);
        }

        // Depoist to Compound protocol and receive cUSDCv3 via supply method.
        uint256 compoundPoolWeightBps = poolWeight[cUSDCv3];
        uint256 amountToDepositCompound = (amount * compoundPoolWeightBps) / 10000;

        if (compoundPoolWeightBps > 0) {
            IERC20(usdcAddress).approve(cUSDCv3, amountToDepositCompound);
            ICompoundUSDCV3(cUSDCv3).supply(usdcAddress, amountToDepositCompound);
        }

        // Deposit to yEarn USDC Vault. Using directly the vault, instead of YearnPartnerTracker.
        uint256 yearnPoolWeightBps = poolWeight[usdcYVault];
        uint256 amountToDepositYearn = (amount * yearnPoolWeightBps) / 10000;

        if (yearnPoolWeightBps > 0) {
            IERC20(usdcAddress).approve(usdcYVault, amountToDepositYearn);
            IYearnVault(usdcYVault).deposit(amountToDepositYearn);
        }

        // Deposit to Conic Finance.
        uint256 conicPoolWeightBps = poolWeight[conicPool];
        uint256 amountToDepositConic = (amount * conicPoolWeightBps) / 10000;

        if (conicPoolWeightBps > 0) {
            IERC20(usdcAddress).approve(conicPool, amountToDepositConic);
            IConicOmniPool(conicPool).depositFor(address(this), amountToDepositConic, minAmountLpConic, true);
        }
    }

    function _withdrawFromPools(uint256 amount) internal {
        // Withdraw form Aave protocol
        uint256 aavePoolWeightBps = poolWeight[aaveV3Pool];
        uint256 amountToWithdrawAave = (amount * aavePoolWeightBps) / 10000;
        if (aavePoolWeightBps > 0) {
            IAaveV3Pool(aaveV3Pool).withdraw(usdcAddress, amountToWithdrawAave, address(this));
        }

        // Withdraw from Compound protocol
        uint256 compoundPoolWeightBps = poolWeight[cUSDCv3];
        uint256 amountToWithdrawCompound = (amount * compoundPoolWeightBps) / 10000;
        if (compoundPoolWeightBps > 0) {
            ICompoundUSDCV3(cUSDCv3).withdraw(usdcAddress, amountToWithdrawCompound);
        }

        // Withdraw from yEarn vault
        uint256 yearnPoolWeightBps = poolWeight[usdcYVault];
        uint256 amountToWithdrawYearn = (amount * yearnPoolWeightBps) / 10000;
        uint256 pricePerShare = IYearnVault(usdcYVault).pricePerShare();
        uint256 amountToWithdrawYearnShares = (amountToWithdrawYearn * (10 ** 6)) / pricePerShare;

        if (yearnPoolWeightBps > 0) {
            IYearnVault(usdcYVault).withdraw(amountToWithdrawYearnShares);
        }

        // Withdraw from Conic Omnipool
        uint256 conicPoolWeightBps = poolWeight[conicPool];
        uint256 amountToWithdrawFromConic = (amount * conicPoolWeightBps) / 10000;

        uint256 exchangeRate = IConicOmniPool(conicPool).exchangeRate();
        uint256 conicLpAmount = (amountToWithdrawFromConic * (10 ** 18) / exchangeRate);

        if (conicPoolWeightBps > 0) {
            if (conicLpAmount > getConicLpTokenBalance()) {
                IConicOmniPool(conicPool).unstakeAndWithdraw(getConicLpTokenBalance(), getConicLpTokenBalance());
            } else {
                IConicOmniPool(conicPool).unstakeAndWithdraw(conicLpAmount, conicLpAmount);
            }
        }
    }

    function toggleWhitelist(address whitelistedAddress, bool isWhitelisted) external onlyOwner {
        whitelist[whitelistedAddress] = isWhitelisted;
        emit AddressAddedToWhitelist(whitelistedAddress, block.timestamp);
    }

    function sweep(address token) external onlyOwner {
        if (token == address(0)) {
            (bool success,) = owner().call{value: address(this).balance}("");
            if (!success) revert UnableToSweep(token);
            emit Sweep(token, address(this).balance, block.timestamp);
        } else {
            bool transferSuccess = IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
            if (!transferSuccess) revert UnableToSweep(token);
            emit Sweep(token, IERC20(token).balanceOf(address(this)), block.timestamp);
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function harvestConicRewardsAndSwapForUnderlying(uint256 minAmountOut) public returns (uint256 amountOut) {
        (uint256 cncAmount, uint256 crvAmount, uint256 cvxAmount) =
            IConicRewardManager(conicRewardManager).claimEarnings();

        // Swap only in case there is anything to swap
        if (cncAmount != 0 && crvAmount != 0 && cvxAmount != 0) {
            _swapRewardTokenForWeth(cncWethCurvePool, cncAddress, cncAmount);
            _swapRewardTokenForWeth(crvWethCurvePool, crvAddress, crvAmount);
            _swapRewardTokenForWeth(cvxWethCurvePool, cvxAddress, cvxAmount);

            uint256 amountOutWeth = IERC20(wethAddress).balanceOf(address(this));
            amountOut = _swapWethForUnderlying(usdcAddress, amountOutWeth);

            if (amountOut < minAmountOut) {
                revert HighSlippage(minAmountOut, amountOut);
            }

            emit HarvestConicRewards(cncAmount, crvAmount, cvxAmount, amountOut, block.timestamp);
        }
    }

    function _swapRewardTokenForWeth(address pool, address token, uint256 amount) internal {
        IERC20(token).approve(pool, amount);
        ICurvePoolV2(pool).exchange(1, 0, amount, 0, false, address(this));
    }

    function _swapWethForUnderlying(address token, uint256 amountIn) internal returns (uint256 amountOut) {
        IERC20(wethAddress).approve(swapRouter, amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: wethAddress,
            tokenOut: token,
            fee: 500,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        amountOut = ISwapRouter(swapRouter).exactInputSingle(params);
    }

    function updatePoolWeightsAndRebalance(address whitelistedAddress, bool isWhitelisted) external onlyOwner {}

    function rescueFunds(address destination) external onlyOwner {
        uint256 totalAEthUSDC = IERC20(aEthUSDC).balanceOf(address(this));
        if (totalAEthUSDC > 0) {
            IAaveV3Pool(aaveV3Pool).withdraw(usdcAddress, totalAEthUSDC, destination);
        }

        uint256 totalCUSDCV3 = IERC20(cUSDCv3).balanceOf(address(this));
        if (totalCUSDCV3 > 0) {
            ICompoundUSDCV3(cUSDCv3).withdrawTo(destination, usdcAddress, totalCUSDCV3);
        }

        uint256 totalUSDCYVault = IERC20(usdcYVault).balanceOf(address(this));
        if (totalUSDCYVault > 0) {
            IYearnVault(usdcYVault).withdraw(totalUSDCYVault, destination);
        }

        uint256 totalConicLPAmount =
            IConicLPTokenStaker(conicLPtokenStaker).getUserBalanceForPool(conicPool, address(this));
        if (totalConicLPAmount > 0) {
            IConicOmniPool(conicPool).unstakeAndWithdraw(totalConicLPAmount, 0);
        }
    }

    function totalAssets() public view override returns (uint256) {
        return IERC20(usdcAddress).balanceOf(address(this)) + IERC20(aEthUSDC).balanceOf(address(this))
            + IERC20(cUSDCv3).balanceOf(address(this))
            + (IERC20(usdcYVault).balanceOf(address(this)) * IYearnVault(usdcYVault).pricePerShare()) / (10 ** 6)
            + (
                (
                    IConicLPTokenStaker(conicLPtokenStaker).getUserBalanceForPool(conicPool, address(this))
                        * IConicOmniPool(conicPool).exchangeRate()
                ) / (10 ** 18)
            );
    }

    function getYVUSDCBalance() public view returns (uint256) {
        return IERC20(usdcYVault).balanceOf(address(this));
    }

    function getConicLpTokenBalance() public view returns (uint256) {
        return IConicLPTokenStaker(conicLPtokenStaker).getUserBalanceForPool(conicPool, address(this));
    }

    event PoolDonation(address sender, uint256 value);
    event Sweep(address token, uint256 amount, uint256 time);
    event RedeemFromVault(address depositor, uint256 amount, uint256 time);
    event AddressAddedToWhitelist(address whitelistedAddress, uint256 time);
    event WithdrawFromVault(address depositor, uint256 amount, uint256 time);
    event DepositToVault(address depositor, uint256 amount, bytes32 proof, uint256 time);
    event HarvestConicRewards(uint256 cncAmount, uint256 crvAmount, uint256 cvxAmount, uint256 amountOut, uint256 time);
}