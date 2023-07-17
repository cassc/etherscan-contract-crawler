// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

//** HFD Bonding */
//** Author: Aceson Decubate 2022.10 */

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20Metadata, IERC20 } from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";

import { IStaking } from "./interface/IStaking.sol";
import { IOracle } from "./interface/IOracle.sol";

contract HODLBonding is Ownable, ReentrancyGuard, Pausable {
    using Address for address;

    IERC20Metadata public immutable hfd; //HFD Token
    uint256 public initialPrice = 0.1 * 10 ** 6; //0.1$
    bool public isDynamicPriceUsed; //Whether fixed price or dynamic price is used

    uint32 public startTime; //Time at which sale actually starts
    uint32 public limitActiveTill; //Time until which max cap is active
    uint256 public earlyBuyLimit; //Maximum amount that can be bought at initial stages
    uint256 public totalActualBought; //Actual bought from bonding contract

    IStaking public immutable staking; //Staking contract interface
    IOracle public immutable oracle; //Oracle contract interface

    IERC20 internal immutable usdc;
    IERC20 internal immutable usdt;
    address public paymentReceiver; //Address where which payment is sent

    mapping(uint8 => uint256) public discountPerLock; //In percentage. 2 decimals
    mapping(address => uint256) public totalBought; //Total bought by a user

    modifier notContract() {
        //solhint-disable-next-line avoid-tx-origin
        require(!msg.sender.isContract() && (msg.sender == tx.origin), "HODL: Contracts not allowed");
        _;
    }

    event TokensPurchased(
        address indexed user,
        uint256 indexed amount,
        uint256 indexed price,
        address purchaseToken,
        uint8 lockId
    );

    event LimitsChanged(uint32 startTime, uint32 limitActive, uint256 earlyLimit);
    event DiscountsChanged(uint8[] lockIds, uint256[] discounts);
    event PriceInfoChanged(uint256 newPrice, bool isDynamicUsed);
    event ContractStateChanged(bool isPaused);
    event PaymentReceiverChanged(address newReceiver);

    constructor(
        address _hfd,
        address _staking,
        address _oracle,
        address _usdc,
        address _usdt,
        address _receiver,
        uint32 _startTime,
        uint32 _limitActive,
        uint256 _earlyLimit
    ) {
        require(_hfd != address(0) && _staking != address(0) && _oracle != address(0), "HODL: Zero address");
        hfd = IERC20Metadata(_hfd);
        staking = IStaking(_staking);
        oracle = IOracle(_oracle);
        usdc = IERC20(_usdc);
        usdt = IERC20(_usdt);
        paymentReceiver = _receiver;
        startTime = _startTime;
        limitActiveTill = _limitActive;
        earlyBuyLimit = _earlyLimit;

        hfd.approve(address(staking), type(uint256).max);
    }

    function setLimits(uint32 _startTime, uint32 _limitActive, uint256 _earlyLimit) external onlyOwner {
        require(_limitActive >= _startTime, "HODL: Invalid limit");
        limitActiveTill = _limitActive;
        earlyBuyLimit = _earlyLimit;
        startTime = _startTime;
        emit LimitsChanged(_startTime, _limitActive, _earlyLimit);
    }

    function setDiscounts(uint8[] calldata _lockIds, uint256[] calldata _discounts) external onlyOwner {
        require(_lockIds.length == _discounts.length, "HODL: invalid input");
        for (uint256 i = 0; i < _lockIds.length; i++) {
            discountPerLock[_lockIds[i]] = _discounts[i];
        }
        emit DiscountsChanged(_lockIds, _discounts);
    }

    function setPriceInfo(uint256 _newPrice, bool _isDynamicUsed) external onlyOwner {
        initialPrice = _newPrice;
        isDynamicPriceUsed = _isDynamicUsed;
        emit PriceInfoChanged(_newPrice, _isDynamicUsed);
    }

    function setContractState(bool _isPaused) external onlyOwner {
        if (_isPaused) {
            _pause();
        } else {
            _unpause();
        }
        emit ContractStateChanged(_isPaused);
    }

    function setReceiver(address _newReceiver) external onlyOwner {
        require(_newReceiver != address(0), "HODL: Zero address");
        paymentReceiver = _newReceiver;
        emit PaymentReceiverChanged(_newReceiver);
    }

    function buyHFD(
        uint256 _amount,
        address _token,
        uint8 _lockId
    ) external payable notContract nonReentrant whenNotPaused {
        require(block.timestamp >= startTime, "HODL: Bond buy not active");
        require(_lockId > 0, "HODL: Invalid lock id");
        if (block.timestamp <= limitActiveTill) {
            require(totalBought[msg.sender] + _amount <= earlyBuyLimit, "HODL: Amount exceeds max limit");
        }

        uint256 price;
        uint256 discountedPrice;
        if (_token == address(0)) {
            discountedPrice = getDiscountedPriceInETH(_lockId, _amount);
            require(msg.value >= discountedPrice, "HODL: Insufficient funds sent for purchase");

            Address.sendValue(payable(paymentReceiver), discountedPrice);
            //refund
            if (msg.value > discountedPrice) Address.sendValue(payable(msg.sender), msg.value - discountedPrice);
        } else {
            if (_token == address(usdc)) {
                discountedPrice = getDiscountedPriceInUSDC(_lockId, _amount);
                usdc.transferFrom(msg.sender, paymentReceiver, discountedPrice);
            } else if (_token == address(usdt)) {
                discountedPrice = getDiscountedPriceInUSDT(_lockId, _amount);
                usdt.transferFrom(msg.sender, paymentReceiver, discountedPrice);
            } else {
                revert("HODL: Invalid payment token");
            }
        }

        require(discountedPrice > 0, "HODL: Invalid buy amount");
        totalBought[msg.sender] += _amount;
        uint256[] memory amt = new uint256[](1);
        amt[0] = _amount;
        staking.deposit(0, _lockId, msg.sender, amt);
        totalActualBought += _amount;

        emit TokensPurchased(msg.sender, _amount, price, _token, _lockId);
    }

    function getDiscountedPriceInETH(uint8 _lockId, uint256 _amount) public view returns (uint256 discountedPrice) {
        uint256 price = isDynamicPriceUsed
            ? oracle.getPriceInETH(_amount)
            : oracle.convertUSDToETH((initialPrice * _amount) / 10 ** hfd.decimals());
        discountedPrice = price - ((price * discountPerLock[_lockId]) / 10000);
    }

    function getDiscountedPriceInUSDT(uint8 _lockId, uint256 _amount) public view returns (uint256 discountedPrice) {
        uint256 price = isDynamicPriceUsed
            ? oracle.getPriceInUSDT(_amount)
            : (initialPrice * _amount) / 10 ** hfd.decimals();
        discountedPrice = price - ((price * discountPerLock[_lockId]) / 10000);
    }

    function getDiscountedPriceInUSDC(uint8 _lockId, uint256 _amount) public view returns (uint256 discountedPrice) {
        uint256 price = isDynamicPriceUsed
            ? oracle.getPriceInUSDC(_amount)
            : (initialPrice * _amount) / 10 ** hfd.decimals();
        discountedPrice = price - ((price * discountPerLock[_lockId]) / 10000);
    }
}