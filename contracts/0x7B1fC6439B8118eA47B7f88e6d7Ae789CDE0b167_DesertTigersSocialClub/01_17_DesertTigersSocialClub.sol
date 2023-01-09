// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DesertTigersSocialClub is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 public maxSupply = 9999;

    string public baseURI;
    string public notRevealedURI =
        "ipfs://QmPvCe1tbCxH6hUbazz62dZfSBVcsag7zzJesPNmhSFTLc/1.json";
    string public baseExtension = ".json";

    bool public paused = false;
    bool public revealed = false;
    bool public presaleM = false;
    bool public publicM = false;

    uint256 _preSalePrice = 0.1 ether; // 0.1 ETH
    uint256 _publicSalePrice = 0.2 ether; // 0.2 ETH

    Counters.Counter private _tokenIds;

    constructor(string memory uri) ERC721("DTSC Official", "DTSC") {
        setBaseURI(uri);
    }

    function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
        baseURI = _tokenBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    modifier onlyAccounts() {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function togglePresale() public onlyOwner {
        presaleM = !presaleM;
    }

    function togglePublicSale() public onlyOwner {
        publicM = !publicM;
    }
    

    function presaleMint(uint256 _amount) external payable onlyAccounts {
        require(presaleM == true, "Presale is OFF");
        require(!paused, "Contract is paused");

        uint256 current = _tokenIds.current();

        require(current + _amount <= maxSupply, "Max Supply exceeded");
        require(_preSalePrice * _amount <= msg.value, "Not enough balance");

        for (uint256 i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function publicSaleMint(uint256 _amount) external payable onlyAccounts {
        require(publicM == true, "Public sale is OFF");
        require(!paused, "Contract is paused");
        require(_amount > 0, "Zero ammount");

        uint256 current = _tokenIds.current();

        require(current + _amount <= maxSupply, "Max supply exceeded");
        require(_publicSalePrice * _amount <= msg.value, "Not enough balance");

        for (uint256 i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function mintInternal() internal nonReentrant {
        _tokenIds.increment();

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);
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
            "ERC721Metaddata: URI query for nonexistent token"
        );
        if (revealed == false) {
            return notRevealedURI;
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

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}