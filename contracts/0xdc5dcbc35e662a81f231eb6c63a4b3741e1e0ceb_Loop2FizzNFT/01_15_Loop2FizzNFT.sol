// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";

contract Loop2FizzNFT is Ownable, ERC1155URIStorage {
  using Strings for uint256;
  using ECDSA for bytes32;
  using SafeMath for uint256;

  string public name = "Loop2 Fizz Tier NFT";
  string public symbol = "FIZZ";
  uint256 public lastTokenId = 110; // last token id
  uint256 public tokenPrice;

  uint256 public maxPurchasePerId;
  uint256 public maxPurchasePerWallet;

  // @notice company wallet address which accept all payments
  address payable public companyAddress;

  // @notice base token uri for metadata uri
  string public publicBaseURI = "";

  mapping(address => uint256) private purchaseCounterPerWallet;
  mapping(address => uint256) private purchaseCounterPerId;

  bool public isSalePaused;

  event PublicSale(uint256 tokenId, uint256 tokenQuantity, address sender);

  constructor(string memory _publicBaseURI, address _companyAddress, uint256 _tokenPrice)
      ERC1155(_publicBaseURI)
  {

    publicBaseURI = _publicBaseURI;
    lastTokenId = 110;
    maxPurchasePerId = 1;
    maxPurchasePerWallet = 10;
    tokenPrice = _tokenPrice;
    companyAddress = payable(_companyAddress);
  }

  /**
   * @notice buy nfts
   * @param tokenIds token id array to be minted
   * @param tokenQuantities token amount array for each mint id
   */
  function buy(uint256[] memory tokenIds, uint256[] memory tokenQuantities) external payable {
    require(!isSalePaused, "Sale is not active yet");
    require(tokenIds.length == tokenQuantities.length, "token id array and token quantity array should have same length");
    require(tokenPrice * tokenIds.length <= msg.value, "Not Enough payments included" );
    require(purchaseCounterPerWallet[msg.sender] + tokenIds.length < maxPurchasePerWallet, "User max mint limit exceed");
    for (uint32 index = 0; index < tokenIds.length; index++) {
      require(
        lastTokenId >= tokenIds[index],
        "Sorry, there is no such token id at the moment."
      );

      require(purchaseCounterPerId[msg.sender] + tokenQuantities[index] <= maxPurchasePerId, "Sorry, there are not enough token left to be minted on this id.");
    }
    _mintBatch(msg.sender, tokenIds, tokenQuantities, "");
    for (uint32 index = 0; index < tokenIds.length; index++) {
      emit PublicSale(tokenIds[index], tokenQuantities[index], msg.sender);

      purchaseCounterPerWallet[msg.sender] = purchaseCounterPerWallet[msg.sender] + tokenQuantities[index];
      purchaseCounterPerId[msg.sender] = purchaseCounterPerId[msg.sender] + tokenQuantities[index];
    }
    // drain message
    companyAddress.transfer(msg.value);
  }

  /**
   * @notice mint NFT from admin
   * @param tokenId token id to mint
   * @param tokenQuantity total amount of nft to be minted
   * @param to wallet address which nft to be minted
   */
  function adminMint(uint32 tokenId, uint32 tokenQuantity, address to) external onlyOwner {
    require(
      lastTokenId >= tokenId,
      "Sorry, there is no such token id at the moment."
    );

    require(purchaseCounterPerId[to] + tokenQuantity <= maxPurchasePerId, "Sorry, there are not enough token left to be minted on this id.");

    _mint(to, tokenId, tokenQuantity, "");
    emit PublicSale(tokenId, tokenQuantity, to);
  }

  /**
   * @notice Results a metadata URI
   * @param tokenId token URI per token ID
   */
  function uri(uint256 tokenId)
    public
    view
    override(ERC1155URIStorage)
    returns (string memory)
  {
    require(tokenId <= lastTokenId, "Cannot query non-existent token");
    return
      string( abi.encodePacked(
                                publicBaseURI,
                                tokenId.toString(),
                                ".json"
                                ) );
  }

  /**
   * @notice set new token price
   * @param _price new token price
   */
  function setTokenPrice(uint256 _price) public onlyOwner {
    tokenPrice = _price;
  }

  /**
   * @notice Results a metadata uri
   * @param _tokenPublicBaseURI token ID which need to be finished
   */
  function setTokenPublicBaseUri(string memory _tokenPublicBaseURI)
    public
    onlyOwner
  {
    publicBaseURI = _tokenPublicBaseURI;
  }

  /**
   * @notice set max mint limit for each id
   * @param _maxPurchasePerId max mint limit for each token id
   */
  function setMaxPurchasePerId(uint256 _maxPurchasePerId) public onlyOwner {
    maxPurchasePerId = _maxPurchasePerId;
  }
  /**
   * @notice set max mint limit for all id
   * @param _maxPurchasePerWallet max mint limit for all id
   */
  function setMaxPurchasePerWallet(uint256 _maxPurchasePerWallet) public onlyOwner {
    maxPurchasePerId = _maxPurchasePerWallet;
  }
  /**
   * @notice Results a company wallet address
   * @param addr change another wallet address from wallet address
   */
  function setCompanyAddress(address payable addr) public onlyOwner {
    companyAddress = addr;
  }

  /**
   * @notice update sale status
   * @param isPaused pause sale status
   */
  function setIsSalePaused(bool isPaused) public onlyOwner {
    isSalePaused = isPaused;
  }
}