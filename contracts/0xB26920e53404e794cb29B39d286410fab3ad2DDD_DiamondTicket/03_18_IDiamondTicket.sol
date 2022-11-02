// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDiamondTicket {

    //////////////////////////////
   // User Execution Functions //
  //////////////////////////////

  // Verify whether an address is in the whitelist;
  function verify(uint256 _maxMintableQuantity, bytes calldata _signature) external view returns(bool _whitelisted);
  // Owner can giveaway tickets to designated address.
  function giveawayTicket(address _to, uint256 _quantity) external;
  // User with whitelisted address can mint tickets.
  function mintWhitelistTicket(uint256 _quantity, uint256 _maxMintableQuantity, bytes calldata _signature) external;
  // User can mint tickets with any address.
  function mintPublicTicket() external payable;
  // User can cut their ticket to mint Cozeis.
  function cutTicket(uint256[] calldata _tokenId) external payable;
  // Get the total minted tickets.
  function totalMinted() external view returns (uint256 _minted);

    /////////////////////////
   // Set Phase Functions //
  /////////////////////////

  // Set the variables to enable the whitelist mint phase by owner.
  function setWhitelistMintPhase(uint256 _startTime, uint256 _endTime) external;
  // Set the variables to enable the public mint phase by owner.
  function setPublicMintPhase(uint256 _startTime, uint256 _endTime) external;
  // Set the variables to enable the cut ticket phase by owner.
  function setCutTicketPhase(uint256 _startTime, uint256 _endTime) external;

    //////////////////////////
   // Set Params Functions //
  //////////////////////////

  // Set the price of public mint.
  function setMintPrice(uint256 _price) external;
  // Set the price of cutting the ticket.
  function setCutPrice(uint256 _price) external;
  // Set the maximum mintable amount during each phase.
  function setMaxTicketAmount(uint256 _amount) external;
  // Set collection royalties with platforms that support ERC2981.
  function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external;
  // Set royalties of specific token with platforms that support ERC2981.
  function setTokenRoyalty(uint256 _tokenId, address _receiver, uint96 _feeNumerator) external;
  // Set the URI to return the tokens metadata.
  function setBaseURI(string memory _baseURI) external;
  // Set the URI suffix to return the tokens metadata.
  function setURISuffix(string memory _uriSuffix) external;
  // Set the address to transfer the fund in this contract.
  function setTreasury(address _treasury) external;
  // Set the address to sign for whitelist address.
  function setSigner(address _signer) external;

    /////////////////////
   // Admin Functions //
  /////////////////////

  // Transfer the ownership of the Cozies smart contract
  function transferCoziesOwnership(address _owner) external;
  // Withdraw all the fund inside the contract to the treasury address.
  function withdraw(uint256 _amount) external;

  // This event is triggered whenever a call to #cutTicket succeeds.
  event CutTicket(address _from, uint256 _quantity);
  // This event is triggered whenever a call to #setWhitelistMintPhase, #setPublicMintPhase, and #setCutTicketPhase succeeds.
  event PhaseSet(uint256 _startTime, uint256 _endTime, string _type);
  // This event is triggered whenever a call to #setTreasury and #setSigner succeeds.
  event AddressSet(address _address, string _type);
  // This event is triggered whenever a call to #setCutPrice and #setMaxTicketTierAmount succeeds.
  event NumberSet(uint256 _amount, string _type);
  // This event is triggered whenever a call to #setBaseURI succeeds.
  event URISet(string _context, string _type);
  // This event is triggered whenever a call to #withdraw
  event FundWithdraw(uint256 _amount, address _treasury);
  // This event is triggered whenever a call to #transferCoziesOwnership
  event TransferOwnership(address _owner, address _contract);
}