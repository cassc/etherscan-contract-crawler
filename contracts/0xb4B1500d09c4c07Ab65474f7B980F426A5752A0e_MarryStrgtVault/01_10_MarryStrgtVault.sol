// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC4626} from "solmate/src/mixins/ERC4626.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {Owned} from "solmate/src/auth/Owned.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";

import {ILPStaking} from "./interfaces/ILPStaking.sol";
import {IStrgtRouter} from "./interfaces/IStrgtRouter.sol";
import {IStrgtPool} from "./interfaces/IStrgtPool.sol";
import {ISwapper} from "./interfaces/ISwapper.sol";

/// @notice Vault to auto-compound rewards from Strgt LP
contract MarryStrgtVault is ERC4626, Owned {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for ERC20;

    /*//////////////////////////////////////////////////////////////
                        ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice Address of Strgt Staking Contract
    ILPStaking public immutable strgtStaking;

    /// @notice Address of Strgt Router
    IStrgtRouter public immutable strgtRouter;

    /// @notice Reward Token issued by Strgt i.e. STG Token
    ERC20 public immutable rewardToken;

    /// @notice Underlying Asset in the Strgt Pool
    ERC20 public immutable underlyingAsset;

    /// @notice Address of the Fee Receiver
    address public feeTo;

    /*//////////////////////////////////////////////////////////////
                        STARGATE STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Pool Id of the Strgt Pool
    uint256 public immutable poolId;

    /// @notice Pid in the Staking Contract
    uint256 public immutable pid;

    /*//////////////////////////////////////////////////////////////
                        VAULT STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Total Strgt Pool Asssets held by the vault
    uint256 private totalBaseAssets;

    /// @notice Fee for the Vault FEE_PRECISION - 1e18
    /// @dev 1e17 - 10%, 20e16 - 20%, can't set 100%
    uint256 public fee;

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

    error MarryStrgtVault__InsufficientOut();
    error MarryStrgtVault__NotExecutor();
    error MarryStrgtVault__InvalidFee();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the vault configurations
    /// @param _asset Address of Strgt Pool Tokens
    /// @param _underlyingAsset Address of underlying tokens of the Strgt Pool
    /// @param _strgtStaking Address of the Strgt Staking contract
    /// @param _strgtRouter Address of the Strgt Router contract
    /// @param _rewardToken Address of the Reward Token
    /// @param _poolId Pool Id of the Strgt Pool Token
    /// @param _pid PID of the asset in Staking Contract
    /// @param _feeTo Address of the Fee Receiver
    /// @param _owner Address of the Onwer of the vault
    constructor(
        ERC20 _asset,
        ERC20 _underlyingAsset,
        address _strgtStaking,
        address _strgtRouter,
        ERC20 _rewardToken,
        uint256 _poolId,
        uint256 _pid,
        address _feeTo,
        address _owner
    )
        ERC4626(
            _asset,
            // ex: Yield Optimized Mary - S*USDC - Strgt Vault
            string(
                abi.encodePacked(
                    "Yield Optimized Mary -",
                    _asset.name(),
                    "- Strgt Vault"
                )
            ),
            // ex: yoSifu_Stargate_S*USDC
            string(abi.encodePacked("yoSifu_Stargate_", _asset.symbol()))
        )
        Owned(_owner)
    {
        executors[_owner] = true;
        strgtStaking = ILPStaking(_strgtStaking);
        strgtRouter = IStrgtRouter(_strgtRouter);
        rewardToken = _rewardToken;
        pid = _pid;
        feeTo = _feeTo;
        poolId = _poolId;
        underlyingAsset = _underlyingAsset;

        _underlyingAsset.safeApprove(
            address(strgtRouter),
            type(uint256).max
        );
        _asset.safeApprove(address(strgtStaking), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                    ERC4626 OVERRIDES FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function afterDeposit(
        uint256 assets,
        uint256 /*shares*/
    ) internal virtual override {
        totalBaseAssets += assets;
        strgtStaking.deposit(pid, assets);
    }

    function beforeWithdraw(
        uint256 assets,
        uint256 /*shares*/
    ) internal virtual override {
        totalBaseAssets -= assets;
        if (asset.balanceOf(address(this)) < assets) {
            strgtStaking.withdraw(pid, assets);
        }
    }

    // TODO: Add delayed harvest logic? Maybe next version?
    function totalAssets() public view override returns (uint256) {
        return totalBaseAssets;
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
            revert MarryStrgtVault__NotExecutor();

        uint256 baseAssetBalanceBefore = asset.balanceOf(address(this));

        strgtStaking.deposit(pid, 0);

        uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(swapper, rewardTokenBalance);
        ISwapper(swapper).onSwapReceived(data);

        uint256 underlyingAssetBalance = underlyingAsset.balanceOf(
            address(this)
        );

        if (underlyingAssetBalance < amountOutMin)
            revert MarryStrgtVault__InsufficientOut();

        strgtRouter.addLiquidity(
            poolId,
            underlyingAssetBalance,
            address(this)
        );

        uint256 baseAssetBalance = asset.balanceOf(address(this)) -
            baseAssetBalanceBefore;

        uint256 totalFee = baseAssetBalance.mulDivDown(fee, 1e18);

        asset.safeTransfer(feeTo, totalFee);

        strgtStaking.deposit(pid, baseAssetBalance - totalFee);

        totalBaseAssets += baseAssetBalance - totalFee;

        emit LogFeeClaimed(feeTo, totalFee);

        emit LogHarvested(baseAssetBalance);
    }

    /// @notice Stake all the base tokens, ideally there shouldn't be any left
    function stakeAllBaseAsset() public onlyOwner {
        uint256 balance = asset.balanceOf(address(this));
        strgtStaking.deposit(pid, balance);
        emit LogStakedAllAssets(balance);
    }

    /// @notice Emergency Withdraw
    /// @dev This would forfeit the rewards but would withdraw all tokens
    /// from the staking contract
    function emergencyWithdraw() public onlyOwner {
        strgtStaking.emergencyWithdraw(pid);
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
        if (_newFees >= 1e18) revert MarryStrgtVault__InvalidFee();
        fee = _newFees;
        emit LogSetFees(_newFees);
    }
}