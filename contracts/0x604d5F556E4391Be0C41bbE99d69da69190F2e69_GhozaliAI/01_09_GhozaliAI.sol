// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "./MerkleWhitelist.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GhozaliAI is Ownable, ERC721A, MerkleWhitelist, ReentrancyGuard{

    string public CONTRACT_URI = "ipfs://QmbNA9vHJoof5HRn6yQ5ETdx8Ln7BmbtTjnKQLiNPtoNJs";
    mapping(address => bool) public userHasMintedPublicWL;
    bool public REVEALED;
    string public UNREVEALED_URI = "ipfs://bafybeidynujaxmkqub2kiuldsc5lstmflhsrevjdqrfz6lx57behu3546m/14.png";
    string public BASE_URI;
    bool public isPublicMintEnabled = false;
    uint public COLLECTION_SIZE = 1000;
    uint public WL_MINT_PRICE = 0.05 ether;
    uint public MINT_PRICE = 0.06 ether;
    uint public MAX_BATCH_SIZE = 3;
    uint public MAX_WL_BATCH_SIZE = 1;

    constructor() ERC721A("GhozaliAI", "GAI") {}

    function teamMint(uint256 quantity, address receiver) public onlyOwner {
        //Max supply
        require(
            totalSupply() + quantity <= COLLECTION_SIZE,
            "Max collection size reached!"
        );
        //Mint the quantity
        _safeMint(receiver, quantity);
    }

    function mintPublicWL(uint256 quantity, bytes32[] memory proof)
        public
        payable
        onlyPublicWhitelist(proof)
    {
        uint256 price = (WL_MINT_PRICE) * quantity;
        require(!userHasMintedPublicWL[msg.sender], "Can only mint once during public WL!");   
        require(totalSupply() + quantity <= COLLECTION_SIZE, "Max Collection Size reached!");
        require(quantity <= MAX_WL_BATCH_SIZE, "Cannot mint this quantity");
        require(msg.value >= price, "Must send enough eth for WL Mint");

        userHasMintedPublicWL[msg.sender] = true;

        //Mint them
        _safeMint(msg.sender, quantity);
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function publicSaleMint(uint256 quantity)
        external
        payable
        callerIsUser
    {
        uint256 price = (MINT_PRICE) * quantity;
        require(isPublicMintEnabled == true, "public sale has not begun yet");
        require(totalSupply() + quantity <= COLLECTION_SIZE, "Max Collection Size reached!");
        require(quantity <= MAX_BATCH_SIZE, "Tried to mint quanity over limit, retry with reduced quantity");
        require(msg.value >= price, "Must send enough eth for public mint");
        _safeMint(msg.sender, quantity);
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setPublicMintEnabled(bool _isPublicMintEnabled) public onlyOwner {
        isPublicMintEnabled = _isPublicMintEnabled;
    }

    function setBaseURI(bool _revealed, string memory _baseURI) public onlyOwner {
        BASE_URI = _baseURI;
        REVEALED = _revealed;
    }

    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        CONTRACT_URI = _contractURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (REVEALED) {
            return
                string(abi.encodePacked(BASE_URI, Strings.toString(_tokenId)));
        } else {
            return UNREVEALED_URI;
        }
    }
}