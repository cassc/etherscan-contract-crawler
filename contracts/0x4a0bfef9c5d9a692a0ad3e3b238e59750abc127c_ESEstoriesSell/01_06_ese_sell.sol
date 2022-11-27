// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

  error PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
  error ItemNotForSale(address nftAddress, uint256 tokenId);
  error NotListed(address nftAddress, uint256 tokenId);
  error AlreadyListed(address nftAddress, uint256 tokenId);
  error NoProceeds();
  error NotOwner();
  error IsNotOwner();
  error NotApprovedForMarketplace();
  error PriceMustBeAboveZero();

contract ESEstoriesSell is ReentrancyGuard{
     using SafeMath for uint256;
     address thisOwner;
     uint256 nftRoy;

  constructor() { 
     thisOwner = msg.sender;
     nftRoy = 100000000000000;
  }
  struct Listing {
      uint256 price;
      address seller;
  }
   event ItemListed(
       address indexed seller,
       address indexed nftAddress,
       uint256 indexed tokenId,
       uint256 price
   );

    event ItemCanceled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event ItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    mapping(address => mapping(uint256 => Listing)) private s_listings;
    mapping(address => uint256) private s_proceeds;
	
	  // Reduce to small Code Size - modifier notListed
  function _listedNot(address nftAddress, uint256 tokenId) private view {
	         Listing memory listing = s_listings[nftAddress][tokenId];
        
        if (listing.price > 0) {
            revert AlreadyListed(nftAddress, tokenId);
       }
   }		
  modifier notListed( address nftAddress, uint256 tokenId ) {_listedNot(nftAddress, tokenId); _; }

           // Reduce to small Code Size - modifier isListed
  function _listedIs(address nftAddress, uint256 tokenId) private view {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price <= 0) {
            revert NotListed(nftAddress, tokenId);
       }
   }   
  modifier isListed(address nftAddress, uint256 tokenId) {  _listedIs(nftAddress, tokenId);  _; }

           // Reduce to small Code Size - modifier onlyOwner
  function _onlyOwner() private view {
   require(msg.sender == thisOwner, "Not owner");
    }
  modifier onlyOwner() {
       _onlyOwner(); 
        _;
    }
 
           // Reduce to small Code Size - modifier isOwner
  function _isOwner( address nftAddress, uint256 tokenId, address spender ) private view {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (spender != owner) {
            revert NotOwner();
        }
    }
   modifier isOwner( address nftAddress, uint256 tokenId, address spender ) {  _isOwner( nftAddress, tokenId, spender ); _; }
            // Reduce to small Code Size - modifier isNotOwner
   function _isNotOwner( address nftAddress, uint256 tokenId, address spender ) private view {
	          IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (spender == owner) {
            revert IsNotOwner();
        }
     }		
   modifier isNotOwner( address nftAddress, uint256 tokenId, address spender ) { _isNotOwner( nftAddress, tokenId, spender );  _; } 

   function getThisOwner() external view returns (address) { return thisOwner; }

   function getRoy() external view returns (uint256) { return nftRoy; }

   function setRoy(uint256 royEther) onlyOwner external { nftRoy = royEther; }

   function addRoy(uint256 m, uint256 s) private pure returns (uint256){ uint256 ms = m - s; return ms;}

   function isApprovedToSell(address Addr, uint256 tokenId) external view returns (bool){
        IERC721 nft = IERC721(Addr);
        address sender = nft.ownerOf(tokenId);
        return (nft.isApprovedForAll(sender, address(this)));
     }
    function listItem( address nftAddress, uint256 tokenId, uint256 price ) external
        notListed(nftAddress, tokenId)
        isOwner(nftAddress, tokenId, msg.sender)
    {
        IERC721 nft = IERC721(nftAddress);
        if (price <= 0 * 10**18) {
            revert PriceMustBeAboveZero();
        }
        require(nft.isApprovedForAll(msg.sender,  address(this)), "Not Approved For Sell");
        s_listings[nftAddress][tokenId] = Listing(price, msg.sender);
        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }


    function cancelListing(address nftAddress, uint256 tokenId) external
        isOwner(nftAddress, tokenId, msg.sender)
        isListed(nftAddress, tokenId)
    {
        delete (s_listings[nftAddress][tokenId]);
        emit ItemCanceled(msg.sender, nftAddress, tokenId);
    }


    function buyItem(address nftAddress, uint256 tokenId) external payable isListed(nftAddress, tokenId) nonReentrant {
        Listing memory listedItem = s_listings[nftAddress][tokenId];
        if (msg.value < listedItem.price) {
            revert PriceNotMet(nftAddress, tokenId, listedItem.price);
        }       
        s_proceeds[listedItem.seller] += msg.value;
        delete (s_listings[nftAddress][tokenId]);
        IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
        emit ItemBought(msg.sender, nftAddress, tokenId, listedItem.price);       
        payable(listedItem.seller).transfer(addRoy(msg.value, nftRoy));
    }

    function updateListing( address nftAddress, uint256 tokenId, uint256 newPrice ) external
        isListed(nftAddress, tokenId)
        nonReentrant
        isOwner(nftAddress, tokenId, msg.sender)
    {
     if (newPrice <= 0.0000000000000) {
            revert PriceMustBeAboveZero();
        }
        s_listings[nftAddress][tokenId].price = newPrice;
        emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
    }
    function getListing(address nftAddress, uint256 tokenId) external view returns (Listing memory)
    {
        return s_listings[nftAddress][tokenId];
    }

    function getProceeds(address seller) external view returns (uint256) {
        return s_proceeds[seller];
    }
     // Getter smart contract Balance
    function getContractBalance() external view returns(uint) {
        return address(this).balance;
    }

    // Use transfer method to return user an amount  and for updating automatically the balance
    function returnUserAmount(address _to, uint _value) public onlyOwner {
       require(msg.sender == thisOwner, "You have no rights");
        (bool success, ) = payable(_to).call{value: _value}("");
        require(success, "Transfer failed");
    }


}