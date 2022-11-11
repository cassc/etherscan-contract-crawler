// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IGalaxyFrens {  
    //////////////////////////////
   // User Execution Functions //
  //////////////////////////////

  // Verify whether an address is in the whitelist;
  function verify(uint256 _maxMintableQuantity, address _signer, bytes calldata _signature) external view returns(bool _whitelisted);
  // Mint giveaway Galaxy Frens to an address by owner.
  function mintGiveawayFrens(address _to, uint256 _quantity) external;
  // RPF holders mint specific amount of the Galaxy Frens with signature & maximum mintable amount to verify.
  function mintRPFHoldersFrens(uint256 _quantity, uint256 _maxQuantity, bytes calldata _signature) external;
  // Whitelisted addresses mint specific amount of the Galaxy Frens with signature & maximum mintable amount to verify.
  function mintWhitelistFrens(uint256 _quantity, uint256 _maxQuantity, bytes calldata _signature) external;
  // Public addresses mint specific amount of tokens in public sale.
  function mintPublicFrens(uint256 _quantity) external;

    ////////////////////////////
   // Info Getters Functions //
  ////////////////////////////

  // Get all the tokenIds of an address.
  function tokensOfOwner(address _owner, uint256 _start, uint256 _end) external view returns(uint256[] memory _tokenIds);
  // Get the status of whether a token is set to invalid.
  function getTokenValidStatus(uint256 _tokenId) external view returns(bool _status);
  // Get the dreaming period (How long owners hold a token) of a token.
  function getDreamingPeriod(uint256 _tokenId) external view returns(uint256 _dreamingTime);
  // Get all the dreaming period (How long owners hold a token) of a token of a owner's address.
  function getDreamingPeriodByOwner(address _owner) external view returns(uint256[] memory _dreamingTimeList);

    /////////////////////////
   // Set Phase Functions //
  /////////////////////////

  // Set the variables to enable the whitelist mint phase by owner.
  function setRPFHoldersMintPhase(uint256 _startTime, uint256 _endTime) external;
  // Set the variables to enable the whitelist mint phase by owner.
  function setWhitelistMintPhase(uint256 _startTime, uint256 _endTime) external;
  // Set the variables to enable the public mint phase by owner.
  function setPublicMintPhase(uint256 _startTime, uint256 _endTime) external;

    ////////////////////////////////////////
   // Set Roles & Token Status Functions //
  ////////////////////////////////////////

  // Set the authorized status of an address, true to have authorized access, false otherwise.
  function setAuthorizer(address _authorizer, bool _status) external;
  // Set the address to generate and validate the signature for RPF holders.
  function setSignerRPF(address _signer) external;
  // Set the address to generate and validate the signature for whitelist address.
  function setSignerGF(address _signer) external;
  // Set token invalid, so that the token cannot be transferred.
  function setTokenInvalid(uint256 _tokenId) external;
  // Set token valid, so that the token can be transferred.
  function setTokenValid(uint256 _tokenId) external;

    //////////////////////////
   // Set Params Functions //
  //////////////////////////

  // Set collection royalties with platforms that support ERC2981.
  function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external;
  // Set royalties of specific token with platforms that support ERC2981.
  function setTokenRoyalty(uint256 _tokenId, address _receiver, uint96 _feeNumerator) external;
  // Set the URI to return the tokens metadata.
  function setBaseURI(string memory _baseURI) external;
  // Set the init time of dreaming.
  function setDreamingInitTime(uint256 _initTime) external;
  // Set the address to transfer the contract fund to.
  function setMission(address _mission) external;

  // This event is triggered whenever a call to #mintGiveawayFrens, #mintRPFHoldersFrens, #mintWhitelistFrens and #mintPublicFrens succeeds.
  event MintGalaxyFrens(address _owner, uint256 _quantity, uint256 _totalSupply);
  // This event is triggered whenever a call to #setRPFHoldersMintPhase, #setWhitelistMintPhase and #setPublicMintPhase succeeds.
  event PhaseSet(uint256 _startTime, uint256 _endTime, string _type);
  // This event is triggered whenever a call to #setAuthorizer.
  event StatusChange(address _change, bool _status);
  // This event is triggered whenever a call to #setTokenInvalid, #setTokenInvalidInBatch, #setTokenValid, and #setTokenValidInBatch succeeds,
  event TokenStatusChange(uint256 _tokenId, bool _status);
  // This event is triggered whenever a call to #setBaseURI succeeds.
  event BaseURISet(string _baseURI);
  // This event is triggered whenever a call to #setDreamingInitTime succeeds.
  event NumberSet(uint256 _amount, string _type);
  // This event is triggered whenever a call to #setSignerRPF, #setSignerGF, and #setMission succeeds.
  event AddressSet(address _address, string _type);
}