// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ERC4626} from "solmate/src/mixins/ERC4626.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {Owned} from "solmate/src/auth/Owned.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";

import {ILPStaking} from "./interfaces/ILPStaking.sol";
import {IStargateRouter} from "./interfaces/IStargateRouter.sol";
import {IStargatePool} from "./interfaces/IStargatePool.sol";
import {ISwapper} from "./interfaces/ISwapper.sol";

/// @notice Vault to auto-compound rewards from Stargate LP
contract YoSifuStargateVault is ERC4626, Owned {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for ERC20;

    /*//////////////////////////////////////////////////////////////
                        ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice Address of Stargate Staking Contract
    ILPStaking public immutable stargateStaking;

    /// @notice Address of Stargate Router
    IStargateRouter public immutable stargateRouter;

    /// @notice Reward Token issued by Stargate i.e. STG Token
    ERC20 public immutable rewardToken;

    /// @notice Underlying Asset in the Stargate Pool
    ERC20 public immutable underlyingAsset;

    /// @notice Address of the Fee Receiver
    address public feeTo;

    /*//////////////////////////////////////////////////////////////
                        STARGATE STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Pool Id of the Stargate Pool
    uint256 public immutable poolId;

    /// @notice Pid in the Staking Contract
    uint256 public immutable pid;

    /*//////////////////////////////////////////////////////////////
                        VAULT STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Total Stargate Pool Asssets held by the vault
    uint256 private totalBaseAssets;

    /// @notice Fee for the Vault FEE_PRECISION - 1e18
    /// @dev 1e17 - 10%, 20e16 - 20%, can't set 100%
    uint256 public fee;

    /// @notice profit locked in between harvest
    uint256 public totalLockedProfit;

    /// @notice last harvest block
    uint256 public lastHarvestBlock;

    /// @notice Executor Address status
    mapping(address => bool) public executors;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event LogFeeClaimed(address feeTo, uint256 feeAmount);
    event LogHarvested(uint256 amount);
    event LogStakedAllAssets(uint256 assets);
    event LogEmergencyWithdraw(uint256 pid, uint256 assets);
    event LogSetExecutorStatus(address executor, bool status);
    event LogSetFeeTo(address owner);
    event LogSetFees(uint256 fee);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error YoSifuStargateVault__InsufficientOut();
    error YoSifuStargateVault__NotExecutor();
    error YoSifuStargateVault__InvalidFee();
    error YoSifuStargateVault__HarvestAtSameBlock();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the vault configurations
    /// @param _asset Address of Stargate Pool Tokens
    /// @param _underlyingAsset Address of underlying tokens of the Stargate Pool
    /// @param _stargateStaking Address of the Stargate Staking contract
    /// @param _stargateRouter Address of the Stargate Router contract
    /// @param _rewardToken Address of the Reward Token
    /// @param _poolId Pool Id of the Stargate Pool Token
    /// @param _pid PID of the asset in Staking Contract
    /// @param _feeTo Address of the Fee Receiver
    /// @param _owner Address of the Onwer of the vault
    constructor(
        ERC20 _asset,
        ERC20 _underlyingAsset,
        address _stargateStaking,
        address _stargateRouter,
        ERC20 _rewardToken,
        uint256 _poolId,
        uint256 _pid,
        address _feeTo,
        address _owner
    )
        ERC4626(
            _asset,
            // ex: Yield Optimized Sifu - S*USDC - Stargate Vault
            string(
                abi.encodePacked(
                    "Yield Optimized Sifu -",
                    _asset.name(),
                    "- Stargate Vault"
                )
            ),
            // ex: yoSifu_Stargate_S*USDC
            string(abi.encodePacked("yoSifu_Stargate_", _asset.symbol()))
        )
        Owned(_owner)
    {
        executors[_owner] = true;
        stargateStaking = ILPStaking(_stargateStaking);
        stargateRouter = IStargateRouter(_stargateRouter);
        rewardToken = _rewardToken;
        pid = _pid;
        feeTo = _feeTo;
        poolId = _poolId;
        underlyingAsset = _underlyingAsset;

        _underlyingAsset.safeApprove(
            address(stargateRouter),
            type(uint256).max
        );
        _asset.safeApprove(address(stargateStaking), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                    ERC4626 OVERRIDES FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function afterDeposit(
        uint256 assets,
        uint256 /*shares*/
    ) internal virtual override {
        totalBaseAssets += assets;
        stargateStaking.deposit(pid, assets);
    }

    function beforeWithdraw(
        uint256 assets,
        uint256 /*shares*/
    ) internal virtual override {
        totalBaseAssets -= assets;
        if (asset.balanceOf(address(this)) < assets) {
            stargateStaking.withdraw(pid, assets);
        }
    }

    // TODO: Add delayed harvest logic
    function totalAssets() public view override returns (uint256) {
        return totalBaseAssets - lockedProfit();
    }

    function lockedProfit() public view returns (uint256) {
        if (block.number <= lastHarvestBlock) {
            return totalLockedProfit;
        }

        return 0;
    }

    /*//////////////////////////////////////////////////////////////
                        HARVEST FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // TODO: Add delayed harvest logic

    /// @notice Harvests the yield
    /// @dev Can only be called by the executor
    /// @param swapper Address of the Swapper
    /// @param amountOutMin Minimum amount of underlying tokens received
    /// @param data Data to be passed for the swapper
    function harvest(
        address swapper,
        uint256 amountOutMin,
        bytes calldata data
    ) public {
        if (executors[msg.sender] != true)
            revert YoSifuStargateVault__NotExecutor();

        if (lastHarvestBlock == block.number)
            revert YoSifuStargateVault__HarvestAtSameBlock();

        uint256 baseAssetBalanceBefore = asset.balanceOf(address(this));

        stargateStaking.deposit(pid, 0);

        uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(swapper, rewardTokenBalance);
        ISwapper(swapper).onSwapReceived(data);

        uint256 underlyingAssetBalance = underlyingAsset.balanceOf(
            address(this)
        );

        if (underlyingAssetBalance < amountOutMin)
            revert YoSifuStargateVault__InsufficientOut();

        stargateRouter.addLiquidity(
            poolId,
            underlyingAssetBalance,
            address(this)
        );

        uint256 baseAssetBalance = asset.balanceOf(address(this)) -
            baseAssetBalanceBefore;

        uint256 totalFee = baseAssetBalance.mulDivDown(fee, 1e18);

        asset.safeTransfer(feeTo, totalFee);

        stargateStaking.deposit(pid, baseAssetBalance - totalFee);

        totalLockedProfit = baseAssetBalance - totalFee;
        totalBaseAssets += baseAssetBalance - totalFee;

        lastHarvestBlock = block.number;

        emit LogFeeClaimed(feeTo, totalFee);

        emit LogHarvested(baseAssetBalance);
    }

    /// @notice Stake all the base tokens, ideally there shouldn't be any left
    function stakeAllBaseAsset() public onlyOwner {
        uint256 balance = asset.balanceOf(address(this));
        stargateStaking.deposit(pid, balance);
        emit LogStakedAllAssets(balance);
    }

    /// @notice Emergency Withdraw
    /// @dev This would forfeit the rewards but would withdraw all tokens
    /// from the staking contract
    function emergencyWithdraw() public onlyOwner {
        stargateStaking.emergencyWithdraw(pid);
        emit LogEmergencyWithdraw(pid, asset.balanceOf(address(this)));
    }

    /*//////////////////////////////////////////////////////////////
                        VAULT ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the status of the executor
    /// @dev Only owner of the vault can set this
    /// @param _executor Address of the Executor
    /// @param _status Status of the Executor
    function setExecutorsStatus(address _executor, bool _status)
        external
        onlyOwner
    {
        executors[_executor] = _status;
        emit LogSetExecutorStatus(_executor, _status);
    }

    /// @notice Sets the new fee receiver
    /// @dev Only owner of the vault can set this
    /// @param _newFeeTo Address of the New Fee Receiver
    function setFeeTo(address _newFeeTo) external onlyOwner {
        feeTo = _newFeeTo;
        emit LogSetFeeTo(_newFeeTo);
    }

    /// @notice Sets the Fees
    /// @dev Only owner of the vault can set this
    /// @param _newFees New Fee Vaule
    function setFees(uint256 _newFees) external onlyOwner {
        // can't set it to 100%
        if (_newFees >= 1e18) revert YoSifuStargateVault__InvalidFee();
        fee = _newFees;
        emit LogSetFees(_newFees);
    }
}