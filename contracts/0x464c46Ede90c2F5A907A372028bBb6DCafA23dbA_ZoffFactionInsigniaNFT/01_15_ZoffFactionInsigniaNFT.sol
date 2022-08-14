//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract ZoffFactionInsigniaNFT is Ownable, ERC721A, ReentrancyGuard {
    bool public saleIsActive = false;
    string private _baseURIextended;
    string public baseExtension = "";

    // Variables controling wheather the NFTs are revealed or not.
    string _contractURI;

    uint256 public maxSupply = 3022;
    uint256 public maxPublicMint = 1;
    uint256 private pricePerToken = 0 ether;

    constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _contractURIParam,
    uint256 maxBatchSize_,
    uint256 collectionSize_
    ) ERC721A(_name, _symbol, maxBatchSize_, collectionSize_) {
        maxPublicMint = maxBatchSize_;  
        setBaseURI(_initBaseURI);
        _contractURI = _contractURIParam;
    } 

    // Function used to update the maxPublicMint
    function setMaxPublicMint(uint256 n) public onlyOwner {
        maxPublicMint = n;
    }

    function setMaxSupply(uint256 n) public onlyOwner {
        maxSupply = n;
    }

    // Function used to update the pricePerToken
    function setPricePerToken(uint256 newPrice) public onlyOwner {
        pricePerToken = newPrice;
    }

    function getPricePerToken() public view returns (uint256){
        return pricePerToken;
    }

    // Function used to return tokenURI based on the reveal status
    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
      require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
      );

    //   string memory currentBaseURI = _baseURI();
      return string(abi.encodePacked(super.tokenURI(tokenId), baseExtension));
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
      baseExtension = _newBaseExtension;
    }

    // contractURI returns a URL for the storefront-level metadata for your contract
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /*
    * Function used to mint a reserve supply of NFTS to the owner of the contract
    */
    function reserve(uint256 n) public onlyOwner {
      uint supply = totalSupply();
      uint i;
      for (i = 0; i < n; i++) {
          _safeMint(msg.sender, supply + i);
      }
    }

    /*
    * Function to change the state of the sale from active to inactive and vice-versa
    */
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    /**
    * Mints NFT on public sale
    */
    function mint(uint numberOfTokens) public payable {
        uint256 ts = totalSupply();
        uint256 walletBalance = numberMinted(msg.sender);

        require(saleIsActive, "Sale must be active to mint tokens");

        require(numberOfTokens <= maxPublicMint, "Exceeded max token purchase");

        require(walletBalance + numberOfTokens <= maxPublicMint, "Can not mint this many");

        require(ts + numberOfTokens <= maxSupply, "Purchase would exceed max tokens");

        require(pricePerToken * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _safeMint(msg.sender, numberOfTokens);
    }

    /*
    * Function responsible for withdrawal of funds from the contract
    */
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // ERC721A functions

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
}