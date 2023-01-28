//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.x;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IIERC20 is IERC20{
    function burn(uint256 amount) external;
    function decimals() external view returns (uint8);
}

contract CodoPresale is Ownable, ReentrancyGuard {
    using SafeERC20 for IIERC20;
    using SafeMath for uint256;

    uint256 public endTier;    
    IIERC20 public token;
    address payable public collectedFunds;
    bool public saleActive;
    bool public claimStarted;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public totalTokenAmountSent;
    uint256 public tokenAmountSentPerTier;
    mapping(address => uint256) public investors;
    mapping(uint256 => uint256) public tierPrices;
    mapping(uint256 => uint256) public tierSupply;
    uint256 public currentTier;
    uint256 public totalSupply;
    uint256 public totalFunds;

    event NewInvestment(address investor, uint256 value);
    event TokensSent(address receiver, uint256 amount);
    event TokensBurned(uint256 amount);
    event TierChanged(uint256 newTier);
    event TierPricesChanged(uint256 tier, uint256 value);
    event TierSupplyChanged(uint256 tier, uint256 value);
    event SaleStarted();
    event SaleEnded();
    event ClaimStarted();

    constructor() {
        collectedFunds = payable(address(0x40eAc2b844b8710C08Cff35eCEBe205d578F60f5));
        saleActive = false;
        claimStarted = false;
        currentTier = 1;
        startTime = 0;
        endTime = 0;
        totalTokenAmountSent = 0;
        tokenAmountSentPerTier = 0;

        // Set up tier prices and supply
        tierPrices[1] = 13e-6 ether;
        tierPrices[2] = 14e-6 ether;
        tierPrices[3] = 15e-6 ether;
        tierPrices[4] = 16e-6 ether;
        tierPrices[5] = 17e-6 ether;
        tierPrices[6] = 18e-6 ether;
        tierPrices[7] = 19e-6 ether;
        tierPrices[8] = 20e-6 ether;
        tierPrices[9] = 21e-6 ether;
        tierPrices[10] = 22e-6 ether;

        tierSupply[1] = 2e7;
        tierSupply[2] = 2e7;
        tierSupply[3] = 3e7;
        tierSupply[4] = 3e7;
        tierSupply[5] = 4e7;
        tierSupply[6] = 6e7;
        tierSupply[7] = 7e7;
        tierSupply[8] = 7e7;
        tierSupply[9] = 8e7;
        tierSupply[10] = 8e7;

        endTier = 10;
        totalSupply = 50e7;
        totalFunds = 0;
    }

    function setToken(address _token) external onlyOwner {
        require(_token != address(0));
        token = IIERC20(_token);
    }

    function startSale(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(!saleActive);
        require(_startTime >= block.timestamp, "Sale Start Time: INVALID_VALUE");
        require(_endTime > _startTime, "Sale End Time: INVALID_VALUE");
        startTime = _startTime;
        endTime = _endTime;
        saleActive = true;

        emit SaleStarted();
    }

    function endSale() external onlyOwner {
        require(saleActive);
        saleActive = false;

        emit SaleEnded();
    }

    function buy() public nonReentrant payable {
        require(msg.value >= tierPrices[currentTier]);
        require(saleActive);
        require(block.timestamp >= startTime, "Token Sale Time: TOO_SOON");
        require(block.timestamp <= endTime, "Token Sale Time: TOO_LATE");

        uint256 decimal = token.decimals();
        uint256 one = 10 ** decimal;
        uint256 tokensToBuy = one * msg.value.div(tierPrices[currentTier]);
        require(tokensToBuy <= one * tierSupply[currentTier] - tokenAmountSentPerTier, "Token Sale: Token Balance Not Sufficient");

        investors[msg.sender] = investors[msg.sender].add(tokensToBuy);
        tokenAmountSentPerTier = tokenAmountSentPerTier.add(tokensToBuy);
        totalTokenAmountSent = totalTokenAmountSent.add(tokensToBuy);

        totalFunds = totalFunds.add(msg.value);
        collectedFunds.transfer(msg.value);

        emit NewInvestment(msg.sender, msg.value);

        if (tokenAmountSentPerTier >= one * tierSupply[currentTier]) {
            currentTier = currentTier + 1;
            tokenAmountSentPerTier = 0;
            emit TierChanged(currentTier);
        }
    }

    function startClaim() external onlyOwner {
        require(!claimStarted);
        require(!saleActive);
        claimStarted = true;

        emit ClaimStarted();
    }

    function claim() public nonReentrant {
        require(claimStarted, "Token Sale: Claiming Not Enabled");

        uint256 tokensToClaim = investors[msg.sender];
        require(tokensToClaim > 0, "Token Sale: No Claimalble Token");
        require(token.balanceOf(address(this)) >= tokensToClaim, "Token Sale: Token Balance Not Sufficient");

        require(token.transfer(msg.sender, tokensToClaim));
        delete investors[msg.sender];
        
        emit TokensSent(msg.sender, tokensToClaim);
    }

    function burnUnsoldTokens() external onlyOwner {
        // require(!claimStarted);
        require(!saleActive);

        uint remainsAmount = token.balanceOf(address(this));
        require(remainsAmount > 0, "Token Sale: No Burnable Token");

        token.burn(remainsAmount);

        emit TokensBurned(remainsAmount);
    }

    function changeCollectedFunds(address payable newCollectedFunds) external onlyOwner {
        require(newCollectedFunds != address(0));
        collectedFunds = newCollectedFunds;
    }

    function getTierPrice(uint256 tier) public view returns (uint256) {
        return tierPrices[tier];
    }

    function setTierPrice(uint256 tier, uint256 value) external onlyOwner {
        require(tier >= currentTier, "Presale Token: Tier must be greater than currentTier");
        require(value > 0, "Presale Token: Invalid Price");

        if(tier > endTier) endTier = tier;

        tierPrices[tier] = value;

        emit TierPricesChanged(tier, value);
    }

    function getTierSupply(uint256 tier) public view returns (uint256) {
        return tierSupply[tier];
    }

    function setTierSupply(uint256 tier, uint256 value) external onlyOwner {
        require(tier >= currentTier, "Presale Token: Tier must be greater than currentTier");
        require(value > 0, "Presale Token: Invalid Supply");

        if(tier > endTier) endTier = tier;

        totalSupply = totalSupply.sub(tierSupply[tier]);
        totalSupply = totalSupply.add(value);
        tierSupply[tier] = value;

        emit TierSupplyChanged(tier, value);
    }

    function getRemaindTokenAmount() public view returns (uint256) {
        uint256 decimal = token.decimals();
        uint256 one = 10 ** decimal;
        return one * tierSupply[currentTier] - tokenAmountSentPerTier;
    }

    function getEndTier() public view returns (uint256) {
        return endTier;
    }

    function getCurrentTier() public view returns (uint256) {
        return currentTier;
    }

    function setTier(uint256 newTier) external onlyOwner {
        require(newTier >= currentTier, "Presale Token: Tier must be greater than currentTier");
        require(newTier <= endTier, "Presale Token: Tier must be less than currentTier");

        currentTier = newTier;

        emit TierChanged(currentTier);
    }

    function getTotalSoldAmount() public view returns (uint256) {
        return totalTokenAmountSent;
    }

    function getUserBalance(address _account) public view returns (uint256) {
        return investors[_account];
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function getTotalFunds() public view returns (uint256) {
        return totalFunds;
    }
}