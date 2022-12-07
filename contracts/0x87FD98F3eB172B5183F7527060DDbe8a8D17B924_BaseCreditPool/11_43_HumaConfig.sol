// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./Errors.sol";

import "hardhat/console.sol";

/** @notice HumaConfig maintains all the global configurations supported by Huma protocol.
 */
contract HumaConfig is Ownable, Pausable {
    /// Lower bound of protocol default grace period.
    uint32 private constant MIN_DEFAULT_GRACE_PERIOD = 1 days;

    /// The initial value for default grace period.
    uint32 private constant PROTOCOL_DEFAULT_GRACE_PERIOD = 60 days;

    /// The default treasury fee in bps.
    uint16 private constant DEFAULT_TREASURY_FEE = 1000; // 10%

    /// The treasury fee upper bound in bps.
    uint16 private constant TREASURY_FEE_UPPER_BOUND = 5000; // 50%

    /// Seconds passed the due date before a default can be triggered
    uint32 public protocolDefaultGracePeriodInSeconds;

    /// % of platform income that will be reserved in the protocol, measured in basis points
    uint16 public protocolFee;

    /// Huma protocol treasury
    address public humaTreasury;

    /// address of EvaluationAgentNFT contract
    address public eaNFTContractAddress;

    /// service account for Huma's evaluation agent hosting service
    address public eaServiceAccount;

    /// service account for Huma's payment detection service
    address public pdsServiceAccount;

    /// pausers can pause the pool.
    mapping(address => bool) private pausers;

    // poolAdmins has the list of approved accounts who can create and operate pools
    mapping(address => bool) private poolAdmins;

    /// List of assets supported by the protocol for investing and borrowing
    mapping(address => bool) private validLiquidityAssets;

    /// Contract address for Evaluation Agent NFT changed
    event EANFTContractAddressChanged(address eaNFT);

    /// Service account for the Evaluation Agent platform has changed
    event EAServiceAccountChanged(address eaService);

    /// The treasury address for Huma protocol has changed
    event HumaTreasuryChanged(address indexed newTreasuryAddress);

    /// New underlying asset supported by the protocol is added
    event LiquidityAssetAdded(address asset, address by);

    /// Remove the asset that is no longer supported by the protocol
    event LiquidityAssetRemoved(address asset, address by);

    /// A pauser has been added. A pauser is someone who can pause the protocol.
    event PauserAdded(address indexed pauser, address by);

    /// A pauser has been removed
    event PauserRemoved(address indexed pauser, address by);

    /// Service account for Payment Detection Service has been changed
    event PDSServiceAccountChanged(address pdsService);

    event PoolAdminAdded(address indexed poolAdmin, address by);
    event PoolAdminRemoved(address indexed poolAdmin, address by);
    event ProtocolDefaultGracePeriodChanged(uint256 gracePeriod);
    event ProtocolInitialized(address by);
    event TreasuryFeeChanged(uint256 oldFee, uint256 newFee);

    /// Makes sure the msg.sender is one of the pausers
    modifier onlyPausers() {
        if (!pausers[msg.sender]) revert Errors.notPauser();
        _;
    }

    /**
     * @notice Initiates the config. Only the protocol owner can set the treasury
     * address, add pausers and pool admins, change the default grace period,
     * treasury fee, add or remove assets to be supported by the protocol.
     * @dev Emit ProtocolInitialized event and HumaTreasuryChanged event
     */
    constructor() {
        protocolDefaultGracePeriodInSeconds = PROTOCOL_DEFAULT_GRACE_PERIOD;

        protocolFee = DEFAULT_TREASURY_FEE;

        emit ProtocolInitialized(msg.sender);
    }

    /**
     * @notice Adds a pauser, who can pause the entire protocol. Only proto admin can do so.
     * @param _pauser Address to be added to the pauser list
     * @dev If address(0) is provided, revert with "zeroAddressProvided()"
     * @dev If the address is already a pauser, revert w/ "alreadyAPauser"
     * @dev Emits a PauserAdded event.
     */
    function addPauser(address _pauser) external onlyOwner {
        if (_pauser == address(0)) revert Errors.zeroAddressProvided();
        if (pausers[_pauser]) revert Errors.alreadyAPauser();

        pausers[_pauser] = true;

        emit PauserAdded(_pauser, msg.sender);
    }

    /**
     * @notice Adds a pool admin.  Only proto admin can do so.
     * @param _poolAdmin Address to be added as a pool admin
     * @dev If address(0) is provided, revert with "zeroAddressProvided()"
     * @dev If the address is already a poolAdmin, revert w/ "ALREADY_A_POOL_ADMIN"
     * @dev Emits a PauserAdded event.
     */
    function addPoolAdmin(address _poolAdmin) external onlyOwner {
        if (_poolAdmin == address(0)) revert Errors.zeroAddressProvided();
        if (poolAdmins[_poolAdmin]) revert Errors.alreadyPoolAdmin();

        poolAdmins[_poolAdmin] = true;

        emit PoolAdminAdded(_poolAdmin, msg.sender);
    }

    /**
     * @notice Pauses the entire protocol. Used in extreme cases by the pausers.
     * @dev This function will not be governed by timelock due to its sensitivity to timing.
     */
    function pause() external onlyPausers {
        _pause();
    }

    /**
     * @notice Removes a pauser. Only proto admin can do so.
     * @param _pauser Address to be removed from the pauser list
     * @dev If address(0) is provided, revert with "zeroAddressProvided()"
     * @dev If the address is not currently a pauser, revert w/ "notPauser()"
     * @dev Emits a PauserRemoved event.
     */
    function removePauser(address _pauser) external onlyOwner {
        if (_pauser == address(0)) revert Errors.zeroAddressProvided();
        if (!pausers[_pauser]) revert Errors.notPauser();

        pausers[_pauser] = false;

        emit PauserRemoved(_pauser, msg.sender);
    }

    /**
     * @notice Removes a poolAdmin. Only proto admin can do so.
     * @param _poolAdmin Address to be removed from the poolAdmin list
     * @dev If address(0) is provided, revert with "zeroAddressProvided()"
     * @dev If the address is not currently a poolAdmin, revert w/ "notPoolOwner()"
     * @dev Emits a PauserRemoved event.
     */
    function removePoolAdmin(address _poolAdmin) external onlyOwner {
        if (_poolAdmin == address(0)) revert Errors.zeroAddressProvided();
        if (!poolAdmins[_poolAdmin]) revert Errors.notPoolOwner();

        poolAdmins[_poolAdmin] = false;

        emit PoolAdminRemoved(_poolAdmin, msg.sender);
    }

    /**
     * @notice Sets the contract address for Evaluation Agent NFT contract. Only proto admin can do so.
     */
    function setEANFTContractAddress(address contractAddress) external onlyOwner {
        if (contractAddress == address(0)) revert Errors.zeroAddressProvided();
        eaNFTContractAddress = contractAddress;
        emit EANFTContractAddressChanged(contractAddress);
    }

    /**
     * @notice Sets the service account for Evaluation Agent service. This is the account
     * that can approve credit requests. Only proto admin can make the change.
     */
    function setEAServiceAccount(address accountAddress) external onlyOwner {
        if (accountAddress == address(0)) revert Errors.zeroAddressProvided();
        eaServiceAccount = accountAddress;
        emit EAServiceAccountChanged(accountAddress);
    }

    /**
     * @notice Sets the address of Huma Treasury. Only proto admin can do so.
     * @param treasury the new Huma Treasury address
     * @dev If address(0) is provided, revert with "zeroAddressProvided()"
     * @dev emit HumaTreasuryChanged(address newTreasury) event
     */
    function setHumaTreasury(address treasury) external onlyOwner {
        if (treasury == address(0)) revert Errors.zeroAddressProvided();
        if (treasury != humaTreasury) {
            humaTreasury = treasury;
            emit HumaTreasuryChanged(treasury);
        }
    }

    /**
     * @notice Sets the validity of an asset for liquidity in Huma. Only proto admin can do so.
     * @param asset Address of the valid asset.
     * @param valid The new validity status of a Liquidity Asset in Pools.
     * @dev Emits a LiquidityAssetAdded event when the asset is set to be valid
     * Emits a LiquidityAssetRemoved event when the asset is set to be invalid
     */
    function setLiquidityAsset(address asset, bool valid) external onlyOwner {
        if (valid) {
            validLiquidityAssets[asset] = true;
            emit LiquidityAssetAdded(asset, msg.sender);
        } else {
            validLiquidityAssets[asset] = false;
            emit LiquidityAssetRemoved(asset, msg.sender);
        }
    }

    /**
     * @notice Sets the service account for Payment Detection Service. Only proto admin can do so.
     * This is the account that can report to the contract that a payment has been received.
     */
    function setPDSServiceAccount(address accountAddress) external onlyOwner {
        if (accountAddress == address(0)) revert Errors.zeroAddressProvided();
        pdsServiceAccount = accountAddress;
        emit PDSServiceAccountChanged(accountAddress);
    }

    /**
     * @notice Sets the default grace period at the protocol level. Only proto admin can do so.
     * @param gracePeriod new default grace period in seconds
     * @dev Rejects any grace period shorter than 1 day to guard against fat finger or attack.
     * @dev Emits ProtocolDefaultGracePeriodChanged(uint256 newGracePeriod) event
     */
    function setProtocolDefaultGracePeriod(uint256 gracePeriod) external onlyOwner {
        if (gracePeriod < MIN_DEFAULT_GRACE_PERIOD)
            revert Errors.defaultGracePeriodLessThanMinAllowed();
        protocolDefaultGracePeriodInSeconds = uint32(gracePeriod);
        emit ProtocolDefaultGracePeriodChanged(gracePeriod);
    }

    /**
     * @notice Sets the treasury fee (in basis points). Only proto admin can do so.
     * @param fee the new treasury fee (in bps)
     * @dev Treasury fee cannot exceed 5000 bps, i.e. 50%
     * @dev Emits a TreasuryFeeChanged event
     */
    function setTreasuryFee(uint256 fee) external onlyOwner {
        if (fee > TREASURY_FEE_UPPER_BOUND) revert Errors.treasuryFeeHighThanUpperLimit();
        uint256 oldFee = protocolFee;
        protocolFee = uint16(fee);
        emit TreasuryFeeChanged(oldFee, fee);
    }

    /**
     * @notice Unpause the entire protocol. Only the protocol owner can do so.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /// Reports if the asset is supported by the protocol or not
    function isAssetValid(address asset) external view returns (bool) {
        return validLiquidityAssets[asset];
    }

    /// Reports if a given user account is an approved pauser or not
    function isPauser(address account) external view returns (bool) {
        return pausers[account];
    }

    /// Reports ia given user account is an approved pool admin
    function isPoolAdmin(address account) external view returns (bool) {
        return poolAdmins[account];
    }
}