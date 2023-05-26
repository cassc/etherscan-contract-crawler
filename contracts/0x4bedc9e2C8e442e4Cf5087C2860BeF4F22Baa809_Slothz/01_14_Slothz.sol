// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Slothz is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint public availableToken = 9999;
    uint256 public price = 0.045 ether;
    uint public constant maxPurchaseSize = 20;

    string _baseTokenURI;
    bool public paused = false;
    address owner1;
    address owner2;
    address owner3;
    address owner4;

    string public METADATA_PROVENANCE_HASH = "";

    constructor(string memory name, string memory symbol, string memory theBaseURI, address theOwner1, address theOwner2, address theOwner3, address theOwner4, uint numToken) ERC721(name, symbol)  {
        setBaseURI(theBaseURI);
        owner1 = theOwner1;
        owner2 = theOwner2;
        owner3 = theOwner3;
        owner4 = theOwner4;
        availableToken = numToken;
    }

    modifier saleIsOpen {
        require(totalSupply() < availableToken, "Sale has ended");
        _;
    }

    modifier notPaused {
        if(msg.sender != owner()){
            require(!paused, "Minting has beend paused");
        }
        _;
    }

    function mintSlothz(uint _count) public payable saleIsOpen notPaused {
        require(_count > 0, "You can't mint 0");
        require(_count <= maxPurchaseSize, "Exceeds 20");
        require(totalSupply() + _count <= availableToken, "Not enough token left");

        uint256 orderPrice = price.mul(_count);
        require(msg.value >= orderPrice, "Value below price");

        for(uint i = 0; i < _count; i++){
            _safeMint(msg.sender, totalSupply());
        }

        payable(owner1).transfer(orderPrice.div(10).mul(4));
        payable(owner2).transfer(orderPrice.div(5));
        payable(owner3).transfer(orderPrice.div(5));
        payable(owner4).transfer(orderPrice.div(5));
    }

    function ownerMint(uint _count, address to) public onlyOwner {
        require(_count > 0, "You can't mint 0");
        require(totalSupply() + _count <= availableToken, "Not enough token left");

        for(uint i = 0; i < _count; i++){
            _safeMint(to, totalSupply());
        }
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function contractURI() public pure returns (string memory) {
        return "https://www.slothz.io/contract-info.json";
    }

    function pause(bool val) public onlyOwner {
        paused = val;
    }

    function walletOfOwner(address _owner) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint i = 0; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function setProvenanceHash(string memory _hash) public onlyOwner {
        METADATA_PROVENANCE_HASH = _hash;
    }

    function setPrice(uint256 _price) public onlyOwner {
        require(_price >= 0.03 ether, "Minimum price is 0.03 ether");
        require(_price <= 0.06 ether, "Maximum price is 0.06 ether");
        price = _price;
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "caller is not owner nor approved");
        _burn(tokenId);
    }
}