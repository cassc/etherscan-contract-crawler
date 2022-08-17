pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (investments/frax-gauge/tranche/ConvexVaultOps.sol)

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../../interfaces/investments/frax-gauge/tranche/IConvexVaultOps.sol";
import "../../../interfaces/investments/frax-gauge/vefxs/IVeFXSProxy.sol";
import "../../../interfaces/external/convex/IConvexJointVaultManager.sol";

import "../../../common/access/Operators.sol";
import "../../../common/Executable.sol";
import "../../../common/CommonEventsAndErrors.sol";

/**
  * @notice The operations manager for Convex Vault's, serving two primary functions
  * 
  * 1/ STAX is JointOwner of the Convex's "Joint Vault Manager". STAX can:
  *     a/ Propose and accept fees with convex
  *     b/ Set the address where joint owner fees get deposited
  *     c/ Add allowed addresses (which are new stax tranche contracts)
  *        to create new convex vaults under this partnership.
  *
  * 2/ Convex's Booster contract automates flipping from Convex veFXS proxy -> STAX veFXS proxy
  *    To do this, it calls into proxyToggleStaker()
  * 
  * Owner: STAX multisig
  * Operators: STAX tranche registry - to whitelist new tranches able to create convex vaults
  * convexOperator: Convex's Booster contract (which is the operator() for their whitelisted veFXSProxy)
  */
contract ConvexVaultOps is IConvexVaultOps, Ownable, Operators {
    using SafeERC20 for IERC20;

    /// @notice The Convex deployed joint vault manager
    /// @dev STAX is the joint owner (convex is the owner)
    /// Any new convex vault owner/creator needs to be whitelisted on 
    /// the joint vault manager first
    IConvexJointVaultManager public convexJointVaultManager;

    /// @notice The operator of the Convex veFXS proxy (and vaults operator). Aka 'Convex Booster'
    address public convexOperator;

    /// @dev STAX's whitelisted veFXS proxy.
    IVeFXSProxy public immutable veFxsProxy;

    /// @dev The underlying gauge address that the convex vault is using,
    /// in particular when the proxyToggleStaker() callback is invoked from the Convex Booster.
    address public gaugeAddress;

    event ConvexOperatorSet(address convexOperator);
    event ConvexJointVaultManagerSet(address convexJointVaultManager);
    event GaugeSet(address indexed gaugeAddress);

    error OnlyOwnerOrConvexOperator(address caller);

    constructor(address _veFxsProxy, address _gauge) {
        veFxsProxy = IVeFXSProxy(_veFxsProxy);
        gaugeAddress = _gauge;
    }

    function addOperator(address _address) external override onlyOwner {
        _addOperator(_address);
    }

    function removeOperator(address _address) external override onlyOwner {
        _removeOperator(_address);
    }

    /// @notice Set the operator of the Convex veFXS proxy (and vaults operator). Aka 'Convex Booster'
    function setConvexOperator(address _convexOperator) external onlyOwner {
        convexOperator = _convexOperator;
        emit ConvexOperatorSet(_convexOperator);
    }

    /// @notice Set the Convex deployed joint vault manager.
    function setConvexJointVaultManager(address _convexJointVaultManager) external onlyOwner {
        convexJointVaultManager = IConvexJointVaultManager(_convexJointVaultManager);
        emit ConvexJointVaultManagerSet(_convexJointVaultManager);
    }

    /// @notice Set the underlying gauge address that the convex joint vault will be using
    function setGauge(address _gaugeAddress) external onlyOwner {
        gaugeAddress = _gaugeAddress;
        emit GaugeSet(_gaugeAddress);
    }

    /**
      * @notice Propose new fees to be used in the convex joint vault manager.
      * @dev If stax proposes, then convex needs to 'acceptFees()' - and vice versa.
      * FEE_DENOMINATOR = 10000
      */
    function setFees(uint256 _owner, uint256 _coowner, uint256 _booster) external onlyOwner {
        convexJointVaultManager.setFees(_owner, _coowner, _booster);
    }

    /**
      * @notice Accept convex proposed fees in the convex joint vault manager.
      * @dev Check Convex's JointVaultManager for what was proposed before calling:
      *    newOwnerIncentive()
      *    newJointownerIncentive()
      *    newBoosterIncentive()
      */
    function acceptFees() external onlyOwner {
        convexJointVaultManager.acceptFees();
    }

    /**
      * @notice Set the address where STAX's share of convex vault fees will be sent
      * whenever getRewards() is called
      */
    function setJointOwnerDepositAddress(address _deposit) external onlyOwner {
        convexJointVaultManager.setJointOwnerDepositAddress(_deposit);
    }

    /**
      * @notice If Convex has released a Booster that we don't agree with (or shuts it down)
      * then the veFXS proxy can be set to be STAX.
      * 
      * @dev USE WITH CAUTION - once called, this vault cannot be set to use Convex's veFXS boost again.
      */
    function setVaultProxy(address _vault) external onlyOwner {
        convexJointVaultManager.setVaultProxy(_vault);
    }

    /**
      * @notice Give permission to Convex's current booster contract.
      * @dev Only call if absolutely necessary, otherwise we cannot force the switch back to STAXs veFXS proxy
      */
    function allowConvexBooster() external onlyOwner {
        convexJointVaultManager.allowBooster();
    }

    /**
      * @notice Whitelist a new address which has permissions to create a new vault under
      * the joint partnership
      */
    function setAllowedAddress(address _account, bool _allowed) external override onlyOwnerOrOperators {
        convexJointVaultManager.setAllowedAddress(_account, _allowed);
    }

    /**
      * @notice Convex's Booster will call this hook in order to switch the veFXS boost to STAX's veFXS proxy
      *         It toggles the underlying veFxsProxy's allowance of it's veFXS boost, 
      *         for this particular staker (ie convex vault), in this particular gauge instance.
      * @dev gauge.toggleValidVeFXSProxy(address _proxy_addr) needs to be called by Frax Gov first.
      * @param _stakerAddress The address of the contract which will be locking LP
      */
    function proxyToggleStaker(address _stakerAddress) external onlyOwnerOrConvexOperator {
      IVeFXSProxy(veFxsProxy).gaugeProxyToggleStaker(gaugeAddress, _stakerAddress);
    }

    /// @dev Provided in case there are extra functions required to call on the Convex Joint Vault Manager in future
    function execute(address _to, uint256 _value, bytes calldata _data) external onlyOwnerOrOperators returns (bytes memory) {
        return Executable.execute(_to, _value, _data);
    }

    /// @notice Owner can recover tokens
    function recoverToken(address _token, address _to, uint256 _amount) external onlyOwner {
      IERC20(_token).safeTransfer(_to, _amount);
      emit CommonEventsAndErrors.TokenRecovered(_to, _token, _amount);
    }

    modifier onlyOwnerOrOperators() {
        if (msg.sender != owner() && !operators[msg.sender]) revert CommonEventsAndErrors.OnlyOwnerOrOperators(msg.sender);
        _;
    }

    modifier onlyOwnerOrConvexOperator() {
        if (msg.sender != owner() && msg.sender != convexOperator) revert OnlyOwnerOrConvexOperator(msg.sender);
        _;
    }
}