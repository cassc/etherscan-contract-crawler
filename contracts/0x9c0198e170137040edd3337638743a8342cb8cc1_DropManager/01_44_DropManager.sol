// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/*
  _______ .______     .___________.____    __    ____  __  .__   __.  _______     _______.
 /  _____||   _  \    |           |\   \  /  \  /   / |  | |  \ |  | |   ____|   /       |
|  |  __  |  |_)  |   `---|  |----` \   \/    \/   /  |  | |   \|  | |  |__     |   (----`
|  | |_ | |      /        |  |       \            /   |  | |  . `  | |   __|     \   \    
|  |__| | |  |\  \----.   |  |        \    /\    /    |  | |  |\   | |  |____.----)   |   
 \______| | _| `._____|   |__|         \__/  \__/     |__| |__| \__| |_______|_______/    
                                                                                     
*/

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IDropManager.sol";
import "../interfaces/IRedemptionManager.sol";
import "../interfaces/IRoyaltyDistributor.sol";
import "../libraries/GrtLibrary.sol";
import "../vendors/ExtendedBitmap.sol";
import "../interfaces/ISwap.sol";
import "./DropManagerAdmin.sol";

/// @title Drop Manager
/// @author Developed by Labrys on behalf of GRT Wines
/// @custom:contributor Sean L (slongdotexe)
/// @custom:contributor mfbevan (mfbevan.eth)
/// @custom:contributor Seb N
/// @custom:contributor Jo Rocca
/// @notice The nerve centre of the Droping system for GRT. Responsible for routing calls to relevant implementation
///         contracts for purchase and token logic
contract DropManager is IDropManager, DropManagerAdmin, IERC721Receiver {
  using SafeMath for uint256;
  using ExtendedBitmap for ExtendedBitmap.BitMap;
  using BitMaps for BitMaps.BitMap;
  using SafeERC20 for ERC20;

  uint128 public override releaseCounter = 0;
  uint128 public override listingCounter = 0;

  // releaseId => release info
  mapping(uint128 => Release) public override releases;

  // listingId => pending eth for listing
  mapping(uint128 => uint256) public override pendingEth;

  ExtendedBitmap.BitMap internal bidTokens;
  ExtendedBitmap.BitMap internal soldTokens;

  ITokenContract public immutable liquidToken;
  IRoyaltyDistributor public royaltyDistributor;
  IRedemptionManager public redemptionManager;
  ISwap public swapContract;

  uint256 public constant PERCENTAGE_PRECISION = 10 ** 2;
  address public royaltyWallet;

  constructor(
    address _superUser,
    address _liquidToken,
    address _redemptionManager,
    address _royaltyWallet,
    address _royaltyDistributor,
    address _swapContract
  ) DropManagerAdmin(_superUser) {
    GrtLibrary.checkZeroAddress(_superUser, "super user");
    GrtLibrary.checkZeroAddress(_liquidToken, "liquid token");
    GrtLibrary.checkZeroAddress(_redemptionManager, "redemption manager");
    GrtLibrary.checkZeroAddress(_royaltyWallet, "royalty wallet");
    GrtLibrary.checkZeroAddress(_royaltyDistributor, "royalty distributor");
    GrtLibrary.checkZeroAddress(_swapContract, "swap contract");

    liquidToken = ITokenContract(_liquidToken);
    redemptionManager = IRedemptionManager(_redemptionManager);
    royaltyDistributor = IRoyaltyDistributor(_royaltyDistributor);
    swapContract = ISwap(_swapContract);
    royaltyWallet = _royaltyWallet;
  }

  /// @dev Increment the global release counter
  ///      uint128 Represents 3.402824 × 10^38 - several orders of magnitude more releases than we expect to ever create,
  ///      hence this should never reasonably over-flow and can remain unchecked
  function _incrementReleaseCounter()
    internal
    returns (uint128 incrementedCount)
  {
    unchecked {
      incrementedCount = releaseCounter + 1;
      releaseCounter = incrementedCount;
    }
  }

  /// @dev Increment the global listing counter. This counter is shared across all listing contracts so that all listings have a unique index
  function _incrementListingCounter()
    internal
    returns (uint128 incrementedCount)
  {
    unchecked {
      incrementedCount = listingCounter + 1;
      listingCounter = incrementedCount;
    }
  }

  /// @dev Calls the liquid token contract to mint a sequential range of tokens and add tokens URIs to the registry
  /// @param qty The number of tokens to mint for the release
  /// @param liquidUri The liquid token URI to set for the batch
  /// @param redeemedUri The redeemed token URI to set for the batch
  /// @param producer The address of the producer who will receive funds for release sales
  /// @param producerPercentage The percentage of sales to send to producers. The remaining funds will be claimed by GRT
  function _createRelease(
    uint128 qty,
    string memory liquidUri,
    string memory redeemedUri,
    address producer,
    uint16 producerPercentage
  ) internal returns (Release memory release, uint128 releaseId) {
    GrtLibrary.checkZeroAddress(producer, "producer wallet");
    if (producerPercentage > 100 * PERCENTAGE_PRECISION) {
      revert InvalidProducerPercentage(producerPercentage);
    }

    releaseId = _incrementReleaseCounter();
    emit ReleaseCreated(releaseCounter);
    uint128 tokenCount = SafeCast.toUint128(
      liquidToken.mint(address(this), qty, liquidUri, redeemedUri)
    );
    release = Release({
      listingId: 0,
      startTokenId: (tokenCount - qty) + 1,
      endTokenId: tokenCount,
      listingType: 0,
      producerPercentage: producerPercentage,
      producer: producer
    });
  }

  /// @dev Create a new listing on one of the listing contracts based on the listing type
  /// @param release The release to create a listing for
  /// @param listing The listing details
  /// @param listingType The type of listing to be created (e.g English Drop or Buy It Now)
  /// @param releaseDate The date at which the listing is to be unlocked for redemption
  function _createListing(
    Release memory release,
    IListing.Listing memory listing,
    uint8 listingType,
    uint256 releaseDate,
    bytes calldata data
  ) internal returns (Release memory _release) {
    if (release.endTokenId == 0) {
      revert InvalidRelease(msg.sender, listing.releaseId);
    }
    _release = release;
    uint128 currentId = _incrementListingCounter();
    IListing listingContract = listingRegistry[listingType];

    _release.listingId = currentId;
    _release.listingType = listingType;
    listingContract.createListing(currentId, listing, data);
    if (releaseDate != 0) {
      redemptionManager.setTimeLock(listing.releaseId, releaseDate);
      emit TimeLockSet(listing.releaseId, releaseDate);
    }
  }

  /// @dev Wrapper for sending usdc to an address including error handling
  /// @param destination The address to send the amount to
  /// @param amount The amount to send
  function _callSendUsdc(address destination, uint256 amount) internal {
    GrtLibrary.checkZeroAddress(destination, "destination");
    if (amount == 0) {
      revert InvalidTokenAmount();
    }
    ERC20 token = swapContract.baseToken();
    token.safeTransfer(destination, amount);
  }

  function hasBid(uint128 tokenId) public view override returns (bool status) {
    status = bidTokens.get(tokenId);
  }

  function hasSold(uint128 tokenId) public view override returns (bool status) {
    status = soldTokens.get(tokenId);
  }

  function createRelease(
    uint128 qty,
    string memory liquidUri,
    string memory redeemedUri,
    address producer,
    uint16 producerPercentage
  ) external override onlyRole(PLATFORM_ADMIN_ROLE) {
    (Release memory release, uint128 releaseId) = _createRelease(
      qty,
      liquidUri,
      redeemedUri,
      producer,
      producerPercentage
    );
    releases[releaseId] = release;
  }

  function createListing(
    IListing.Listing calldata listing,
    uint8 listingType,
    uint256 releaseDate,
    bytes calldata data
  ) external override onlyRole(PLATFORM_ADMIN_ROLE) {
    Release memory release = releases[listing.releaseId];
    if (release.listingId != 0) {
      revert ReleaseAlreadyListed(msg.sender, listing.releaseId);
    }
    releases[listing.releaseId] = _createListing(
      release,
      listing,
      listingType,
      releaseDate,
      data
    );
  }

  function createReleaseAndList(
    uint8 listingType,
    uint128 qty,
    string memory liquidUri,
    string memory redeemedUri,
    address producer,
    uint16 producerPercentage,
    IListing.Listing memory listing,
    uint256 releaseDate,
    bytes calldata data
  ) external override onlyRole(PLATFORM_ADMIN_ROLE) {
    (Release memory release, uint128 releaseId) = _createRelease(
      qty,
      liquidUri,
      redeemedUri,
      producer,
      producerPercentage
    );
    listing.releaseId = releaseId;
    releases[releaseId] = _createListing(
      release,
      listing,
      listingType,
      releaseDate,
      data
    );
  }

  function updateListing(
    uint8 listingType,
    uint128 listingId,
    IListing.Listing calldata listing,
    bytes calldata data
  ) external override onlyRole(PLATFORM_ADMIN_ROLE) {
    IListing listingContract = listingRegistry[listingType];
    listingContract.updateListing(listingId, listing, data);
  }

  function deleteListing(
    uint8 listingType,
    uint128 listingId
  ) external onlyRole(PLATFORM_ADMIN_ROLE) {
    IListing listingContract = listingRegistry[listingType];
    listingContract.deleteListing(listingId);
  }

  function relistRelease(
    uint128 releaseId,
    uint8 newListingType,
    IListing.Listing calldata listing,
    bytes calldata data
  ) external override onlyRole(PLATFORM_ADMIN_ROLE) {
    Release memory release = releases[releaseId];
    IListing listingContract = listingRegistry[release.listingType];
    if (!(listingContract.listingEnded(release.listingId))) {
      revert ListingActive(release.listingId);
    }

    for (
      uint256 i = release.startTokenId >> 8;
      i <= release.endTokenId >> 8;
      i++
    ) {
      uint256 bid = bidTokens.getMaskedBucket(
        release.startTokenId,
        release.endTokenId,
        i * 256
      );
      uint256 sold = soldTokens.getMaskedBucket(
        release.startTokenId,
        release.endTokenId,
        i * 256
      );
      soldTokens.setBucket(i, bid | sold);
    }
    releases[releaseId] = _createListing(
      release,
      listing,
      newListingType,
      0,
      data
    );
  }

  function placeBidWithUSDC(
    uint128 releaseId,
    uint128 tokenId,
    uint256 amount,
    bytes calldata data
  ) external {
    Release memory release = releases[releaseId];
    if (allListingsPaused || pausedListings.get(release.listingId)) {
      revert ListingPaused();
    }
    _tokenInRelease(release, tokenId);
    if (soldTokens.get(tokenId)) {
      revert TokenAlreadySold();
    }
    IListing listingContract = listingRegistry[release.listingType];
    IListing.Bid memory bid = IListing.Bid({
      bidder: msg.sender,
      amount: amount
    });
    bidTokens.set(tokenId);
    ERC20 token = swapContract.baseToken();
    pendingEth[release.listingId] += amount;
    token.safeTransferFrom(msg.sender, address(this), amount);
    listingContract.registerBid(release.listingId, tokenId, bid, data);
  }

  function placeBidWithETH(
    uint128 releaseId,
    uint128 tokenId,
    uint256 amount,
    address spender,
    address payable swapTarget,
    bytes calldata data
  ) external payable {
    ERC20 token = swapContract.baseToken();
    uint256 initialBalance = token.balanceOf(address(this));
    Release memory release = releases[releaseId];
    if (allListingsPaused || pausedListings.get(release.listingId)) {
      revert ListingPaused();
    }
    _tokenInRelease(release, tokenId);
    if (soldTokens.get(tokenId)) {
      revert TokenAlreadySold();
    }
    IListing listingContract = listingRegistry[release.listingType];
    swapContract.depositETH{value: msg.value}(
      token,
      msg.value,
      address(this),
      spender,
      swapTarget,
      data
    );
    uint256 newBalance = token.balanceOf(address(this));
    if (newBalance < initialBalance.add(amount)) {
      revert IncorrectSwapParams();
    }
    uint256 _amountReceived = newBalance.sub(initialBalance);
    IListing.Bid memory bid = IListing.Bid({
      bidder: msg.sender,
      amount: _amountReceived
    });
    bidTokens.set(tokenId);
    pendingEth[release.listingId] += _amountReceived;
    listingContract.registerBid(release.listingId, tokenId, bid, data);
  }

  function placeETHBidWithReceiver(
    uint128 releaseId,
    uint128 tokenId,
    address receiver,
    uint256 amount,
    address spender,
    address payable swapTarget,
    bytes calldata data
  ) external payable {
    ERC20 token = swapContract.baseToken();
    uint256 initialBalance = token.balanceOf(address(this));
    Release memory release = releases[releaseId];
    if (allListingsPaused || pausedListings.get(release.listingId)) {
      revert ListingPaused();
    }
    _tokenInRelease(release, tokenId);
    if (soldTokens.get(tokenId)) {
      revert TokenAlreadySold();
    }
    IListing listingContract = listingRegistry[release.listingType];
    swapContract.depositETH{value: msg.value}(
      token,
      msg.value,
      address(this),
      spender,
      swapTarget,
      data
    );
    uint256 _amountReceived = token.balanceOf(address(this)).sub(initialBalance);
    if (_amountReceived < amount) {
      revert IncorrectSwapParams();
    }
    IListing.Bid memory bid = IListing.Bid({
      bidder: receiver,
      amount: _amountReceived
    });
    bidTokens.set(tokenId);
    pendingEth[release.listingId] += _amountReceived;
    listingContract.registerBid(release.listingId, tokenId, bid, data);
  }

  function transferBaseToken(
    uint8 listingType,
    uint128 listingId,
    address destination,
    uint256 amount
  ) external override onlyListingOperator(listingType) {
    pendingEth[listingId] -= amount;
    _callSendUsdc(destination, amount);
  }

  function transferToken(
    uint8 listingType,
    uint128 tokenId,
    address destination
  ) external onlyListingOperator(listingType) {
    soldTokens.set(tokenId);
    liquidToken.safeTransferFrom(address(this), destination, tokenId);
  }

  function claimToken(
    uint128 releaseId,
    uint128 tokenId,
    uint128 listingId,
    uint8 listingType
  ) external override {
    Release memory release = releases[releaseId];
    _tokenInRelease(release, tokenId);
    IListing listingInstance = listingRegistry[listingType];
    emit TokenClaimed(msg.sender, tokenId);
    uint256 saleAmount = listingInstance.validateTokenClaim(
      listingId,
      releaseId,
      tokenId,
      msg.sender
    );
    if (saleAmount > 0) {
      _distributeFunds(
        releaseId,
        listingId,
        release.producer,
        release.producerPercentage,
        saleAmount
      );
    }
    liquidToken.safeTransferFrom(address(this), msg.sender, tokenId);
  }

  function withdrawTokens(
    uint128 releaseId,
    uint128[] calldata tokens,
    address destination
  ) external override onlyRole(PLATFORM_ADMIN_ROLE) {
    Release memory release = releases[releaseId];
    IListing listingInstance = listingRegistry[release.listingType];
    if (!(listingInstance.listingEnded(release.listingId))) {
      revert ListingActive(release.listingId);
    }
    for (uint16 i = 0; i < tokens.length; i++) {
      _tokenInRelease(release, tokens[i]);
      if (bidTokens.get(tokens[i]) || soldTokens.get(tokens[i])) {
        revert TokenHasBid(tokens[i]);
      }
      soldTokens.set(tokens[i]);
      liquidToken.safeTransferFrom(address(this), destination, tokens[i]);
    }
    emit TokensWithdrawn(destination, release.listingId, tokens);
  }

  function distributeListingFunds(
    uint8 listingType,
    uint128 listingId,
    uint128 releaseId
  ) external onlyRole(PLATFORM_ADMIN_ROLE) {
    Release memory release = releases[releaseId];
    IListing listingInstance = listingRegistry[listingType];

    if (!listingInstance.validateManualDistribution(listingId)) {
      revert IListing.DistributionNotSupported();
    }

    uint256 totalRemainingSales = pendingEth[listingId];

    if (totalRemainingSales == 0) {
      revert NoFundsRemaining(listingId);
    }

    _distributeFunds(
      releaseId,
      release.listingId,
      release.producer,
      release.producerPercentage,
      totalRemainingSales
    );
  }

  function distributeSaleFunds(
    uint8 listingType,
    uint128 listingId,
    uint128 releaseId,
    uint256 saleAmount
  ) external onlyListingOperator(listingType) {
    Release memory release = releases[releaseId];
    _distributeFunds(
      releaseId,
      listingId,
      release.producer,
      release.producerPercentage,
      saleAmount
    );
  }

  function distributeSecondaryFunds(
    uint128 releaseId,
    uint256 amount
  ) external onlyRole(PLATFORM_ADMIN_ROLE) {
    Release memory release = releases[releaseId];
    royaltyDistributor.distributeFunds(
      amount,
      release.producer,
      release.producerPercentage,
      royaltyWallet,
      releaseId
    );
  }

  /// @dev Distribute funds between a receiver and the GRT royalty wallet. Any remaining funds (100% - receiver percentage) will be sent to the royalty wallet
  /// @param releaseId The id of the release for which the listing was made
  /// @param listingId The id of the listing for the distibution to decrement the pending sale amount
  /// @param receiver The receiver of the percentage royalties (i.e a producer)
  /// @param receiverPercentage The percentage of the sale amount to send to the receiver
  /// @param saleAmount The value of the sale to distribute in wei
  function _distributeFunds(
    uint128 releaseId,
    uint128 listingId,
    address receiver,
    uint256 receiverPercentage,
    uint256 saleAmount
  ) internal {
    GrtLibrary.checkZeroAddress(receiver, "receiver address");
    uint256 receiverAmount = saleAmount.mul(receiverPercentage).div(
      PERCENTAGE_PRECISION * 100
    );
    uint256 royaltyAmount = saleAmount.sub(receiverAmount);
    pendingEth[listingId] -= saleAmount;

    emit FundsDistributed(receiver, receiverAmount, releaseId);
    emit FundsDistributed(royaltyWallet, royaltyAmount, releaseId);

    _callSendUsdc(receiver, receiverAmount);
    _callSendUsdc(royaltyWallet, royaltyAmount);
  }

  /// @dev Check that a token exists within the bounds of a release (between the start and end token id, inclusive)
  /// @param release The release to check
  /// @param tokenId The id of the token to check
  function _tokenInRelease(
    Release memory release,
    uint128 tokenId
  ) internal pure {
    if (release.startTokenId > tokenId || tokenId > release.endTokenId) {
      revert TokenNotInRelease(tokenId);
    }
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }

  //#########################
  //####### SETTERS ########

  function setRedemptionManager(
    address _redemptionManager
  ) external onlyRole(PLATFORM_ADMIN_ROLE) {
    GrtLibrary.checkZeroAddress(_redemptionManager, "redemption manager");
    redemptionManager = IRedemptionManager(_redemptionManager);
  }

  function setRoyaltyDistributor(
    address _royaltyDistributor
  ) external onlyRole(PLATFORM_ADMIN_ROLE) {
    GrtLibrary.checkZeroAddress(_royaltyDistributor, "royalty distributor");
    royaltyDistributor = IRoyaltyDistributor(_royaltyDistributor);
  }

  function setRoyaltyWallet(
    address _royaltyWallet
  ) external onlyRole(PLATFORM_ADMIN_ROLE) {
    GrtLibrary.checkZeroAddress(_royaltyWallet, "royalty wallet");
    royaltyWallet = _royaltyWallet;
  }

  modifier onlyListingOperator(uint8 listingType) {
    if (msg.sender != address(listingRegistry[listingType])) {
      revert InvalidTransferOperator();
    }
    _;
  }
}