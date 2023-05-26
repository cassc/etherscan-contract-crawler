// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./Token.sol";

/**
  @title A basic smart contract for tracking the ownership of SuperFarm Tokens.
  @author Tim Clancy

  This is the governing registry of all SuperFarm Token assets.
*/
contract FarmTokenRecords is Ownable, ReentrancyGuard {

  /// A version number for this record contract's interface.
  uint256 public version = 1;

  /// A mapping for an array of all Tokens deployed by a particular address.
  mapping (address => address[]) public tokenRecords;

  /// An event for tracking the creation of a new Token.
  event TokenCreated(address indexed tokenAddress, address indexed creator);

  /**
    Create a Token on behalf of the owner calling this function. The Token
    supports immediate minting at the time of creation to particular addresses.

    @param _name The name of the Token to create.
    @param _ticker The ticker symbol of the Token to create.
    @param _cap The supply cap of the Token.
    @param _directMintAddresses An array of addresses to mint directly to.
    @param _directMintAmounts An array of Token amounts to mint to keyed addresses.
  */
  function createToken(string calldata _name, string calldata _ticker, uint256 _cap, address[] calldata _directMintAddresses, uint256[] calldata _directMintAmounts) external nonReentrant returns (Token) {
    require(_directMintAddresses.length == _directMintAmounts.length,
      "Direct mint addresses length cannot be mismatched with mint amounts length.");

    // Create the token and optionally mint any specified addresses.
    Token newToken = new Token(_name, _ticker, _cap);
    for (uint256 i = 0; i < _directMintAddresses.length; i++) {
      address directMintAddress = _directMintAddresses[i];
      uint256 directMintAmount = _directMintAmounts[i];
      newToken.mint(directMintAddress, directMintAmount);
    }

    // Transfer ownership of the new Token to the user then store a reference.
    newToken.transferOwnership(msg.sender);
    address tokenAddress = address(newToken);
    tokenRecords[msg.sender].push(tokenAddress);
    emit TokenCreated(tokenAddress, msg.sender);
    return newToken;
  }

  /**
    Allow a user to add an existing Token contract to the registry.

    @param _tokenAddress The address of the Token contract to add for this user.
  */
  function addToken(address _tokenAddress) external {
    tokenRecords[msg.sender].push(_tokenAddress);
  }

  /**
    Get the number of entries in the Token records mapping for the given user.

    @return The number of Tokens added for a given address.
  */
  function getTokenCount(address _user) external view returns (uint256) {
    return tokenRecords[_user].length;
  }
}