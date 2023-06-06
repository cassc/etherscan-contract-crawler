//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract Whitelist {
  // The owner of the contract
  address whitelistOwner;

  bool private whiteListEnabled;

  // To store our addresses, we need to create a mapping that will receive the user's address and return if he is whitelisted or not.
  mapping(address => bool) private whitelistedAddresses;

  //Event which gets emitted when user is added to whitelist(status true) & when user is removed from whitelist(status false)
  event Whitelisted(address user, bool status);

  constructor(address _owner) {
    whitelistOwner = _owner;
  }

  // Validate only the owner can call the function
  modifier onlyOwner() {
    require(msg.sender == whitelistOwner, 'Error: Caller is not the owner');
    _;
  }

  function addUserAddressToWhitelist(address _addressToWhitelist)
    external
    onlyOwner
  {
    // Validate the caller is not already part of the whitelist.
    require(
      !whitelistedAddresses[_addressToWhitelist],
      'Error: Sender already been whitelisted'
    );

    // Set whitelist boolean to true.
    whitelistedAddresses[_addressToWhitelist] = true;

    emit Whitelisted(_addressToWhitelist, true);
  }

  function isWhitelisted(address _whitelistedAddress)
    public
    view
    returns (bool)
  {
    // Verifying if the user has been whitelisted
    bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
    return userIsWhitelisted;
  }

  function enableWhitelisting(bool value) internal {
    whiteListEnabled = value;
  }

  function isWhitelistingActive() public view returns (bool) {
    return whiteListEnabled;
  }

  // Remove user from whitelist
  function removeUserAddressFromWhitelist(address _addressToRemove)
    public
    onlyOwner
  {
    // Validate the caller is already part of the whitelist.
    require(
      whitelistedAddresses[_addressToRemove],
      'Error: Sender is not whitelisted'
    );

    // Set whitelist boolean to false.
    whitelistedAddresses[_addressToRemove] = false;
    emit Whitelisted(_addressToRemove, false);
  }

  // Get the owner of the contract
  function getOwner() internal view returns (address) {
    return whitelistOwner;
  }
}