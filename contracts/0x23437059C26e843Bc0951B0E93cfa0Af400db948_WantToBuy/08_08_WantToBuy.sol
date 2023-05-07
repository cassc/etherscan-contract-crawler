// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract WantToBuy is ERC20, ERC20Burnable, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 internal _totalSupply;

    address payable public devWallet;
    address public uniswapV2Pair;

    // Trying to limit bots
    mapping(address => bool) private blacklists;
    uint256 public maxPercentageHoldingAmount;

    // Exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;

    // Custom events
    event UpdateFees(uint256 lotteryPercentageFees);
    event UpdateMinHolding(uint256 minHoldingPercentageForDistribution);
    event FeesDistributed(address indexed recipient, uint256 amount);
    event UniswapPairAddressUpdated(address indexed pairAddress);

    // Lottery, time-based fee distribution
    uint256 public lotteryPercentageFees;
    uint256 public distributionInterval;
    uint256 public lastDistributionTime;
    uint256 public totalFees;
    uint256 public minHoldingPercentageForDistribution;
    EnumerableSet.AddressSet private holders;

    constructor(
        uint256 totalSupply,
        uint256 _lotteryPercentageFees,
        uint256 _distributionInterval, // in minutes
        uint256 _minHoldingPercentageForDistribution, // will be divided by 100. e.g. 0.01% = '1'/100
        uint256 _maxPercentageHoldingAmount
    ) ERC20("WantToBuy", "WTB") {
        _totalSupply = totalSupply * 10 ** decimals();
        lotteryPercentageFees = _lotteryPercentageFees;
        distributionInterval = _distributionInterval;
        minHoldingPercentageForDistribution =
            _minHoldingPercentageForDistribution /
            100;
        maxPercentageHoldingAmount = _maxPercentageHoldingAmount;

        devWallet = payable(0xfEb9e4323923693142fc23bDDB3f1132c96514D8);

        // exclude from paying fees or having max transaction amount
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[address(devWallet)] = true;
        _isExcludedFromFees[msg.sender] = true;

        // Add the owner to the list of holders
        holders.add(msg.sender);
        holders.add(devWallet);

        // mint 95% of tokens to contract creator
        uint256 devAmount = (_totalSupply * 5) / 100;
        _mint(msg.sender, _totalSupply - devAmount);
        // and 5% to dev wallet
        _mint(devWallet, devAmount);
    }

    /**
     * @dev Hook to limit bots
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!blacklists[to] && !blacklists[from], "Address blacklisted");
        if (to != owner() && to != devWallet) {
            require(
                super.balanceOf(to) + amount <=
                    (_totalSupply * maxPercentageHoldingAmount) / 100,
                "Max holding amount exceeded"
            );
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Override transfer function to put a fee in the lottery pool
     */
    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        uint256 lotteryAmount = (amount * lotteryPercentageFees) / 100;
        address owner = _msgSender();
        if (
            !_isExcludedFromFees[owner] &&
            !_isExcludedFromFees[to] &&
            lotteryAmount > 0
        ) {
            _transfer(owner, to, amount - lotteryAmount);
            _transfer(owner, address(this), lotteryAmount);
        } else {
            _transfer(owner, to, amount);
        }

        // If the recipient has a zero balance, add it to the list of holders
        if (balanceOf(to) == 0) {
            holders.add(to);
        }

        // Track total fees collected
        totalFees += lotteryAmount;

        return true;
    }

    /**
     * @dev Call the 'distributeFees' function if the distribution interval has been reached
     * and if it's a BUY transaction
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);
        if (
            block.timestamp >=
            lastDistributionTime + distributionInterval * 1 minutes &&
            to != uniswapV2Pair &&
            totalFees > 0
        ) {
            distributeFees();
        }
    }

    /**
     * @dev Distribute part of the fees to a lucky holder
     */
    function distributeFees() private returns (bool) {
        require(
            block.timestamp >=
                lastDistributionTime + distributionInterval * 1 minutes,
            "Distribution interval not reached yet"
        );
        require(totalFees > 0, "No fees collected for distribution");
        lastDistributionTime = block.timestamp;
        uint256 distributionAmount = totalFees / getRandomNumber(30); // Distribute up to 30% of total fees
        uint256 eligibleHoldersCount = 0;
        for (uint256 i = 0; i < holders.length(); i++) {
            address holder = holders.at(i);
            uint256 balance = balanceOf(holder);
            uint256 holdingPercentage = (balance * 10000) / _totalSupply;
            if (
                holdingPercentage >= minHoldingPercentageForDistribution &&
                !blacklists[holder]
            ) {
                eligibleHoldersCount++;
            }
        }
        if (eligibleHoldersCount == 0) {
            totalFees = 0;
            return false;
        }
        uint256 luckyIndex = getRandomNumber(eligibleHoldersCount);
        uint256 count = 0;
        for (uint256 i = 1; i < holders.length(); i++) {
            address holder = holders.at(i);
            uint256 balance = balanceOf(holder);
            uint256 holdingPercentage = (balance * 10000) / _totalSupply;
            if (
                holdingPercentage >= minHoldingPercentageForDistribution &&
                !blacklists[holder]
            ) {
                if (count == luckyIndex) {
                    _transfer(address(this), holder, distributionAmount);
                    emit FeesDistributed(holder, distributionAmount);
                    break;
                }
                count++;
            }
        }
        totalFees -= distributionAmount;
        return true;
    }

    /**
     * @dev Define max holding amount by wallet to prevent bots from owning too much liquidity,
     * can not be lower than 1% of the supply, and higher than 5% of the supply
     */
    function setMaxHoldingAmount(uint256 value) external onlyOwner {
        require(
            value < 1 || value > 5,
            "max tokens by wallet cannot be set to less than 1% and not more than 5%"
        );
        maxPercentageHoldingAmount = value;
    }

    /**
     * @dev Black list potential bad actors
     */
    function blacklist(
        address _address,
        bool _isBlacklisting
    ) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    /**
     * @dev Update lottery fees
     */
    function updateLotteryFees(uint256 fees) public onlyOwner {
        require(fees <= 5, "total lottery fees cannot exceed 5%");
        lotteryPercentageFees = fees;
        emit UpdateFees(lotteryPercentageFees);
    }

    /**
     * @dev Update min holding percentage for distribution
     */
    function updateMinHolding(uint256 amount) public onlyOwner {
        require(amount <= 100, "total lottery fees cannot exceed 1%");
        minHoldingPercentageForDistribution = amount;
        emit UpdateMinHolding(minHoldingPercentageForDistribution);
    }

    /**
     * @dev Update Uniswap V2 pair address
     */
    function updateUniswapPairAddress(address _address) public onlyOwner {
        uniswapV2Pair = _address;
        emit UniswapPairAddressUpdated(uniswapV2Pair);
    }

    /**
     * @dev Generate a random number between 0 and max
     */
    function getRandomNumber(uint max) internal view returns (uint) {
        uint randomNumber = (uint(
            keccak256(
                abi.encode(block.timestamp, block.prevrandao, block.number)
            )
        ) % max) + 1;
        return randomNumber;
    }

    receive() external payable {}
}