// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract DexHero is ERC20, Ownable {

    uint8 private MAX_MINT_BATCH = 12;
    uint128 private PRICE_USD = 0.01 ether;

    AggregatorV3Interface private _priceFeedETH; // ETH/USD
    IERC20 private _tokenUSD; // USD token

    constructor(
        string memory name,
        string memory symbol,
        address tokenUSDAddress,
        address priceFeedUSDAddress
    ) ERC20(name, symbol) {
        _priceFeedETH = AggregatorV3Interface(priceFeedUSDAddress);
        _tokenUSD = IERC20(tokenUSDAddress);
    }

    // ------------- Public Views methods -----------------

    function getPriceUsd() public view returns(uint256){
        return PRICE_USD;
    }

    function getMaxMintBatch() public view returns(uint256){
        return MAX_MINT_BATCH;
    }

    function getETHper1USD() public view returns (uint256) {
        (, int256 price, , , ) = _priceFeedETH.latestRoundData();
        return uint256(price);
    }

    function getUSDPerToken(uint8 count) public view returns (uint256){
        return count * PRICE_USD;
    }

    function getETHperToken(uint8 count) public view returns (uint256) {
        return PRICE_USD * ((getETHper1USD() * 1e6 )/1e18) / 1e6 * count;
    }

    // ---------- Internal Private methods -------------
    function mint(address to, uint32 mintAmount) private {
        uint256 timestamp = block.timestamp;
        require(mintAmount > 0, "cant mint 0 tokens");
        require(mintAmount <= MAX_MINT_BATCH, "max mint reached");
        uint256 balance= balanceOf(to);

        if(balance<timestamp)balance=timestamp;
        balance += (mintAmount * 2592000); // months
        _mint(to,balance);
    }


    function sendETH(address to, uint256 val) private {
        if (val > 0) {
            (bool success, ) = payable(to).call{value:val}("");
            require(success);
        }
    }
 
    // ----- External public write methods --------

    function buyForUSD(address to,uint8 mintAmount ) external {
        uint256 priceUSD = getUSDPerToken(mintAmount);
        _tokenUSD.transferFrom(msg.sender, address(this), priceUSD);
        mint(to, mintAmount);
    }

    function buyForETH( address to, uint8 mintAmount ) external payable {
        require(mintAmount>0);
        uint256 priceETH = getETHperToken(mintAmount);
        require(msg.value >= priceETH, "insuffucient value");
        mint(to, mintAmount);
        sendETH(msg.sender, msg.value - priceETH);
    }
    
    receive() external payable {
        uint256 priceETH = getETHperToken(1);
        uint8 mintAmount = uint8(msg.value / priceETH);
        require(mintAmount>1, "insuffucient value");
        priceETH *= mintAmount;
        mint(msg.sender, mintAmount);
        sendETH(msg.sender, msg.value - priceETH);
    }

    // ----- External onlyOwner methods --------

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        sendETH(msg.sender, balance);
        uint256 balanceUSD = _tokenUSD.balanceOf(address(this));
          _tokenUSD.transfer(msg.sender, balanceUSD);
    }

    function setMaxMintBatch(uint8 newMaxMintBatch) external onlyOwner {
        MAX_MINT_BATCH = newMaxMintBatch;
    }

    function setPriceFeed(address priceFeedUSDAddress) external onlyOwner {
        _priceFeedETH = AggregatorV3Interface(priceFeedUSDAddress);
    }

    function setPriceUsd( uint128 priceUsd ) external onlyOwner {
        require(priceUsd>=1e15,"priceUsd must be more than 0.001");
        PRICE_USD = priceUsd;
    }

    // ----- overrides

   function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(amount>0 && (from==address(0) || to==address(0)));
    }
}