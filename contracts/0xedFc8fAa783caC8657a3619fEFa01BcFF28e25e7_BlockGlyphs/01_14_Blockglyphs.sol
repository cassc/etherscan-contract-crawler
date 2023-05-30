// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BlockGlyphs is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    string _baseTokenURI;
    uint256 private _maxMint = 10;
    uint256 private _devShare = 10;
    uint256 private _price = 75 * 10**15; //0.075 ETH;
    bool public _paused = true;
    uint public constant MAX_ENTRIES = 1001;

    address public constant creatorAddress = 0x43D7ada37De2C08da05993E33b7A675316A7cf0A;

    constructor(string memory baseURI) ERC721("BlockGlyphs", "BlockGlyphs")  {
        setBaseURI(baseURI);
    }

    function mint(address _to, uint256 num) public payable {
        uint256 supply = totalSupply();

        if(msg.sender != owner()) {
          require(!_paused, "Sale Paused");
          require( num < (_maxMint+1),"You can min between 1 and 10 Block Glyphs at a time" );
          require( msg.value >= _price * num,"Ether sent is not correct" );
        }

        require( supply + num < MAX_ENTRIES+1, "Exceeds maximum supply" );

        for(uint256 i; i < num; i++){
          _safeMint( _to, supply + i );
        }
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function getPrice() public view returns (uint256){
        if(msg.sender == owner()) {
            return 0;
        }
        return _price;
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }

    function getMaxMint() public view returns (uint256){
        return _maxMint;
    }

    function setMaxMint(uint256 _newMaxMint) public onlyOwner() {
        _maxMint = _newMaxMint;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getDevShare() public view returns (uint256){
        return _devShare;
    }

    function setDevShare(uint256 _newDevShare) public onlyOwner() {
        _devShare = _newDevShare;
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function withdrawAll() public payable onlyOwner {
      uint256 balance = address(this).balance;
      require(balance > 0);
      require(payable(msg.sender).send(balance.mul(_devShare).div(100)), "Transfer to dev failed");
      require(payable(creatorAddress).send(address(this).balance), "Transfer to creator failed");
    }
}