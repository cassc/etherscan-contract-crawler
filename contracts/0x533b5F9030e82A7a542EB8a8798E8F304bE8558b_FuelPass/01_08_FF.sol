// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "hardhat/console.sol";

contract FuelPass is ERC721AQueryable, Ownable {
    string public baseTokenURI;
    string public hiddenTokenURI;
    uint256 public maxSupply = 1776;
    uint256 public maxAmountPerTx = 10;
    uint256 public maxAirdropSupply = maxSupply;
    uint256 public airdropSupply = 0;
    uint256 public prePrice = 0.1776 ether;
    uint256 public publicPrice = 0.1776 ether;
    uint256 public revealTime = 0;
    bool public isTokenHidden = false;
    bool public isPublicSaleActive = true;
    bool public paused = false;
    address affAdd = 0x9C0F87f8Bd04511F0Cadd8B3af84F3Eb6ddC4a4B;
    string affAddStr = "0x9C0F87f8Bd04511F0Cadd8B3af84F3Eb6ddC4a4B";

    modifier onlyNotPaused() {
        require(!paused, "1");
        _;
    }

    constructor(address _affAdd) ERC721A("FuelFest", "FF") {
        affAdd = _affAdd;
    }

    function price() public view returns (uint256) {
        if (isPublicSaleActive) {
            return publicPrice;
        } else {
            return prePrice;
        }
    }

    function setPublicSale() public onlyOwner {
        isPublicSaleActive = true;
    }

    function setPreSale() public onlyOwner {
        isPublicSaleActive = false;
    }

    function setMaxAmountPerTx(uint256 _maxAmountPerTx) public onlyOwner {
        maxAmountPerTx = _maxAmountPerTx;
    }

    function mint(address _to, uint256 _count) public payable onlyNotPaused {
        uint256 amt;
        require(totalSupply() + _count <= maxSupply, "5");
        require(msg.value >= price() * _count, "6");
        require(maxAmountPerTx >= _count, "7");
        amt = (msg.value * 15) / 100;
        if (amt > 0) {
            (bool hs, ) = payable(affAdd).call{value: amt}("");
            require(hs, "6");
            //emit AffPaid(affAdd, amt);
        }
        _safeMint(_to, _count);
    }

    function airDrop(address[] memory addresses)
        external
        onlyOwner
        onlyNotPaused
    {
        uint256 supply = totalSupply();
        console.log(airdropSupply);
        console.log(addresses.length);
        console.log(maxAirdropSupply);
        require(
            airdropSupply + addresses.length <= maxAirdropSupply,
            "This transaction would exceed airdrop max supply"
        );
        require(
            supply + addresses.length <= maxSupply,
            "This transaction would exceed max supply"
        );
        for (uint8 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], 1);
            airdropSupply += 1;
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        return
            string(
                abi.encodePacked(_baseURI(), "/", _toString(tokenId), ".json")
            );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _hiddenURI() internal view virtual returns (string memory) {
        return hiddenTokenURI;
    }

    function revealToken() public onlyOwner {
        isTokenHidden = false;
        revealTime = block.timestamp;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setHiddenURI(string memory baseURI) public onlyOwner {
        hiddenTokenURI = baseURI;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function numberMinted(address add) public view returns (uint256) {
        return _numberMinted(add);
    }

    function setPrice(uint256 _price) public onlyOwner {
        prePrice = _price;
        publicPrice = _price;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}