// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";

contract Seasons is
  ERC1155Upgradeable,
  OwnableUpgradeable,
  ERC1155URIStorageUpgradeable
{
  // -------------------------------------------------------------
  // STORAGE
  // --------------------------------------------------------------

  uint256 private startTokenID;
  uint256 public submissionCount;
  uint public seasonCount;
  address payable protocolWallet;
  address payable treasuryWallet;
  uint treasurySplitPercentage;
  uint artistFeePercentage;
  uint256 public tokenPrice;
  bool private isShutdown;
  uint private latestTokenID;

  uint[] amountsBoughtPerAddress;
  uint[] totalSalesOfTokenIDs;

  struct Submission {
    uint256[] tokenID;
    uint256 season;
    string tokenURI;
    address payable SubmissionOwner;
  }

  struct Season {
    uint[] submissionIDs;
    uint[] tokenIDs;
    uint[] topSubmissions;
    uint startTime;
    uint endTime;
    uint lastTokenIDOfSeason;
    bool isClosed;
  }

  mapping(uint => Season) seasons;
  // submissionID => struct
  mapping(uint256 => Submission) submissions;
  //tokenID => top buyer address
  mapping(uint256 => address) public artifactTopBuyer;

  // tokenID => amount
  mapping(uint256 => uint256) public topAmontOfTokenSold;
  // tokenID => amout
  mapping(uint => uint) public totalAmountOfTokensSold;

  // address => season => amount
  mapping(address => mapping(uint => uint)) totalTokensPurchasedPerAddressPerSeason;
  // tokenID => amount => user
  mapping(address => mapping(uint => uint)) totalAmountPurchasedPerToken;
  // season => amount => tokenIDs
  mapping(uint => mapping(uint => uint[])) amountToTokenIDsOfSeason;

  // seasonID => submissionID => blacklist
  mapping(uint => mapping(uint => bool)) isBlacklistedInSeason;
  // seasonID => submissionID => amount
  mapping(uint => mapping(uint => uint)) amountSoldBeforeBlackList;
  // --------------------------------------------------------------
  // EVENTS
  // --------------------------------------------------------------

  event SubmissionCreated(uint256 submissionID, address SubmissionOwner);
  event SeasonCreated(uint seasonID);
  event ProtocolWalletAddressSet(address protocolWallet);
  event SeasonClosed(uint256 _season);
  event TokenPriceSet(uint price);
  event Shutdown(bool _isShutdown);
  event TreasuryFeeSplitPercentageSet(uint percentage);
  event ArtistFeePercentageSet(uint percentage);
  event ArtifactMinted(address to, uint tokenID, uint amount);
  event FeesWithdrawn(uint balance);
  event RoyaltyTransferred(address to, uint amount);
  event SubmissionBlacklistedFromSeason(uint season, uint submissionID);
  // --------------------------------------------------------------
  // CUSTOM ERRORS
  // --------------------------------------------------------------
  error ZeroAddressNotAllowed(string message);
  error SeasonAlreadyClosed(uint256 season);
  error NoMoreSubmissionsToThisSeason(uint256 season);
  error IncorrectAmount(string message);
  error ContractShutdown(string message);
  error IncorrectTimesGiven(string message);
  error SeasonDoesntExist();
  error SubmissionDoesntExist();
  error SeasonStillRunning(uint season);
  error ProjectBlacklistedInSeason(uint submissionID, uint season);
  error SubmissionIsNotPartOfSeason(uint submissionID);
  error AlreadyBlackListed(uint submissionID, uint season);
  error NotBlacklisted(uint season, uint submissionID);

  // --------------------------------------------------------------
  // CONSTRUCTOR
  // --------------------------------------------------------------

  function initialize() public initializer {
    startTokenID = 123;
    submissionCount = 123;
    seasonCount = 1;
    __ERC1155_init("");
    __Ownable_init();
    __ERC1155URIStorage_init();
  }

  // --------------------------------------------------------------
  // STATE-MODIFYING FUNCTIONS
  // --------------------------------------------------------------

  function setProtocolWalletAddress(
    address payable _protocolWallet
  ) public onlyOwner {
    if (_protocolWallet == address(0))
      revert ZeroAddressNotAllowed("Cannot set zero address");
    assembly {
      sstore(protocolWallet.slot, _protocolWallet)
    }
    emit ProtocolWalletAddressSet(_protocolWallet);
  }

  function setTokenPrice(uint256 price) public onlyOwner returns (uint256) {
    assembly {
      sstore(tokenPrice.slot, price)
    }
    emit TokenPriceSet(price);
  }

  function setArtistFeePercentage(uint percentage) public onlyOwner {
    assembly {
      sstore(artistFeePercentage.slot, percentage)
    }
    emit ArtistFeePercentageSet(percentage);
  }

  function shutdown(bool _isShutdown) external onlyOwner {
    isShutdown = _isShutdown;
    emit Shutdown(_isShutdown);
  }

  /**
        @notice Registers season with given parameters
        @param startTime starting time of season
        @param endTime end time of season
    */
  function createSeason(
    uint startTime,
    uint endTime
  ) public onlyOwner returns (uint) {
    if (isShutdown) revert ContractShutdown("Contract has been shut down");
    if (startTime > endTime)
      revert IncorrectTimesGiven("Incorrect times given");

    unchecked {
      seasonCount++;
    }

    seasons[seasonCount].startTime = startTime;
    seasons[seasonCount].endTime = endTime;

    emit SeasonCreated(seasonCount);

    return seasonCount;
  }

  /**
        @notice Registers a submission with given parameters
        @param _season season the submission is published
        @param _tokenURI tokenURI for NFT
         @param _submissionOwner address related to project
    */
  function createSubmission(
    uint256 _season,
    string memory _tokenURI,
    address payable _submissionOwner
  ) public onlyOwner returns (uint256) {
    if (_season > seasonCount) revert SeasonDoesntExist();
    if (isShutdown) revert ContractShutdown("Contract has been shut down");
    if (_submissionOwner == address(0)) revert ZeroAddressNotAllowed("");
    if (seasons[_season].endTime < block.timestamp)
      revert NoMoreSubmissionsToThisSeason(_season);
    if (seasons[_season].isClosed) revert SeasonAlreadyClosed(_season);

    unchecked {
      submissionCount++;
    }

    uint[] storage submissionIDsOfSeason = seasons[_season].submissionIDs;
    submissionIDsOfSeason.push(submissionCount);

    uint256 latestTokenID = getLatestTokenID(_season);
    uint256 tokenToMint = latestTokenID++;
    submissions[submissionCount].tokenID.push(tokenToMint);
    submissions[submissionCount].season = _season;
    submissions[submissionCount].tokenURI = _tokenURI;
    submissions[submissionCount].SubmissionOwner = _submissionOwner;

    // persist information to season struct

    uint[] storage tokenIDsOfSeason = seasons[_season].tokenIDs;
    tokenIDsOfSeason.push(tokenToMint);

    emit SubmissionCreated(tokenToMint, _submissionOwner);

    return submissionCount;
  }

  /**
        @notice Closes submissions to a season and sends protocol fees to protocol wallet
        @param _season season to be closed
    */

  function closeSeason(uint256 _season) public onlyOwner {
    if (_season > seasonCount) revert SeasonDoesntExist();
    if (seasons[_season].endTime > block.timestamp)
      revert SeasonStillRunning(_season);
    if (seasons[_season].isClosed) revert SeasonAlreadyClosed(_season);

    // return last tokenIDOfSeason

    uint[] memory tokenIDsofSeason = seasons[_season].tokenIDs;
    uint _lastTokenIDofSeason = seasons[_season].tokenIDs[
      tokenIDsofSeason.length - 1
    ];

    seasons[_season].lastTokenIDOfSeason = _lastTokenIDofSeason;
    seasons[_season].isClosed = true;

    withdrawProtocolFees();
    calculateTopSubmissionsOfSeason(_season);
    emit SeasonClosed(_season);
  }

  /**
        @notice Mints artifact to buyer
        @param submissionID id of submission
        @param amount amount of tokens to be minted
    */

  function mintArtifact(
    uint[] memory submissionID,
    uint[] memory amount
  ) public payable {
    uint tokenIDToMint = submissionID[0];
    uint amountSold = amount[0];
    if (isShutdown) revert ContractShutdown("Contract has been shut down");
    if (tokenIDToMint > submissionCount) revert SubmissionDoesntExist();

    if (msg.value != tokenPrice * amountSold) revert IncorrectAmount("");
    uint seasonOfSubmission = submissions[tokenIDToMint].season;
    if (seasons[seasonOfSubmission].isClosed)
      revert SeasonAlreadyClosed(seasonOfSubmission);
    if (seasons[seasonOfSubmission].endTime < block.timestamp)
      revert SeasonAlreadyClosed(seasonOfSubmission);
    if (isBlacklistedInSeason[submissions[tokenIDToMint].season][tokenIDToMint])
      revert ProjectBlacklistedInSeason(
        tokenIDToMint,
        submissions[tokenIDToMint].season
      );

    totalTokensPurchasedPerAddressPerSeason[msg.sender][
      submissions[tokenIDToMint].season
    ] += amountSold;

    totalAmountOfTokensSold[tokenIDToMint] += amountSold;

    totalAmountPurchasedPerToken[msg.sender][tokenIDToMint] += amountSold;

    amountToTokenIDsOfSeason[submissions[tokenIDToMint].season][amountSold]
      .push(tokenIDToMint);

    // register top buyer
    if (
      // amounts purchased per address
      topAmontOfTokenSold[tokenIDToMint] <
      totalAmountPurchasedPerToken[msg.sender][tokenIDToMint]
    ) {
      uint newTopAmount = getTotalAmountPurchasedPerToken(
        msg.sender,
        tokenIDToMint
      );
      artifactTopBuyer[tokenIDToMint] = msg.sender;
      topAmontOfTokenSold[tokenIDToMint] = newTopAmount;
    }

    _setURI(tokenIDToMint, submissions[tokenIDToMint].tokenURI);

    _mintBatch(msg.sender, submissionID, amount, "");
    _mintBatch(protocolWallet, submissionID, amount, "");
    _mintBatch(
      submissions[tokenIDToMint].SubmissionOwner,
      submissionID,
      amount,
      ""
    );

    sendArtistRoyalty(msg.value, submissions[tokenIDToMint].SubmissionOwner);
    emit ArtifactMinted(msg.sender, tokenIDToMint, amountSold);
  }

  /**
        @notice Calculates top submission of a season
        @param _seasonID id of season
    */
  function calculateTopSubmissionsOfSeason(uint _seasonID) public onlyOwner {
    if (_seasonID > seasonCount) revert SeasonDoesntExist();
    setTotalSalesOfTokenIDs(_seasonID);
    setTopSubmissionsOfSeason(_seasonID);
  }

  /**
        @notice Withdraws protocol fees to protocoll wallet */
  function withdrawProtocolFees() public onlyOwner {
    protocolWallet.transfer(address(this).balance);

    emit FeesWithdrawn(address(this).balance);
  }

  function blacklistSubmissionFromSeason(
    uint seasonID,
    uint submissionID
  ) external onlyOwner {
    if (submissions[submissionID].season != seasonID)
      revert SubmissionIsNotPartOfSeason(submissionID);
    if (isBlacklistedInSeason[seasonID][submissionID])
      revert AlreadyBlackListed(submissionID, seasonID);

    isBlacklistedInSeason[seasonID][submissionID] = true;
    amountSoldBeforeBlackList[seasonID][submissionID] = totalAmountOfTokensSold[
      submissionID
    ];
    totalAmountOfTokensSold[submissionID] = 0;

    emit SubmissionBlacklistedFromSeason(seasonID, submissionID);
  }

  // --------------------------------------------------------------
  // INTERNAL FUNCTIONS
  // --------------------------------------------------------------

  function sendArtistRoyalty(
    uint value,
    address payable to
  ) internal returns (bool) {
    uint splitArtist = (value / 100) * artistFeePercentage;
    to.transfer(splitArtist);
    emit RoyaltyTransferred(to, splitArtist);
  }

  function setTopSubmissionsOfSeason(uint _seasonID) internal {
    uint largestAmount = getLargestAmountOfTokensSoldInSeason(_seasonID);

    uint[] memory IDs = getAmountToTokenIDsOfSeason(_seasonID, largestAmount);
    for (uint i = 0; i < IDs.length; i++) {
      seasons[_seasonID].topSubmissions.push(IDs[i]);
    }
  }

  // Step 1 TOP submission - creating array of all number of sales per token per season
  function setTotalSalesOfTokenIDs(uint _season) internal {
    uint[] memory submissionIDs = seasons[_season].submissionIDs;

    for (uint i = 0; i < submissionIDs.length; i++) {
      uint totalTokenSales = getTotalTokenSales(submissionIDs[i]);

      totalSalesOfTokenIDs.push(totalTokenSales);
    }
  }

  // Step 2 - returning largest amount sold in season , make this internal
  function getLargestAmountOfTokensSoldInSeason(
    uint _season
  ) internal view returns (uint) {
    uint256 largest = 0;

    for (uint i = 0; i < totalSalesOfTokenIDs.length; i++) {
      if (totalSalesOfTokenIDs[i] > largest) {
        largest = totalSalesOfTokenIDs[i];
      }
    }
    return largest;
  }

  function getAmountToTokenIDsOfSeason(
    uint seasonID,
    uint amount
  ) internal view returns (uint[] memory) {
    if (seasonID > seasonCount) revert SeasonDoesntExist();
    return amountToTokenIDsOfSeason[seasonID][amount];
  }

  // --------------------------------------------------------------
  // VIEW FUNCTIONS
  // --------------------------------------------------------------

  function getSeason(uint seasonID) public view returns (Season memory) {
    if (seasonID > seasonCount) revert SeasonDoesntExist();
    return seasons[seasonID];
  }

  function getSubmission(
    uint submissionID
  ) public view returns (Submission memory) {
    if (submissionID > submissionCount) revert SubmissionDoesntExist();
    return submissions[submissionID];
  }

  function getprotocolWalletAddress() public view returns (address wallet) {
    assembly {
      wallet := sload(protocolWallet.slot)
    }
  }

  function getLatestTokenID(
    uint seasonID
  ) public view returns (uint256 lastTokenID) {
    if (seasonID > seasonCount) revert SeasonDoesntExist();
    uint[] memory allTokenIDs = seasons[seasonID].submissionIDs;
    lastTokenID = allTokenIDs[allTokenIDs.length - 1];
  }

  function getTotalTokenSales(uint submissionID) public view returns (uint) {
    uint[] memory tokenID = submissions[submissionID].tokenID;
    uint tokenIDToCheck = tokenID[0];

    return totalAmountOfTokensSold[tokenIDToCheck];
  }

  function getTopBuyerPerArtifact(
    uint submissionID
  ) public view returns (address) {
    if (submissionID > submissionCount) revert SubmissionDoesntExist();
    uint[] memory tokenID = submissions[submissionID].tokenID;
    uint tokenIDToCheck = tokenID[0];

    return artifactTopBuyer[tokenIDToCheck];
  }

  function getTotalTokensPurchasedPerAddressInSeason(
    address buyer,
    uint seasonID
  ) public view returns (uint) {
    if (seasonID > seasonCount) revert SeasonDoesntExist();
    return totalTokensPurchasedPerAddressPerSeason[buyer][seasonID];
  }

  function getProtocolWalletAddress() public view returns (address wallet) {
    assembly {
      wallet := sload(protocolWallet.slot)
    }
  }

  function getArtistFeePercentage() public view returns (uint percentage) {
    assembly {
      percentage := sload(artistFeePercentage.slot)
    }
  }

  function getTokenPrice() public view returns (uint price) {
    assembly {
      price := sload(tokenPrice.slot)
    }
  }

  function getTopSubmissionsOfSeason(
    uint seasonID
  ) public view returns (uint[] memory) {
    if (seasonID > seasonCount) revert SeasonDoesntExist();
    return seasons[seasonID].topSubmissions;
  }

  function getTotalAmountPurchasedPerToken(
    address user,
    uint tokenID
  ) public view returns (uint totalAmount) {
    totalAmount = totalAmountPurchasedPerToken[user][tokenID];
  }

  function isBlacklisted(
    uint seasonID,
    uint submissionID
  ) external view returns (bool isBlacklisted) {
    isBlacklisted = isBlacklistedInSeason[seasonID][submissionID];
  }

  function getAmountSoldBeforeBlackList(
    uint seasonID,
    uint submissionID
  ) external view returns (uint) {
    return amountSoldBeforeBlackList[seasonID][submissionID];
  }

  function uri(
    uint256 tokenId
  )
    public
    view
    override(ERC1155Upgradeable, ERC1155URIStorageUpgradeable)
    returns (string memory)
  {
    return super.uri(tokenId);
  }
}