// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Machinie is ERC721Enumerable, Ownable {

    using Strings for uint256;
    
    uint256 public constant _maxSupply = 8888;
    uint public constant _maxPurchasable = 20;
    bool public _paused = true;
    uint256 private _price = 0.018 ether ; //0.018 eth
    uint256 private _reserved = 88;
    uint256 public _quota = 0;


    address kingAddress = 0x714FdF665698837f2F31c57A3dB2Dd23a4Efe84c;
    address hathumAddress = 0xD37a936ACAe6e186f3938C550f11910E0809D67B;

    constructor() ERC721("Machinie", "MACH") {
        _safeMint(kingAddress,0);
        _safeMint(hathumAddress,1);
    }
 
    function giveAway(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= _reserved, "" );

        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }

        _reserved -= _amount;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://rest-api-machinie-nft.herokuapp.com/tokens/";
    }
    //LEAK!!
    
    function leak() public  {
        uint256 supply = totalSupply();
        require(balanceOf(msg.sender) < 1);
        require(totalSupply() <= 97); 
        _safeMint(msg.sender, supply);
    }

    function teleport(uint256 num) public payable {
        uint256 supply = totalSupply();
        require( !_paused,                   "Sale paused" );
        require( num <= _maxPurchasable,      "Only 20 Machinies can fit through the portal!" );
        require( supply + num < _maxSupply - _reserved, "Exceeds maximum Machines alive" );
        require( msg.value >= _price * num,     "Ether sent is not correct" );
        require(num <= _quota, "This exceeds the limit of jump!");

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
        }

        _quota -= num;
    }
    
    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function setQuota(uint256 _newQuota) public onlyOwner {
        _quota = _newQuota;
    }

    function setReserve(uint256 _newReserved) public onlyOwner {
        _reserved = _newReserved;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

}