// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";
import "./utils/RescueTokens.sol";

/// @author MELD team
/// @title BaseToken
/// @notice BaseToken is an ERC20 token with minting, burning and pausing capabilities, as well as meta-transaction support.
contract BaseToken is ERC20, Pausable, AccessControl, ERC2771Recipient, RescueTokens {
    using SafeERC20 for IERC20;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
    bytes32 public constant TRUSTED_FORWARDER_SETTER_ROLE =
        keccak256("TRUSTED_FORWARDER_SETTER_ROLE");

    /// @dev Timestamp of the last minting period for each account
    mapping(address minter => uint256 timestamp) public lastMintingPeriod;
    /// @dev Amount of tokens minted in the current minting period for each account
    mapping(address minter => uint256 mintedAmount) public currentMintingAmount;
    /// @dev Amount of tokens that can be minted in a minting period for each account
    mapping(address minter => uint256 threshold) public mintingAmountThreshold;
    /// @dev Length of a minting period for each account
    mapping(address minter => uint256 periodLength) public mintingPeriodLength;

    /// @dev The number of decimals of the token
    uint8 internal immutable __decimals;

    event TrustedForwarderChanged(address oldForwarder, address newForwarder);
    event MintingPermissionChanged(address account, uint256 amountThreshold, uint256 periodLength);

    /// @dev Modifier that checks that the receiver is not this contract
    /// @param _to The address to transfer to
    modifier notToThisContract(address _to) {
        require(_to != address(this), "BaseToken: Cannot transfer to this contract");
        _;
    }

    /// @dev Modifier that checks that the sender is not the trusted forwarder
    /// @dev This is used to prevent meta-transactions from being sent to the centralized functions (mint, burn, etc.)
    modifier notTrustedForwarder() {
        require(
            !isTrustedForwarder(msg.sender),
            "EIP2771Recipient: meta transaction is not allowed"
        );
        _;
    }

    /// @notice BaseToken constructor
    /// @param _defaultAdmin The address of the default admin, who will be able to grant roles to other accounts
    constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol) {
        require(_defaultAdmin != address(0), "BaseToken: Default admin cannot be the zero address");
        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        __decimals = _decimals;
    }

    /// @dev Grants `_role` to `_account`.
    /// @dev Created to ensure it is not called by the trusted forwarder
    /// @param _role The role to grant
    /// @param _account The account to grant the role to
    function grantRole(
        bytes32 _role,
        address _account
    ) public virtual override notTrustedForwarder {
        super.grantRole(_role, _account);
    }

    /// @dev Revokes `_role` from `_account`.
    /// @dev Created to ensure it is not called by the trusted forwarder
    /// @param _role The role to revoke
    /// @param _account The account to revoke the role from
    function revokeRole(
        bytes32 _role,
        address _account
    ) public virtual override notTrustedForwarder {
        super.revokeRole(_role, _account);
    }

    /// @dev Revokes `_role` from the calling account.
    /// @dev Created to ensure it is not called by the trusted forwarder
    /// @param _role The role to renounce
    /// @param _account The account to renounce the role from. Must be equal to the _msgSender()
    function renounceRole(
        bytes32 _role,
        address _account
    ) public virtual override notTrustedForwarder {
        super.renounceRole(_role, _account);
    }

    /// @notice Sets the minting amount threshold and period length for an account
    /// @notice Also grants MINTER_ROLE to the account if the threshold is greater than 0, or revokes it otherwise
    /// @dev Only callable by an account with DEFAULT_ADMIN_ROLE
    /// @param _account The account to set the minting permission for
    /// @param _amountThreshold The amount of tokens that can be minted in a minting period
    /// @param _periodLength The length of a minting period
    function setMintingAccount(
        address _account,
        uint256 _amountThreshold,
        uint256 _periodLength
    ) public virtual onlyRole(DEFAULT_ADMIN_ROLE) notTrustedForwarder {
        require(_account != address(0), "BaseToken: Account cannot be the zero address");
        if (_amountThreshold == 0) {
            _revokeRole(MINTER_ROLE, _account);
        } else {
            _grantRole(MINTER_ROLE, _account);
        }
        mintingAmountThreshold[_account] = _amountThreshold;
        mintingPeriodLength[_account] = _periodLength;
        emit MintingPermissionChanged(_account, _amountThreshold, _periodLength);
    }

    /// @notice Sets the trusted forwarder address
    /// @dev Only callable by an account with TRUSTED_FORWARDER_SETTER_ROLE
    /// @dev The trusted forwarder is used to support meta-transactions
    /// @param _forwarder The address of the trusted forwarder
    function setTrustedForwarder(
        address _forwarder
    ) public virtual onlyRole(TRUSTED_FORWARDER_SETTER_ROLE) notTrustedForwarder {
        emit TrustedForwarderChanged(getTrustedForwarder(), _forwarder);
        _setTrustedForwarder(_forwarder);
    }

    /// @notice Pauses the token
    /// @dev Only callable by an account with PAUSER_ROLE
    /// @dev Pausing the token prevents mints and burns
    function pause() public virtual onlyRole(PAUSER_ROLE) notTrustedForwarder {
        _pause();
    }

    /// @notice Unpauses the token
    /// @dev Only callable by an account with UNPAUSER_ROLE
    function unpause() public virtual onlyRole(UNPAUSER_ROLE) notTrustedForwarder {
        _unpause();
    }

    /// @notice Mints tokens to an account
    /// @dev Only callable by an account with MINTER_ROLE
    /// @dev The amount of tokens minted in a minting period cannot exceed the minting amount threshold
    /// @param _to The account to mint tokens to
    /// @param _amount The amount of tokens to mint
    function mint(
        address _to,
        uint256 _amount
    ) public virtual whenNotPaused onlyRole(MINTER_ROLE) notTrustedForwarder {
        require(_amount > 0, "BaseToken: Amount must be greater than 0");

        address minter = _msgSender();

        // Minting period has ended
        if (block.timestamp > lastMintingPeriod[minter] + mintingPeriodLength[minter]) {
            currentMintingAmount[minter] = 0;
            lastMintingPeriod[minter] = block.timestamp;
        }
        require(
            currentMintingAmount[minter] + _amount <= mintingAmountThreshold[minter],
            "BaseToken: Minting amount exceeds threshold"
        );

        currentMintingAmount[minter] += _amount;

        _mint(_to, _amount);
    }

    /// @notice Burns tokens from the caller's account
    /// @dev Only callable by an account with BURNER_ROLE
    /// @param _amount The amount of tokens to burn
    function burn(
        uint256 _amount
    ) public virtual whenNotPaused onlyRole(BURNER_ROLE) notTrustedForwarder {
        require(_amount > 0, "BaseToken: Amount must be greater than 0");
        _burn(_msgSender(), _amount);
    }

    /// @notice Overrides transfer to add checks to avoid transfers to this contract
    /// @param _to The account to transfer tokens to
    /// @param _amount The amount of tokens to transfer
    function transfer(
        address _to,
        uint256 _amount
    ) public virtual override notToThisContract(_to) returns (bool) {
        return super.transfer(_to, _amount);
    }

    /// @notice Overrides transferFrom to add checks to avoid transfers to this contract
    /// @param _from The account to transfer tokens from
    /// @param _to The account to transfer tokens to
    /// @param _amount The amount of tokens to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public virtual override notToThisContract(_to) returns (bool) {
        return super.transferFrom(_from, _to, _amount);
    }

    /// @notice Allows the admin to rescue ERC20 tokens sent to this contract
    /// @dev Only callable by an account with DEFAULT_ADMIN_ROLE
    /// @param _token The address of the ERC20 token to rescue
    /// @param _to The account to transfer the ERC20 tokens to
    function rescueERC20(
        address _token,
        address _to
    ) public virtual onlyRole(DEFAULT_ADMIN_ROLE) notTrustedForwarder {
        _rescueERC20(_token, _to);
    }

    /// @notice Allows the admin to rescue ERC721 tokens sent to this contract
    /// @dev Only callable by an account with DEFAULT_ADMIN_ROLE
    /// @param _token The address of the ERC721 token to rescue
    /// @param _to The account to transfer the ERC721 tokens to
    /// @param _tokenId The ID of the ERC721 token to rescue
    function rescueERC721(
        address _token,
        address _to,
        uint256 _tokenId
    ) public virtual onlyRole(DEFAULT_ADMIN_ROLE) notTrustedForwarder {
        _rescueERC721(_token, _to, _tokenId);
    }

    /// @notice Allows the admin to rescue ERC1155 tokens sent to this contract
    /// @dev Only callable by an account with DEFAULT_ADMIN_ROLE
    /// @param _token The address of the ERC1155 token to rescue
    /// @param _to The account to transfer the ERC1155 tokens to
    /// @param _tokenId The ID of the ERC1155 token to rescue
    function rescueERC1155(
        address _token,
        address _to,
        uint256 _tokenId
    ) public virtual onlyRole(DEFAULT_ADMIN_ROLE) notTrustedForwarder {
        _rescueERC1155(_token, _to, _tokenId);
    }

    /// @notice Returns the decimals of the token
    function decimals() public view virtual override returns (uint8) {
        return __decimals;
    }

    /// @notice Overrides _msgSender hook to add support for meta-transactions using the ERC2771 standard
    function _msgSender()
        internal
        view
        override(Context, ERC2771Recipient)
        returns (address sender)
    {
        sender = ERC2771Recipient._msgSender();
    }

    /// @notice Overrides _msgData hook to add support for meta-transactions using the ERC2771 standard
    function _msgData() internal view override(Context, ERC2771Recipient) returns (bytes calldata) {
        return ERC2771Recipient._msgData();
    }
}