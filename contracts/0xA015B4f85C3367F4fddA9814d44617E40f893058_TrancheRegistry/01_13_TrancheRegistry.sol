pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (investments/frax-gauge/tranche/TrancheRegistry.sol)

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../../interfaces/investments/frax-gauge/tranche/ITranche.sol";
import "../../../interfaces/investments/frax-gauge/tranche/ITrancheRegistry.sol";

import "../../../common/access/Operators.sol";
import "../../../common/Executable.sol";
import "../../../common/CommonEventsAndErrors.sol";

/**
  * @notice A Tranch Registry which can create new tranches, and perform some operations on the tranches
  * it has created and initialized.
  * 
  * @dev Each new tranche is cloned from a template implementation which is statically deployed
  * once and added here (addTrancheImpl).
  *
  * Owner: STAX multisig
  * Operators: Liquidity Ops (needs to create new tranches)
 */
contract TrancheRegistry is ITrancheRegistry, Ownable, Operators {
    using SafeERC20 for IERC20;

    // Note these have a custom getter as the function is in the interface (so needs to be explicitly defined)
    mapping(uint256 => ImplementationDetails) private _implDetails;
    uint256 public implDetailsLength;

    // implId -> tranche array
    mapping(uint256 => address[]) public trancheList; 
        
    // tranche address -> was created from this registry
    mapping(address => bool) public allTranches;

    /// @notice Retrieve the implementation details for a given tranche ID
    function implDetails(uint256 _implId) external view override onlyValidImplId(_implId) returns (ImplementationDetails memory details) {
        return _implDetails[_implId];
    }

    /// @notice The list of all known created tranche instances in the registry
    function trancheListLength(uint256 _implId) external view onlyValidImplId(_implId) returns (uint256 length) {
        return trancheList[_implId].length;
    }

    /// @notice Whether a given address is a tranche that this registry created.
    function createdTranche(address trancheAddress) external  view returns (bool) {
        return allTranches[trancheAddress];
    }

    /// @notice Disable/Enable a particular tranche implementation ID template from future use.
    /// @dev New createTranche() calls on this ID will fail.
    function setImplDisabled(uint256 _implId, bool _isDisabled) external  onlyOperators onlyValidImplId(_implId) {
        _implDetails[_implId].disabled = _isDisabled;
        emit ImplementationDisabled(_implId, _isDisabled);
    }

    /// @notice Disable/Enable a particular tranche instance which was created by this registry.
    function setTrancheDisabled(address _tranche, bool _isDisabled) external onlyOperators {
        ITranche(_tranche).setDisabled(_isDisabled);
    }

    /// @notice Update the registry on a particular tranche instance - eg on registry upgrade.
    function updateRegistryOnTranche(address _tranche, address _registry) external onlyOperators {
        ITranche(_tranche).setRegistry(_registry);
    }

    /// @notice Close a given tranche template ID from being staked into in future.
    /// @dev Withdraws are still allowed upon expiry.
    function closeImplForStaking(uint256 _implId, bool _value) external  onlyOperators onlyValidImplId(_implId) {
        _implDetails[_implId].closedForStaking = _value;
        emit ImplementationClosedForStaking(_implId, _value);
    }

    /// @notice Add a new tranche template implementation.
    function addTrancheImpl(address _implementation) external  onlyOperators {
        if (_implementation == address(0)) revert CommonEventsAndErrors.InvalidAddress(_implementation);

        _implDetails[implDetailsLength] = ImplementationDetails({
            implementation: _implementation,
            closedForStaking: false,
            disabled: false
        });
        
        emit TrancheImplCreated(implDetailsLength, _implementation);
        implDetailsLength++;
    }

    /// @notice Operators (eg liquidity ops) can create new tranches for a particular tranche implementation id.
    function createTranche(uint256 _implId) external override onlyOperators onlyValidImplId(_implId) returns (address tranche, address stakingAddress, address stakingToken)  {       
        // Clone the implementation, if it's valid
        {
            ImplementationDetails storage details = _implDetails[_implId];

            if (details.disabled) revert InvalidTrancheImpl(_implId);
            tranche = Clones.clone(details.implementation);
        }

        // Add into the registry.
        trancheList[_implId].push(tranche);
        allTranches[tranche] = true;

        // Set the owner of the new tranche to the caller.
        (stakingAddress, stakingToken) = ITranche(tranche).initialize(address(this), _implId, msg.sender);

        emit TrancheCreated(_implId, tranche, stakingAddress, stakingToken);
    }

    /// @dev In case of registry upgrade - owner of the new registry can add existing tranches
    /// after setting up the unique implId in addTrancheImpl()
    function addExistingTranche(uint256 _implId, address _tranche) external onlyOwner onlyValidImplId(_implId) {
        if (_tranche == address(0)) revert CommonEventsAndErrors.InvalidAddress(_tranche);
        if (allTranches[_tranche]) revert TrancheAlreadyExists(_tranche);
        if (ITranche(_tranche).disabled()) revert ITranche.InactiveTranche(_tranche);

        trancheList[_implId].push(_tranche);
        allTranches[_tranche] = true;
        emit AddedExistingTranche(_implId, _tranche);
    }

    function addOperator(address _address) external override onlyOwner {
        _addOperator(_address);
    }

    function removeOperator(address _address) external override onlyOwner {
        _removeOperator(_address);
    }

    /// @notice Owner can recover tokens
    function recoverToken(address _token, address _to, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
        emit CommonEventsAndErrors.TokenRecovered(_to, _token, _amount);
    }

    /**
      * Owner (msig), Operator (liquidity ops), and the tranches which this registry created can call.
      * 
      * The ConvexVaultTranche implementation needs to whitelist the tranche such that it's allowed on Convex
      * to create new vaults.
      *
      * This needs to be done from a fixed/known address which is granted an operator role upfront.
      *   Eg: TrancheRegistry is given operator access to call on ConvexVaultOps.setAllowedAddress()
      */
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external override returns (bytes memory) {
        // Onwer, operator, or tranche that this registry created
        if (msg.sender != owner() && !operators[msg.sender] && !allTranches[msg.sender])
            revert OnlyOwnerOperatorTranche(msg.sender);

        return Executable.execute(_to, _value, _data);
    }

    modifier onlyValidImplId(uint256 _implId) {
        if (_implId >= implDetailsLength || _implDetails[_implId].implementation == address(0)) revert InvalidTrancheImpl(_implId);
        _;
    }
}