// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAaveV3Pool} from "./interfaces/IAaveV3Pool.sol";
import {ISwapRouter} from "./interfaces/ISwapRouter.sol";
import {IYearnVault} from "./interfaces/IYearnVault.sol";
import {ICurvePoolV2} from "./interfaces/ICurvePoolV2.sol";
import {IConicOmniPool} from "./interfaces/IConicOmniPool.sol";
import {ICompoundUSDCV3} from "./interfaces/ICompoundUSDCV3.sol";
import {IConicRewardManager} from "./interfaces/IConicRewardManager.sol";
import {IConicLpTokenStaker} from "./interfaces/IConicLpTokenStaker.sol";

/**
 * @title Return Finance USDC Vault
 * @author Stanislav Trenev - <[email protected]>
 * @dev The contract leverages the ERC4626 Tokenised Vault Standard.
 * @dev This contract allows for deposits and withdrawals of USDC, and manages the allocation of USDC to different DeFi pools.
 */
contract ReturnFinanceUSDCVault is ERC4626, Ownable, Pausable {
    using SafeERC20 for IERC20;
    using Math for uint256;

    /**
     * @notice Represents the weight of each pool in the total allocation of USDC
     */
    mapping(address => uint256) public poolWeight;

    /**
     * @notice Represents the whitelist of addresses that can interact with this contract
     */
    mapping(address => bool) public whitelist;

    // Constants
    string public constant VAULT_NAME = "Return Finance USDC Vault";
    string public constant VAULT_SYMBOL = "rfUSDC";

    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant CNC = 0x9aE380F0272E2162340a5bB646c354271c0F5cFC;

    address public constant AAVE_V3 = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address public constant A_ETH_USDC = 0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c;
    address public constant C_USDC_V3 = 0xc3d688B66703497DAA19211EEdff47f25384cdc3;
    address public constant USDC_Y_VAULT = 0xa354F35829Ae975e850e23e9615b11Da1B3dC4DE;
    address public constant CONIC_OMNI_POOL_USDC = 0x07b577f10d4e00f3018542d08a87F255a49175A5;

    address public constant CONIC_REWARD_MANAGER = 0xE976F643d4dc08Aa3CeD55b0CA391B1d11328347;
    address public constant CONIC_LP_TOKEN_STAKER = 0xeC037423A61B634BFc490dcc215236349999ca3d;

    address public constant CNC_WETH_CURVE_POOL = 0x838af967537350D2C44ABB8c010E49E32673ab94;
    address public constant CVX_WETH_CURVE_POOL = 0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4;
    address public constant CRV_WETH_CURVE_POOL = 0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511;
    address public constant UNISWAP_ROUTER_V3 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    /**
     * @dev NotInWhitelist Error that is thrown when an address is not in the whitelist
     */
    error NotInWhitelist(address wrongAddress);
    /**
     * @dev UnableToSweep Error that is thrown when an attempt to sweep fails
     */
    error UnableToSweep(address token);
    /**
     * @dev DepositFailed Error that is thrown when a deposit fails
     */
    error DepositFailed(address depositor, uint256 amount);
    /**
     * @dev WithdrawFailed Error that is thrown when a withdrawal fails
     */
    error WithdrawFailed(address depositor, uint256 amount);
    /**
     * @dev IncorrectWeights Error that is thrown when the total weights are not correct
     */
    error IncorrectWeights(uint256 totalWeights);
    /**
     * @dev HighSlippage Error that is thrown when the slippage is too high
     */
    error HighSlippage(uint256 minAmountOut, uint256 amountOut);

    /**
     * @dev Emitted when ether is sent to this contract (a "donation")
     */
    event PoolDonation(address sender, uint256 value);

    /**
     * @dev Emitted when the contract owner sweeps an ERC20 token
     */
    event SweepFunds(address token, uint256 amount);

    /**
     * @dev Emitted when an address is added/removed to the whitelist
     */
    event AddressWhitelisted(address whitelistedAddress, bool isWhitelisted);

    /**
     * @dev Emitted when a user withdraws assets from the vault
     */
    event WithdrawFromVault(address depositor, uint256 amount);

    /**
     * @dev Emitted when a user deposits assets to the vault
     */
    event DepositToVault(address depositor, uint256 amount, bytes32 proof);
    /**
     * @dev Emitted when contract's USDC balance is re-depositted to the pools
     */
    event ReDepositToPools(uint256 amount);

    /**
     * @dev Emitted when the contract harvests Conic rewards
     */
    event HarvestConicRewards(uint256 cncAmount, uint256 crvAmount, uint256 cvxAmount, uint256 amountOut);

    /**
     * @dev Emitted when funds are rescued and withdrawn from pools
     */
    event RescueFunds(uint256 totalAEthUSDC, uint256 totalCUSDCV3, uint256 totalUSDCYVault, uint256 totalConicLpAmount);

    /**
     * @dev Emitted when the contract updates pool weights and rebalances
     */
    event PoolWeightsUpdated(
        uint256 aavePoolWeight, uint256 compoundPoolWeight, uint256 yearnPoolWeight, uint256 conicPoolWeight
    );

    /**
     * @dev Emitted when there is error in external function call
     */
    event LogError(string reason);

    /**
     * @notice Modifier that allows only whitelisted addresses to interact with the contract
     */
    modifier onlyWhitelist() {
        if (!whitelist[_msgSender()]) revert NotInWhitelist(_msgSender());
        _;
    }

    /**
     * @notice Constructor for the ReturnFinanceUSDCVault contract
     * @param _aavePoolWeightBps The weight for the AAVE pool
     * @param _compoundPoolWeightBps The weight for the Compound pool
     * @param _yearnPoolWeightBps The weight for the Yearn pool
     * @param _conicPoolWeightBps The weight for the Conic pool
     */
    constructor(
        uint256 _aavePoolWeightBps,
        uint256 _compoundPoolWeightBps,
        uint256 _yearnPoolWeightBps,
        uint256 _conicPoolWeightBps
    ) ERC4626(IERC20(USDC)) ERC20(VAULT_NAME, VAULT_SYMBOL) {
        uint256 totalWeights = _aavePoolWeightBps + _compoundPoolWeightBps + _yearnPoolWeightBps + _conicPoolWeightBps;
        if (totalWeights != 10000) revert IncorrectWeights(totalWeights);

        poolWeight[AAVE_V3] = _aavePoolWeightBps;
        poolWeight[C_USDC_V3] = _compoundPoolWeightBps;
        poolWeight[USDC_Y_VAULT] = _yearnPoolWeightBps;
        poolWeight[CONIC_OMNI_POOL_USDC] = _conicPoolWeightBps;
    }

    /**
     * @notice Function to receive ether, which emits a donation event
     */
    receive() external payable {
        emit PoolDonation(_msgSender(), msg.value);
    }

    /**
     * @notice Deposit funds into the vault
     * @param amount The amount to deposit
     * @param receiver The address that will receive the shares
     * @param proof A proof of the deposit transaction
     * @param minAmountLpConic The minimum amount to be deposited into the Conic pool
     * @param minAmountHarvest The minimum amount of USDC to be received after a swap
     * @return shares The number of shares issued to the receiver
     */
    function deposit(
        uint256 amount,
        address receiver,
        bytes32 proof,
        uint256 minAmountLpConic,
        uint256 minAmountHarvest
    ) external onlyWhitelist whenNotPaused returns (uint256 shares) {
        harvestConicRewardsAndSwapForUnderlying(minAmountHarvest);

        if (amount <= 1 * 10 ** 6) revert DepositFailed(_msgSender(), amount);
        require(amount <= maxDeposit(receiver), "ERC4626: deposit more than max");

        shares = previewDeposit(amount);
        _deposit(_msgSender(), receiver, amount, shares);
        _depositToPools(amount, minAmountLpConic);

        emit DepositToVault(_msgSender(), amount, proof);
    }

    /**
     * @notice Redeem shares for underlying assets
     * @param shares The number of shares to redeem
     * @param receiver The address that will receive the assets
     * @param owner The address of the owner of the shares
     * @param minAmountHarvest The minimum amount of USDC to be received after a swap
     * @return amountOut The amount of underlying assets received
     */
    function withdraw(uint256 shares, address receiver, address owner, uint256 minAmountOut, uint256 minAmountHarvest)
        external
        onlyWhitelist
        whenNotPaused
        returns (uint256 amountOut)
    {
        harvestConicRewardsAndSwapForUnderlying(minAmountHarvest);
        uint256 previewAmount = previewRedeem(shares);

        require(previewAmount > 0, "Return Finance: Withdraw Failed");
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        uint256 underlyingTokenBalance = getUSDCBalance();

        // If there is not enough underlying token(USDC) available, we have to withdraw from the pools
        if (underlyingTokenBalance < previewAmount) {
            _withdrawFromPools(previewAmount - underlyingTokenBalance);
        }

        uint256 underlyingTokenBalanceAfter = getUSDCBalance();

        // Prevent withdrawing more funds than intended
        previewAmount > underlyingTokenBalanceAfter
            ? amountOut = underlyingTokenBalanceAfter
            : amountOut = previewAmount;

        if (amountOut < minAmountOut) revert WithdrawFailed(_msgSender(), minAmountOut);

        _withdraw(_msgSender(), receiver, owner, amountOut, shares);

        emit WithdrawFromVault(_msgSender(), amountOut);
    }

    /**
     * @notice Update the weights of pools and rebalance the funds accordingly
     * @param newAavePoolWeightBps The new weight for AAVE pool
     * @param newCompoundPoolWeightBps The new weight for Compound pool
     * @param newYearnPoolWeightBps The new weight for Yearn pool
     * @param newConicPoolWeightBps The new weight for Conic pool
     * @param minAmountLpConic The minimum amount to deposit in the Conic pool
     */
    function updatePoolWeightsAndRebalance(
        uint256 newAavePoolWeightBps,
        uint256 newCompoundPoolWeightBps,
        uint256 newYearnPoolWeightBps,
        uint256 newConicPoolWeightBps,
        uint256 minAmountLpConic
    ) external onlyOwner {
        rescueFunds(address(this));
        uint256 totalWeights =
            newAavePoolWeightBps + newCompoundPoolWeightBps + newYearnPoolWeightBps + newConicPoolWeightBps;
        if (totalWeights != 10000) revert IncorrectWeights(totalWeights);

        poolWeight[AAVE_V3] = newAavePoolWeightBps;
        poolWeight[C_USDC_V3] = newCompoundPoolWeightBps;
        poolWeight[USDC_Y_VAULT] = newYearnPoolWeightBps;
        poolWeight[CONIC_OMNI_POOL_USDC] = newConicPoolWeightBps;

        uint256 balanceInPool = getUSDCBalance();
        _depositToPools(balanceInPool, minAmountLpConic);

        emit PoolWeightsUpdated(
            newAavePoolWeightBps, newCompoundPoolWeightBps, newYearnPoolWeightBps, newConicPoolWeightBps
        );
    }

    /**
     * @notice Send all tokens or ETH held by the contract to the owner
     * @param token The token to sweep, or 0 for ETH
     */
    function sweepFunds(address token) external onlyOwner {
        if (token == address(0)) {
            (bool success,) = owner().call{value: address(this).balance}("");
            if (!success) revert UnableToSweep(token);
            emit SweepFunds(token, address(this).balance);
        } else {
            IERC20(token).safeTransfer(owner(), IERC20(token).balanceOf(address(this)));
            emit SweepFunds(token, IERC20(token).balanceOf(address(this)));
        }
    }

    /**
     * @notice Allow or disallow an address to interact with the contract
     * @param updatedAddress The address to change the whitelist status for
     * @param isWhitelisted Whether the address should be whitelisted
     */
    function toggleWhitelist(address updatedAddress, bool isWhitelisted) external onlyOwner {
        whitelist[updatedAddress] = isWhitelisted;

        emit AddressWhitelisted(updatedAddress, isWhitelisted);
    }

    /**
     * @notice Pause the contract, preventing non-owner interactions
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract, allowing non-owner interactions
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice This is an empty override, please use deposit
     * @param amount The amount of funds to deposit
     * @param receiver The address to receive the shares
     * @return shares The number of shares minted
     */
    function deposit(uint256 amount, address receiver) public override returns (uint256 shares) {}

    /**
     * @notice This is an empty override, please use withdraw
     * @param amount The amount of funds to withdraw
     * @param receiver The address to receive the funds
     * @param owner The owner of the shares to burn
     * @return shares The number of shares burned
     */
    function withdraw(uint256 amount, address receiver, address owner) public override returns (uint256 shares) {}

    /**
     * @notice This is an empty override, please use withdraw
     * @param shares The number of shares to redeem
     * @param receiver The address to receive the assets
     * @param owner The owner of the shares
     * @return assets The amount of assets received
     */
    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256 assets) {}

    /**
     * @notice This is an empty override, please use deposit
     * @param shares The number of shares to mint
     * @param receiver The address to receive the shares
     * @return assets The amount of assets that the shares represent
     */
    function mint(uint256 shares, address receiver) public override returns (uint256 assets) {}

    /**
     * @notice Claim and swap pending Conic rewards for the underlying asset. The swapped assets remain in the vault.
     * @param minAmountOut The minimum amount expected to receive from the swap
     * @return amountOut The actual amount received from the swap
     */
    function harvestConicRewardsAndSwapForUnderlying(uint256 minAmountOut)
        public
        whenNotPaused
        onlyWhitelist
        returns (uint256 amountOut)
    {
        if (poolWeight[CONIC_OMNI_POOL_USDC] > 0) {
            (uint256 cncAmount, uint256 crvAmount, uint256 cvxAmount) =
                IConicRewardManager(CONIC_REWARD_MANAGER).claimEarnings();

            // Swap only in case there is anything to swap
            if (cncAmount != 0) {
                _swapRewardTokenForWeth(CNC_WETH_CURVE_POOL, CNC, cncAmount);
            }

            if (crvAmount != 0) {
                _swapRewardTokenForWeth(CRV_WETH_CURVE_POOL, CRV, crvAmount);
            }

            if (cvxAmount != 0) {
                _swapRewardTokenForWeth(CVX_WETH_CURVE_POOL, CVX, cvxAmount);
            }

            uint256 amountOutWeth = IERC20(WETH).balanceOf(address(this));

            if (amountOutWeth > 0) {
                amountOut = _swapWethForUnderlying(USDC, amountOutWeth);

                if (amountOut < minAmountOut) {
                    revert HighSlippage(minAmountOut, amountOut);
                }
                emit HarvestConicRewards(cncAmount, crvAmount, cvxAmount, amountOut);
            }
        }
    }

    /**
     * @notice Rescue any locked funds from the pools
     * @param destination The address where the funds should be sent
     */
    function rescueFunds(address destination) public onlyOwner {
        uint256 totalAEthUSDC = getAaveEthUSDCBalance();
        if (totalAEthUSDC > 0) {
            try IAaveV3Pool(AAVE_V3).withdraw(USDC, totalAEthUSDC, destination) {}
            catch Error(string memory reason) {
                emit LogError(reason);
            }
        }

        uint256 totalCUSDCV3 = getCompoundUSDCV3Balance();
        if (totalCUSDCV3 > 0) {
            try ICompoundUSDCV3(C_USDC_V3).withdrawTo(destination, USDC, totalCUSDCV3) {}
            catch Error(string memory reason) {
                emit LogError(reason);
            }
        }

        uint256 totalUSDCYVault = getYVUSDCBalance();
        if (totalUSDCYVault > 0) {
            try IYearnVault(USDC_Y_VAULT).withdraw(totalUSDCYVault, destination) {}
            catch Error(string memory reason) {
                emit LogError(reason);
            }
        }

        uint256 totalConicLpAmount = getConicLpTokenBalance();
        if (totalConicLpAmount > 0) {
            try IConicOmniPool(CONIC_OMNI_POOL_USDC).unstakeAndWithdraw(totalConicLpAmount, 0) {}
            catch Error(string memory reason) {
                emit LogError(reason);
            }
        }

        emit RescueFunds(totalAEthUSDC, totalCUSDCV3, totalUSDCYVault, totalConicLpAmount);
    }

    /**
     * @notice Re-deposit underlying USDC assets sitting in the contract to the pools
     * @notice Helper function to use if there is any USDC lying around in the pool
     */
    function reDepositUnderlyingIntoPools(uint256 minAmountLpConic) external onlyOwner {
        uint256 currentUnderlyingBalance = getUSDCBalance();
        _depositToPools(currentUnderlyingBalance, minAmountLpConic);

        emit ReDepositToPools(currentUnderlyingBalance);
    }

    /**
     * @notice Calculate total assets of the contract. This does not take into account claimable rewards of CNC, CVX and CRV
     * @return Total assets in the form of uint256
     */
    function totalAssets() public view override returns (uint256) {
        return getUSDCBalance() + getAaveEthUSDCBalance() + getCompoundUSDCV3Balance()
            + getYVUSDCBalance().mulDiv(IYearnVault(USDC_Y_VAULT).pricePerShare(), 10 ** 6, Math.Rounding.Down)
            + getConicLpTokenBalance().mulDiv(
                IConicOmniPool(CONIC_OMNI_POOL_USDC).exchangeRate(), 10 ** 18, Math.Rounding.Down
            );
    }

    /**
     * @notice Get the balance of Aave ETH-USDC held by the contract
     * @return Aave ETH-USDC balance in the form of uint256
     */
    function getAaveEthUSDCBalance() public view returns (uint256) {
        return IERC20(A_ETH_USDC).balanceOf(address(this));
    }

    /**
     * @notice Get the balance of Compound USDC V3 held by the contract
     * @return Compound USDC V3 balance in the form of uint256
     */
    function getCompoundUSDCV3Balance() public view returns (uint256) {
        return IERC20(C_USDC_V3).balanceOf(address(this));
    }

    /**
     * @notice Get the balance of Yearn Finance USDC Vault tokens held by the contract
     * @return Yearn Finance USDC Vault balance in the form of uint256
     */
    function getYVUSDCBalance() public view returns (uint256) {
        return IERC20(USDC_Y_VAULT).balanceOf(address(this));
    }

    /**
     * @notice Get the balance of Conic LP tokens for a specific pool held by the contract
     * @return Conic LP token balance in the form of uint256
     */
    function getConicLpTokenBalance() public view returns (uint256) {
        return IConicLpTokenStaker(CONIC_LP_TOKEN_STAKER).getUserBalanceForPool(CONIC_OMNI_POOL_USDC, address(this));
    }

    /**
     * @notice Get the balance of USDC held by the contract
     * @return USDC balance in the form of uint256
     */
    function getUSDCBalance() public view returns (uint256) {
        return IERC20(USDC).balanceOf(address(this));
    }

    /**
     * @notice Get the calimable Rewards from Conic since latest harvest
     * @return The CNC, CRV and CVX amounts
     */
    function getClaimableRewardsFromConic() public view returns (uint256, uint256, uint256) {
        return IConicRewardManager(CONIC_REWARD_MANAGER).claimableRewards(address(this));
    }

    /**
     * @notice Deposit the specified amount into each pool, relative to its weight
     * @param amount The total amount to deposit
     * @param minAmountLpConic The minimum amount to deposit in the Conic pool
     */
    function _depositToPools(uint256 amount, uint256 minAmountLpConic) internal {
        uint256 amountToDepositAave = 0;
        uint256 amountToDepositCompound = 0;
        uint256 amountToDepositYearn = 0;
        uint256 amountToDepositConic = 0;
        // Deposit to Aave protocol
        uint256 aavePoolWeightBps = poolWeight[AAVE_V3];

        if (aavePoolWeightBps > 0) {
            amountToDepositAave = amount.mulDiv(aavePoolWeightBps, 10000);
            require(IERC20(USDC).approve(AAVE_V3, amountToDepositAave), "Return Finance: Approve Failed");
            try IAaveV3Pool(AAVE_V3).supply(USDC, amountToDepositAave, address(this), 0) {}
            catch Error(string memory reason) {
                emit LogError(reason);
            }
        }

        // Depoist to Compound protocol and receive cUSDCv3 via supply method.
        uint256 compoundPoolWeightBps = poolWeight[C_USDC_V3];

        if (compoundPoolWeightBps > 0) {
            amountToDepositCompound = amount.mulDiv(compoundPoolWeightBps, 10000);
            require(IERC20(USDC).approve(C_USDC_V3, amountToDepositCompound), "Return Finance: Approve Failed");
            try ICompoundUSDCV3(C_USDC_V3).supply(USDC, amountToDepositCompound) {}
            catch Error(string memory reason) {
                emit LogError(reason);
            }
        }

        // Deposit to yEarn USDC Vault. Using directly the vault, instead of YearnPartnerTracker.
        uint256 yearnPoolWeightBps = poolWeight[USDC_Y_VAULT];

        if (yearnPoolWeightBps > 0) {
            amountToDepositYearn = amount.mulDiv(yearnPoolWeightBps, 10000);
            require(IERC20(USDC).approve(USDC_Y_VAULT, amountToDepositYearn), "Return Finance: Approve Failed");
            try IYearnVault(USDC_Y_VAULT).deposit(amountToDepositYearn) {}
            catch Error(string memory reason) {
                emit LogError(reason);
            }
        }

        // Deposit to Conic Finance.
        uint256 conicPoolWeightBps = poolWeight[CONIC_OMNI_POOL_USDC];

        if (conicPoolWeightBps > 0) {
            // Prevent dust staying in the ocntract
            amountToDepositConic = amount - amountToDepositAave - amountToDepositCompound - amountToDepositYearn;
            require(IERC20(USDC).approve(CONIC_OMNI_POOL_USDC, amountToDepositConic), "Return Finance: Approve Failed");
            try IConicOmniPool(CONIC_OMNI_POOL_USDC).depositFor(
                address(this), amountToDepositConic, minAmountLpConic, true
            ) {} catch Error(string memory reason) {
                emit LogError(reason);
            }
        }
    }
    /**
     * @notice Withdraw the specified amount from each pool, relative to its weight
     * @param amount The total amount to withdraw
     */

    function _withdrawFromPools(uint256 amount) internal {
        uint256 amountToWithdrawAave = 0;
        uint256 amountToWithdrawCompound = 0;
        uint256 amountToWithdrawYearn = 0;
        uint256 amountToWithdrawFromConic = 0;
        // Withdraw form Aave protocol
        uint256 aavePoolWeightBps = poolWeight[AAVE_V3];
        if (aavePoolWeightBps > 0) {
            amountToWithdrawAave = amount.mulDiv(aavePoolWeightBps, 10000);
            try IAaveV3Pool(AAVE_V3).withdraw(USDC, amountToWithdrawAave, address(this)) {}
            catch Error(string memory reason) {
                emit LogError(reason);
            }
        }

        // Withdraw from Compound protocol
        uint256 compoundPoolWeightBps = poolWeight[C_USDC_V3];
        if (compoundPoolWeightBps > 0) {
            amountToWithdrawCompound = amount.mulDiv(compoundPoolWeightBps, 10000);
            try ICompoundUSDCV3(C_USDC_V3).withdraw(USDC, amountToWithdrawCompound) {}
            catch Error(string memory reason) {
                emit LogError(reason);
            }
        }

        // Withdraw from yEarn vault
        uint256 yearnPoolWeightBps = poolWeight[USDC_Y_VAULT];
        if (yearnPoolWeightBps > 0) {
            amountToWithdrawYearn = amount.mulDiv(yearnPoolWeightBps, 10000);
            uint256 pricePerShare = IYearnVault(USDC_Y_VAULT).pricePerShare();
            uint256 amountToWithdrawYearnShares = amountToWithdrawYearn.mulDiv(10 ** 6, pricePerShare);
            uint256 totalYvUSDCBalance = getYVUSDCBalance();
            if (amountToWithdrawYearnShares > totalYvUSDCBalance) {
                try IYearnVault(USDC_Y_VAULT).withdraw(totalYvUSDCBalance) {}
                catch Error(string memory reason) {
                    emit LogError(reason);
                }
            } else {
                try IYearnVault(USDC_Y_VAULT).withdraw(amountToWithdrawYearnShares) {}
                catch Error(string memory reason) {
                    emit LogError(reason);
                }
            }
        }

        // Withdraw from Conic Omnipool
        uint256 conicPoolWeightBps = poolWeight[CONIC_OMNI_POOL_USDC];
        if (conicPoolWeightBps > 0) {
            amountToWithdrawFromConic = amount - amountToWithdrawAave - amountToWithdrawCompound - amountToWithdrawYearn;
            uint256 exchangeRate = IConicOmniPool(CONIC_OMNI_POOL_USDC).exchangeRate();
            uint256 conicLpAmount = amountToWithdrawFromConic.mulDiv((10 ** 18), exchangeRate);
            uint256 totalConicLpAmount = getConicLpTokenBalance();
            if (conicLpAmount > totalConicLpAmount) {
                try IConicOmniPool(CONIC_OMNI_POOL_USDC).unstakeAndWithdraw(totalConicLpAmount, totalConicLpAmount) {}
                catch Error(string memory reason) {
                    emit LogError(reason);
                }
            } else {
                try IConicOmniPool(CONIC_OMNI_POOL_USDC).unstakeAndWithdraw(conicLpAmount, conicLpAmount) {}
                catch Error(string memory reason) {
                    emit LogError(reason);
                }
            }
        }
    }

    /**
     * @notice Swap a reward token for WETH
     * @param pool The Curve pool address to be used for the swap
     * @param token The address of the token to be swapped
     * @param amount The amount of tokens to be swapped
     */
    function _swapRewardTokenForWeth(address pool, address token, uint256 amount) internal {
        require(IERC20(token).approve(pool, amount), "Return Finance: Approve Failed");
        ICurvePoolV2(pool).exchange(1, 0, amount, 0, false, address(this));
    }

    /**
     * @notice Swap WETH for the underlying token (USDC)
     * @param token The address of the token to be received
     * @param amountIn The amount of WETH to be swapped
     * @return amountOut The amount of tokens received from the swap
     */
    function _swapWethForUnderlying(address token, uint256 amountIn) internal returns (uint256 amountOut) {
        require(IERC20(WETH).approve(UNISWAP_ROUTER_V3, amountIn), "Return Finance: Approve Failed");

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH,
            tokenOut: token,
            fee: 500,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        amountOut = ISwapRouter(UNISWAP_ROUTER_V3).exactInputSingle(params);
    }
}