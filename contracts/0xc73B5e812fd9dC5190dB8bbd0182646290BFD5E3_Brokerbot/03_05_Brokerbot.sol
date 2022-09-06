/**
* SPDX-License-Identifier: LicenseRef-Aktionariat
*
* Proprietary License
*
* This code cannot be used without an explicit permission from the copyright holder.
* If you wish to use the Aktionariat Brokerbot, you can either use the open version
* named Brokerbot.sol that can be used under an MIT License with Automated License Fee Payments,
* or you can get in touch with use to negotiate a license to use LicensedBrokerbot.sol .
*
* Copyright (c) 2021 Aktionariat AG (aktionariat.com), All rights reserved.
*/
pragma solidity ^0.8.0;

import "../utils/Ownable.sol";
import "../ERC20/IERC20.sol";
import "../ERC20/IERC677Receiver.sol";
import "./IBrokerbot.sol";

contract Brokerbot is IBrokerbot, Ownable {

    address public paymenthub;

    IERC20 public override immutable base;  // ERC-20 currency
    IERC20 public immutable token; // ERC-20 share token

    uint256 private price; // current offer price in base currency, without drift
    uint256 public increment; // increment step the price in/decreases when buying/selling

    uint256 public driftStart;
    uint256 public timeToDrift; // seconds until drift pushes price by one drift increment
    int256 public driftIncrement;

    // Note that these settings might be hard-coded in various places, so better not change these values.
    uint8 private constant BUYING_ENABLED = 0x1;
    uint8 private constant SELLING_ENABLED = 0x2;
    // note that in the UI, we call the setting "convert ether", which is the opposite
    uint8 private constant KEEP_ETHER = 0x4;

    // Version history
    // Version 2: added ability to process bank orders even if buying disabled
    // Version 3: added various events, removed license fee
    // Version 4: made version field public so it is actually usable    
    // Version 5: added target address for withdrawEther
    uint8 public constant VERSION = 0x5;

    // more bits to be used by payment hub
    uint256 public override settings = BUYING_ENABLED | SELLING_ENABLED;

    event Trade(IERC20 indexed token, address who, bytes ref, int amount, IERC20 base, uint totPrice, uint fee, uint newprice);
    event PaymentHubUpdate(address indexed paymentHub);
    event PriceSet(uint256 price, uint256 increment);
    event DriftSet(uint256 timeToDrift, int256 driftIncrement);
    event SettingsChange(uint256 setting);

    constructor(
        IERC20 _token,
        uint256 _price,
        uint256 _increment,
        IERC20 _base,
        address _owner,
        address _paymentHub
    )
        Ownable(_owner)
    {
        base = _base;
        token = _token;
        price = _price;
        increment = _increment;
        paymenthub = _paymentHub;
        // Should we disabled recoverability in the recovery hub here?
        // No, if someone attacks us, we can always trigger a transfer and recover the tokens as well as the collateral.
    }

    function setPrice(uint256 _price, uint256 _increment) external onlyOwner {
        anchorPrice(_price);
        increment = _increment;
        emit PriceSet(_price, _increment);
    }

    function hasDrift() public view returns (bool) {
        return timeToDrift != 0;
    }

    // secondsPerStep should be negative for downwards drift
    function setDrift(uint256 secondsPerStep, int256 _driftIncrement) external onlyOwner {
        anchorPrice(getPrice());
        timeToDrift = secondsPerStep;
        driftIncrement = _driftIncrement;
        emit DriftSet(secondsPerStep, _driftIncrement);
    }

    function anchorPrice(uint256 currentPrice) private {
        price = currentPrice;
        // rely on time stamp is ok, no exact time stamp needed
        // solhint-disable-next-line not-rely-on-time
        driftStart = block.timestamp;
    }

    function getPrice() public view returns (uint256) {
        // rely on time stamp is ok, no exact time stamp needed
        // solhint-disable-next-line not-rely-on-time
        return getPriceAtTime(block.timestamp);
    }

    function getPriceAtTime(uint256 timestamp) public view returns (uint256) {
        if (hasDrift()){
            uint256 passed = timestamp - driftStart;
            int256 drifted = int256(passed / timeToDrift) * driftIncrement;
            int256 driftedPrice = int256(price) + drifted;
            if (driftedPrice < 0){
                return 0;
            } else {
                return uint256(driftedPrice);
            }
        } else {
            return price;
        }
    }

    function buy(address from, uint256 paid, bytes calldata ref) internal returns (uint256) {
        require(hasSetting(BUYING_ENABLED), "buying disabled");
        uint shares = getShares(paid);
        uint costs = notifyTraded(from, shares, ref);
        if (costs < paid){
            IERC20(base).transfer(from, paid - costs);
        }
        IERC20(token).transfer(from, shares);
        return shares;
    }

    // Callers must verify that (hasSetting(BUYING_ENABLED) || msg.sender == owner) holds!
    function notifyTraded(address from, uint256 shares, bytes calldata ref) internal returns (uint256) {
        // disabling the requirement below for efficiency as this always holds once we reach this point
        // require(hasSetting(BUYING_ENABLED) || msg.sender == owner, "buying disabled");
        uint costs = getBuyPrice(shares);
        price = price + (shares * increment);
        emit Trade(token, from, ref, int256(shares), base, costs, 0, getPrice());
        return costs;
    }

    function notifyTrade(address buyer, uint256 shares, bytes calldata ref) external onlyOwner {
        notifyTraded(buyer, shares, ref);
    }

    function notifyTradeAndTransfer(address buyer, uint256 shares, bytes calldata ref) public onlyOwner {
        notifyTraded(buyer, shares, ref);
        IERC20(token).transfer(buyer, shares);
    }

    function notifyTrades(address[] calldata buyers, uint256[] calldata shares, bytes[] calldata ref) external onlyOwner {
        for (uint i = 0; i < buyers.length; i++) {
            notifyTraded(buyers[i], shares[i], ref[i]);
        }
    }

    function notifyTradesAndTransfer(address[] calldata buyers, uint256[] calldata shares, bytes[] calldata ref) external onlyOwner {
        for (uint i = 0; i < buyers.length; i++) {
            notifyTradeAndTransfer(buyers[i], shares[i], ref[i]);
        }
    }

    /**
     * Payment hub might actually have sent another accepted token, including Ether.
     */
    function processIncoming(IERC20 incomingAsset, address from, uint256 amount, bytes calldata ref) public override payable returns (uint256) {
        require(msg.sender == address(incomingAsset) || msg.sender == paymenthub, "invalid caller");
        if (incomingAsset == token){
            return sell(from, amount, ref);
        } else if (incomingAsset == base){
            return buy(from, amount, ref);
        } else {
            revert("invalid token");
        }
    }

    // ERC-677 recipient
    function onTokenTransfer(address from, uint256 amount, bytes calldata ref) external returns (bool) {
        processIncoming(IERC20(msg.sender), from, amount, ref);
        return true;
    }

    function hasSetting(uint256 setting) private view returns (bool) {
        return settings & setting == setting;
    }

    /**
     * ref 0x01 or old format sells shares for base currency.
     * ref 0x02 indicates a sell via bank transfer.
     */
    function isDirectSale(bytes calldata ref) internal pure returns (bool) {
        if (ref.length == 0 || ref.length == 20) {
            return true; // old format
        } else {
            if (ref[0] == bytes1(0x01)){
                return true;
            } else if (ref[0] == bytes1(0x02)) {
                return false;
            } else {
                revert("unknown ref");
            }
        }
    }


    function sell(address recipient, uint256 amount, bytes calldata ref) internal returns (uint256) {
        require(hasSetting(SELLING_ENABLED), "selling disabled");
        uint256 totPrice = getSellPrice(amount);
        IERC20 baseToken = IERC20(base);
        price -= amount * increment;
        if (isDirectSale(ref)){
            baseToken.transfer(recipient, totPrice);
        }
        emit Trade(token, recipient, ref, -int256(amount), base, totPrice, 0, getPrice());
        return totPrice;
    }

    function getSellPrice(uint256 shares) public view returns (uint256) {
        return getPrice(getPrice() - (shares * increment), shares);
    }

    function getBuyPrice(uint256 shares) public view returns (uint256) {
        return getPrice(getPrice(), shares);
    }

    function getPrice(uint256 lowest, uint256 shares) internal view returns (uint256){
        if (shares == 0) {
            return 0;
        } else {
            uint256 highest = lowest + (shares - 1) * increment;
            return ((lowest + highest) / 2) * shares;
        }
    }

    function getShares(uint256 money) public view returns (uint256) {
        uint256 currentPrice = getPrice();
        uint256 min = 0;
        uint256 max = money / currentPrice;
        while (min < max){
            uint256 middle = (min + max)/2;
            uint256 totalPrice = getPrice(currentPrice, middle);
            if (money > totalPrice){
                min = middle + 1;
            } else {
                max = middle;
            }
        }
        return min;
    }

    function withdrawEther(address target, uint256 amount) public ownerOrHub() {
        (bool success, ) = payable(target).call{value:amount}("");
        require(success, "Transfer failed");
    }

    function withdrawEther(uint256 amount) external ownerOrHub() {
        withdrawEther(msg.sender, amount);
    }

    function approve(address erc20, address who, uint256 amount) external onlyOwner() {
        IERC20(erc20).approve(who, amount);
    }

    function withdraw(address ercAddress, address to, uint256 amount) external ownerOrHub() {
        IERC20(ercAddress).transfer(to, amount);
    }

    function setPaymentHub(address hub) external onlyOwner() {
        paymenthub = hub;
        emit PaymentHubUpdate(paymenthub);
    }

    function setSettings(uint256 _settings) public onlyOwner() {
        settings = _settings;
        emit SettingsChange(_settings);
    }

    function setEnabled(bool _buyingEnabled, bool _sellingEnabled) external onlyOwner() {
        uint256 _settings = settings;
        if (_buyingEnabled != hasSetting(BUYING_ENABLED)){
            _settings ^= BUYING_ENABLED;
        }
        if (_sellingEnabled != hasSetting(SELLING_ENABLED)){
            _settings ^= SELLING_ENABLED;
        }
        setSettings(_settings);
    }
    
    modifier ownerOrHub() {
        require(owner == msg.sender || paymenthub == msg.sender, "not owner nor hub");
        _;
    }
}