//SPDX-License-Identifier: None
pragma solidity >= 0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {UpdatableOperatorFilterer} from "./libs/UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "./libs/RevokableDefaultOperatorFilterer.sol";

contract BCD721 is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;

    uint256 public mintingPrice = 0.15 ether;
    uint256 public MAX_TOKENS = 1000;

    bool public revealed;
    bool public mintingAvailable;

    address public withdrawerAddress = 0xBcaAB7c34809a3E173efE1fb30988A8730E24ddC;
    address public crossmintAddress = 0xdAb1a1854214684acE522439684a145E62505233;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        string memory _notRevealedUri
    ) ERC721(_name, _symbol) {
        baseURI = _baseUri;
        notRevealedUri = _notRevealedUri;
    }

    function mint(uint256 numberOfTokens) public payable {
        require(msg.value >= (numberOfTokens * mintingPrice), "Price is not enough");
        require(totalSupply() + numberOfTokens <= MAX_TOKENS, "Max token overflow");
        require(mintingAvailable, "minting closed");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function crossmint(uint256 numberOfTokens, address _to) public payable {
        require(msg.value >= (numberOfTokens * mintingPrice), "Price is not enough");
        require(totalSupply() + numberOfTokens <= MAX_TOKENS, "Max token overflow");
        require(mintingAvailable, "minting closed");

        require(msg.sender == crossmintAddress, "This function is for Crossmint only.");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            _safeMint(_to, mintIndex);
        }
    }

    function withdraw() public {
        require(msg.sender == withdrawerAddress, "Only withdrawer");
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // owner methods

    function setMintingPrice(uint256 _price) public onlyOwner {
        mintingPrice = _price;
    }

    function toggleReveal() public onlyOwner {
        revealed = !revealed;
    }

    function setNotRevealedUri(string memory _uri) public onlyOwner {
        notRevealedUri = _uri;
    }

    function setBaseUri(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function toggleMinting() public onlyOwner {
        mintingAvailable = !mintingAvailable;
    }

    function changeCrossmintAddress(address _crosssmintAddress) public onlyOwner{
        crossmintAddress = _crosssmintAddress;
    }

    function changeWithdrawer(address _withdrawerAddress) public onlyOwner {
        withdrawerAddress = _withdrawerAddress;
    }

    // view methods

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
        tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

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
        
        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    // internal methods

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}