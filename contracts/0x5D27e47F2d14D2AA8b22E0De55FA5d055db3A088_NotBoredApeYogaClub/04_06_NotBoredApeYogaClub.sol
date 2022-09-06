// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "erc721a/contracts/ERC721A.sol";

contract NotBoredApeYogaClub is ERC721A, Ownable {
    uint256 public constant RESERVE_SUPPLY = 200;

    uint256 public MAX_SUPPLY = 10000;
    uint256 public MINT_LIMIT = 10;
    uint256 public TRANSACTION_LIMIT = 10;
    uint256 public PUBLIC_PRICE = 0;

    bool public isPublicSaleActive;

    string private baseURI = "ipfs://QmWhAXEYguMtnLc6PsmR5R3Wf6GmJQdgFHsEyWXvUVFtyP/";

    mapping(address => uint256) public mintedNumber;

    constructor() ERC721A("Not Bored Ape Yoga Club", "NBAYC") {
        _mint(msg.sender, RESERVE_SUPPLY);
    }

    modifier supplyMintLimit(uint256 numberOfTokens) {
        require(!Address.isContract(msg.sender), "CONTRACT_MINT");
        require(numberOfTokens + totalSupply() <= MAX_SUPPLY, "EXCEED_SUPPLY");
        require(numberOfTokens + numberMinted(msg.sender) <= MINT_LIMIT, "EXCEED_MINT_LIMIT");
        require(numberOfTokens <= TRANSACTION_LIMIT, "EXCEED_TX_LIMIT");
        _;
    }

    modifier mintCompliance(uint256 amount) {
        require(isPublicSaleActive, "PUBLIC_MINT_IS_NOT_YET_ACTIVE");
        require(msg.value >= PUBLIC_PRICE * amount, "INVALID_AMOUNT");
        _;
    }

    //Essential
    function stretchDemLegs(uint256 legs) external payable supplyMintLimit(legs) mintCompliance(legs) {
        _mint(msg.sender, legs);
        mintedNumber[msg.sender] += legs;
        uint256 overStretched = msg.value - (PUBLIC_PRICE * legs);

        if (overStretched > 0) {
            (bool success, ) = msg.sender.call{value: overStretched}("");
            require(success, "FAILED_TO_REFUND");
        }
    }

    function numberMinted(address owner) public view returns (uint256) {
        return mintedNumber[owner];
    }

    // Admin

    function devMint(address[] memory _addresses, uint256[] memory quantities) external onlyOwner {
        require(_addresses.length == quantities.length, "WRONG_PARAMETERS");
        uint256 totalTokens = 0;
        for (uint256 i = 0; i < quantities.length; i++) {
            totalTokens += quantities[i];
        }
        require(totalTokens + totalSupply() <= MAX_SUPPLY, "NOT_ENOUGH_SUPPLY");
        for (uint256 i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], quantities[i]);
        }
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setPublicSaleStatus() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(owner()).transfer(address(this).balance);
    }

    function setPublicPrice(uint256 _publicPrice) external onlyOwner {
        PUBLIC_PRICE = _publicPrice;
    }

    function decreaseSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply < MAX_SUPPLY, "CANT_INCREASE_SUPPLY");
        MAX_SUPPLY = _maxSupply;
    }

    function setApeLimit(uint256 _mintLimit) external onlyOwner {
        MINT_LIMIT = _mintLimit;
    }

    function setTransactionLimit(uint256 _transactionLimit) external onlyOwner {
        TRANSACTION_LIMIT = _transactionLimit;
    }

    function burn(uint256[] calldata tokenIds) external onlyOwner {
        require(tokenIds.length > 0, "NO_TOKEN_IDS_PROVIDED");
        for (uint256 i; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}