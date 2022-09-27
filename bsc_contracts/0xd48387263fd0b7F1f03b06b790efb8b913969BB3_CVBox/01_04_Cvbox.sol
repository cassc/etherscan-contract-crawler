// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "Ownable.sol";
import "IERC20.sol";

contract CVBox is Ownable {
    IERC20 private immutable _token;
    uint256 private _taxRate = 25; // 2.5%
    uint256 private _cvPrice = 10 * 1e18;
    uint256 private _treasureBalance = 0;
    mapping(address => mapping(address => bool)) private paidCVAddresses;
    mapping(address => uint256) private claimableBalance;
    mapping(address => uint256) private cvViewedCount;

    // ************** //
    // *** EVENTS *** //
    // ************** //
    event LogPurchase(IERC20 indexed token, address indexed from, address indexed cvOwner, uint256 amount);
    event LogClaim(IERC20 indexed token, address indexed from, address indexed to, uint256 amount);
    event LogClaimTreasure(IERC20 indexed token, address indexed from, address indexed to, uint256 amount);

    // ******************* //
    // *** CONSTRUCTOR *** //
    // ******************* //

    constructor(IERC20 payableToken) public {
        _token = payableToken;
    }

    function taxRate() public view returns (uint256) {
        return _taxRate;
    }

    function cvPrice() public view returns (uint256) {
        return _cvPrice;
    }

    function treasureBalance() public view returns (uint256) {
        return _treasureBalance;
    }

    function setCVPrice(uint256 price) external onlyOwner {
        _cvPrice = price;
    }

    function setTaxRate(uint256 rate) external onlyOwner {
        _taxRate = rate;
    }

    function purchaseCV(address cvOwner, uint256 amount) external returns (bool) {
        require(paidCVAddresses[msg.sender][cvOwner] == false, "CVBox: already purchased this CV.");
        require(_cvPrice == amount, "CVBox: need correct amount to purchase CV.");
        uint256 tax = (amount * _taxRate) / 1000;
        cvViewedCount[cvOwner] += 1;
        claimableBalance[cvOwner] += (amount - tax);
        _treasureBalance += tax;
        paidCVAddresses[msg.sender][cvOwner] = true;
        _token.transferFrom(msg.sender, address(this), amount);
        emit LogPurchase(_token, msg.sender, cvOwner, amount);
        return true;
    }

    function hasPurchasedCV(address viewer, address cvOwner) external view returns (bool) {
        return paidCVAddresses[viewer][cvOwner];
    }

    function viewedCount(address cvOwner) external view returns (uint256) {
        return cvViewedCount[cvOwner];
    }

    function amountForClaim(address cvOwner) external view returns (uint256) {
        return claimableBalance[cvOwner];
    }

    function claim(address to, uint256 amount) external returns (bool) {
        require(to != address(0), "CVBox: to not set");
        require(claimableBalance[msg.sender] >= amount, "CVBox: claim amount exceeds balance.");
        claimableBalance[msg.sender] -= amount;
        _token.transfer(to, amount);
        emit LogClaim(_token, msg.sender, to, amount);
        return true;
    }

    function claimTreasure(address to, uint256 amount) external onlyOwner returns (bool) {
        require(to != address(0), "CVBox: to not set");
        require(_treasureBalance >= amount, "CVBox: claim amount exceeds treasure balance.");
        _treasureBalance -= amount;
        _token.transfer(to, amount);
        emit LogClaimTreasure(_token, msg.sender, to, amount);
        return true;
    }
}