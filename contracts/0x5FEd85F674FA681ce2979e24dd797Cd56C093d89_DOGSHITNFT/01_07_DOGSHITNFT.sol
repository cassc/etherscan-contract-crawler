// SPDX-License-Identifier: MIT

/**
     ____.               __                       __  .__        __                   .__                              _____         .__    .__  __   
    |    |__ __  _______/  |_  _____      _______/  |_|__| ____ |  | _____.__. ______ |__| ____   ____  ____     _____/ ____\   _____|  |__ |__|/  |_ 
    |    |  |  \/  ___/\   __\ \__  \    /  ___/\   __\  |/    \|  |/ <   |  | \____ \|  |/ __ \_/ ___\/ __ \   /  _ \   __\   /  ___/  |  \|  \   __\
/\__|    |  |  /\___ \  |  |    / __ \_  \___ \  |  | |  |   |  \    < \___  | |  |_> >  \  ___/\  \__\  ___/  (  <_> )  |     \___ \|   Y  \  ||  |  
\________|____//____  > |__|   (____  / /____  > |__| |__|___|  /__|_ \/ ____| |   __/|__|\___  >\___  >___  >  \____/|__|    /____  >___|  /__||__|  
                    \/              \/       \/               \/     \/\/      |__|           \/     \/    \/                      \/     \/         

 @powered by: amadeus-nft.io
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DOGSHITNFT is Ownable, ERC721A, ReentrancyGuard {
    constructor() ERC721A("DOG SHIT NFT", "DSHIT") {}
    
    uint256 public collectionSize = 1082;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // For marketing etc.
    function reserveMintBatch(uint256[] calldata quantities, address[] calldata tos) external onlyOwner {
        for(uint256 i = 0; i < quantities.length; i++){
            require(
                totalSupply() + quantities[i] <= collectionSize,
                "Too many already minted before dev mint."
            );
            _safeMint(tos[i], quantities[i]);
        }
    }

    // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        address amadeusAddress = address(0x718a7438297Ac14382F25802bb18422A4DadD31b);
        uint256 royaltyForAmadeus = address(this).balance / 100 * 10;
        uint256 remain = address(this).balance - royaltyForAmadeus;
        (bool success, ) = amadeusAddress.call{value: royaltyForAmadeus}("");
        require(success, "Transfer failed.");
        (success, ) = msg.sender.call{value: remain}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }
    // allowList mint
    uint256 public allowListMintPrice = 0.000000 ether;
    // default false
    bool public allowListStatus = false;
    uint256 public amountForAllowList = 100;
    uint256 public immutable maxPerAddressDuringMint = 1;

    mapping(address => uint256) public allowList;

    function allowListMint(uint256 quantity) external payable {
        require(allowListStatus, "not begun");
        require(allowList[msg.sender] >= quantity, "reached max amount per address");
        require(amountForAllowList >= quantity, "reached max amount");
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        allowList[msg.sender] -= quantity;
        _safeMint(msg.sender, quantity);
        amountForAllowList -= quantity;
        refundIfOver(allowListMintPrice*quantity);
    }

    function setAllowList(address[] calldata allowList_) external onlyOwner {
        for(uint256 i = 0;i < allowList_.length;i++){
            allowList[allowList_[i]] = maxPerAddressDuringMint;
        }
    }

    function setAllowListStatus(bool status) external onlyOwner {
        allowListStatus = status;
    }

    function isInAllowList(address addr) public view returns(bool) {
        return allowList[addr] > 0;
    }
    //public sale
    bool public publicSaleStatus = false;
    uint256 public publicPrice = 0.100000 ether;
    uint256 public amountForPublicSale = 900;
    // per address public sale limitation
    mapping(address => uint256) private publicSaleMintedPerAddress;
    uint256 public immutable publicSalePerAddress = 2;

    function publicSaleMint(uint256 quantity) external payable callerIsUser {
        require(publicSaleStatus, "not begun");
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        require(amountForPublicSale >= quantity, "reached max amount");

        require(publicSaleMintedPerAddress[msg.sender] + quantity <= publicSalePerAddress, "reached max amount per address");

        _safeMint(msg.sender, quantity);
        amountForPublicSale -= quantity;
        publicSaleMintedPerAddress[msg.sender] += quantity;
        refundIfOver(uint256(publicPrice) * quantity);
    }

    function setPublicSaleStatus(bool status) external onlyOwner {
        publicSaleStatus = status;
    }
}