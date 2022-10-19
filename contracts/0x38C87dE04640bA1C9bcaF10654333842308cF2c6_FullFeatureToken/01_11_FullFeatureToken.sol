// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Helpers} from "./libraries/Helpers.sol";

contract FullFeatureToken is ERC20, ERC20Burnable, ERC20Pausable, Ownable {
  uint8 public constant VERSION = 5;
  uint8 private immutable _decimals;

  struct ERC20ConfigProps {
    bool _isMintable;
    bool _isBurnable;
    bool _isPausable;
    bool _isBlacklistEnabled;
    bool _isDocumentAllowed;
    bool _isWhitelistEnabled;
    bool _isMaxAmountOfTokensSet;
    bool _isForceTransferAllowed;
  }

  ERC20ConfigProps private configProps; // contract properties describing available features
  mapping(address => bool) private _isBlacklisted; // list of blacklisted addresses
  mapping(address => bool) public whitelist; // whitelisted addresses map
  address[] whitelistedAddresses; // array for keeping track of whitelisted users
  string public initialDocumentUri;
  string public documentUri; // URI of the document that exist off-chain
  uint256 public immutable initialSupply;
  uint256 public immutable initialMaxTokenAmountPerAddress;
  uint256 public maxTokenAmountPerAddress; // max token amount per address
  address public immutable initialFeeReceiver;
  address public immutable initialTokenOwner;

  event UserBlacklisted(address blacklistedAddress);
  event UserUnBlacklisted(address whitelistedAddress);
  event DocumentUriSet(string newDocUri);
  event MaxTokenAmountPerSet(uint256 newMaxTokenAmount);
  event UsersWhitelisted(address[] updatedAddresses);

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 initialSupplyToSet,
    uint8 decimalsToSet,
    address tokenOwner,
    ERC20ConfigProps memory customConfigProps,
    uint256 maxTokenAmount,
    string memory newDocumentUri,
    address payable feeReceiver
  ) payable ERC20(name_, symbol_) {
    require(msg.value > 0, "Deployment fee required");
    require(initialSupplyToSet > 0, "Initial supply must be greater than 0");
    if (customConfigProps._isMaxAmountOfTokensSet) {
      require(
        maxTokenAmount > 0,
        "Max token amount must be greater than 0"
      );
    }
    require(decimalsToSet <= 18, "Decimals are outside of allowed range: 0 - 18");

    Helpers.requireNonZeroAddress(tokenOwner);
    Helpers.requireNonZeroAddress(feeReceiver);

    Address.sendValue(feeReceiver, msg.value);

    initialSupply = initialSupplyToSet;
    initialMaxTokenAmountPerAddress = maxTokenAmount;
    initialDocumentUri = newDocumentUri;
    initialFeeReceiver = feeReceiver;
    initialTokenOwner = tokenOwner;

    _decimals = decimalsToSet;
    configProps = customConfigProps;
    documentUri = newDocumentUri;
    maxTokenAmountPerAddress = maxTokenAmount;

    _mint(tokenOwner, initialSupplyToSet * 10**decimalsToSet);

    if (tokenOwner != msg.sender) {
      transferOwnership(tokenOwner);
    }
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20, ERC20Pausable) {
    super._beforeTokenTransfer(from, to, amount);
  }

  function isPausable() external view returns (bool) {
    return configProps._isPausable;
  }

  function isMintable() external view returns (bool) {
    return configProps._isMintable;
  }

  function isBurnable() external view returns (bool) {
    return configProps._isBurnable;
  }

  function isBlacklistEnabled() external view returns (bool) {
    return configProps._isBlacklistEnabled;
  }

  function isWhitelistEnabled() external view returns (bool) {
    return configProps._isWhitelistEnabled;
  }

  function isMaxAmountOfTokensSet() external view returns (bool) {
    return configProps._isMaxAmountOfTokensSet;
  }

  function isDocumentUriAllowed() external view returns (bool) {
    return configProps._isDocumentAllowed;
  }

  function isForceTransferAllowed() external view returns (bool) {
    return configProps._isForceTransferAllowed;
  }

  function decimals() public view virtual override returns (uint8) {
    return _decimals;
  }

  function setDocumentUri(string memory newDocUri) external onlyOwner {
    documentUri = newDocUri;

    emit DocumentUriSet(newDocUri);
  }

  function setMaxTokenAmountPerAddress(uint256 newMaxTokenAmount)
    external
    onlyOwner
  {
    require(
      newMaxTokenAmount > maxTokenAmountPerAddress,
      "Cannot set less than last value"
    );
    maxTokenAmountPerAddress = newMaxTokenAmount;

    emit MaxTokenAmountPerSet(newMaxTokenAmount);
  }

  function blackList(address user) external onlyOwner whenNotPaused {
    Helpers.requireNonZeroAddress(user);
    require(
      configProps._isBlacklistEnabled,
      "Blacklisting not possible on this contract"
    );
    require(!_isBlacklisted[user], "User already blacklisted!");

    if (configProps._isWhitelistEnabled && whitelist[user]) {
      revert("Cannot blacklist a whitelisted address");
    }

    _isBlacklisted[user] = true;

    emit UserBlacklisted(user);
  }

  function removeFromBlacklist(address user) external onlyOwner whenNotPaused {
    require(
      configProps._isBlacklistEnabled,
      "Blacklisting not possible on this contract"
    );
    require(_isBlacklisted[user], "User already whitelisted");
    _isBlacklisted[user] = false;

    emit UserUnBlacklisted(user);
  }

  function transfer(address to, uint256 value)
    public
    virtual
    override
    whenNotPaused
    returns (bool)
  {
    if (configProps._isBlacklistEnabled) {
      require(!_isBlacklisted[to], "Recipient is blacklisted");
      require(!_isBlacklisted[msg.sender], "Sender is blacklisted");
    }
    if (configProps._isWhitelistEnabled) {
      require(whitelist[to], "Recipient not whitelisted");
      require(whitelist[msg.sender], "Sender not whitelisted");
    }
    if (configProps._isMaxAmountOfTokensSet) {
      require(
        balanceOf(to) + value <= maxTokenAmountPerAddress,
        "This address cannot hold that amount of tokens"
      );
    }
    return super.transfer(to, value);
  }

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) public virtual override whenNotPaused returns (bool) {
    if (configProps._isBlacklistEnabled) {
      require(!_isBlacklisted[to], "Recipient is blacklisted");
      require(!_isBlacklisted[from], "Sender is blacklisted");
    }
    if (configProps._isWhitelistEnabled) {
      require(whitelist[to], "Recipient not whitelisted");
      require(whitelist[from], "Sender not whitelisted");
    }
    if (configProps._isMaxAmountOfTokensSet) {
      require(
        balanceOf(to) + value <= maxTokenAmountPerAddress,
        "This address cannot hold that amount of tokens"
      );
    }

    if (configProps._isForceTransferAllowed && owner() == msg.sender) {
      _transfer(from, to, value);
      return true;
    } else {
      return super.transferFrom(from, to, value);
    }
  }

  function mint(address account, uint256 amount)
    external
    onlyOwner
    whenNotPaused
  {
    require(
      configProps._isMintable,
      "Error: mint is not allowed in this contract"
    );
    if (configProps._isMaxAmountOfTokensSet) {
      require(
        balanceOf(account) + amount <= maxTokenAmountPerAddress,
        "This address cannot hold that amount of tokens"
      );
    }
    if (configProps._isBlacklistEnabled) {
      require(!_isBlacklisted[account], "Recipient is blacklisted");
    }
    if (configProps._isWhitelistEnabled) {
      require(whitelist[account], "Recipient not whitelisted");
    }

    super._mint(account, amount);
  }

  function burn(uint256 amount) public override onlyOwner whenNotPaused {
    require(
      configProps._isBurnable,
      "Error: burn is not allowed in this contract"
    );

    super.burn(amount);
  }

  function burnFrom(address account, uint256 amount)
    public
    override
    onlyOwner
    whenNotPaused
  {
    require(
      configProps._isBurnable,
      "Error: burn is not allowed in this contract"
    );

    super.burnFrom(account, amount);
  }

  function pause() external onlyOwner {
    require(
      configProps._isPausable,
      "Error: pause is not allowed in this contract"
    );

    _pause();
  }

  function unpause() external onlyOwner {
    require(
      configProps._isPausable,
      "Error: unpause is not allowed in this contract"
    );

    _unpause();
  }

  function renounceOwnership() public override onlyOwner whenNotPaused {
    super.renounceOwnership();
  }

  function transferOwnership(address newOwner)
    public
    override
    onlyOwner
    whenNotPaused
  {
    super.transferOwnership(newOwner);
  }

  /**
   * @notice Method for updating whitelist
   * @param updatedAddresses new whitelist addresses
   */
  function updateWhitelist(address[] memory updatedAddresses)
    external
    payable
    onlyOwner
  {
    require(configProps._isWhitelistEnabled, "Whitelist not enabled");

    _removeFromWhitelist(whitelistedAddresses);
    _addManyToWhitelist(updatedAddresses);
    whitelistedAddresses = updatedAddresses;

    emit UsersWhitelisted(updatedAddresses);
  }

  function getWhitelistedAddresses() external view returns (address[] memory) {
    return whitelistedAddresses;
  }

  /**
   * @dev Adds list of addresses to whitelist.
   * @param _beneficiaries Addresses to be added to the whitelist
   */
  function _addManyToWhitelist(address[] memory _beneficiaries) internal {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      Helpers.requireNonZeroAddress(_beneficiaries[i]);
      if (configProps._isBlacklistEnabled && _isBlacklisted[_beneficiaries[i]]) {
        revert("Cannot whitelist a blacklisted address");
      }

      whitelist[_beneficiaries[i]] = true;
    }
  }

  /**
   * @dev Cleans whitelist, removing every user.
   * @param _beneficiaries Addresses to be unlisted
   */
  function _removeFromWhitelist(address[] memory _beneficiaries) internal {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = false;
    }
  }
}