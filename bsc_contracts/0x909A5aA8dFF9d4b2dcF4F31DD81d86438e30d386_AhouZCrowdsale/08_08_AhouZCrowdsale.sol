// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * To buy AhouZ user must be Whitelisted
 * Add user address and value to Whitelist
 * Remove user address from Whitelist
 * Check if User is Whitelisted
 * Check if User have equal or greater value than Whitelisted
 */

library Whitelist {
    struct List {
        mapping(address => bool) registry;
        mapping(address => uint256) amount;
    }

    function addUserWithValue(
        List storage list,
        address _addr,
        uint256 _value
    ) internal {
        list.registry[_addr] = true;
        list.amount[_addr] = _value;
    }

    function add(List storage list, address _addr) internal {
        list.registry[_addr] = true;
    }

    function remove(List storage list, address _addr) internal {
        list.registry[_addr] = false;
        list.amount[_addr] = 0;
    }

    function check(
        List storage list,
        address _addr
    ) internal view returns (bool) {
        return list.registry[_addr];
    }

    function checkValue(
        List storage list,
        address _addr,
        uint256 _value
    ) internal view returns (bool) {
        /**
         * divided by  10^18 because bnb decimal is 18
         * and conversion to bnb to uint256 is carried out
         */

        return list.amount[_addr] >= _value;
    }
}

/**
 * Contract to whitelist User for buying token
 */
contract Whitelisted is Ownable {
    Whitelist.List private _list;
    uint256 decimals = 1000000000000000000;
    address public whitelister;

    modifier onlyWhitelisted() {
        require(Whitelist.check(_list, msg.sender) == true);
        _;
    }

    modifier onlyWhitelister() {
        require(msg.sender == whitelister);
        _;
    }

    event AddressAdded(address _addr);
    event AddressRemoved(address _addr);
    event AddressReset(address _addr);

    /**
     * Add User to Whitelist with bnb amount
     * @param _address User Wallet address
     * @param amount The amount of bnb user Whitelisted in wei
     */
    function addWhiteListAddress(
        address _address,
        uint256 amount
    ) public onlyWhitelister {
        require(!isAddressWhiteListed(_address));

        Whitelist.addUserWithValue(_list, _address, amount);

        emit AddressAdded(_address);
    }

    /**
     * Set User's Whitelisted bnb amount to 0 so that
     * during second buy transaction user won't need to
     * validate for Whitelisted amount
     */
    function resetUserWhiteListAmount() internal {
        Whitelist.addUserWithValue(_list, msg.sender, 0 ether);
        emit AddressReset(msg.sender);
    }

    /**
     * Disable User from Whitelist so user can't buy token
     * @param _addr User Wallet address
     */
    function disableWhitelistAddress(address _addr) public onlyOwner {
        Whitelist.remove(_list, _addr);
        emit AddressRemoved(_addr);
    }

    /**
     * Check if User is Whitelisted
     * @param _addr User Wallet address
     */
    function isAddressWhiteListed(address _addr) public view returns (bool) {
        return Whitelist.check(_list, _addr);
    }

    /**
     * Check if User has enough bnb amount in Whitelisted to buy token
     * @param _addr User Wallet address
     * @param amount The amount of bnb user inputed
     */
    function isWhiteListedValueValid(
        address _addr,
        uint256 amount
    ) public view returns (bool) {
        return Whitelist.checkValue(_list, _addr, amount);
    }

    /**
     * Check if User is valid to buy token
     * @param _addr User Wallet address
     * @param amount The amount of bnb user inputed
     */
    function isValidUser(
        address _addr,
        uint256 amount
    ) public view returns (bool) {
        return
            isAddressWhiteListed(_addr) &&
            isWhiteListedValueValid(_addr, amount);
    }

    /**
     * returns the total amount of the address hold by the user during white list
     */
    function getUserAmount(address _addr) public view returns (uint256) {
        require(isAddressWhiteListed(_addr));
        return _list.amount[_addr];
    }

    /**
     * change whitelister address
     */
    function transferWhitelister(address newWhitelister) public onlyOwner {
        whitelister = newWhitelister;
    }
}

contract AhouZCrowdsale is Whitelisted {
    using SafeMath for uint256;

    AggregatorV3Interface internal priceFeed;
    address public beneficiary;
    uint256 public amountRaised;
    uint256[2] public seedSaleDates;
    uint256[2] public privateSale1Dates;
    uint256[2] public privateSale2Dates;
    uint256[2] public publicSaleDates;
    uint256 public fundTransferred;
    uint256 public tokenSold;
    uint256 public tokenSoldWithBonus;
    uint256[4] public price;
    ERC20 public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool public crowdsaleClosed = false;
    bool public returnFunds = false;

    event GoalReached(address recipient, uint256 totalAmountRaised);
    event FundTransfer(address backer, uint256 amount, bool isContribution);

    constructor(
        address _priceFeed,
        address _beneficiary,
        address _tokenReward
    ) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        beneficiary = _beneficiary;
        seedSaleDates = [1666224000, 1671494400];
        privateSale1Dates = [1671494400, 1679270400];
        privateSale2Dates = [1679270400, 1687219200];
        publicSaleDates = [1687219200, 1693267200];
        // price should be in 10^18 format.
        price = [
            500000000000000,
            550000000000000,
            600000000000000,
            750000000000000
        ];
        tokenReward = ERC20(_tokenReward);
    }

    function GetRewardAmount(
        uint256 _amount,
        uint256 _price
    ) public view returns (uint256) {
        uint256 priceOfEth = uint256(GetLatestPrice());
        uint256 cost = priceOfEth.div(_price);
        uint256 amount = _amount.mul(cost);
        return amount;
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    fallback() external payable {}

    receive() external payable {
        // custom function code
        uint256 bonus = 0;
        uint256 bonusPercent = 0;
        uint256 amount = 0;
        uint256 amountWithBonus = 0;
        uint256 ethamount = msg.value;

        require(!crowdsaleClosed);

        require(isValidUser(msg.sender, ethamount));

        //add bonus for funders
        if (
            block.timestamp >= seedSaleDates[0] &&
            block.timestamp <= seedSaleDates[1]
        ) {
            amount = GetRewardAmount(ethamount, price[0]);
            bonusPercent = GetBonusForSeedSale();
        } else if (
            block.timestamp >= privateSale1Dates[0] &&
            block.timestamp <= privateSale1Dates[1]
        ) {
            amount = GetRewardAmount(ethamount, price[1]);
            bonusPercent = GetBonusForPrivateSale1();
        } else if (
            block.timestamp >= privateSale2Dates[0] &&
            block.timestamp <= privateSale2Dates[1]
        ) {
            amount = GetRewardAmount(ethamount, price[2]);
            bonusPercent = GetBonusForPrivateSale2();
        } else if (
            block.timestamp >= publicSaleDates[0] &&
            block.timestamp <= publicSaleDates[1]
        ) {
            amount = GetRewardAmount(ethamount, price[3]);
            bonusPercent = GetBonusForPublicSale();
        }

        bonus = (amount * bonusPercent) / 100;
        amountWithBonus = amount.add(bonus);

        balanceOf[msg.sender] = balanceOf[msg.sender].add(ethamount);
        amountRaised = amountRaised.add(ethamount);

        tokenReward.transfer(msg.sender, amountWithBonus);
        tokenSold = tokenSold.add(amount);
        tokenSoldWithBonus = tokenSoldWithBonus.add(amountWithBonus);

        resetUserWhiteListAmount();
        emit FundTransfer(msg.sender, ethamount, true);
    }

    function GetBonusForSeedSale() private view returns (uint256) {
        uint256 saleDuration = seedSaleDates[1] - seedSaleDates[0];
        uint256 meanPoint = (saleDuration / 2) + seedSaleDates[0];
        if (block.timestamp <= meanPoint) {
            return 25;
        }
        return 23;
    }

    function GetBonusForPrivateSale1() private view returns (uint256) {
        uint256 saleDuration = privateSale1Dates[1] - privateSale1Dates[0];
        uint256 meanPoint = (saleDuration / 2) + privateSale1Dates[0];
        if (block.timestamp <= meanPoint) {
            return 20;
        }
        return 18;
    }

    function GetBonusForPrivateSale2() private view returns (uint256) {
        uint256 saleDuration = privateSale2Dates[1] - privateSale2Dates[0];
        uint256 meanPoint = (saleDuration / 2) + privateSale2Dates[0];
        if (block.timestamp <= meanPoint) {
            return 15;
        }
        return 12;
    }

    function GetBonusForPublicSale() private view returns (uint256) {
        uint256 saleDuration = publicSaleDates[1] - publicSaleDates[0];
        uint256 meanPoint = (saleDuration / 2) + publicSaleDates[0];
        if (block.timestamp <= meanPoint) {
            return 10;
        }
        return 5;
    }

    modifier AfterDeadline() {
        if (block.timestamp >= publicSaleDates[1]) _;
    }

    function GetLatestPrice() public view returns (int) {
        (
            ,
            /*uint80 roundID*/ int answer /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData();
        return answer * 10 ** 10;
    }

    /**
     *ends the campaign after deadline
     */

    function EndCrowdsale() public AfterDeadline onlyOwner {
        crowdsaleClosed = true;
    }

    function EnableReturnFunds() public onlyOwner {
        returnFunds = true;
    }

    function DisableReturnFunds() public onlyOwner {
        returnFunds = false;
    }

    function BonusSent() public view returns (uint256) {
        return tokenSoldWithBonus - tokenSold;
    }

    /**
     * seed sale price
     * private sale 1 price
     * private sale 2 price
     * public sale price
     */
    function ChangeSalePrices(
        uint256 _seed_price,
        uint256 _privatesale1_price,
        uint256 _privatesale2_price,
        uint256 _publicsale_price
    ) public onlyOwner {
        price[0] = _seed_price;
        price[1] = _privatesale1_price;
        price[2] = _privatesale2_price;
        price[3] = _publicsale_price;
    }

    function ChangeAggregator(address _priceFeed) public onlyOwner {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function ChangeBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    function ChangeSeedSaleDates(
        uint256 _seedSaleStartdate,
        uint256 _seedSaleDeadline
    ) public onlyOwner {
        if (_seedSaleStartdate != 0) {
            seedSaleDates[0] = _seedSaleStartdate;
        }
        if (_seedSaleDeadline != 0) {
            seedSaleDates[1] = _seedSaleDeadline;
        }

        if (crowdsaleClosed == true) {
            crowdsaleClosed = false;
        }
    }

    function ChangePrivateSale1Dates(
        uint256 _privateSale1Startdate,
        uint256 _privateSale1Deadline
    ) public onlyOwner {
        if (_privateSale1Startdate != 0) {
            privateSale1Dates[0] = _privateSale1Startdate;
        }
        if (_privateSale1Deadline != 0) {
            privateSale1Dates[1] = _privateSale1Deadline;
        }

        if (crowdsaleClosed == true) {
            crowdsaleClosed = false;
        }
    }

    function ChangePrivateSale2Dates(
        uint256 _privateSale2Startdate,
        uint256 _privateSale2Deadline
    ) public onlyOwner {
        if (_privateSale2Startdate != 0) {
            privateSale2Dates[0] = _privateSale2Startdate;
        }
        if (_privateSale2Deadline != 0) {
            privateSale2Dates[1] = _privateSale2Deadline;
        }

        if (crowdsaleClosed == true) {
            crowdsaleClosed = false;
        }
    }

    function ChangeMainSaleDates(
        uint256 _mainSaleStartdate,
        uint256 _mainSaleDeadline
    ) public onlyOwner {
        if (_mainSaleStartdate != 0) {
            publicSaleDates[0] = _mainSaleStartdate;
        }
        if (_mainSaleDeadline != 0) {
            publicSaleDates[1] = _mainSaleDeadline;
        }

        if (crowdsaleClosed == true) {
            crowdsaleClosed = false;
        }
    }

    /**
     * Get all the remaining token back from the contract
     */
    function GetTokensBack() public onlyOwner {
        require(crowdsaleClosed);

        uint256 remaining = tokenReward.balanceOf(address(this));
        tokenReward.transfer(beneficiary, remaining);
    }

    /**
     * User can get their bnb back if crowdsale didn't meet it's requirement
     */
    function SafeWithdrawal() public AfterDeadline {
        if (returnFunds) {
            uint256 amount = balanceOf[msg.sender];
            if (amount > 0) {
                if (payable(msg.sender).send(amount)) {
                    emit FundTransfer(msg.sender, amount, false);
                    balanceOf[msg.sender] = 0;
                    fundTransferred = fundTransferred.add(amount);
                }
            }
        }

        if (returnFunds == false && beneficiary == msg.sender) {
            uint256 ethToSend = amountRaised - fundTransferred;
            if (payable(beneficiary).send(ethToSend)) {
                fundTransferred = fundTransferred.add(ethToSend);
            }
        }
    }
}