//SPDX-License-Identifier: MIT
/*
 ██████  ██████  ███    ███ ██  ██████ ██████   ██████  ██   ██ ███████ ██      ███████ 
██      ██    ██ ████  ████ ██ ██      ██   ██ ██    ██  ██ ██  ██      ██      ██      
██      ██    ██ ██ ████ ██ ██ ██      ██████  ██    ██   ███   █████   ██      ███████ 
██      ██    ██ ██  ██  ██ ██ ██      ██   ██ ██    ██  ██ ██  ██      ██           ██ 
 ██████  ██████  ██      ██ ██  ██████ ██████   ██████  ██   ██ ███████ ███████ ███████ 
*/                                                                           
pragma solidity ^0.8.15; 
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/interfaces/IERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./NFTCatalog.sol";  //contains Ownable from OZ

contract DegenAfterHours is ERC721A, NFTCatalog, ReentrancyGuard {
  //URIs
  string public baseURI = "";
  string public contractURI = "";
  
  //token limits
  uint8 constant public maxBatchSize = 30;
  
  //token state - start in paused mode
  bool public paused = true;

  //redemption/free mint support 
  IERC721A private immutable boxelContract;
  bytes32 public rootRedeemableTokens;

  mapping(uint256 => uint8) private redeemedBoxels;  //boxel ids that have been redeemed already

  ///@dev prevent calling a function from another contract
  modifier onlyUser() {
    require(tx.origin == msg.sender, "Only a wallet address can mint");
    _;
  }

  error MaxBatchSizeExceeded(uint16 maxBatchSize);
  error InsufficientPayment(uint256 expected);
  error NonRedeemableToken();
  error NotOwnerOfToken();
  error AddressNotApprovedForFreeMint();
  error TokenHasBeenRedeemed();
  error TokenPaused();

  event TokenMintingPaused();
  event TokenMintingResumed();
  event BoxelRedeemed(uint256 tokenId);

  constructor(
    string memory name_,
    string memory symbol_,
    string memory baseURI_,
    string memory contractURI_,
    address boxelContract_,
    bytes32 rootRedeemableTokens_
  ) ERC721A(name_, symbol_) {
    baseURI = baseURI_;
    contractURI = contractURI_;
    //ComicBoxels Genesis is at 0xfF58403B9b011659f45d12744a0bE5F01c9FB607
    boxelContract = IERC721A(boxelContract_);
    rootRedeemableTokens = rootRedeemableTokens_;
  }

  ///@dev first token index starts at 1
  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  /** Mint functions */
  ///@dev mint a quantity of frames by sku
  function mint(string memory sku, uint16 quantity) public payable nonReentrant onlyUser {
    if(paused && msg.sender != owner()) revert TokenPaused();
    if(quantity > maxBatchSize && msg.sender != owner()) revert MaxBatchSizeExceeded({maxBatchSize: maxBatchSize});
    ITEM memory item = getItemBySku(sku);  //check SKU exists, reverts otherwise
    if(item.quantity < quantity) revert InsufficientQuantity({quantity: catalog[sku].quantity});
    uint256 totalPrice = calculatePrice(sku, quantity);
    if(msg.value < totalPrice) revert InsufficientPayment({expected: totalPrice});
    mintAndDeduct(msg.sender, sku, quantity);
  }

  ///@dev redeem a Boxel token, providing Merkle Proof to the token number
  function redeem(string memory sku, uint256 boxelId, bytes32[] memory proof) external onlyUser {
    if(paused && msg.sender != owner()) revert TokenPaused();
    if(boxelContract.ownerOf(boxelId) != msg.sender) revert NotOwnerOfToken();
    if(isBoxelRedeemed(boxelId)) revert TokenHasBeenRedeemed();
    ITEM memory item = getItemBySku(sku);  //check SKU exists, reverts otherwise
    if(item.quantity == 0) revert InsufficientQuantity({quantity: 0});
    bytes32 token = keccak256(abi.encodePacked(_toString(boxelId)));
    if(!MerkleProof.verify(proof, rootRedeemableTokens, token)) revert NonRedeemableToken();
    //you can redeem your boxel twice! Yay!
    mintAndDeduct(msg.sender, sku, 1);
    redeemedBoxels[boxelId] = redeemedBoxels[boxelId] == 0 ? 1 : 2;
    emit BoxelRedeemed(boxelId);
  }

  ///@dev mint a quantity of frames by sku
  ///@dev updates the catalog's availability
  ///@dev updates the minted tokens mapping
  function mintAndDeduct(address minter, string memory sku, uint16 quantity) internal {
    uint256 startTokenId = _nextTokenId();
    _safeMint(minter, quantity);                      //emits a Transfer event for every token minted
    recordMintedTokens(sku, startTokenId, quantity);  //record token type and decrease tokens quantity
  }

  ///@dev checks if a Genesis boxel has been redeemed already
  function isBoxelRedeemed(uint256 tokenId) public view returns(bool) {
    return (redeemedBoxels[tokenId] == 2);
  }

  ///@dev this function calculates the price for a SKU and quantity,
  ///@dev taking into account Genesis Boxel ownership 
  function calculatePrice(string memory sku, uint16 quantity) public view returns (uint256) {
    ITEM memory item = getItemBySku(sku);  //check SKU exists, reverts otherwise
    if(msg.sender == owner()) {
      return 0 ether;
    }
    bool discount = (address(0) != msg.sender) && (boxelContract.balanceOf(msg.sender) > 0);
    return (discount ? (item.price - 0.01 ether) : item.price) * quantity;
  }

  /// @dev Returns the tokenIds of the address. O(totalSupply) in complexity.
  /// @dev avoid implementing if totalSupply >= 10,000
  function tokensOfOwner(address owner) external view returns (uint256[] memory) {
    unchecked {
      uint256[] memory a = new uint256[](balanceOf(owner)); 
      uint256 end = _nextTokenId();
      uint256 tokenIdsIdx;
      address currOwnershipAddr;
      for (uint256 i; i < end; i++) {
        TokenOwnership memory ownership = _ownershipAt(i);
        if (ownership.burned) {
          continue;
        }
        if (ownership.addr != address(0)) {
          currOwnershipAddr = ownership.addr;
        }
        if (currOwnershipAddr == owner) {
          a[tokenIdsIdx++] = i;
        }
      }
      return a;    
    }
  }

  /** URI functions */

  ///@dev token URI is baseURI + token type ID
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
    return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenIdToSKU[tokenId], '.json')) : '';
  }

  /** Owner only functions */

  function setBaseURI(string memory baseURI_) public onlyOwner {
    baseURI = baseURI_;
  }

  function setContractURI(string memory contractURI_) public onlyOwner {
    contractURI = contractURI_;
  }

  ///@dev Pause/resume token minting
  function pause(bool paused_) external onlyOwner {
    paused = paused_;
    if(paused)
      emit TokenMintingPaused();
    else
      emit TokenMintingResumed(); 
  }

  function setMerkleRoot(bytes32 rootRedeemableTokens_) external onlyOwner {
    rootRedeemableTokens = rootRedeemableTokens_;
  }

  function withdraw() external nonReentrant onlyOwner {
    uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
  }
}