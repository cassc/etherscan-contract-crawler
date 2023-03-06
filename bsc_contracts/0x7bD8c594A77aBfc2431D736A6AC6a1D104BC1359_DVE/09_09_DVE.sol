// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract DVE is ERC20, ERC20Burnable, Ownable, Pausable {
    struct Claim {
        uint256 unclaimed; // this is the amount of dividends that has not been claimed yet **IN BNB**
        uint256 lastUpdate; // this is the **blocktime** of the last dividend recalculation
    }

    mapping(address => Claim) public dividendClaims;

    uint256 internal constant ONE_MONTH = 30 days;
    uint256 public totalPendingDividends; // this is the total amount of dividends that has not been claimed yet **IN BNB**

    address public bnbUsdFeed;
    uint256 public lastBnbUsdPrice; // we refresh this every fill-up

    uint256 public dividendPctNumerator = 25; // default is 2.5%
    uint256 public dividendPctDenominator = 1000;

    // address of the sale contract
    // we keep track of this so that we can stop giving dividends to the sale contract
    address public sale = address(0);

    // The feed address for BNB/USD
    // on mainnet: 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
    // on testnet: 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
    constructor(uint256 initialSupply, address _bnbUsdFeed)
        ERC20("Dayvidende", "DVE")
        Ownable()
        Pausable()
    {
        require(
            _bnbUsdFeed != address(0),
            "USD to BNB feed address cannot be 0x0"
        );

        _mint(msg.sender, initialSupply);
        bnbUsdFeed = _bnbUsdFeed;
        lastBnbUsdPrice = getLatestBnbToUsd();
    }

    // ********** USER FUNCTIONS **********

    // This function is called by the user to claim their dividends
    // It will calculate the amount of dividends that the user is entitled to
    // and transfer it to the user's wallet
    function claimDividend() external whenNotPaused {
        recalculateClaim(msg.sender);

        Claim storage claim = dividendClaims[msg.sender];
        uint256 amountBnb = claim.unclaimed;
        claim.unclaimed = 0;

        totalPendingDividends -= amountBnb;

        (bool success, ) = msg.sender.call{value: amountBnb}("");
        require(success, "Transfer failed.");
    }

    // This function is called by the user to calculate the amount of dividends that they are entitled to
    function calculateMyDividend() external view returns (uint256 dayvidende) {
        dayvidende = calculateDividend(msg.sender, dividendClaims[msg.sender]);
    }

    // ********** OWNER FUNCTIONS **********

    // This function is called by the owner to set the dividend percentage
    function setDividendPercentage(uint256 numerator, uint256 denominator)
        external
        onlyOwner
    {
        require(
            numerator <= denominator,
            "Numerator cannot be greater than denominator"
        );
        dividendPctNumerator = numerator;
        dividendPctDenominator = denominator;
    }

    function mint(address to, uint256 amount) external onlyOwner whenNotPaused {
        _mint(to, amount);
    }

    function setSale(address _sale) external onlyOwner {
        Claim storage claim = dividendClaims[sale];
        claim.lastUpdate = 0;
        claim.unclaimed = 0;
        sale = _sale;
    }

    // ********** UTILITY FUNCTIONS **********

    function calculateDividend(address who, Claim storage claim)
        internal
        view
        returns (uint256 dividend)
    {
        // null and the sale contract don't get dividends
        if (who == address(0) || who == sale) {
            return 0;
        }

        if (claim.lastUpdate == 0) {
            return 0;
        }

        uint256 timeSinceLastUpdate = block.timestamp - claim.lastUpdate;
        uint256 newDividendUsd = (timeSinceLastUpdate *
            balanceOf(who) *
            dividendPctNumerator) / (ONE_MONTH * dividendPctDenominator);
        uint256 newDividendBnb = (newDividendUsd * 10**8) / lastBnbUsdPrice;

        dividend = claim.unclaimed + newDividendBnb;
    }

    // This function is internally called to recalculate the amount of dividends that the user is entitled to
    // and update it in the dividendClaims mapping
    function recalculateClaim(address who) internal {
        // null user doesn't get dividends
        if (who == address(0)) {
            return;
        }

        Claim storage claim = dividendClaims[who];

        uint256 oldDividend = claim.unclaimed;
        uint256 newDividend = calculateDividend(who, claim);

        totalPendingDividends += newDividend - oldDividend;

        claim.unclaimed = newDividend;
        claim.lastUpdate = block.timestamp;
    }

    function setPriceFeed(address _bnbUsdFeed) external onlyOwner {
        require(
            _bnbUsdFeed != address(0),
            "USD to BNB feed address cannot be 0x0"
        );

        bnbUsdFeed = _bnbUsdFeed;
    }

    // 1 BNB = getLatestPrice() / 10**8 USD
    function getLatestBnbToUsd() public view returns (uint256) {
        (, int256 price, , , ) = AggregatorV3Interface(bnbUsdFeed)
            .latestRoundData();
        return uint256(price); // 8 decimals
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 /*amount*/
    ) internal override whenNotPaused {
        recalculateClaim(from);
        recalculateClaim(to);
    }

    function withdraw() external onlyOwner whenPaused {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // we need to have the receive function to receive BNB
    receive() external payable {
        // if the owner sends BNB, we refresh the price
        if (msg.sender == owner()) {
            lastBnbUsdPrice = getLatestBnbToUsd();
        }
    }
}