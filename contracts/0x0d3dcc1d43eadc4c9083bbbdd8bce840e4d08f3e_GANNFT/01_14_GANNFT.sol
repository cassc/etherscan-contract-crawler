// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";


contract GANNFT is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Address for address;
    
    Counters.Counter private _tokenIdCounter;

    ERC721 Gapes = ERC721(0xBaE6f981dc151CfC633212f06A9c5B4E37920454);

    string private baseURI = "ipfs://QmQbba54XNYkQ5DGrYtoA4qhnjMDw5JEcrv6Ypv38X3QwL/";
    string private _contractURI = "";

    string public constant PROVANCE = "fa4760a07a0088994d78b6532f5eaf347ebff0457020f8f24c9269a177838186";

    address payable internal devwallet = payable(0x376Fd64563274bb4fCde4eBCFbAbEde3503688Ba);

    uint256 public constant PRICE = 0.1 ether;
    uint256 public constant PRICEGAPE = 0.05 ether;
    uint256 public constant MAXPURCHASE = 10;
    uint256 public constant MAXSUPPLY = 1111;
    uint256 public promo = 10;
    bool public saleIsActive;

    mapping(address => uint256) public GapesMinted;

    bool public frozenMetadata;
    event PermanentURI(string _baseURI, string _contractURI);

    constructor() ERC721("GANNFT-Faces", "GAN-Faces") {
    }

    function _baseURI() internal view override returns (string memory) {        
        return baseURI;
    }

    function setBaseUri(string memory baseURI_) external onlyOwner {
        require(!frozenMetadata,"Metadata already frozen");
        baseURI = baseURI_;
    }

    function contractURI() public view returns (string memory) {        
        return _contractURI;
    }

    function setContractURI(string memory contractURI_) external onlyOwner {
        require(!frozenMetadata,"Metadata already frozen");
        _contractURI = contractURI_;
    }

    function freezeMetadata() external onlyOwner {
        frozenMetadata = true;
        emit PermanentURI(baseURI, _contractURI);
    }

    function mint(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint new NFTs");
        require(numberOfTokens <= MAXPURCHASE, "You can't mint that many at once");
        require(totalSupply() + numberOfTokens <= MAXSUPPLY, "Purchase would exceed max supply");
        require(PRICE * numberOfTokens <= msg.value, "too little value has been sent");       

        for(uint i = 0; i < numberOfTokens; i++) {
            _safeMint(_msgSender(), _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function mintGAPE(uint256 numberOfTokens) public payable {
        //minting for Gape holders
        require(saleIsActive, "Sale must be active to mint new NFTs");
        require(numberOfTokens <= MAXPURCHASE, "You can't mint that many at once");
        require(totalSupply() + numberOfTokens <= MAXSUPPLY, "Purchase would exceed max supply");
        require(numberOfTokens <= Gapes.balanceOf(_msgSender()) - GapesMinted[_msgSender()], "You don't own enough Gapes");
        require(PRICEGAPE * numberOfTokens <= msg.value, "too little value has been sent");       

        for(uint i = 0; i < numberOfTokens; i++) {
            _safeMint(_msgSender(), _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }

        GapesMinted[_msgSender()] += numberOfTokens;
    }

    function mintPromo(uint256 numberOfTokens) public onlyOwner {
        //mint promotional NFTs before the sale begins
        require(numberOfTokens <= promo, "You can't mint that many at once");
        require(totalSupply() + numberOfTokens <= MAXSUPPLY, "Purchase would exceed max supply");

        for(uint i = 0; i < numberOfTokens; i++) {
            _safeMint(_msgSender(), _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }

        //subtract from total reserved for promo
        promo -= numberOfTokens;
    }


    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function withdrawETH () public onlyOwner {
        devwallet.transfer(address(this).balance);
	}
}