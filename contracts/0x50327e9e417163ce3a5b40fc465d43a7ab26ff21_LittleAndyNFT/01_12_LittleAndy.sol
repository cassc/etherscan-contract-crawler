pragma solidity ^0.8.0;
/**
* The Little Andy NFT contract was deployed by Ownerfy Inc. of Ownerfy.com
* https://ownerfy.com/littleandy
* Visit Ownerfy.com for exclusive NFT drops or inquiries for your project.
*
* This contract is not a proxy. 
* This contract is not pausable.
* This contract is not lockable.
* This contract cannot be rug pulled.
* The URIs are not changeable after ownership is relinquished. 
* This contract uses IPFS 
* The NFT Owners and only the NFT Owners have complete control over their NFTs 
*/

// SPDX-License-Identifier: UNLICENSED

// From base: 
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract LittleAndyNFT is Context, ERC1155, Ownable {

  using SafeMath for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdTracker;

  uint256 public salePrice = 135 * 10**15;
  uint256 public comicSalePrice = 34 * 10**15;
  uint256 public constant maxAndys = 2222;
  string public constant name = 'Little Andy';

  string public baseTokenURI;
  bool public placeHolder = true;
  bool public saleOn = false;
  bool public comicSaleOn = false;
  bool public listOnly = true;
  uint public totalComics = 0;
  uint256 wlm = 5;
  uint256 sm = 13;
  uint256 wlc = 3333;

  uint256 private _royaltyBps = 500;
  address payable private _royaltyRecipient;

  bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
  bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
  bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

  mapping (address => uint8) public totalBought;
  mapping (address => uint8) public totalComicsBought;

  event Mint(address indexed sender, uint256 count, uint256 paid, uint256 price);
  event UpdateRoyalty(address indexed _address, uint256 _bps);

    /**
     * deploys the contract.
     */
    constructor(string memory _uri) payable ERC1155(_uri) {
      _royaltyRecipient = payable(msg.sender);
      baseTokenURI = _uri;
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }


    modifier saleIsOpen {
        require(_totalSupply() <= maxAndys, "Sale end");
        require(saleOn, "Sale hasnt started");
        
        _;
    }

    modifier comicSaleIsOpen {
        require(comicSaleOn, "Sale hasnt started");
        
        _;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply() + totalComics;
    }

    function totalAndys() public view returns (uint256) {
        return _tokenIdTracker.current();
    }


    function mint(uint8 _count, address _to, uint256 code) public payable saleIsOpen {
        uint256 total = _totalSupply();
        uint256 cost = salePrice.mul(_count);
        require(total + _count <= maxAndys, "Max limit");
        require(msg.value >= cost, "Value below price");
        
        if(listOnly) {

          require(code == wlc, "Sender not on whitelist");
          require(totalBought[_to] + _count < wlm, "MAX WHITELIST AMOUNT PURCHASED");
          
          totalBought[_to] = totalBought[_to] + _count;

          _mintElements(_count, _to);
          Mint(_to, _count, cost, salePrice);

        } else {

          require(totalBought[_to] + _count < sm, "MAX GENERAL SALE AMOUNT PURCHASED");
          totalBought[_to] = totalBought[_to] + _count;
          _mintElements(_count, _to);
          Mint(_to, _count, cost, salePrice);
        }
    }

    function mintComic(uint8 _count, address _to) public payable comicSaleIsOpen {
        uint256 cost = comicSalePrice.mul(_count);
        require(totalComics + _count <= 1111, "Max limit");
        require(msg.value >= cost, "Value below price");
        
        require(totalComicsBought[_to] + _count < sm, "MAX GENERAL SALE AMOUNT PURCHASED");
        totalComicsBought[_to] = totalComicsBought[_to] + _count;
        totalComics = _count + totalComics;

        _mint(_to, 0, _count, '');
        Mint(_to, _count, cost, salePrice);
    }

    function creditCardMint(uint _count, address _to) public onlyOwner {
        uint256 total = _totalSupply();
        uint256 cost = salePrice.mul(_count);
        require(total + _count <= maxAndys, "Max limit");
        Mint(_to, _count, cost, salePrice);
        _mintElements(_count, _to);
    }

    function creditCardComicMint(uint _count, address _to) public onlyOwner {
        uint256 cost = comicSalePrice.mul(_count);
        require(totalComics + _count <= 1111, "Max limit");
        
        totalComics = _count + totalComics;

        _mint(_to, 0, _count, '');
        Mint(_to, _count, cost, salePrice);
    }


    function _mintElements(uint256 _count, address _to) private {
        uint[] memory tokenArr = new uint[](_count);
        uint[] memory tokenQtys = new uint[](_count);

        for (uint256 i = 0; i < _count; i++) {
          _tokenIdTracker.increment();
          tokenArr[i] = _tokenIdTracker.current();
          tokenQtys[i] = 1;
        }

        _mintBatch(_to, tokenArr, tokenQtys, '');
        
    }

    // Set price
    function setPrice(uint256 _price) public onlyOwner{
        salePrice = _price;
    }

    function setComicSalePrice(uint256 _price) public onlyOwner{
        comicSalePrice = _price;
    }

    function setWlc(uint256 _wlc) public onlyOwner{
        wlc = _wlc;
    }

    function setSm(uint256 _sm) public onlyOwner{
        _sm = sm;
    }

    function setWlm(uint256 _wlm) public onlyOwner{
        wlm = _wlm;
    }

    function withdraw() public onlyOwner{
        uint amount = address(this).balance;

        (bool success, ) = owner().call{value: amount}("");
        require(success, "Failed to send Ether");
        
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }


    function setPlaceHolder(bool isOn) public onlyOwner {
        placeHolder = isOn;
    }

    function setSaleOn(bool isOn) public onlyOwner {
        saleOn = isOn;
    }

    function setComicSaleOn(bool isOn) public onlyOwner {
        comicSaleOn = isOn;
    }

    function setListOnly(bool isOn) public onlyOwner {
        listOnly = isOn;
    }


    function uri(uint256 _id) public view virtual override returns (string memory) {
        if(placeHolder) {
          return baseTokenURI;
        } else {
          return string(abi.encodePacked(baseTokenURI, uint2str(_id), ".json"));
        }
    }

    /**
    * @dev Update royalties
    */
    function updateRoyalties(address payable recipient, uint256 bps) external onlyOwner {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
        emit UpdateRoyalty(recipient, bps);
    }

    /**
      * ROYALTY FUNCTIONS
      */
    function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256) external view returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external view returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return ERC1155.supportsInterface(interfaceId) || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE
               || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

     function uint2str(
      uint256 _i
    )
      internal
      pure
      returns (string memory str)
    {
      if (_i == 0)
      {
        return "0";
      }
      uint256 j = _i;
      uint256 length;
      while (j != 0)
      {
        length++;
        j /= 10;
      }
      bytes memory bstr = new bytes(length);
      uint256 k = length;
      j = _i;
      while (j != 0)
      {
        bstr[--k] = bytes1(uint8(48 + j % 10));
        j /= 10;
      }
      str = string(bstr);
    }

}