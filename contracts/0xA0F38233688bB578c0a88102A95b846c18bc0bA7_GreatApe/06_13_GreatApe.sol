// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract GreatApe is ERC721Enumerable, Ownable {
    uint256 public itemPrice=40000000000000000; // 0.04 ETH
    address public wallet1=0x8EA76a223b85a66E0aed572D64C07a95596ae0FF;
    uint public constant MaxGreatApe = 10000;
	bool public isSale = false;
    string _baseTokenURI = "https://api.greatapesociety.io/api/meta/";

    constructor() ERC721("Great Ape Society", "GAS")  {
    }

    function mintGreatApe(address _to, uint _count) public payable {
        require(isSale, "No Sale");
        require(_count <= 20, "Exceeds 20");
        require(msg.value >= price(_count), "Value below price");
        require(totalSupply() + _count <= MaxGreatApe, "Max limit");
        require(totalSupply() < MaxGreatApe, "Sale end");

        for(uint i = 0; i < _count; i++){
            _safeMint(_to, totalSupply());
        }
    }
    

    
    function price(uint _count) public view returns (uint256) {
        return _count * itemPrice;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function walletOfOwner(address _owner) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint i = 0; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
    
    function saleControl(bool val) public onlyOwner {
        isSale = val;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 wallet1_balance = address(this).balance;
        require(payable(wallet1).send(wallet1_balance));
    }
    function changeWallet(address _accountnew) external onlyOwner {
        wallet1 = _accountnew;
    }
}