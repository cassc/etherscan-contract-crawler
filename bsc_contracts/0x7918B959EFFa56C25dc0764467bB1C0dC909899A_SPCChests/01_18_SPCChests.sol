// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SPCDust.sol";

contract SPCChests is ERC721, ERC721Enumerable, Ownable {
    bool public saleIsActive = false;

    uint256 public maxSupply = 777;
   
    uint256 public initialPricePerTokenBusd = 55 ether;
    uint256 public minBusdPrice = 15 ether;

    uint256 public busdChangeIntervalInSeconds = 3 * 60;
    uint256 public busdAmountToChangePerInterval = 5 ether;

    uint256 public pricePerTokenDust = 9999 ether;
    
    uint private lastMintTimestamp;
    string private _baseURIextended;
    uint256 public pricePerTokenBusd;

    SPCDust dustToken;
    ERC20 busdToken;

    constructor(
        address _busdTokenAddress, 
        address _dustTokenAddress
    ) ERC721("Space Cartels Equipment", "SPCEQ") {
        busdToken = ERC20(_busdTokenAddress);
        dustToken = SPCDust(_dustTokenAddress);

        pricePerTokenBusd = initialPricePerTokenBusd;
    }

    function setSaleIsActive(bool _saleIsActive) external onlyOwner {
        saleIsActive = _saleIsActive;
        lastMintTimestamp = block.timestamp;
    }

    function mintWithDust() external {
        uint256 ts = totalSupply();
        uint256 tokenBalance = dustToken.balanceOf(msg.sender);

        require(saleIsActive, "Sale must be active to mint tokens.");
        require(ts + 1 <= maxSupply, "Purchase would exceed max tokens.");
        require(pricePerTokenDust <= tokenBalance, "You don't have enough DUST.");

        dustToken.transferFrom(msg.sender, address(this), pricePerTokenDust);
        mint(ts);
    }

    function mintWithBusd(uint256 declaredBusdPrice) external {
        uint256 ts = totalSupply();
        uint256 tokenBalance = busdToken.balanceOf(msg.sender);
        
        checkBusdPrice();

        require(saleIsActive, "Sale must be active to mint tokens.");
        require(ts + 1 <= maxSupply, "Purchase would exceed max tokens.");
        require(pricePerTokenBusd <= tokenBalance, "You don't have enough BUSD.");
        require(pricePerTokenBusd <= declaredBusdPrice, "NFT price changed. Please try again.");

        busdToken.transferFrom(msg.sender, address(this), pricePerTokenBusd);
        mint(ts);
    }

    function mint(uint256 id) private {
        _safeMint(msg.sender, id);

        lastMintTimestamp = block.timestamp;
        pricePerTokenBusd = initialPricePerTokenBusd;
    }

    function checkBusdPrice() private {
        uint256 timestampDiff = block.timestamp - lastMintTimestamp;

        if(timestampDiff >= busdChangeIntervalInSeconds) {
            uint256 decreasePriceBy = timestampDiff / busdChangeIntervalInSeconds * busdAmountToChangePerInterval;

            unchecked {
                pricePerTokenBusd = initialPricePerTokenBusd - decreasePriceBy;

                if(pricePerTokenBusd < minBusdPrice || pricePerTokenBusd > initialPricePerTokenBusd) {
                    pricePerTokenBusd = minBusdPrice;
                }
            } 
        }
    }

    function setDustTokenAddress(address _dustTokenAddress) external onlyOwner {
        dustToken = SPCDust(_dustTokenAddress);
    }

    function setBusdTokenAddress(address _busdTokenAddress) external onlyOwner {
        busdToken = ERC20(_busdTokenAddress);
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setInitialPricePerTokenBusd(uint256 _initialPricePerTokenBusd) external onlyOwner {
        initialPricePerTokenBusd = _initialPricePerTokenBusd;
        pricePerTokenBusd = _initialPricePerTokenBusd;
    }

    function setPricePerTokenDust(uint256 _pricePerTokenDust) external onlyOwner {
        pricePerTokenDust = _pricePerTokenDust;
    }

    function setBusdAmountToChangePerInterval(uint256 _busdAmountToChangePerInterval) external onlyOwner {
        busdAmountToChangePerInterval = _busdAmountToChangePerInterval;
    }

    function setMinBusdPrice(uint256 _minBusdPrice) external onlyOwner {
        minBusdPrice = _minBusdPrice;
    }

    function setBusdChangeIntervalInSeconds(uint256 _busdChangeIntervalInSeconds) external onlyOwner {
        busdChangeIntervalInSeconds = _busdChangeIntervalInSeconds;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    function withdrawBusd() external onlyOwner { 
        uint256 busdBalance = busdToken.balanceOf(address(this));
        busdToken.transfer(msg.sender, busdBalance);
    }

    function burnDust() external onlyOwner {
        uint256 dustBalance = dustToken.balanceOf(address(this));
        dustToken.burn(dustBalance);
    }
}