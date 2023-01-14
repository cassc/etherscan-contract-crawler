//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract BojiMigration is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    address public token1; // address of version1 token
    address public token2; // address of version2 token
    uint256 public divider; // version1 token amount equivalent to `1` version2
    uint256 public restictionTime; // in second
    mapping(address => uint256) public lastMigrate; // timestamp of last migration

    event Migrate(address indexed account);
    event ChangeDivider(uint256 newDivider);
    event UpdateRestrictionTime(uint256 newRestrictionTime);
    event TransferTokenOwnership(address token, address newOwner);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
        @dev Initializes the contract.
     */
    function initialize(
        address token1_,
        address token2_,
        uint256 divider_
    ) public initializer {
        __Ownable_init_unchained();
        __Pausable_init_unchained();

        token1 = token1_;
        token2 = token2_;
        divider = divider_;
        restictionTime = 0;
    }

    /**
     * @dev For authorizing the uups upgrade
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @dev Updates `divider` with new `divider_`
     *
     * @param divider_ new divider
     *
     * Requirements:
     *
     * - `divider_` should be greater than zero
     *
     * Emits {ChangeDivider} event
     */
    function changeDivider(uint256 divider_) external onlyOwner {
        require(divider_ > 0, "error : divider should be greater than zero");
        divider = divider_;
        emit ChangeDivider(divider_);
    }

    /**
     * @dev Updates `restictionTime` with `_newTimeInSeconds`
     *
     * @param _newTimeInSeconds new restriction time in seconds
     *
     * Emits {UpdateRestrictionTime} event
     */
    function updateRestrictionTime(uint256 _newTimeInSeconds)
        external
        onlyOwner
    {
        restictionTime = _newTimeInSeconds;
        emit UpdateRestrictionTime(_newTimeInSeconds);
    }

    /**
     * @dev Pause the contract (stopped state)
     *
     * Requirements:
     *
     * - caller must be the owner of contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract (normal state)
     *
     * Requirements:
     *
     * - caller must be the owner of contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev MIGRATE version1 to version2
     *
     * @param amount token amount to be migrated
     *
     * Emits {Migrate} event
     */
    function migrate(uint256 amount) external whenNotPaused {
        require(
            block.timestamp - lastMigrate[msg.sender] >= restictionTime,
            "Restriction time is not passed"
        );
        uint256 decimal1 = IERC20MetadataUpgradeable(token1).decimals();
        uint256 decimal2 = IERC20MetadataUpgradeable(token2).decimals();
        uint256 v1TokenAmount = amount / (divider);
        uint256 tokenAmountInWei = _getTokenAmountInWei(
            v1TokenAmount,
            decimal1
        );
        uint256 v2TokenAmount = _getMigrateTokenAmount(
            tokenAmountInWei,
            decimal2
        );

        lastMigrate[msg.sender] = block.timestamp;

        IERC20MetadataUpgradeable(token1).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        IERC20MetadataUpgradeable(token2).safeTransfer(
            msg.sender,
            v2TokenAmount
        );
        emit Migrate(msg.sender);
    }

    /**
    * @dev Transfers the ownership of given `_token` to the 
    * owner of migration contract
    *
    * @param _token address of token
    *
    * Requirements:
    *
    * - token address should not be zero
    * - owner of the given token should be address(this)
    *
    * Emits {TransferTokenOwnership} event
     */
    function transferTokenOwnership(address _token) external whenNotPaused onlyOwner{
        require(_token != address(0), "Token address should not be zero");
        require(address(this) == OwnableUpgradeable(_token).owner(), "Migration contract is not the owner of the provided token.");
        OwnableUpgradeable(_token).transferOwnership(owner());
        emit TransferTokenOwnership(_token,owner());
    }

    /**
     * @dev Internal function converts given `_weiAmount` to 18 decimal
     *
     * @param _weiAmount token amount in wei
     * @param decimal decimal of version1 token
     *
     * @return `_weiAmount` in 18 decimal
     */
    function _getTokenAmountInWei(uint256 _weiAmount, uint256 decimal)
        internal
        pure
        returns (uint256)
    {
        if (decimal <= 18) {
            return _weiAmount * 10**(18 - decimal);
        } else {
            return _weiAmount / 10**(decimal - 18);
        }
    }

    /**
     * @dev Internal function converts given `_weiAmount` to version2 token's decimal
     *
     * @param _weiAmount token amount in wei
     * @param decimal decimal of version2 token
     *
     * @return `_weiAmount` in version2 token's decimal
     */
    function _getMigrateTokenAmount(uint256 _weiAmount, uint256 decimal)
        internal
        pure
        returns (uint256)
    {
        if (decimal <= 18) {
            return _weiAmount / 10**(18 - decimal);
        } else {
            return _weiAmount * 10**(decimal - 18);
        }
    }

    /**
     * @dev Transfers `token_` from contract to owner
     *
     * @param token_ address of token to be transferred
     */
    function withdrawAnonymousToken(address token_) external onlyOwner {
        uint256 amount = IERC20MetadataUpgradeable(token_).balanceOf(
            address(this)
        );
        require(amount > 0, "error : contract token balance is zero");
        IERC20MetadataUpgradeable(token_).safeTransfer(owner(), amount);
    }
}