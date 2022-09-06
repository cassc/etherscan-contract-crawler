//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '../lib/IERC721Royalty.sol';
import './SignatureChecker.sol';

contract Auction is IERC721Receiver, Ownable, SignatureChecker {
  // users who want to buy art work first stake eth before bidding
  string public constant name = 'Deepcity Auction Contract';
  string public constant version = '1.1';
  uint256 private constant BPS = 10000;
  uint256 public Fee;

  struct TokenDetails {
    address nftContract;
    uint256 tokenId;
    address payable seller;
    address payable royaltyPaidTo;
    uint256 royaltyBaseAmount;
    uint128 price;
    bool isActive;
    uint256 duration;
    uint256 date;
  }

  mapping(address => mapping(uint256 => TokenDetails)) public tokenToAuction;
  mapping(address => mapping(uint256 => mapping(address => uint256))) public stakes;
  mapping(address => uint256) public totalStake;
  mapping(address => uint256) public royaltyToCreator;
  mapping(address => uint256) public feeToOwner;

  /// @dev event that emits when item is listed for auction sale
  event AuctionCreated(TokenDetails auction, string message);
  /// @dev event that emits when auction is finished
  event AuctionFinished(TokenDetails indexed auctionId);
  /// @dev event that emits when auction is canceled
  event AuctionCancelled(TokenDetails indexed auctionId);

  /// @dev event that emits when stake withdrawn by bidder.
  event stakeWithdrawn(TokenDetails indexed auctionId, uint256 _amount);
  /// @dev event that emits when service fee is withdrawn by owner.
  event feeWithdrawn(uint256 totalCollection, string message);
  /// @dev event that emits when royalty is withdrawn by creator.
  event royaltyWithdrawn(uint256 totalCollection, string message);

  constructor(uint256 _setServiceFee) {
    setCheckSignatureFlag(true);
    Fee = _setServiceFee;
  }

  receive() external payable {}

  /**
    @dev Owner list the token or nft for auction, the values are set in TokenDetails struct and make isActive equal to true
   @param _nft The ERC721 smart contract address
   @param _tokenId The token id or Erc721 token to list
   @param _duration Time limit for auction, set in seconds
   @notice The _tokenId is transferred to this smart contract address for no disruption by the seller
    */
  function createTokenAuction(
    address _nft,
    uint256 _tokenId,
    uint128 _price,
    uint256 _duration
  ) external {
    address nftOwner = IERC721(_nft).ownerOf(_tokenId);
    require(nftOwner == msg.sender, "You can't sell an NFT you don't own!");
    (address _to, uint256 baseAmount) = IERC721Royalty(_nft).royaltyInfo(_tokenId, 1 * 10**18);

    require(msg.sender != address(0));
    require(_nft != address(0));
    require(_price > 0, 'Price: price must be greater than zero.');
    require(_duration > 0, 'Duration: duration must be greater than zero');
    uint256 listingDate = block.timestamp;
    TokenDetails memory _auction = TokenDetails({
      nftContract: _nft,
      tokenId: _tokenId,
      seller: payable(msg.sender),
      royaltyPaidTo: payable(_to),
      royaltyBaseAmount: baseAmount / 10**14,
      price: _price,
      isActive: true,
      duration: _duration,
      date: listingDate
    });
    ERC721(_nft).safeTransferFrom(msg.sender, address(this), _tokenId);
    tokenToAuction[_nft][_tokenId] = _auction;
    emit AuctionCreated(_auction, 'Item successfull listed for auction sale.');
  }

  /**
  @notice Staker or who wan't to make a bid, Value is store individually for an nft and also track total stake in the smart contract
  @dev  Before making off-chain stakes potential bidders need to stake eth and either they will get it back when the auction ends or they can withdraw it any anytime.
  */
  function stake(address _nft, uint256 _tokenId) external payable {
    require(msg.sender != address(0));
    TokenDetails storage auction = tokenToAuction[_nft][_tokenId];
    require(msg.value >= auction.price);
    require(auction.duration > block.timestamp, 'Auction for this nft has ended');
    stakes[_nft][_tokenId][msg.sender] += msg.value;
    totalStake[msg.sender] += msg.value;
  }

  /**
      @dev Called by the seller when the auction duration, since all stakes are made offchain so the seller needs to pick the highest bid infoirmation and pass it on-chain ito this function
    */
  function executeSale(
    address _nft,
    uint256 _tokenId,
    address bidder,
    uint256 amount,
    bytes memory sig
  ) external {
    require(bidder != address(0), "Bidder can't be a zero address");
    TokenDetails storage auction = tokenToAuction[_nft][_tokenId];
    require(bidder != auction.seller, 'Seller cannot be the bidder :(.');
    require(amount <= stakes[_nft][_tokenId][bidder]);
    require(amount >= auction.price);
    require(auction.duration <= block.timestamp, "Auction hasn't ended yet");
    require(auction.seller == msg.sender);
    require(auction.isActive);
    auction.isActive = false;
    bytes32 messageHash = keccak256(abi.encodePacked(_tokenId, _nft, bidder, amount));
    bool isBidder = checkSignature(messageHash, sig, bidder);
    require(isBidder, 'Invalid Bidder');
    uint256 bidderStake = stakes[_nft][_tokenId][bidder];
    // since this is individualized hence okay to delete
    delete stakes[_nft][_tokenId][bidder];
    totalStake[bidder] -= amount;
    if (bidderStake > amount) {
      (bool transfer, ) = bidder.call{value: bidderStake - amount}('');
      require(transfer);
    }
    uint256 serviceFee = (amount * Fee) / BPS;
    uint256 finalCut = 0;
    if (auction.royaltyBaseAmount != 0) {
      uint256 royalty = (amount * auction.royaltyBaseAmount) / BPS;
      finalCut = amount - royalty - serviceFee;
      (bool success, ) = auction.seller.call{value: finalCut}('');
      require(success, 'Failed to send amount to seller.');
      royaltyToCreator[auction.royaltyPaidTo] += royalty;
      feeToOwner[owner()] += serviceFee;
    } else {
      finalCut = amount - serviceFee;
      (bool success, ) = auction.seller.call{value: finalCut}('');
      require(success, 'Failed to send amount to seller.');
      feeToOwner[owner()] += serviceFee;
    }
    ERC721(_nft).safeTransferFrom(address(this), bidder, _tokenId);
    emit AuctionFinished(auction);
  }

  /**
    @dev Called by the seller if they want to cancel the auction for their nft so the bidders get back the locked eth. The seller get's back the nft and the seller needs to do this tx by passing all bid info received off-chain
   */
  function cancelAuction(
    address _nft,
    uint256 _tokenId,
    address[] memory _bidders
  ) external {
    TokenDetails storage auction = tokenToAuction[_nft][_tokenId];
    require(auction.seller == msg.sender);
    require(auction.isActive);
    auction.isActive = false;
    bool success;
    for (uint256 i = 0; i < _bidders.length; i++) {
      require(stakes[_nft][_tokenId][_bidders[i]] > 0);
      uint256 amount = stakes[_nft][_tokenId][_bidders[i]];
      delete stakes[_nft][_tokenId][_bidders[i]];
      totalStake[_bidders[i]] -= amount;
      (success, ) = _bidders[i].call{value: amount}('');
      require(success);
    }
    ERC721(_nft).safeTransferFrom(address(this), auction.seller, _tokenId);
    emit AuctionCancelled(auction);
  }

  /// @dev Individual bidders or who stake eth can withdraw their stake after the auction ends
  function withdrawStake(address _nft, uint256 _tokenId) external {
    require(msg.sender != address(0));
    TokenDetails storage auction = tokenToAuction[_nft][_tokenId];
    require(stakes[_nft][_tokenId][msg.sender] > 0);
    require(auction.duration <= block.timestamp, "Auction hasn't ended yet");
    uint256 amount = stakes[_nft][_tokenId][msg.sender];
    delete stakes[_nft][_tokenId][msg.sender];
    totalStake[msg.sender] -= amount;
    (bool success, ) = msg.sender.call{value: amount}('');
    require(success);
    emit stakeWithdrawn(auction, amount);
  }

  /// @dev Withdraw service fee collection
  function withdrawServiceFee(string memory _message) external payable onlyOwner {
    require(feeToOwner[msg.sender] > 0, 'Owner: Service fee can only be withdrawn by owner');
    uint256 feeCollection = feeToOwner[msg.sender];
    delete feeToOwner[msg.sender];
    (bool success, ) = msg.sender.call{value: feeCollection}('');
    require(success, 'withdrawServiceFee: Transaction failed');
    emit feeWithdrawn(feeCollection, _message);
  }

  /// @dev Withdraw collected royalty
  function withdrawRoyalty(string memory _message) external payable {
    require(royaltyToCreator[msg.sender] > 0, 'withdrawRoyalty(): Not the royalty collector.');
    uint256 royaltyCollection = royaltyToCreator[msg.sender];
    delete royaltyToCreator[msg.sender];
    (bool success, ) = msg.sender.call{value: royaltyCollection}('');
    require(success, 'withdrawServiceFee: Transaction failed');
    emit royaltyWithdrawn(royaltyCollection, _message);
  }

  /// @dev Setting up the new service fee
  function setServiceFee(uint256 _newFee) external onlyOwner {
    Fee = _newFee;
  }

  /// @notice Returns the total amount of eth bidder stake in all of the listings on smart contract
  function getTotalBidderStake(address _bidder) external view returns (uint256) {
    return totalStake[_bidder];
  }

  /// @inheritdoc IERC721Receiver
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    return bytes4(keccak256('onERC721Received(address,address,uint256,bytes)'));
  }

  /// @notice Returns the bidder stake on a particular nft or token.
  function getStakeInfo(
    address _nft,
    uint256 _tokenId,
    address _staker
  ) public view returns (uint256) {
    return stakes[_nft][_tokenId][_staker];
  }

  /**
  @notice Returns a particular nft listing.
  @return TokenDetails struct details of token or nft listing.
 */
  function getTokenAuctionDetails(address _nft, uint256 _tokenId) public view returns (TokenDetails memory) {
    TokenDetails memory auction = tokenToAuction[_nft][_tokenId];
    return auction;
  }

  // * Get ERC721Royalty compliance from external contract
  // Checks to see if the contract being interacted with supports royaltyInfo function
  function supportERC721Royalty(address _nftContract) public view returns (bool) {
    IERC721(_nftContract).ownerOf(1);
    (address _to, uint256 _amount) = IERC721Royalty(_nftContract).royaltyInfo(1, 1 * 10**18);
    if (_amount > 0 && _to != address(0)) {
      return true;
    } else {
      return false;
    }
  }
}