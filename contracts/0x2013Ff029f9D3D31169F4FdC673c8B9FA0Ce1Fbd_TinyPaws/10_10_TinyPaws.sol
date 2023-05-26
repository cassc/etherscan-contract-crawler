// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TinyPaws is ERC1155, Ownable {

    enum SaleState {Inactive, PreOrder, Sale}
    struct PreOrderPlan {
        uint price;
        uint amount;
    }

    uint constant public TOKEN_ID = 0;
    uint constant public MAX_PREORDERS = 200;
    uint constant public TRADE_TOKEN_ID_OFFSET = 8000;
    uint constant public EXCLUSIVE_TOKEN_ID_OFFSET = 10000;

    SaleState public saleState;
    uint public mintPrice;
    uint public preOrdersCount;
    uint public maxNFTPerMint;
    uint public maxSupply;
    uint public tradeSupply;

    uint private mintedNFTs;
    uint private burnedNFTs;
    uint private tradeNFTsMinted;
    uint private exclusiveNFTsMinted;
    uint private tokensSupply;

    mapping(uint => PreOrderPlan) public preOrderPlans;

    constructor() ERC1155("https://meta.tinypawnft.com/meta/{id}") {
        preOrderPlans[1] = PreOrderPlan(0.04 ether, 1);
        preOrderPlans[2] = PreOrderPlan(0.07 ether, 2);
        preOrderPlans[3] = PreOrderPlan(0.1 ether, 3);

        saleState = SaleState.Inactive;
        mintPrice = 0.06 ether;
        maxSupply = 5000;
    }

    // Setters region
    function setURI(string memory uri) external onlyOwner {
        _setURI(uri);
    }

    function setMintPrice(uint _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setSaleState(SaleState _saleState) external onlyOwner {
        saleState = _saleState;
    }

    function setMaxNFTPerMint(uint _maxNFTPerMint) external onlyOwner {
        maxNFTPerMint = _maxNFTPerMint;
    }

    function setMaxSupply(uint _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setTradeSupply(uint _tradeSupply) external onlyOwner {
        tradeSupply = _tradeSupply;
    }

    function configure(
        uint _mintPrice,
        uint _maxNFTPerMint,
        SaleState _saleState,
        uint _maxSupply,
        uint _tradeSupply
    ) external onlyOwner {
        mintPrice = _mintPrice;
        maxNFTPerMint = _maxNFTPerMint;
        saleState = _saleState;
        tradeSupply = _tradeSupply;
        maxSupply = _maxSupply;
    }
    // End Setters region

    modifier maxSupplyCheck(uint amount)  {
        require(mintedNFTs + tokensSupply + amount <= maxSupply, "Tokens supply reached limit");
        require(amount <= maxNFTPerMint, "You can't mint more than maxNFTPerMint tokens");
        _;
    }

    // Pre order functions
    function sendTokens(address[] memory accounts, uint[] memory amounts) external onlyOwner {
        require(accounts.length == amounts.length, "accounts.length == amounts.length");
        for (uint i = 0; i < accounts.length; i++) {
            mintTokens(accounts[i], amounts[i]);
        }
    }

    function preOrder(uint plan) external payable {
        require(saleState == SaleState.PreOrder, "PreOrder is not allowed");
        require(preOrdersCount < MAX_PREORDERS, "PreOrder ended");
        require(preOrderPlans[plan].amount != 0, "No such pre order plan");
        require(preOrderPlans[plan].price == msg.value, "Incorrect ethers value");

        preOrdersCount += 1;
        mintTokens(msg.sender, preOrderPlans[plan].amount);
    }

    function mintTokens(address account, uint amount) internal maxSupplyCheck(amount) {
        tokensSupply += amount;
        _mint(account, TOKEN_ID, amount, "");
    }

    function burnTokens(address account, uint amount) internal {
        _burn(account, TOKEN_ID, amount);
        tokensSupply -= amount;
    }
    // endregion

    // Mint and Claim functions
    function claim(uint amount) external {
        require(saleState == SaleState.Sale, "Claiming is not allowed");
        require(amount <= balanceOf(msg.sender, TOKEN_ID), "Insufficient tokens to claim such amount of nft");
        burnTokens(msg.sender, amount);
        mintNFTs(msg.sender, amount);
    }

    function mint(uint amount) external payable {
        require(saleState == SaleState.Sale, "Minting is not allowed");
        require(mintPrice * amount == msg.value, "Incorrect ethers value");
        mintNFTs(msg.sender, amount);
    }

    function airdrop(address[] memory accounts, uint[] memory amounts) external onlyOwner {
        require(accounts.length == amounts.length, "accounts.length == amounts.length");
        for (uint i = 0; i < accounts.length; i++) {
            mintNFTs(accounts[i], amounts[i]);
        }
    }

    function mintExclusive(address account) external onlyOwner {
        exclusiveNFTsMinted += 1;
        _mint(account, EXCLUSIVE_TOKEN_ID_OFFSET + exclusiveNFTsMinted, 1, "");
    }

    function mintNFTs(address account, uint amount) internal maxSupplyCheck(amount) {
        uint mintFrom = mintedNFTs + 1;
        mintedNFTs += amount;
        for (uint i = 0; i < amount; i++) {
            _mint(account, mintFrom + i, 1, "");
        }
    }
    // endregion

    // totalSupply for etherscan token tracker
    function totalSupply() external view returns (uint) {
        return mintedNFTs + tradeNFTsMinted - burnedNFTs + exclusiveNFTsMinted;
    }

    // trades
    function trade(uint[] memory tokens) external {
        require(tradeNFTsMinted < tradeSupply, "Trade tokens supply is out");
        require(tokens.length == 3, "Provide 3 tokens to get 1 from trade supply");
        for (uint i = 0; i < tokens.length; i++) {
            require(balanceOf(msg.sender, tokens[i]) > 0, "You must own tokens to burn them");
            _burn(msg.sender, tokens[i], 1);
        }
        burnedNFTs += 3;
        tradeNFTsMinted += 1;
        _mint(msg.sender, TRADE_TOKEN_ID_OFFSET + tradeNFTsMinted, 1, "");
    }

    // withdraw
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        uint share1 = balance * 15 / 100;
        payable(0x21C8CB6770975d7c49E0E66AA60B51588Da4dCA9).transfer(share1);
        payable(0xA26bcE5C479A8829c9233E1F087D500FB1C9019C).transfer(balance - share1);
    }
}