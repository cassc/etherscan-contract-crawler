// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ExpandablesMarketplace is Ownable {
    using SafeERC20 for IERC20;
    
    uint256 public whitelistCounter;

    mapping(uint256 => Whitelist) whitelists;
    mapping(uint => mapping(address => bool)) _hasPurchased;

    address immutable stakingAddress;
    address paymentReceiver;

    mapping(address => string) public names;

    struct Whitelist {
        uint256 id;
        uint256 price;
        uint256 amount;
        address acceptedCurrency;
        uint128 percentPerToken;
        uint128 maxTotalPercent;
    }

    event Purchase (uint256 indexed _id, address indexed _address);
    event PurchasedWithName (uint256 indexed _id, address indexed _address, string name);

    constructor(
        address _paymentReceiver,
        address _stakingAddress
    ) { 
        paymentReceiver = _paymentReceiver;
        stakingAddress = _stakingAddress;
    }

    function addWhitelist(uint256 _amount, uint256 _price, address _acceptedCurrency, uint128 _percentPerToken, uint128 _maxTotalPercent) external onlyOwner {
        Whitelist memory wl = Whitelist(
            whitelistCounter,
            _price * 10 ** 18,
            _amount,
            _acceptedCurrency,
            _percentPerToken,
            _maxTotalPercent
        );

        whitelists[whitelistCounter++] = wl;
    }

    function purchase(uint256 _id) public {
        _purchase(_id);

        emit Purchase(_id, msg.sender);
    }

    function purchaseWithName(uint256 _id, string memory name) public {
        _purchase(_id);

        names[msg.sender] = name;

        emit PurchasedWithName(_id, msg.sender, name);
    }

    function _purchase(uint256 _id) internal {
        require(
            whitelists[_id].amount > 0,
            "No spots left"
        );
       require(
           !_hasPurchased[_id][msg.sender],
           "Address has already purchased");

        uint256 discountPercentage = whitelists[_id].percentPerToken > 0 ? min(BambooStaking(stakingAddress).stakedPandasOf(msg.sender).length * whitelists[_id].percentPerToken, whitelists[_id].maxTotalPercent) : 0;
        uint256 price = discountPercentage > 0 ? (whitelists[_id].price - (whitelists[_id].price * discountPercentage / 100)) : whitelists[_id].price;

        unchecked {
            whitelists[_id].amount--;
        }

        _hasPurchased[_id][msg.sender] = true;

        IERC20(whitelists[_id].acceptedCurrency).safeTransferFrom(msg.sender, paymentReceiver, price);    
    }

    function setPaymentReceiver(address _paymentReceiver) external onlyOwner {
        paymentReceiver = _paymentReceiver;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }  

    function getWhitelist(uint256 _id) public view returns (Whitelist memory) {
        return whitelists[_id];
    }

    function hasPurchased(uint256 _id, address _address) public view returns (bool) {
        return _hasPurchased[_id][_address];
    }     
}

interface BambooStaking {
    function stakedPandasOf(address account) external view returns (uint256[] memory);
 }