/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UncannyUnicorns is ERC721Enumerable, Ownable {
    uint public constant MAX_UNU = 10000;
	string _baseTokenURI;

    constructor(string memory baseURI) ERC721("Uncanny Unicorns", "UNU")  {
        setBaseURI(baseURI);
    }

   bool public saleIsActive = false;

    function flipSaleState() public onlyOwner {
    saleIsActive = !saleIsActive;
    }  
    

    function mintUNU(address _to, uint _count) public payable {
        require(saleIsActive, "Sale must be active to mint");
        require(totalSupply() + _count <= MAX_UNU, "Max limit");
        require(totalSupply() < MAX_UNU, "Sale end");
        require(_count <= 20, "Exceeds 20");
        require(msg.value >= price(_count), "Value below price");

        for(uint i = 0; i < _count; i++){
            _safeMint(_to, totalSupply());
        }
    }

    function price(uint _count) public view returns (uint256) {
        
        return 50000000000000000 * _count; // 0.05 ETH
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint i = 0; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }
}