// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./CappedCrowdsale.sol";
import "./TimedCrowdsale.sol";
import "./Crowdsale.sol";
import "./CrowdsaleAccessControl.sol";
import "../Inventory/CCOFInventory.sol";

contract CCOFPublicsale is
    Crowdsale,
    TimedCrowdsale,
    CappedCrowdsale,
    CrowdsaleAccessControl
{
    /**
     * @dev txTokenLimit token limit per transaction
     */
    uint256 public immutable txTokenLimit = 2;

    mapping(address => uint256) public lastBlockNumber;

    CCOFInventory public inventory;

    /**
     * @dev owner can set new opening time through the setter function
     * @param _openingTime new opening time of the crowdsale
     */

    function setOpeningTime(uint256 _openingTime) public onlyOwner {
        openingTime = _openingTime;
    }

    /**
     * @dev owner can set new closing time through the setter function
     * @param _closingTime new closing time of the crowdsale
     */

    function setClosingTime(uint256 _closingTime) public onlyOwner {
        closingTime = _closingTime;
    }

    /**
     * @dev owner can set new price through the setter function
     * @param _price new price  of the token
     */

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    /**
     * Constructor.
     * @param _inventory addresss of the inventory contract
     * @param _cap total supply of tokens
     * @param _openingTime start time of the crowdsale
     * @param _closingTime end time of the crowdsale
     * @param _price price of the token.
     * @param _treasury wallet where all collected funds are stored
     */

    constructor(
        address _inventory,
        uint256 _cap,
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _price,
        address payable _treasury
    )
        CrowdsaleAccessControl()
        Crowdsale(_price, _treasury)
        CappedCrowdsale(_cap)
        TimedCrowdsale(_openingTime, _closingTime)
    {
        inventory = CCOFInventory(_inventory);
    }

    /**
     * @dev Executed when a user is buying tokens
     */
    function buyTokensPublicsale() external payable {
        require(
            lastBlockNumber[msg.sender] < block.number,
            "ERROR: multiple mint transactions"
        );
        require(msg.sender == tx.origin, "ERROR: msg sender not EOA");
        lastBlockNumber[msg.sender] = block.number;
        buyTokens();
    }

    function _getTokenAmount(
        address _beneficiary,
        uint256 _weiAmount,
        uint256 _price
    ) internal override(Crowdsale) returns (uint256) {
        uint256 tokenAmount = super._getTokenAmount(
            _beneficiary,
            _weiAmount,
            _price
        );

        if ((tokenSold + tokenAmount) > cap) {
            tokenAmount = cap - tokenSold;
        }
        if (tokenAmount > txTokenLimit) {
            return txTokenLimit;
        }

        return tokenAmount;
    }

    function _preValidatePurchase(address _beneficiary, uint256 _tokenAmount)
        internal
        override(CappedCrowdsale, TimedCrowdsale, Crowdsale)
        whenNotPaused
    {
        require(
            _tokenAmount <= txTokenLimit,
            "ERROR:Max 2 mints in one transaction"
        );

        super._preValidatePurchase(_beneficiary, _tokenAmount);
    }

    function _updatePurchasingState(
        address _beneficiary,
        uint256 _tokenAmount,
        uint256 _weiAmount
    ) internal override {
        super._updatePurchasingState(_beneficiary, _tokenAmount, _weiAmount);
    }

    function _deliverToken(address _beneficiary, uint256 tokenAmount)
        internal
        override
    {
        inventory.mint(_beneficiary, tokenAmount);
    }
}