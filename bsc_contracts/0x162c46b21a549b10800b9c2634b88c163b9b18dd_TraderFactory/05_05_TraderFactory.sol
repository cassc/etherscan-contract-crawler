// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AthTrader.sol";
import "./interfaces/ISHORTFACTORY.sol";


contract TraderFactory {


    // fee that goes to trader in %, example 50% = 50
    uint8 public traderFee = 50;

    // fee to be paid for creating a tradingContract
    uint public traderDeploymentFee = 0.1 ether;

    // array of all created tradingContracts
    address[] public traders;

    // address of owner
    address public owner;

    // address of AthStaking contract, used for checking level of users
    address public athLevel;

    // address of factory of shorts, independent because of space limitations
    address public shortFactory;

    /**
    * @dev returns the index of the trader in the traders array, mind that actual index is index - 1 because of the 0 default value
    */
    mapping(address => uint256) public traderIndex;

    /**
    * @dev mapping of allowedTokens for trading
    */
    mapping(address => bool) public AllowedTokens;

    /**
    * @dev Returns investor's fee in percentage  of given level
     */
    mapping(uint8 => uint8) public athLevelFee;

    /**
    * @dev Returns referrerFee in percentage  of given level
     */
    mapping(uint8 => uint8) public referrerFeeFromLevel;

    /**
    * @dev create instance of this contract
    * @param athLevel_ address of AthLevel contract
    * @param shortFactory_ address of shortFactory contract
     */
    constructor(address athLevel_, address shortFactory_) {
        owner = msg.sender;
        athLevel = athLevel_;
        shortFactory = shortFactory_;

    }

    // To check if accessed by an owner
    modifier onlyOwner() {
        isOwner();
        _;
    }


    /**
    * @dev set the address of shortFactory
    * @param shortFactory_ address of shortFactory contract
    * @notice only owner can call this function
     */
    function setShortFactory(address shortFactory_) external onlyOwner {
        shortFactory = shortFactory_;
    }

    /**
    * @dev set the address of AthLevel
    * @param athLevel_ address of AthLevel contract
    * @notice only owner can call this function
     */
    function setAthLevel(address athLevel_) external onlyOwner {
        athLevel = athLevel_;
    }

    /**
    * @dev add tokens to the list of allowed tokens for trading
    * @param tokens_ array of tokens to be added
    * @notice only owner can call this function
    */
    function addAllowedToken(address[] memory tokens_) external onlyOwner {
        for (uint256 i = 0; i < tokens_.length; i++) {
            AllowedTokens[tokens_[i]] = true;
        }
    }

    /**
    * @dev remove tokens from the list of allowed tokens for trading
    * @param tokens_ array of tokens to be removed
    * @notice only owner can call this function
    */
    function removeAllowedToken(address[] memory tokens_) external onlyOwner {
        for (uint256 i = 0; i < tokens_.length; i++) {
            AllowedTokens[tokens_[i]] = false;
        }
    }

    /**
    * @dev returns length of traders array
    */
    function tradersLength() external view returns (uint256) {
        return traders.length;
    }


    /**
    * @dev removes Trader from traders array and from traderIndex mapping by address
    * @param tradersToRemove_ array of traders addresses to be removed
    * @notice only owner can call this function
    */
    function removeTraderByAddress(address[] memory tradersToRemove_) external onlyOwner {
        for (uint256 i = 0; i < tradersToRemove_.length; i++) {
            require(traderIndex[tradersToRemove_[i]] != 0, "Trader not found");
            removeTraderByIndex(traderIndex[tradersToRemove_[i]] - 1);
        }

    }


    /**
    * @dev removes Trader from traders array and from traderIndex mapping by index
    * @param index_ index of trader to be removed
    * @notice only owner can call this function
    */
    function removeTraderByIndex(uint256 index_) public onlyOwner {
        if (index_ == traders.length - 1) {
            traderIndex[traders[index_]] = 0;
            traders.pop();
        } else {

            traderIndex[traders[index_]] = 0;
            traders[index_] = traders[traders.length - 1];
            traderIndex[traders[index_]] = index_ + 1;
            traders.pop();
        }
    }

    /**
    * @dev sets the fee that goes to trader in %, example 50% would be 50
    * @param fee_ fee that goes to trader in %
    * @notice only owner can call this function
    */
    function setTraderFee(uint8 fee_) external onlyOwner {
        traderFee = fee_;
    }

    /**
    * @dev sets the fee that  trader needs to pay for deploying a tradingContract
    * @param fee_ fee that trader needs to pay for deploying a tradingContract
    * @notice only owner can call this function
    */
    function setTraderDeploymentFee(uint fee_) external onlyOwner {
        traderDeploymentFee = fee_;
    }

    /**
    * @dev sets the fee that investor pays on profits in % for given level, example 50% would be 50
    * @param level_ array of levels
    * @param fee_ array of fees in % respective to levels
    * @notice only owner can call this function
    */
    function setAthLevelFee(
        uint8[] memory level_,
        uint8[] memory fee_
    ) external onlyOwner {
        require(level_.length == fee_.length, "Invalid input");
        for (uint8 i; i < level_.length; i++) {
            // Record fee for given level
            athLevelFee[level_[i]] = fee_[i];

            // Emit an event
            //            emit SetFee(level_[i], fee_[i]);
        }
    }

    /**
    * @dev sets the fee that referrer gets  in % for given level, example 50% would be 50
    * @param level_ array of levels
    * @param fee_ array of fees in % respective to levels
    * @notice only owner can call this function
    */
    function setReferrerFeeFromLevel(
        uint8[] memory level_,
        uint8[] memory fee_
    ) external onlyOwner {
        require(level_.length == fee_.length, "Invalid input");

        for (uint8 i; i < level_.length; i++) {
            // Record fee for given level
            referrerFeeFromLevel[level_[i]] = fee_[i];

            // Emit an event
            //            emit SetReferrerFee(level_[i], fee_[i]);
        }
    }


    /**
    * @dev deploy a trading contract
    * @param traderEOA_ address of trader
    */
    function createTrader(address traderEOA_) payable external returns (AthTrader) {
        // collect  fee from sender
        require(msg.value >= traderDeploymentFee, "Fee not paid");
        //        send fee to owner address
        payable(owner).transfer(msg.value);
        return _deployTrader(traderEOA_);
    }


    /**
    * @dev deploy a trading contract without fee
    * @notice only owner can call this function
    * @param traderEOA_ address of trader
    */
    function createTraderByOwner(address traderEOA_) external onlyOwner returns (AthTrader) {
        return _deployTrader(traderEOA_);
    }

    /**
    * @dev returns traders array
    */
    function getTraders() external view returns (address[] memory) {
        return traders;
    }
    /**
    * @dev internal function to deploy a trading contract
    * @param traderEOA_ address of trader
    */
    function _deployTrader(address traderEOA_) internal returns (AthTrader) {
        AthTrader trader = new AthTrader(athLevel, owner, traderEOA_);
        traders.push(address(trader));
        traderIndex[address(trader)] = traders.length;
        return trader;
    }

    /**
    * @dev deploy and associate a short contract with a trading contract
    * @param traderContract_ address of traderContract to be associated with
    */
    function addShortToTrader(address traderContract_) external {
        AthTrader trader = AthTrader(traderContract_);

        require(traderIndex[traderContract_] != 0, "Trader not found");
        require(trader.owner() == msg.sender || trader.trader() == msg.sender, "Only owner can add short");
        require(trader.shortOrderContract() == address(0), "Short already added");
        require(trader.fundingStartTime() > 0, "Trader not initialized");

        address shortContract = ISHORTFACTORY(shortFactory).createShort(
            trader.fundingStartTime(),
            traderContract_,
            trader.trader(),
            trader.participationToken()
        );

        trader.setShortOrderContractAddr(shortContract);
    }


    /**
    * @dev set owner of this contract
    * @param newOwner_ address of new owner
    * @notice only owner can call this function
    */
    function transferOwnership(address newOwner_) external onlyOwner {
        owner = newOwner_;
    }

    /**
	 * * @dev view function to check msg.sender is owner
     */
    function isOwner() internal view {
        require(owner == msg.sender, "Not an owner");
    }
}