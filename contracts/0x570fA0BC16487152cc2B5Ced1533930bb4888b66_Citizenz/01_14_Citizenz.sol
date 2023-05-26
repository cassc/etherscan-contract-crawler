pragma solidity ^0.8.0;
/**
* The Citizenz NFT contract was deployed by Ownerfy Inc.
*
* This contract is not a proxy. 
* This contract is not pausable.
* This contract is not lockable.
* This contract cannot be rug pulled.
* Ownership will be renounced after full sale. 
* This contract uses IPFS 
*/

// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract Citizenz is Context, ERC721, Ownable {

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public salePrice = 5 * 10**16;
    uint8 public whiteListMax = 4;
    uint256 public constant MAX_ELEMENTS = 5000;
    string public baseTokenURI;
    bool public placeHolder = true;
    bool public saleOn = true;
    bool public listOnly = true;
    uint256 wlc = 4000;
    address payable private gnosisWallet = payable(0xd1D29Ca91e967568b561d9755FF34553f2CCF956);

    uint256 private _royaltyBps = 500;
    address payable private _royaltyRecipient;

    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    mapping (address => uint8) public totalBought;

    event Mint(address indexed sender);
    event UpdateRoyalty(address indexed _address, uint256 _bps);

    /**
     * deploys the contract.
     */
    constructor(string memory _uri) payable ERC721("Citizenz NFT", "CTZN") {
        _royaltyRecipient = gnosisWallet;
        baseTokenURI = _uri;
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }


    modifier saleIsOpen {
        require(_totalSupply() <= MAX_ELEMENTS, "Sale end");
        require(saleOn, "Sale hasnt started");
        
        _;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply();
    }


    function whiteListMint(uint8 _count, address _to, uint256 code) public payable saleIsOpen {
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(listOnly, "Whitelist only method");
        require(msg.value >= price(_count), "Value below price");
        require(code == wlc, "Sender not on whitelist");
        require(totalBought[_to] + _count < whiteListMax, "MAX WHITELIST AMOUNT PURCHASED");
        
        totalBought[_to] = totalBought[_to] + _count;
        _mintElements(_count, _to);
        

    }

    function mint(uint8 _count, address _to) public payable saleIsOpen {
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(msg.value >= price(_count), "Value below price");
        require(totalBought[_to] + _count < 6, "MAX GENERAL SALE AMOUNT PURCHASED");
        totalBought[_to] = totalBought[_to] + _count;
        _mintElements(_count, _to);

    }


    function _mintElements(uint256 _count, address _to) private {
        for (uint256 i = 0; i < _count; i++) {
          _tokenIdTracker.increment(); 
          _safeMint(_to, _tokenIdTracker.current());
          Mint(_to);
        }
    }

    function price(uint256 _count) public view returns (uint256) {
        return salePrice.mul(_count);
    }

    // Set price
    function setPrice(uint256 _price) public onlyOwner{
        salePrice = _price;
    }

    function setWhiteListMax(uint8 _wlm) public onlyOwner{
        whiteListMax = _wlm;
    }

    function setWlc(uint256 _wlc) public onlyOwner{
        wlc = _wlc;
    }

    // Function to withdraw all Ether and tokens from this contract.
    function withdraw() public {
        uint _balance = address(this).balance;

        (bool success1, ) = gnosisWallet.call{value: _balance * 20 / 100}("");
        (bool success2, ) = owner().call{value: _balance * 20 / 100}("");
        (bool success3, ) = payable(0xe7247eb2D815799e7663dC84C59F09FE647400f3).call{value: _balance * 20 / 100}("");
        (bool success4, ) = payable(0xD5AEb2B7b92625bd27c202C45B70F117Cb76b6d6).call{value: _balance * 20 / 100}("");
        (bool success5, ) = payable(0x43aD07dc321d0367D9eC1871cF71C21c7a928490).call{value: _balance * 20 / 100}("");
        require(success1 && success2 && success3 && success4 && success5, "Failed to send all eth");
        
    }

    function withdrawGnosis() public {
        require(msg.sender == gnosisWallet, "Only Gnosis can call");
        uint _balance = address(this).balance;
        (bool success, ) = gnosisWallet.call{value: _balance}("");
        require(success, "Failed to send to Gnosis wallet eth");
        
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

    function setListOnly(bool isOn) public onlyOwner {
        listOnly = isOn;
    }

    
    function tokenURI(uint256 _id) public view virtual override returns (string memory) {
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
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE
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