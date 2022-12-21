// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./erc721/ERC721URIStorage.sol";
import "./utils/Counters.sol";
import "./access/Ownable.sol";
import "./utils/Base64.sol";
import "./utils/Strings.sol";
import "./utils/MerkleProof.sol";
import "./security/ReentrancyGuard.sol"; 
import "./erc20/IERC20.sol";


contract Erc721WhiteList is ERC721URIStorage, ReentrancyGuard,Ownable{

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
 
  string baseTokenURI;
  uint256 public price ;
  uint256 public whitePrice ;
  uint256 public maxIds;

  IERC20 usdt;

  bytes32 public merkleRoot;
  
  //whiteliste config
  uint max;
  uint whitelistedNumber;

  bool public whiteMinted;
  bool public minted;


  //address list
  mapping (address => bool) whiteMints;
  mapping (address => bool) public whiteMap;


  modifier onlyWhiteMinted {
    require(whiteMinted, "Contract currently paused");
    _;
  }

  modifier onlyBuyMinted {
    require(minted, "mint currently paused");
    _;
  }

  event DebugMsg(string  func,address AddressMsg,string exec,uint256 number);
  event MerkleMsg(string  func,address AddressMsg,bytes32 exec);

  constructor(
        string memory name,
        string memory symbol,
        string memory _baseTokenURI) ERC721(name, symbol){
    

    maxIds=5000;
    whitelistedNumber = 0;
    baseTokenURI =_baseTokenURI;
    price=285000000;
    whitePrice=143000000;

    whiteMinted = true;
    minted = true;

    usdt =IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  }

  //status control
  function buyOpened() public onlyOwner{
    minted = true;
  }

  function buyClosed()  public onlyOwner{
    minted = false;
  }

  function whiteOpened() public onlyOwner{
    whiteMinted = true;
  }

  function whiteClosed()  public onlyOwner{
    whiteMinted = false;
  }


  function whiteMint(bytes32[] calldata proof) public  onlyWhiteMinted {

    uint256 _usdtAmount=whitePrice;
    uint256 currentTokenIds = _tokenIds.current();
    uint256 amount=usdt.balanceOf(address(msg.sender));

    // check whitelist
    //require(verifyWhite(msg.sender), "You are not whitelisted");
    require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(address(msg.sender)))), 'You are not whitelisted');

    // check mint
    require(!whiteMints[msg.sender], "you are minted");

    // check mint number
    require(currentTokenIds < maxIds, "Exceeded maximum");

    //whitelist price
    //require(msg.value >= whitePrice, "eth sent is not correct");

    //check usdt Amount
    require(amount >= whitePrice, "usdt sent is not correct");

    usdt.transferFrom(address(msg.sender),address(this), _usdtAmount);
    
    string memory TokenUri =concat(toSlice(baseTokenURI),toSlice(Strings.toString(currentTokenIds)));

    emit DebugMsg("whiteMint",address(msg.sender),TokenUri,currentTokenIds);

    _safeMint(msg.sender, currentTokenIds);
    _setTokenURI(currentTokenIds,TokenUri);
    _tokenIds.increment();
    whiteMints[msg.sender] = true;
  }

  function buyMint() public onlyBuyMinted {

    uint256 _usdtAmount=price;
    uint256 currentTokenIds = _tokenIds.current();
    uint256 amount=usdt.balanceOf(address(msg.sender));

    // check mint number
    require(currentTokenIds < maxIds, "Exceeded maximum");

    //check usdt Amount
    require(amount >= price, "usdt sent is not correct");

    usdt.transferFrom(address(msg.sender),address(this), _usdtAmount);

    string memory TokenUri =concat(toSlice(baseTokenURI),toSlice(Strings.toString(currentTokenIds)));

   emit DebugMsg("mint",address(msg.sender),TokenUri,currentTokenIds);

    _safeMint(msg.sender, currentTokenIds);
    _setTokenURI(currentTokenIds, TokenUri);
    _tokenIds.increment();
  }

  //query token url
  function QueryTokenUrl(uint256 tokenId) public view returns (string memory) {
    return tokenURI(tokenId);
  }

  //query baseUrl url
  function QueryBaseUrl() public view returns (string memory) {
    return baseTokenURI;
  }


  function verifyWhite(bytes32[] calldata proof) public view returns(bool){
    return MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(address(msg.sender))));
  }
   
  function setWhitelist(bytes32 _root) public onlyOwner {
    //merkleRoot = stringToBytes32(_root);
    merkleRoot = _root;
    emit MerkleMsg("setWhitelist",address(msg.sender),merkleRoot);
  }
  

  /*
   send eth from address
  */
  function withdraw(address addr) public onlyOwner {
    //address _owner = owner();
    uint256 amount = address(this).balance;
    (bool sendStatus, ) = addr.call{value: amount}("");
    require(sendStatus, "Failed send");
  }

  function withdrawUsdt(address _target, uint256 _amount) public onlyOwner {
      usdt.transfer(_target, _amount);
  }

  function changeWhitePrice(uint256 _whitePrice) public onlyOwner{
     whitePrice=_whitePrice;
  }

  function changePrice(uint256 _price) public onlyOwner{
     price=_price;
  }


  function transferOwner(address addr) public onlyOwner{
    transferOwnership(addr);
  }

  receive() external payable {}
  fallback() external payable {}

  //Tools
  function stringToBytes32(string memory source) public pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
}

     struct slice {
        uint _len;
        uint _ptr;
    }


    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = type(uint).max;
        if (len > 0) {
            mask = 256 ** (32 - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

      /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }


}