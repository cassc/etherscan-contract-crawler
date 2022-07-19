//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import '../lib/IERC721Royalty.sol';

contract FixedSale is ReentrancyGuard, IERC721Receiver, Ownable {
  string public constant name = 'Deepcity Fixed Sale Contract';
  string public constant version = '1.1';
  uint256 private constant BPS = 10000;
  uint256 public Fee;

  constructor(uint256 _setServiceFee) {
    Fee = _setServiceFee;
  }

  // * Structs
  // Single NFT listing
  struct TokenDetails {
    address nftContract;
    uint256 nftId;
    address payable seller;
    address payable royaltyPaidTo;
    uint256 royaltyBaseAmount;
    uint128 price;
    bool isActive;
    uint256 date;
  }

  mapping(address => mapping(uint256 => TokenDetails)) public tokenToSale;
  mapping(address => uint256) public royaltyToCreator;
  mapping(address => uint256) public feeToOwner;

  /// @dev event that emits when the item is listed for sale.
  event SaleCreated(TokenDetails details, string message);
  /// @dev event that emits when the item is sold.
  event ItemSold(address buyer, address nftContract, uint256 tokenId);
  /// @dev event that emits when auction is canceled.
  event SaleCanceled(address indexed seller, address nftContract, uint256 tokenId);
  /// @dev event that emits when listing price is reduce.
  event priceUpdated(address nft, uint256 tokenId, uint256 newPrice, string message);
  /// @dev event that emits when service fee is withdrawn by owner.
  event feeWithdrawn(uint256 totalCollection, string message);
  /// @dev event that emits when royalty is withdrawn by creator.
  event royaltyWithdrawn(uint256 totalCollection, string message);

  receive() external payable {}

  /**
    @dev Owner list the token or nft for fixed price sale, the values are set in TokenDetails struct and make isActive equal to true
   @param _nft The ERC721 smart contract address
   @param _tokenId The token id or Erc721 token to list
   @notice The _tokenId is transferred to this smart contract address for no disruption by the seller
    */
  function putItemForSale(
    address _nft,
    uint128 _price,
    uint256 _tokenId
  ) external nonReentrant {
    address nftOwner = IERC721(_nft).ownerOf(_tokenId);
    require(nftOwner == msg.sender, "You can't sell an NFT you don't own!");
    (address _to, uint256 baseAmount) = 
    IERC721Royalty(_nft).royaltyInfo(_tokenId, 1 * 10**18);

    require(msg.sender != address(0), "Zero address: Function cannot be called() by zero address");
    require(_nft != address(0), "Zero address: Nft contract cannot be zero address");
    require(_price > 0 ether, 'Price must be greater than zero.');
    uint256 listingDate = block.timestamp;
    TokenDetails memory itemListing = TokenDetails({
      nftContract: _nft,
      nftId: _tokenId, 
      seller: payable(msg.sender), 
      royaltyPaidTo: payable(_to),
      royaltyBaseAmount: baseAmount / 10**14,
      price: _price, 
      isActive: true, 
      date: listingDate
       });
    ERC721(_nft).safeTransferFrom(msg.sender, address(this), _tokenId);
    tokenToSale[_nft][_tokenId] = itemListing;
    emit SaleCreated(itemListing, 'Item put for fixed price sale.');
  }

  /**
  @notice The _updatePrice should be less than the previous listing price
  @param _updatedPrice require to update the listing price
  @dev update the price of the listed token
   */
  function updateListingPrice(
    address _nft,
    uint256 _tokenId,
    uint128 _updatedPrice
  ) external {
    TokenDetails storage token = tokenToSale[_nft][_tokenId];
    require(token.seller == msg.sender, 'Only the seller allowed to update the listing price.');
    require(_updatedPrice < token.price, 'Update price must be lower than the previous price');
    token.price = _updatedPrice;
    emit priceUpdated(_nft, _tokenId, _updatedPrice, 'Listing price updated successfully.');
  }

  /// @dev delete the tokenToSale of the token or nft only by the seller and the token or nft is transferred back to the seller
  function cancelSale(address _nft, uint256 _tokenId) external {
    TokenDetails storage token = tokenToSale[_nft][_tokenId];
    require(token.seller == msg.sender, 'Only the seller allowed to cancel the sale.');
    require(token.isActive, 'Sale has already ended');
    token.isActive = false;
    ERC721(_nft).transferFrom(address(this), token.seller, _tokenId);
    delete tokenToSale[_nft][_tokenId];
    emit SaleCanceled(token.seller, _nft, _tokenId);
  } 

  /**
    @dev Buy the listed token and transfer the value to the seller and also delete tokenToSale
   */
  function buyItem(address _nft, uint256 _tokenId) external payable nonReentrant {
    TokenDetails storage token = tokenToSale[_nft][_tokenId];
    uint256 price = token.price;
    uint256 baseRoyalty = token.royaltyBaseAmount;
    address royaltyReciever = token.royaltyPaidTo;
    address nftSeller = token.seller;
    require(nftSeller != msg.sender, 'You cannot buy the item your selling');
    require(token.isActive, 'Sale has already ended');
    require(msg.value >= price, 'Amount should be greater than or equal to fixed price');
    token.isActive = false;
    uint256 serviceFee = (price * Fee) / BPS;
    uint256 finalCut = 0;
    if(baseRoyalty != 0){
      uint256 royalty = (price * baseRoyalty) / BPS;
      finalCut = price - royalty - serviceFee;
      payable(nftSeller).transfer(finalCut);
      royaltyToCreator[royaltyReciever] += royalty;
      feeToOwner[owner()] += serviceFee;
    } else {
      finalCut = price - serviceFee;
      payable(nftSeller).transfer(finalCut);
      feeToOwner[owner()] += serviceFee;
    }
    ERC721(_nft).safeTransferFrom(address(this), msg.sender, _tokenId);
    delete tokenToSale[_nft][_tokenId];
    emit ItemSold(msg.sender, _nft, _tokenId);
  }

  //@dev Withdraw service fee collection
  function withdrawServiceFee(string memory _message) external payable onlyOwner {
    require(feeToOwner[msg.sender] > 0, "Owner: Service fee can only be withdrawn by owner");
    uint256 feeCollection = feeToOwner[msg.sender];
    delete feeToOwner[msg.sender];
    (bool success,) = msg.sender.call{value: feeCollection}('');
    require(success, "withdrawServiceFee: Transaction failed");
    emit feeWithdrawn(feeCollection, _message);
  }

  // Withdraw collected royaly
  function withdrawRoyalty(string memory _message) external payable {
    require(royaltyToCreator[msg.sender] > 0, "withdrawRoyalty(): Not the royalty collector.");
    uint256 royaltyCollection = royaltyToCreator[msg.sender];
    delete royaltyToCreator[msg.sender];
    (bool success,) = msg.sender.call{value: royaltyCollection}('');
    require(success, "withdrawServiceFee: Transaction failed");
    emit royaltyWithdrawn(royaltyCollection, _message);
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

  /**
  @notice Returns a particular nft listing.
  @return TokenDetails struct details of token or nft listing.
 */
  function getTokenSaleDetails(address _nft, uint256 _tokenId) public view returns (TokenDetails memory) {
    TokenDetails memory token = tokenToSale[_nft][_tokenId];
    return token;
  }

  /// @dev Setting up the new service fee
  function setServiceFee(uint256 _newFee) public onlyOwner {
    Fee = _newFee;
  }

      // * Get ERC721Royalty compliance from external contract
    // Checks to see if the contract being interacted with supports royaltyInfo function
    function supportERC721Royalty(address _nftContract)
        public
        view
        returns (bool)
    {
        IERC721(_nftContract).ownerOf(1);
        (address _to, uint256 _amount) = IERC721Royalty(_nftContract)
            .royaltyInfo(1, 1 * 10**18);
        if (_amount > 0 && _to != address(0)) {
            return true;
        } else {
            return false;
        }
    }
}