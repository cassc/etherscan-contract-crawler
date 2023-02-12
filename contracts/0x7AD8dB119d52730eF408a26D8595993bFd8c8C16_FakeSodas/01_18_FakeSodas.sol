// SPDX-License-Identifier: MIT

// /$$$$$$$$        /$$                      /$$$$$$                  /$$                    
// | $$_____/       | $$                     /$$__  $$                | $$                    
// | $$     /$$$$$$ | $$   /$$  /$$$$$$     | $$  \__/  /$$$$$$   /$$$$$$$  /$$$$$$   /$$$$$$$
// | $$$$$ |____  $$| $$  /$$/ /$$__  $$    |  $$$$$$  /$$__  $$ /$$__  $$ |____  $$ /$$_____/
// | $$__/  /$$$$$$$| $$$$$$/ | $$$$$$$$     \____  $$| $$  \ $$| $$  | $$  /$$$$$$$|  $$$$$$ 
// | $$    /$$__  $$| $$_  $$ | $$_____/     /$$  \ $$| $$  | $$| $$  | $$ /$$__  $$ \____  $$
// | $$   |  $$$$$$$| $$ \  $$|  $$$$$$$    |  $$$$$$/|  $$$$$$/|  $$$$$$$|  $$$$$$$ /$$$$$$$/
// |__/    \_______/|__/  \__/ \_______/     \______/  \______/  \_______/ \_______/|_______/ 
                                                                                                                                                                                               

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DefaultOperatorFilterer.sol";

contract FakeSodas is ERC721Enumerable, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;
    string public baseURI = "https://files.fakesodas.com/data/";
    string public baseExtension = ".json";
    string public notRevealedUri;

    uint256 public MaxMint = 10;
    mapping(address => uint256) public Minted;

    bool public RevealedActive = true;
    bool public PublicMode = true;

    uint256 public PublicPrice = 0.013117 ether;
    uint256 public MaxSupply = 10000;

    constructor() ERC721("FakeSodas", "FK") {}


    function PublicMint(uint256 _Amount) public payable { 
        uint256 supply = totalSupply();
        uint256 ownerMintedCount = Minted[msg.sender];
        require(_Amount > 0, "");
        require(PublicMode == true, "Public Sale not started");
        require( ownerMintedCount + _Amount <= MaxMint, "Max NFT per Wallet Reached");
        require(supply + _Amount <= MaxSupply, "Sold Out");
        require(msg.value >= PublicPrice * _Amount, "Balance Insufficient");

        for (uint256 i = 1; i <= _Amount; i++) {
            Minted[msg.sender]++;
            _safeMint(msg.sender, supply + i);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

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
        require(_exists(tokenId), "");
        if (RevealedActive == false) {
            return notRevealedUri;
        }
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    // Owner Mint & Airdrop
    function OwnerMint(uint256 _mintAmount) external onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= MaxSupply, "Sold Out");
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function AirdropMint(address _to, uint256 _mintAmount) external onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= MaxSupply, "Sold Out");
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }


    // Set phases
    function TurnPublicMode(bool _state) public onlyOwner {
        PublicMode = _state;
    }

    // Set Public Price & Presale Price
    function setPublicPrice(uint256 _newPublicPrice) public onlyOwner {
        PublicPrice = _newPublicPrice;
    }

    // Set MaxMint
    function setMaxMint(uint256 _newMaxMint) public onlyOwner {
        MaxMint = _newMaxMint;
    }

    // Set NFTs CID and Place Holder CID
    function setURIBase(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    // Reveal the NFTs
    function Reveal() public onlyOwner {
        RevealedActive = true;
    }

    // Withdraw smart contract funds
    function withdraw() public payable onlyOwner {
        (bool bq, ) = payable(owner()).call{value: address(this).balance}("");
        require(bq);
    }

    // Opensea royalties
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}