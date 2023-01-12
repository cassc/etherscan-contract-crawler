// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract ASSPIX is Ownable, ERC721A {

    using Strings for uint;

    enum Steps {
        Before,
        PublicSale,
        SoldOut//,
        //Reveal
    }

    string public baseURI;
    //string public notRevealedURI;

    //bool public revealed = false;

    Steps public sellingStep;

    uint private constant MAX_SUPPLY = 10000;
    uint public Price = 0.002 ether;

    address payable private team;

    mapping(address => uint) nftsPerWallet;
    mapping(address => bool) public hasFreeNFT;

    constructor() ERC721A("Asspix.wtf", "ASSPIX") {
        baseURI = "https://bafybeihtcwwirnowdt7inyeyzy3iyq6dsepozgnbo4xmby5ggaeg236dea.ipfs.nftstorage.link/";
        //notRevealedURI = "https://bafkreidjgmnkpm6mizxl6a3hch5h2klctubtmewshoajedhe5vfvglw7zy.ipfs.nftstorage.link/";
        sellingStep = Steps.PublicSale;
        team = payable(0x90f7a3f2478b2c6231f11150Cfd463F717FD5389);
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
        uint freeNFTs = 0;
        if (!hasFreeNFT[msg.sender]) {
        freeNFTs = 1;
        hasFreeNFT[msg.sender] = true;
        }
        require(msg.value >= price * _quantity, "Not enought funds");
        nftsPerWallet[msg.sender] += _quantity;
        if(totalSupply() == MAX_SUPPLY) {
            sellingStep = Steps.SoldOut;   
        }
        _safeMint(_account, (_quantity + freeNFTs));
    }

    function gift(address _to, uint _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reached max Supply");
        _safeMint(_to, _quantity);
    }

    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setPrice(uint _Price) external onlyOwner {
        Price = _Price;
    }

    function setStep(uint _step) external onlyOwner {
        sellingStep = Steps(_step);
    }

    /*function reveal() external onlyOwner{
        revealed = true;
    }*/

    function tokenURI(uint _nftId) public view override(ERC721A) returns (string memory) {
        require(_exists(_nftId), "This NFT doesn't exist.");
        /*if(revealed == false) {
            return notRevealedURI;
        }*/
        
        string memory currentBaseURI = baseURI;
        return 
            bytes(currentBaseURI).length > 0 
            ? string(abi.encodePacked(currentBaseURI, _nftId.toString(), ".json"))
            : "";
    }

    function withdraw() external {
        team.transfer(address(this).balance);
    }

}