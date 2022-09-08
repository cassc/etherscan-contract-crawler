// SPDX-License-Identifier: ISC

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

contract DropCollection is ERC721Enumerable, ERC721Royalty, Ownable {
  using Strings for uint;

  mapping(uint => string) tokenIdToTokenURI;

  mapping (address => bool) public isAddressWhitelisted;
  string public baseURI;
  string public suffixURI;

  uint public maxSupply; // 0 means no maxSupply
  uint public mintPrice;

  uint public totalValueSold;

  address public collectionVip; // Collection that give a discount
  bool public vipTokenMode;
  uint public discountPercentage; // 50 -> 5%, 25 -> 2.5%
  bool public whitelistedMode;
  address public secondAccountWithdraw;
  uint public splitPercentage;

  /**
   * @notice Constructor
   * @param _name Name of the token
   * @param _symbol Symbol of the token
   * @param _maxSupply Max supply of the collection
   * @param _mintPrice Mint price in BNB
   * @param _vipTokenMode set if this collection have a vip token
   * @param _discountPercentage set discount for vip token
   */
  constructor(string memory _name, string memory _symbol, uint _maxSupply, uint _mintPrice,
    bool _vipTokenMode, uint _discountPercentage, bool _whitelistedMode) ERC721(_name, _symbol) {

    maxSupply = _maxSupply;

    mintPrice = _mintPrice;

    vipTokenMode = _vipTokenMode;
    whitelistedMode= _whitelistedMode;
    discountPercentage = _discountPercentage;
  }

  /**
   * @notice Set prefix of all tokenURI
   * @param _baseURI prefix of all tokenURI
   * @dev only owner can call this function
   */
  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

  /**
   * @notice Mint a new NFT to the specified address
   * @param _to address to mint NFT
   */
  function mint(address _to) public payable {
    require(isAddressWhitelisted[msg.sender] || !whitelistedMode ,"CollectionMinterRoyalty: Address not whitelisted");

    require(totalSupply() < maxSupply || maxSupply == 0, "CollectionMinterRoyalty: max supply reached");
    require(msg.value >= mintPrice, "CollectionMinterRoyalty: not enough ETH");

    uint tokenID = totalSupply();
    _safeMint(_to, tokenID);

    uint amountRefund = processRefund(msg.sender, mintPrice);

    totalValueSold += mintPrice - amountRefund;
  }

  /**
 * @notice Mint batch new NFT to the specified address
 * @param _to address to mint NFT
 * @param _amount value of nft to mint
 */
  function mintBatch(address _to, uint _amount) public payable  {
    require(isAddressWhitelisted[msg.sender] || !whitelistedMode ,"CollectionMinterRoyalty: Address not whitelisted");
    require(msg.value >= mintPrice * _amount, "CollectionMinterRoyalty: not enough ETH");
    require(totalSupply() + _amount <= maxSupply || maxSupply == 0, "CollectionMinterRoyalty: max supply reached");

    for(uint i = 0; i < _amount; i++) {
      uint tokenID = totalSupply()+1;
      _safeMint(_to, tokenID);
    }

    uint amountRefund = processRefund(msg.sender, mintPrice * _amount);

    totalValueSold += mintPrice * _amount - amountRefund;
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   * @param _tokenID id of the token to retrieve
   * This function concatenates the base uri with the token uri set during mint
  */
  function tokenURI(uint _tokenID) public view virtual override returns (string memory) {
    require(_exists(_tokenID), "CollectionMinterRoyalty: tokenID not exist");

    return bytes(suffixURI).length > 0 ? string(abi.encodePacked(baseURI, suffixURI)) : string(abi.encodePacked(baseURI, _tokenID.toString()));
  }

  /**
   * @notice set suffixURI for all token
   * @param _suffixURI suffix uri for tokenURI
  */
  function setSuffixURI(string memory _suffixURI) public onlyOwner {
    suffixURI = _suffixURI;
  }

  /**
   * @notice Returns the royalty denominator
   */
  function royaltyDenominator() external pure returns (uint) {
    return _feeDenominator();
  }

  // PRIVILEGED FUNCTIONS
  function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
    _setDefaultRoyalty(_receiver, _feeNumerator);
  }

  function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }

  // SOLIDITY OVERRIDES
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Enumerable, ERC721) {
    ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
  }

  function _burn(uint tokenId) internal virtual override(ERC721Royalty, ERC721) {
    ERC721._burn(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Royalty, ERC721Enumerable) returns (bool) {
    return ERC721Royalty.supportsInterface(interfaceId);
  }

  /**
   * @notice Change mint price for this collection
   * @param _mintPrice Minting price for this payment token
   */
  function changeMintPrice(uint _mintPrice) public onlyOwner {
    mintPrice = _mintPrice;
  }

  /**
   * @notice Withdraw generated rewards in _token
   * @param _token Payment token to withdraw, address 0 for ETH
   * @dev split balance with secondAccount only for ETH
   */
  function withdraw(address _token) external onlyOwner {
    uint balance;
    if (_token == address(0)) {
      if (secondAccountWithdraw != address(0)) {
        balance = address(this).balance;
        uint amountSplit = ((balance / 100) * splitPercentage ) / 10;

        payable(secondAccountWithdraw).transfer(amountSplit);
      }
      balance = address(this).balance;
      payable(msg.sender).transfer(balance);
    } else {
      if (secondAccountWithdraw != address(0)) {
        IERC20(_token).balanceOf(address(this));
        uint amountSplit = ((balance / 100) * splitPercentage ) / 10;

        IERC20(_token).transfer(secondAccountWithdraw, amountSplit);
      }
      balance = IERC20(_token).balanceOf(address(this));
      IERC20(_token).transfer(msg.sender, balance);
    }
  }

  /**
   * @notice Change vip token mode for this collection
   * @param _vipTokenMode boolean value for vip token mode
   */
  function setVipTokenMode(bool _vipTokenMode) external onlyOwner {
    vipTokenMode = _vipTokenMode;
  }

  /**
   * @notice Change discount percentage for vip token
   * @param _discountPercentage value of discount
   */
  function setDiscountPercentage(uint _discountPercentage) external onlyOwner {
    discountPercentage = _discountPercentage;
  }

  /**
   * @notice Set vip collection for discount
   * @param _collection vip collection
   */
  function setCollectionVip(address _collection) external onlyOwner {
    collectionVip = _collection;
  }
  /**
   * @notice Whitelist new address
   * @param _address address to whitelist
   */
  function addAddressToWhitelist(address _address) external onlyOwner {
    isAddressWhitelisted[_address] = true;
  }
   /**
   * @notice Whitelist remove address
   * @param _address address to remove from whitelist
   */
  function removeAddressFromWhitelist(address _address) external onlyOwner {
    isAddressWhitelisted[_address] = false;
  }
  /**
   * @notice Set second account for split withdraw
   * @param _secondAccountWithdraw second account to split
   */
  function setSecondAccountWithdraw(address _secondAccountWithdraw, uint _splitPercentage) external onlyOwner {
    secondAccountWithdraw = _secondAccountWithdraw;
    splitPercentage = _splitPercentage;
  }
  function setAccountAndPercentage(address _secondAccountWithdraw, uint _splitPercentage) external onlyOwner{
     secondAccountWithdraw = _secondAccountWithdraw;
     splitPercentage = _splitPercentage;
   }
  // Refund a discount if it gets balanceOf > 0 of vipToken
  function processRefund(address _to, uint _amount) internal returns(uint) {
    uint discountAmount = 0;
    require(address(collectionVip) != address(0) || !vipTokenMode, "CollectionMinterRoyalty: collection vip not set");

    if ( vipTokenMode && IERC721(collectionVip).balanceOf(msg.sender) > 0 ) {
      discountAmount = (_amount * discountPercentage / 100) / 10;

      payable(_to).transfer(discountAmount);
    }

    return discountAmount;
  }
}