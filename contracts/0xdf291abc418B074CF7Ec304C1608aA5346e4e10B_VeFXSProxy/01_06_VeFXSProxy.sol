pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IveFXS {
    struct LockedBalance {
        int128 amount;
        uint256 end;
    }
    function create_lock(uint256 _value, uint256 _unlock_time) external;
    function increase_amount(uint256 _value) external;
    function increase_unlock_time(uint256 _unlock_time) external;
    function withdraw() external;
    function balanceOf(address addr, uint256 _t) external view returns (uint256);
    function totalSupply(uint256 t) external view returns (uint256);
    function totalFXSSupply() external  view returns (uint256);
    function locked(address addr) external view returns (LockedBalance memory);
    function token() external view returns (address);
}

interface IGaugeController {
    function vote_for_gauge_weights(address _gauge_addr, uint256 _user_weight) external;
}

interface IUnifiedFarm {
    function proxyToggleStaker(address staker_address) external;
}

contract VeFXSProxy is Ownable {
    using SafeERC20 for IERC20;

    /// @dev The underlying veFXS contract which STAX is locking into.
    IveFXS public veFXS;

    /// @dev The underlying token being locked.
    IERC20 public fxsToken;

    /// @dev Ability to vote for a gauge using STAX's veFXS balance
    IGaugeController public gaugeController;

    /// @dev A set of addresses which are approved to create/update/withdraw the STAX veFXS holdings.
    mapping(address => bool) public opsManagers;

    event ApprovedOpsManager(address opsManager, bool approved);
    event TokenRecovered(address user, uint256 amount);
    event WithdrawnTo(address to, uint256 amount);
    event GaugeProxyToggledStaker(address gaugeAddress, address stakerAddress);

    constructor(address _veFXS, address _gaugeController) {
        veFXS = IveFXS(_veFXS);
        fxsToken = IERC20(veFXS.token());
        gaugeController = IGaugeController(_gaugeController);
    }

    /** 
      * @notice Approve/Unapprove an address as being an operations manager.
      *         The ops Manager is permissioned to add/extend/withdraw the veFXS locks
      *         on STAX behalf.
      * @param _opsManager The address to approve
      * @param _approved Whether to approve/unapprove the address.s
      */
    function approveOpsManager(
        address _opsManager,
        bool _approved
    ) external onlyOwner {
        opsManagers[_opsManager] = _approved;
        emit ApprovedOpsManager(_opsManager, _approved);
    }

    /** 
      * @notice Deposit `_value` tokens for STAX and lock until `_unlock_time`
      *         without modifying the unlock time
      * @param _value Amount to deposit
      * @param _unlock_time Epoch time when tokens unlock, rounded down to whole weeks
      */
    function createLock(uint256 _value, uint256 _unlock_time) external onlyOwnerOrOpsManager {
        // Pull FXS
        fxsToken.safeTransferFrom(msg.sender, address(this), _value);

        // Increase allowance then create lock
        fxsToken.safeIncreaseAllowance(address(veFXS), _value);
        veFXS.create_lock(_value, _unlock_time);
    }

    /** 
      * @notice Deposit `_value` additional tokens for STAX
      *         without modifying the unlock time
      */
    function increaseAmount(uint256 _value) external onlyOwnerOrOpsManager {
        // Pull FXS
        fxsToken.safeTransferFrom(msg.sender, address(this), _value);

        // Increase allowance then increase the lock amount
        fxsToken.safeIncreaseAllowance(address(veFXS), _value);
        veFXS.increase_amount(_value);
    }

    /** 
      * @notice Extend the unlock time for STAX to `_unlock_time`
      * @param _unlock_time New epoch time for unlocking
      */
    function increaseUnlockTime(uint256 _unlock_time) external onlyOwnerOrOpsManager {
        veFXS.increase_unlock_time(_unlock_time);
    }

    /**
      * @dev Allocate voting power for changing pool weights, using STAX's veFXS balance
      * @param _gauge _gauge_addr Gauge which STAX votes for
      * @param _weight Weight for a gauge in bps (units of 0.01%). Minimal is 0.01%. Ignored if 0
      */
    function voteGaugeWeight(address _gauge, uint256 _weight) external onlyOwnerOrOpsManager {
        gaugeController.vote_for_gauge_weights(_gauge, _weight);
    }

    /** 
      * @notice Withdraw all tokens for STAX and send to recipient
      * @dev Only possible if the lock has expired
      */
    function withdrawTo(address _to) external onlyOwnerOrOpsManager {
        // Pull the lock amount (and convert to uint256)
        uint256 lockedAmount = uint128(veFXS.locked(address(this)).amount);

        // Withdraw the FXS, and transfer.
        veFXS.withdraw();
        _transferToken(fxsToken, _to, lockedAmount);

        // An extra event here to also report the account it's sent to.
        emit WithdrawnTo(_to, lockedAmount);
    }

    /** 
      * @notice Get the current voting power for STAX, as of now.
      * @return User voting power
      */
    function veFXSBalance() external view returns (uint256) {
        return veFXS.balanceOf(address(this), block.timestamp);
    }

    /** 
      * @notice Calculate total veFXS voting power, as of now.
      * @return Total voting power
      */
    function totalVeFXSSupply() external view returns (uint256) {
        return veFXS.totalSupply(block.timestamp);
    }

    /** 
      * @notice Calculate FXS supply within veFXS
      * @return Total FXS supply
      */
    function totalFXSSupply() external view returns (uint256) {
        return veFXS.totalFXSSupply();
    }

    /** 
      * @notice STAX's current lock
      * @dev Will revert if no lock has been added yet.
      * @return LockedBalance
      */
    function locked() external view returns (IveFXS.LockedBalance memory) {
        return veFXS.locked(address(this));
    }

    // recover tokens
    function recoverToken(address _token, address _to, uint256 _amount) external onlyOwner {
        _transferToken(IERC20(_token), _to, _amount);
        emit TokenRecovered(_to, _amount);
    }

    function _transferToken(IERC20 _token, address _to, uint256 _amount) internal {
        uint256 balance = _token.balanceOf(address(this));
        require(_amount <= balance, "not enough tokens");
        _token.safeTransfer(_to, _amount);
    }

    /**
      * @dev Allow STAX's veFXS balance in this contract to be used for the gauge boost
      *      of STAX's liquidity ops contract managing the gauge locks.
      * @notice gauge.toggleValidVeFXSProxy(address _proxy_addr) needs to be called by Frax Gov first.
      * @param _gaugeAddress The address of the gauge to whitelist this as a valid proxy
      * @param _stakerAddress The address of the gauge staking contract (STAX's liquidity ops)
      */
    function gaugeProxyToggleStaker(address _gaugeAddress, address _stakerAddress) external onlyOwner {
      IUnifiedFarm(_gaugeAddress).proxyToggleStaker(_stakerAddress);
      emit GaugeProxyToggledStaker(_gaugeAddress, _stakerAddress);
    }

    // execute arbitrary functions
    function execute(address _to, uint256 _value, bytes calldata _data) external onlyOwner returns (bytes memory) {
      (bool success, bytes memory returndata) = _to.call{value: _value}(_data);
      require(success, "Execution failed");
      return returndata;
    }

    modifier onlyOwnerOrOpsManager() {
        require(msg.sender == owner() || opsManagers[msg.sender] == true, "not owner or ops manager");
        _;
    }
}