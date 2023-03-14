// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

// libraries
import "../external/@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "../external/@openzeppelin/utils/SafeCast.sol";
import "../libraries/Bitwise.sol";
import "../libraries/Hash.sol";

// extends
import "../interfaces/vault/IVaultBase.sol";
import "./VaultImmutable.sol";
import "../shared/SpoolOwnable.sol";
import "../shared/Constants.sol";

// other imports
import "../interfaces/vault/IVaultDetails.sol";
import "../interfaces/ISpool.sol";
import "../interfaces/IController.sol";
import "../interfaces/IFastWithdraw.sol";
import "../interfaces/IFeeHandler.sol";
import "../shared/SpoolPausable.sol";

/**
 * @notice Implementation of the {IVaultBase} interface.
 *
 * @dev
 * Vault base holds vault state variables and provides some of the common vault functions.
 */
abstract contract VaultBase is IVaultBase, VaultImmutable, SpoolOwnable, SpoolPausable, BaseConstants {
    using Bitwise for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    /// @notice The central Spool contract
    ISpool internal immutable spool;

    /// @notice The fast withdraw contract
    IFastWithdraw internal immutable fastWithdraw;

    /// @notice The fee handler contract
    IFeeHandler internal immutable feeHandler;

    /// @notice Boolean signaling if the contract was initialized yet
    bool private _initialized;

    /// @notice The owner of the vault, also the vault fee recipient
    address public vaultOwner;

    /// @notice Vault owner fee
    uint16 public vaultFee;

    /// @notice The name of the vault
    string public name;

    /// @notice The total shares of a vault
    uint128 public totalShares;

    /// @notice Total instant deposit, used to calculate vault reward incentives
    uint128 public totalInstantDeposit;

    /// @notice The proportions of each strategy when depositing
    /// @dev Proportions are 14bits each, and the add up to FULL_PERCENT (10.000)
    uint256 public proportions;

    /// @notice Proportions to deposit after reallocation withdraw amount is claimed
    uint256 internal depositProportions;
    
    /// @notice Hash of the strategies list
    bytes32 public strategiesHash;

    /// @notice Number of vault incentivized tokens
    uint8 public rewardTokensCount;
    
    /// @notice Data if vault and at what index vault is reallocating
    uint24 public reallocationIndex;

    /// @notice User vault state values
    mapping(address => User) public users;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Sets the initial immutable values of the contract common for all vaults.
     *
     * @dev
     * All values have been sanitized by the controller contract, meaning
     * that no additional checks need to be applied here.
     *
     * @param _spool the spool implemenation
     * @param _controller the controller implementation
     * @param _fastWithdraw fast withdraw implementation
     * @param _feeHandler fee handler implementation
     */
    constructor(
        ISpool _spool,
        IController _controller,
        IFastWithdraw _fastWithdraw,
        IFeeHandler _feeHandler
    )
    SpoolPausable(_controller)
    {
        require(address(_spool) != address(0), "VaultBase::constructor: Spool address cannot be 0");
        require(address(_fastWithdraw) != address(0), "VaultBase::constructor: FastWithdraw address cannot be 0");
        require(address(_feeHandler) != address(0), "VaultBase::constructor: Fee Handler address cannot be 0");

        spool = _spool;
        fastWithdraw = _fastWithdraw;
        feeHandler = _feeHandler;
    }

    /* ========== INITIALIZE ========== */

    /**
     * @notice Initializes state of the vault at proxy creation.
     * @dev Called only once by vault factory after deploying a vault proxy.
     *      All values have been sanitized by the controller contract, meaning
     *      that no additional checks need to be applied here.
     *
     * @param vaultInitializable initial vault specific variables
     */
    function initialize(
        VaultInitializable memory vaultInitializable
    ) external override initializer {
        vaultOwner = vaultInitializable.owner;
        vaultFee = vaultInitializable.fee;
        name = vaultInitializable.name;

        proportions = _mapProportionsArrayToBits(vaultInitializable.proportions);
        _updateStrategiesHash(vaultInitializable.strategies);
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Calculate and return proportion of passed parameters of 128 bit size
     * @dev Calculates the value using in 256 bit space, later casts back to 128 bit
     * Requirements:
     * 
     * - the result can't be bigger than maximum 128 bits value
     *
     * @param mul1 first multiplication value
     * @param mul2 second multiplication value
     * @param div result division value
     *
     * @return 128 bit proportion result
     */
    function _getProportion128(uint128 mul1, uint128 mul2, uint128 div) internal pure returns (uint128) {
        return SafeCast.toUint128((uint256(mul1) * mul2) / div);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @notice Transfer vault owner to another address.
     *
     * @param _vaultOwner new vault owner address
     *
     * Requirements:
     *
     * - the caller can only be the vault owner or Spool DAO
     */
    function transferVaultOwner(address _vaultOwner) external onlyVaultOwnerOrSpoolOwner {
        vaultOwner = _vaultOwner;
        emit TransferVaultOwner(_vaultOwner);
    }

    /**
     * @notice Set lower vault fee.
     *
     * @param _vaultFee new vault fee
     *
     * Requirements:
     *
     * - the caller can only be the vault owner
     * - new vault fee must be lower than before
     */
    function lowerVaultFee(uint16 _vaultFee) external {
        require(
            msg.sender == vaultOwner &&
            _vaultFee < vaultFee,
            "FEE"
        );

        vaultFee = _vaultFee;
        emit LowerVaultFee(_vaultFee);
    }

    /**
     * @notice Update the name of the vault.
     *
     * @param _name new vault name
     *
     * Requirements:
     *
     * - the caller can only be the Spool DAO
     */
    function updateName(string memory _name) external onlyOwner {
        name = _name;
        emit UpdateName(_name);
    }

    // =========== DEPOSIT HELPERS ============ //

    /**
     * @notice Update instant deposit user and vault amounts
     *
     * @param amount deposited amount
     */
    function _addInstantDeposit(uint128 amount) internal {
        users[msg.sender].instantDeposit += amount;
        totalInstantDeposit += amount;
    }

    /**
     * @notice Get strategy deposit amount for the strategy
     * @param _proportions Vault strategy proportions (14bit each)
     * @param i index to get the proportion
     * @param amount Total deposit amount
     * @return strategyDepositAmount 
     */
    function _getStrategyDepositAmount(
        uint256 _proportions,
        uint256 i,
        uint256 amount
    ) internal pure returns (uint128) {
        return SafeCast.toUint128((_proportions.get14BitUintByIndex(i) * amount) / FULL_PERCENT);
    }

    /**
     * @notice Transfers deposited underlying asset amount from user to spool contract.
     * @dev Transfer happens from the vault or controller, defined by the user
     *
     * @param amount deposited amount
     * @param fromVault flag indicating wether the transfer is intiafed from the vault or controller
     */
    function _transferDepositToSpool(uint128 amount, bool fromVault) internal {
        if (fromVault) {
            _underlying().safeTransferFrom(msg.sender, address(spool), amount);
        } else {
            controller.transferToSpool(msg.sender, amount);
        }
    }

    /* ========== WITHDRAW HELPERS ========== */

    /**
     * @notice Calculates proportions of shares relative to the total shares
     * @dev Value has accuracy of `ACCURACY` which is 10^30
     *
     * @param sharesToWithdraw amount of shares
     *
     * @return total vault shares proportion
     */
    function _getVaultShareProportion(uint128 sharesToWithdraw) internal view returns(uint256) {
        return (ACCURACY * sharesToWithdraw) / totalShares;
    }

    // =========== PERFORMANCE FEES ============ //

    /**
     * @notice Pay fees to fee handler contract and transfer fee amount.
     * 
     * @param profit Total profit made by the users
     * @return feeSize Fee amount calculated from profit
     */
    function _payFeesAndTransfer(uint256 profit) internal returns (uint128 feeSize) {
        feeSize = SafeCast.toUint128(_payFees(profit));

        _underlying().safeTransfer(address(feeHandler), feeSize);
    }

    /**
     * @notice  Call fee handler contract to pay fees, without transfering assets
     * @dev Fee handler updates the fee storage slots and returns 
     *
     * @param profit Total profit made by the users
     * @return Fee amount calculated from profit
     */
    function _payFees(uint256 profit) internal returns (uint256) {
        return feeHandler.payFees(
            _underlying(),
            profit,
            _riskProvider(),
            vaultOwner,
            vaultFee
        );
    }

    // =========== STRATEGIIES ============ //

    /**
     * @notice Map vault strategy proportions array in one uint256 word.
     *
     * @dev Proportions sum up to `FULL_PERCENT` (10_000).
     *      There is maximum of 18 elements, and each takes maximum of 14bits.
     *
     * @param _proportions Vault strategy proportions array
     * @return Mapped propportion 256 bit word format
     */
    function _mapProportionsArrayToBits(uint256[] memory _proportions) internal pure returns (uint256) {
        uint256 proportions14bit;
        for (uint256 i = 0; i < _proportions.length; i++) {
            proportions14bit = proportions14bit.set14BitUintByIndex(i, _proportions[i]);
        }

        return proportions14bit;
    }

    /**
     * @dev Store vault strategy addresses array hash in `strategiesHash` storage
     * @param vaultStrategies Array of strategy addresses
     */
    function _updateStrategiesHash(address[] memory vaultStrategies) internal {
        strategiesHash = Hash.hashStrategies(vaultStrategies);
    }

    /**
     * @dev verify vault strategy addresses array against storage `strategiesHash`
     * @param vaultStrategies Array of strategies to verify
     */
    function _verifyStrategies(address[] memory vaultStrategies) internal view {
        require(Hash.sameStrategies(vaultStrategies, strategiesHash), "VSH");
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @notice Verify the caller is The vault owner or Spool DAO
     *
     * @dev
     * Only callable from onlyVaultOwnerOrSpoolOwner modifier.
     *
     * Requirements:
     *
     * - msg.sender is the vault owner or Spool DAO
     */
    function _onlyVaultOwnerOrSpoolOwner() private view {
        require(
            msg.sender == vaultOwner || isSpoolOwner(),
            "OOD"
        );
    }

    /**
     * @notice Verify the caller is the spool contact
     *
     * @dev
     * Only callable from onlySpool modifier.
     *
     * Requirements:
     *
     * - msg.sender is central spool contract
     */
    function _onlySpool() private view {
        require(address(spool) == msg.sender, "OSP");
    }

    /**
     * @notice Verify caller is the spool contact
     *
     * @dev
     * Only callable from onlyFastWithdraw modifier.
     *
     * Requirements:
     *
     * - caller is fast withdraw contract
     */
    function _onlyFastWithdraw() private view {
        require(address(fastWithdraw) == msg.sender, "OFW");
    }

    /**
     * @notice Dissallow action if Spool reallocation already started
     */
    function _noMidReallocation() private view {
        require(!spool.isMidReallocation(), "NMR");
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice Ensures caller is vault owner or spool owner.
     */
    modifier onlyVaultOwnerOrSpoolOwner() {
        _onlyVaultOwnerOrSpoolOwner();
        _;
    }

    /**
     * @notice Ensures caller is central spool contract
     */
    modifier onlySpool() {
        _onlySpool();
        _;
    }

    /**
     * @notice Ensures caller is fast withdraw contract
     */
    modifier onlyFastWithdraw() {
        _onlyFastWithdraw();
        _;
    }

    /**
     * @notice Verifies given array of strategy addresses
     */
    modifier verifyStrategies(address[] memory vaultStrategies) {
        _verifyStrategies(vaultStrategies);
        _;
    }

    /**
     * @notice Ensures the system is not mid reallocation
     */
    modifier noMidReallocation() {
        _noMidReallocation();
        _;
    }

    /**
     * @notice Ensures the vault has not been initialized before
     */
    modifier initializer() {
        require(!_initialized, "AINT");
        _;
        _initialized = true;
    }
}