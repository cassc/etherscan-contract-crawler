/*
░█▀█░█▀▄░█▀█░█▀▄░█▀▀░░░█▄█░█▀█░█▀▀░▀█▀░█▀▀░█▀▄░█▀▀
░█▀▀░█▀▄░█░█░█▀▄░█▀▀░░░█░█░█▀█░▀▀█░░█░░█▀▀░█▀▄░▀▀█
░▀░░░▀░▀░▀▀▀░▀▀░░▀▀▀░░░▀░▀░▀░▀░▀▀▀░░▀░░▀▀▀░▀░▀░▀▀▀

XXXXXXXXXXXXKXXK0kdolllllllllodk0KXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXKOdlclooodoodoooolclokKXXXXXXXXXXXXXX
KXXXXXXXXKXKOdlloooloodooooloooooc:lOXXXXXXXXXXXXX
KXXXXXXXXXKd:cooooooooooooooooooool:ckKXXXXXXXXXXX
XXXXXXXXX0o;coooooooooooooooooooooolccxKXXXXXXXXXX
XXXXXXXXKx:cooooooooooooooooooooooollcckXXXXXXXXXX
XXXXXXXX0l;loooooooodooooooooooooooollco0XXXXXXXXX
XXXXKXXX0c:oolc:cloooooooooooooollllcc:ckXXXXXXXXX
XXXXKXXX0c;:'....';clooddooolc;''....,;ckXXXXXXXXX
XXXXXXXXKo,.   ...'.,cooool:'''..    .,l0XXXXXXXXX
XXXXXXXXXk:'........'coolll:'.......',:xKXXXXXXXXX
XXXXXXXXXKd;;:clcccccloolclolcclcccc:;o0XXXXXXXXXX
XXXXXXXXXXKd:cloooooooolcllooooolll::d0XKXXXXXXXXX
XXXXXXXXXKXKd::cloddoolccllooodolc:ckKXKXXXXXXXXXX
XXXXXXXXXXXXKOl,,:looolc:cloooo:,:x0XXXXXXXXXXXXXX
XXXXXXXXXXXXXXKkl;;clllc::lool:;lOXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXKkc;clclclloo::xKXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXO:,loollool,lKXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXO:.,clcccc,.c0XXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXKd::;;;;;;;;;:kXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXKOo:clooooooool:cOKXXXXXXXXXXXXXKXX
XXXXXXXXXXK0Okdlc:looooooodoloo::ok0KXXKXXXXXXXXXX
XXXK0Oxdollcc::cllooooolooollooolc:clllodddddk0KXX
XKOocc::cccllllllllllllllcllllllllllcc:::::::::oOK
X0l,cooolclloooooooolllcllllcclllllllllllcclloc;o0
*/

// SPDX-License-Identifier: MIT 
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


contract ProbeMasters is ERC721, ERC721URIStorage, DefaultOperatorFilterer, Ownable {

    uint256 public supply = 4451;
    uint256 public maxMint = 10;
    uint256 public mintPrice = 20000000000000000;
    bool public paused = true;
    uint256 public _tokenId = 0;
    string public baseURI;

    constructor() ERC721("ProbeMasters", "PM") {
        baseURI;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function safeMint(address to, uint256 _numTokens) public payable {
        require(paused == false, "Minting is currently paused.");
        require(balanceOf(to) + _numTokens <= maxMint, "The specified address already holds the maximum number of mintable NFTs.");
        require(msg.value >= mintPrice * _numTokens, "Not enough ether sent.");
        require(_tokenId + _numTokens <= supply, "Total supply cannot be exceeded.");
        require(_numTokens <= maxMint, "You cannot mint that many in one transaction.");

        for(uint256 i = 1; i <= _numTokens; ++i) {
            _tokenId++;
            _safeMint(to, _tokenId);
            _setTokenURI(_tokenId, baseURI);
        }       
    }

    function ownerMint(address to, uint256 _numTokens) public onlyOwner {
        require(_tokenId + _numTokens <= supply, "Total supply cannot be exceeded.");

        for(uint256 i = 1; i <= _numTokens; ++i) {
            _tokenId++;
            _safeMint(to, _tokenId);
            _setTokenURI(_tokenId, baseURI);
        } 
    }

    function withdrawAmount(uint256 _amount) external payable onlyOwner {
        require(address(this).balance > _amount, "Not enough balance.");
        ( bool transfer, ) = payable(0x64A88d29Bc7844cC99f08f8C71700079389cf939).call{value: _amount}("");
        require(transfer, "Transfer failed.");
    }

    function withdrawAll() external payable onlyOwner {
        require(address(this).balance > 0, "Zero balance.");
        ( bool transfer, ) = payable(0x64A88d29Bc7844cC99f08f8C71700079389cf939).call{value: address(this).balance}("");
        require(transfer, "Transfer failed.");
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setSupply(uint256 _maxSupply) external onlyOwner {
        if (_maxSupply <= supply && _maxSupply > _tokenId) {
            supply = _maxSupply;
        }
    }

    function setMaxMint(uint256 _maxMint) external onlyOwner {
        maxMint = _maxMint;
    }

    function totalSupply() public virtual view returns (uint256) {
        return supply;
    }
  
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)

        returns (string memory)
    {
        return string.concat(baseURI, Strings.toString(tokenId), ".json");
    }
}