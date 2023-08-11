// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Presale is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    AggregatorV3Interface internal priceFeed;

    struct Phase {
        uint256 tokensAvailable;
        uint256 tokensSold;
        uint256 tokenPrice;
        uint256 minPurchase;
        uint256 maxPurchase;
    }

    mapping(uint256 => Phase) public phases;
    mapping(address => bool) public whitelist; // Addresses whitelisted for Phase 0
    mapping(address => uint256) public balances; // Balances of buyers

    IERC20 public token; // The token being sold
    IERC20 public weth;
    IERC20 public usdc;
    uint256 public endTime; // End time of presale
    uint256 public currentPhase = 0;

    bool public claimingEnabled = false;
    bool public whitelistEnabled = true;

    event TokensPurchased(
        address indexed buyer,
        uint256 amount,
        uint256 totalPrice
    );
    event TokensClaimed(address indexed buyer, uint256 amount);
    event ClaimingEnabled(bool enabled);
    event Whitelisted(address indexed account);

    modifier claimEnabled() {
        require(claimingEnabled, "Claiming is currently disabled");
        _;
    }

    constructor(
        IERC20 _token,
        uint256 _endTime,
        IERC20 _weth,
        IERC20 _usdc,
        address _priceFeed
    ) {
        // Aggregator: ETH/USD
        priceFeed = AggregatorV3Interface(_priceFeed);

        token = _token;
        endTime = _endTime;
        weth = _weth;
        usdc = _usdc;

        // Phase 0
        phases[0] = Phase({
            minPurchase: 3_000 * 10 ** 18, // 3000 token for test
            // minPurchase:  3_000 * 10 ** 18, // 300 token,
            maxPurchase: 25_000 * 10 ** 18, // 25000 token,
            tokensAvailable: 7_500_000 * 10 ** 18, // 7.5M token,
            tokenPrice: 0.01 * 10 ** 18, // 0.01 USD,
            tokensSold: 0
        });

        // Phase 1
        phases[1] = Phase({
            minPurchase: 3_000 * 10 ** 18, // 3000 token for test
            // minPurchase: 3_000 * 10 ** 18, // 300 token,
            maxPurchase: 50_000 * 10 ** 18, // 50000 token,
            tokensAvailable: 6_000_000 * 10 ** 18, // 6M token,
            tokenPrice: 0.012 * 10 ** 18, // 0.012 USD,
            tokensSold: 0
        });

        // Phase 2
        phases[2] = Phase({
            minPurchase: 2_000 * 10 ** 18, // 2000 token for test
            // minPurchase: 200000000000000000000, // 200 token
            maxPurchase: 75_000 * 10 ** 18, // 75000 token,
            tokensAvailable: 4_500_000 * 10 ** 18, // 4.5M token,
            tokenPrice: 0.014 * 10 ** 18, // 0.014 USD,
            tokensSold: 0
        });

        // Phase 3
        phases[3] = Phase({
            minPurchase: 2_000 * 10 ** 18, // 2000 token for test
            // minPurchase: 200000000000000000000, // 200 token
            maxPurchase: 75_000 * 10 ** 18, // 75000 token,
            tokensAvailable: 3_000_000 * 10 ** 18, // 3M token,
            tokenPrice: 0.016 * 10 ** 18, // 0.016 USD,
            tokensSold: 0
        });

        // Phase 4
        phases[4] = Phase({
            minPurchase: 1_000 * 10 ** 18, // 1000 token for test
            // minPurchase: 100000000000000000000, // 100 token
            maxPurchase: 100_000 * 10 ** 18, // 100000 token,
            tokensAvailable: 1_500_000 * 10 ** 18, // 1.5M token,
            tokenPrice: 0.018 * 10 ** 18, // 0.018 USD,
            tokensSold: 0
        });
    }

    /**
     * Returns the latest price.
     */
    function getETHLatestPrice() public view returns (uint256) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        // ETH has 8 decimals
        return (uint256(price) * 10 ** 18) / 10 ** 8;
    }

    // Whitelist function for Phase 0
    function whitelistAddresses(
        address[] calldata _addresses
    ) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(
                _addresses[i] != address(0),
                "Whitelist address must be valid"
            );

            whitelist[_addresses[i]] = true;
            emit Whitelisted(_addresses[i]);
        }
    }

    function setEndTime(uint256 _endTime) external onlyOwner {
        endTime = _endTime;
    }

    function setWhitelistAbility(bool _enable) external onlyOwner {
        whitelistEnabled = _enable;
    }

    function getTotalBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getCurrentPhase() public view returns (Phase memory) {
        return phases[currentPhase];
    }

    function setCurrentPhase(uint256 _phase) external onlyOwner {
        require(_phase < 5, "Invalid phase number");
        currentPhase = _phase;
    }

    function enableClaiming(bool _enabled) external onlyOwner {
        claimingEnabled = _enabled;
        emit ClaimingEnabled(_enabled);
    }

    function buyTokens(
        uint256 _amount,
        bool _isWithWETH
    ) public payable nonReentrant {
        require(
            block.timestamp < endTime || currentPhase < 5,
            "Presale has ended"
        );
        if (whitelistEnabled)
            require(whitelist[msg.sender], "You are not whitelisted");

        uint256 tokensToBuy = _amount;
        require(tokensToBuy > 0, "Invalid amount");

        // Check if investor is within the min/max range for the current phase
        uint256 min = phases[currentPhase].minPurchase;
        uint256 max = phases[currentPhase].maxPurchase;
        uint256 currentBalance = balances[msg.sender] + tokensToBuy;

        require(
            phases[currentPhase].tokensSold + tokensToBuy <=
                phases[currentPhase].tokensAvailable,
            "Insufficient token amount"
        );

        require(_amount >= min, "Amount is below minimum purchase");
        require(max == 0 || _amount <= max, "Amount is above maximum purchase");

        if (_isWithWETH) {
            // Transfer WETH from buyer to presale contract
            uint256 wethAllowance = weth.allowance(msg.sender, address(this));
            require(
                wethAllowance >=
                    (tokensToBuy * phases[currentPhase].tokenPrice) /
                        getETHLatestPrice(),
                "Insufficient WETH allowance"
            );

            bool transferSuccess = weth.transferFrom(
                msg.sender,
                address(this),
                (tokensToBuy * phases[currentPhase].tokenPrice) /
                    getETHLatestPrice()
            );
            require(transferSuccess, "WETH transfer failed");
        } else {
            // Transfer USDC from buyer to presale contract
            uint256 usdtAllowance = usdc.allowance(msg.sender, address(this));
            require(
                usdtAllowance >=
                    (tokensToBuy * phases[currentPhase].tokenPrice) / 10 ** 18,
                "Insufficient USDC allowance"
            );

            bool transferSuccess = usdc.transferFrom(
                msg.sender,
                address(this),
                (tokensToBuy * phases[currentPhase].tokenPrice) / 10 ** 18
            );
            require(transferSuccess, "USDC transfer failed");
        }

        // Update investor's investment amount and total amount raised
        balances[msg.sender] = currentBalance;

        phases[currentPhase].tokensSold += tokensToBuy;

        emit TokensPurchased(
            msg.sender,
            tokensToBuy,
            phases[currentPhase].tokenPrice
        );
    }

    function claimTokens(
        uint256 _timestamp
    ) external nonReentrant claimEnabled {
        require(
            block.timestamp > endTime && _timestamp > endTime,
            "Presale is still ongoing"
        );
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No tokens to claim");

        balances[msg.sender] = 0;
        token.transfer(msg.sender, balance);

        emit TokensClaimed(msg.sender, balance);
    }

    function withdrawFunds() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawWeth() external onlyOwner {
        require(
            weth.balanceOf(address(this)) > 0,
            "Insufficient funds to withdraw"
        );

        weth.safeTransfer(owner(), weth.balanceOf(address(this)));
    }

    function withdrawUsdc() external onlyOwner {
        require(
            usdc.balanceOf(address(this)) > 0,
            "Insufficient funds to withdraw"
        );

        usdc.safeTransfer(owner(), usdc.balanceOf(address(this)));
    }

    function withdrawToken() external onlyOwner {
        require(block.timestamp > endTime, "Presale is still ongoing");
        require(token.balanceOf(address(this)) > 0, "All tokens sold out");

        token.transfer(owner(), token.balanceOf(address(this)));
    }
}