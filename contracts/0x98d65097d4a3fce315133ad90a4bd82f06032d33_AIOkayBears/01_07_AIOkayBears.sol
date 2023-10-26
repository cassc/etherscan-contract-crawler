// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// :::'###::::'####::'#######::'##:::'##::::'###::::'##:::'##:'########::'########::::'###::::'########:::'######::
// ::'## ##:::. ##::'##.... ##: ##::'##::::'## ##:::. ##:'##:: ##.... ##: ##.....::::'## ##::: ##.... ##:'##... ##:
// :'##:. ##::: ##:: ##:::: ##: ##:'##::::'##:. ##:::. ####::: ##:::: ##: ##::::::::'##:. ##:: ##:::: ##: ##:::..::
// '##:::. ##:: ##:: ##:::: ##: #####::::'##:::. ##:::. ##:::: ########:: ######:::'##:::. ##: ########::. ######::
//  #########:: ##:: ##:::: ##: ##. ##::: #########:::: ##:::: ##.... ##: ##...:::: #########: ##.. ##::::..... ##:
//  ##.... ##:: ##:: ##:::: ##: ##:. ##:: ##.... ##:::: ##:::: ##:::: ##: ##::::::: ##.... ##: ##::. ##::'##::: ##:
//  ##:::: ##:'####:. #######:: ##::. ##: ##:::: ##:::: ##:::: ########:: ########: ##:::: ##: ##:::. ##:. ######::
// ..:::::..::....:::.......:::..::::..::..:::::..:::::..:::::........:::........::..:::::..::..:::::..:::......:::

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract AIOkayBears is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;

    string public baseURI = "";
    string public fullURI = "";
    string public constant baseExtension = ".json";

    uint256 public maxSupply = 10000;
    uint256 public freeSupplyLeft = 3000;
    uint256 public reserveSupplyLeft = 800;

    uint256 MAX_FREE_MINT = 3;
    uint256 MAX_PAID_MINT = 20;
    uint256 MAX_PAID_MINT_PER_TX = 10;

    bool public mintActive = false;
    bool ownerMinted = false;

    uint256 PRICE = 0.0069 ether;

    mapping(address => uint256) public mintedList;
    mapping(address => uint256) public freeMintedList;
    mapping(address => uint256) public reserveList;

    event ToggleMint(bool indexed mintActive);
    event AIOBMinted(address indexed mintAddress, uint8 indexed numTokens, uint8 mintType);

    constructor() ERC721A("AIOkayBears", "AIOB") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Contract calls not allowed");
        _;
    }

    function mint(uint8 numTokens) external payable callerIsUser {
        require(mintActive, "Mint has not started yet");
        require(totalSupply() + numTokens <= maxSupply, "Reached max supply");
        if (msg.value > 0) {
            require(totalSupply() + reserveSupplyLeft + numTokens <= maxSupply, "Reached paid mint supply");
            require(msg.value >= price(numTokens), "Not enough ETH");
            require(numTokens <= MAX_PAID_MINT_PER_TX, "Max 10 NFTs per transaction");
            require(mintedList[msg.sender] + numTokens <= MAX_PAID_MINT, "Max 20 NFTs per wallet");
            mintedList[msg.sender] = mintedList[msg.sender] + numTokens;
            _safeMint(msg.sender, numTokens);
            emit AIOBMinted(msg.sender, numTokens, 2);
        } else {
            require(freeSupplyLeft - numTokens >= 0, "Reached free mint supply");
            require(freeMintedList[msg.sender] + numTokens <= MAX_FREE_MINT, "Max 3 free NFTs per wallet");
            freeMintedList[msg.sender] = freeMintedList[msg.sender] + numTokens;
            freeSupplyLeft = freeSupplyLeft - numTokens;
            _safeMint(msg.sender, numTokens);
            emit AIOBMinted(msg.sender, numTokens, 0);
        }
    }
    
    function reservedMint(uint8 numTokens) external callerIsUser {
        require(mintActive, "Mint has not started yet");
        require(totalSupply() + numTokens <= maxSupply, "Reached max supply");
        require(reserveSupplyLeft - numTokens >= 0, "Reached reserved mint supply");
        require(reserveList[msg.sender] >= numTokens, "Not eligible for reserved mint");
        reserveList[msg.sender] = reserveList[msg.sender] - numTokens;
        reserveSupplyLeft = reserveSupplyLeft - numTokens;
        _safeMint(msg.sender, numTokens);
        emit AIOBMinted(msg.sender, numTokens, 1);
    }
    
    function ownerMint() external onlyOwner {
        require(!ownerMinted, "Owner already minted");
        ownerMinted = true;
        _safeMint(msg.sender, 1);
        emit AIOBMinted(msg.sender, 1, 2);
    }

    function price(uint8 numTokens) private view returns (uint256) {
        return PRICE * numTokens;
    }

    function seedReserveList(address[] memory addresses, uint256[] memory numSlots) external onlyOwner {
        require(addresses.length == numSlots.length, "Addresses does not match numSlots length");
        for (uint256 i = 0; i < addresses.length; i++) {
            reserveList[addresses[i]] = numSlots[i];
        }
    }
    
    function toggleMintState() external onlyOwner {
        mintActive = !mintActive;
        emit ToggleMint(mintActive);
    }
    
    function updatePrice(uint256 newPrice) external onlyOwner {
        PRICE = newPrice;
    }

    function updateFreeBalance(uint256 newFreeBalance) external onlyOwner {
        freeSupplyLeft = newFreeBalance;
    }
    
    function updateReservedBalance(uint256 newReservedBalance) external onlyOwner {
        reserveSupplyLeft = newReservedBalance;
    }
    
    function updateMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply >= totalSupply(), "New supply must be larger than or equal to total supply");
        maxSupply = newMaxSupply;
    }
    
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
        fullURI = "";
    }
    
    function setFullURI(string memory fullURI_) external onlyOwner {
        fullURI = fullURI_;
        baseURI = "";
    }
    
    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist");
        if (bytes(baseURI).length > 0) {
            return string(
                abi.encodePacked(
                    baseURI,
                    _tokenId.toString(),
                    baseExtension
                )
            );
        } else if (bytes(fullURI).length > 0) {
            return fullURI;
        } else {
            return "";
        }
    }
}