// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Helpers} from "./libraries/Helpers.sol";

contract FullFeatureToken is ERC20, ERC20Burnable, ERC20Pausable, Ownable {
  uint8 public version = 5;

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

  uint256 public initialSupply;
  uint256 public initialMaxTokenAmountPerAddress;
  string public initialDocumentUri;
  address public initialFeeReceiver;
  address public initialTokenOwner;

  uint8 private immutable _decimals;
  ERC20ConfigProps private configProps; // contract properties describing available features
  mapping(address => bool) private _isBlacklisted; // list of blacklisted addresses
  string public documentUri; // URI of the document that exist off-chain
  mapping(address => bool) public whitelist; // whitelisted addresses map
  address[] whitelistedAddresses; // array for keeping track of whitelisted users
  uint256 public maxTokenAmountPerAddress; // max token amount per address

  event UserBlacklistedEvent(address _blacklistedAddress);
  event UserUnBlacklistedEvent(address _whitelistedAddress);

  constructor(
    string memory name,
    string memory symbol,
    uint256 initialSupplyToSet,
    uint8 decimalsToSet,
    address tokenOwner,
    ERC20ConfigProps memory customConfigProps,
    uint256 maxTokenAmount,
    string memory newDocumentUri,
    address payable feeReceiver
  ) payable ERC20(name, symbol) {
    require(msg.value > 0, "Deployment fee required");
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

  function isPausable() public view returns (bool) {
    return configProps._isPausable;
  }

  function isMintable() public view returns (bool) {
    return configProps._isMintable;
  }

  function isBurnable() public view returns (bool) {
    return configProps._isBurnable;
  }

  function isBlacklistEnabled() public view returns (bool) {
    return configProps._isBlacklistEnabled;
  }

  function isWhitelistEnabled() public view returns (bool) {
    return configProps._isWhitelistEnabled;
  }

  function isMaxAmountOfTokensSet() public view returns (bool) {
    return configProps._isMaxAmountOfTokensSet;
  }

  function isDocumentUriAllowed() public view returns (bool) {
    return configProps._isDocumentAllowed;
  }

  function isForceTransferAllowed() public view returns (bool) {
    return configProps._isForceTransferAllowed;
  }

  function decimals() public view virtual override returns (uint8) {
    return _decimals;
  }

  function setDocumentUri(string memory newDocUri) public onlyOwner {
    documentUri = newDocUri;
  }

  function setMaxTokenAmountPerAddress(uint256 newMaxTokenAmount)
    public
    onlyOwner
  {
    require(
      newMaxTokenAmount > maxTokenAmountPerAddress,
      "Cannot set less than last value"
    );
    maxTokenAmountPerAddress = newMaxTokenAmount;
  }

  function blackList(address _user) public onlyOwner whenNotPaused {
    Helpers.requireNonZeroAddress(_user);
    require(
      configProps._isBlacklistEnabled,
      "Blacklisting not possible on this contract"
    );
    require(!_isBlacklisted[_user], "User already blacklisted!");
    _isBlacklisted[_user] = true;

    emit UserBlacklistedEvent(_user);
  }

  function removeFromBlacklist(address _user) public onlyOwner whenNotPaused {
    require(
      configProps._isBlacklistEnabled,
      "Blacklisting not possible on this contract"
    );
    require(_isBlacklisted[_user], "User already whitelisted");
    _isBlacklisted[_user] = false;

    emit UserUnBlacklistedEvent(_user);
  }

  function transfer(address _to, uint256 _value)
    public
    virtual
    override
    whenNotPaused
    returns (bool)
  {
    if (configProps._isBlacklistEnabled) {
      require(!_isBlacklisted[_to], "Recipient is blacklisted");
      require(!_isBlacklisted[msg.sender], "Sender is blacklisted");
    }
    if (configProps._isWhitelistEnabled) {
      require(whitelist[_to], "Recipient not whitelisted");
      require(whitelist[msg.sender], "Sender not whitelisted");
    }
    if (configProps._isMaxAmountOfTokensSet) {
      require(
        balanceOf(_to) + _value <= maxTokenAmountPerAddress,
        "This address cannot hold that amount of tokens"
      );
    }
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public virtual override whenNotPaused returns (bool) {
    if (configProps._isBlacklistEnabled) {
      require(!_isBlacklisted[_to], "Recipient is blacklisted");
      require(!_isBlacklisted[_from], "Sender is blacklisted");
    }
    if (configProps._isWhitelistEnabled) {
      require(whitelist[_to], "Recipient not whitelisted");
      require(whitelist[_from], "Sender not whitelisted");
    }
    if (configProps._isMaxAmountOfTokensSet) {
      require(
        balanceOf(_to) + _value <= maxTokenAmountPerAddress,
        "This address cannot hold that amount of tokens"
      );
    }

    if (configProps._isForceTransferAllowed && owner() == msg.sender) {
      _transfer(_from, _to, _value);
      return true;
    } else {
      return super.transferFrom(_from, _to, _value);
    }
  }

  function mint(address account, uint256 amount)
    public
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

  function pause() public onlyOwner {
    require(
      configProps._isPausable,
      "Error: pause is not allowed in this contract"
    );

    super._pause();
  }

  function unpause() public onlyOwner {
    require(
      configProps._isPausable,
      "Error: unpause is not allowed in this contract"
    );

    super._unpause();
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
    public
    payable
    onlyOwner
  {
    require(configProps._isWhitelistEnabled, "Whitelist not enabled");

    _removeFromWhitelist(whitelistedAddresses);
    _addManyToWhitelist(updatedAddresses);
    whitelistedAddresses = updatedAddresses;
  }

  function getWhitelistedAddresses() public view returns (address[] memory) {
    return whitelistedAddresses;
  }

  /**
   * @dev Adds list of addresses to whitelist.
   * @param _beneficiaries Addresses to be added to the whitelist
   */
  function _addManyToWhitelist(address[] memory _beneficiaries) internal {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      Helpers.requireNonZeroAddress(_beneficiaries[i]);

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