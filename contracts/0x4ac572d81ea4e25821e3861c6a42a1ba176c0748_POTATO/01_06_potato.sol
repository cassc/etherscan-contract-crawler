//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract POTATO is Ownable, ERC721A {
    uint256 constant public maxSupply = 3333;
    uint256 public publicPrice = 0.015 ether;
    uint256 constant public limitAmountPerTx = 2;
    uint256 constant public limitAmountPerWallet = 2;
    string public revealedURI = "ipfs:// ----IFPS---/";
    bool public paused = true;
    bool public freeSale = true;
    mapping(address => uint256) public mintedWallets;


    constructor(
        string memory _name,
        string memory _symbol,
        string memory _revealedURI
    ) ERC721A(_name, _symbol) {
        revealedURI = _revealedURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function freeMint(uint256 quantity) external payable mintCompliance(quantity) {
        require(freeSale, "Free sale inactive");
        require(maxSupply > totalSupply(), "sold out");
        uint256 currMints = mintedWallets[msg.sender];
        require(quantity <= limitAmountPerTx, "Quantity too high");
        require(currMints + quantity  <= limitAmountPerWallet, "u wanna mint too many");
        
        if(quantity == 1) {
            require(msg.value >= (quantity) * publicPrice, "give me more money");
            mintedWallets[msg.sender] = (currMints + quantity);
            _safeMint(msg.sender, quantity);
        }else if(quantity == 2){
            require(msg.value >= (quantity-1) * publicPrice, "give me more money2");
            mintedWallets[msg.sender] = quantity;
            _safeMint(msg.sender, quantity);
        }
 
    }


    function ShowTotalSupply() public view returns (uint256) {
        return totalSupply();
    }
    

    function walletOfOwner(address _owner) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }

        currentTokenId++;
        }

        return ownedTokenIds;
    }


    function contractURI() public view returns (string memory) {
        return revealedURI;
    }

    function setPublicPrice(uint256 _publicPrice) public onlyOwner {
        publicPrice = _publicPrice;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        revealedURI = _baseUri;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        revealedURI = _contractURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(revealedURI, Strings.toString(_tokenId), ".json"));
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setFreeEnabled(bool _state) public onlyOwner {
        freeSale = _state;
    }
    

    function mintToUser(uint256 quantity, address receiver) public onlyOwner mintCompliance(quantity) {
        _safeMint(receiver, quantity);
    }

    function withdrawFundsToAddress(address _address, uint256 amount) external onlyOwner {
        (bool success, ) =_address.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    modifier mintCompliance(uint256 quantity) {
        require(!paused, "Contract is paused");
        require(totalSupply() + quantity <= maxSupply, "you cant become ugly anymore");
        require(tx.origin == msg.sender, "No contract minting");
        _;
    }
}