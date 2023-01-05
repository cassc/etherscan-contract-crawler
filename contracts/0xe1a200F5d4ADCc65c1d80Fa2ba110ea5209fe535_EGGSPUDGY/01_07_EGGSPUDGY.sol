// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract EGGSPUDGY is Ownable, ERC721A {

    using Strings for uint;

    enum Steps {
        Before,
        PublicSale,
        SoldOut,
        Reveal
    }

    string public baseURI;
    string public notRevealedURI;

    bool public revealed = false;

    Steps public sellingStep;

    uint private constant MAX_SUPPLY = 8888;
    uint public Price = 0.003 ether;

    address payable private team;

    mapping(address => uint) nftsPerWallet;

    constructor() ERC721A("Egg s By Pudgy Penguins", "EGGSPUDGYs") {
        baseURI = "_baseURI";
        notRevealedURI = "https://bafkreidjgmnkpm6mizxl6a3hch5h2klctubtmewshoajedhe5vfvglw7zy.ipfs.nftstorage.link/";
        sellingStep = Steps.Before;
        team = payable(0x90f7a3f2478b2c6231f11150Cfd463F717FD5389);
        _safeMint(0x32AC1eaFAFfb11fA21dC74324C10DfD05b88a5b1, 25);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function Mint(address _account, uint _quantity) external payable callerIsUser {
        uint price = Price;
        require(price != 0, "Price is 0");
        require(sellingStep == Steps.PublicSale, "Sale is not activated");
        require(nftsPerWallet[msg.sender] + _quantity <= 25, "You can only get 25 NFT");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(msg.value >= price * _quantity, "Not enought funds");
        nftsPerWallet[msg.sender] += _quantity;
        if(totalSupply() == MAX_SUPPLY) {
            sellingStep = Steps.SoldOut;   
        }
        _safeMint(_account, _quantity);
    }

    function gift(address _to, uint _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reached max Supply");
        _safeMint(_to, _quantity);
    }

    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setStep(uint _step) external onlyOwner {
        sellingStep = Steps(_step);
    }

    function reveal() external onlyOwner{
        revealed = true;
    }

    function tokenURI(uint _nftId) public view override(ERC721A) returns (string memory) {
        require(_exists(_nftId), "This NFT doesn't exist.");
        if(revealed == false) {
            return notRevealedURI;
        }
        
        string memory currentBaseURI = _baseURI();
        return 
            bytes(currentBaseURI).length > 0 
            ? string(abi.encodePacked(currentBaseURI, _nftId.toString(), ".json"))
            : "";
    }

    function withdraw() external {
        team.transfer(address(this).balance);
    }

}