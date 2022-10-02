// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;
/// @title Clet Name Service Payment Contract
/// @author Clet Inc.
/// @notice This contract serves as a payment gateway for acquiring clet names
/// @dev All function inputs must be lowercase to prevent undesirable results
/// @custom:contact [email protected]

import "./PriceConverter.sol";
import "./StringManipulation.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error CletPay__Empty();
error CletPay__Expired();
error CletPay__NotForSale();
error CletPay__Unauthorized();
error CletPay__InValidToken();
error CletPay__PaymentFailed();
error CletPay__NameUnavailable();
error CletPay__InsufficientFunds();

contract CletPay is Ownable {
    using StringManipulation for *;
    using PriceConverter for uint256;

    uint256 private NC1 = 399;
    uint256 private NC2 = 199;
    uint256 private NC3 = 99;
    uint256 private NC4 = 9;
    uint256 private NC5_ = 4;
    uint256 private LISTING_FEE = 3;
    uint256 private PARTNER_COMMISSION = 5;
    uint256 private constant TenPow18 = 10**18;
    address private constant CLDGR = 0x47732543a272c54cCAEd2F0983AF47458DC36958;
    AggregatorV3Interface constant priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    mapping(address => bool) public isPartner;
    mapping(string => bool) public nameForSale;
    mapping(string => bool) private name_Exists;
    mapping(string => address) public name_ToOwner;
    mapping(string => uint256) public name_ToPrice;
    mapping(string => uint256) public name_ToExpiry;
    mapping(address => uint256) public dBalance;

    event Paid(
        string _name,
        uint256 _years,
        address indexed _user,
        string _soldBy,
        uint256 _amtPaid_USD,
        uint256 _partnerWeiSent
    );

    event AcquireListed(
        string _name,
        address indexed _buyer,
        address indexed _seller,
        uint256 _amtPaid_USD,
        uint256 _sellerWeiSent,
        uint256 _cletWeiCommission
    );

    /// @notice Unlocks any available name on the SKALE Chain
    function pay(
        string memory _name,
        uint256 _years,
        address _partner
    ) public payable noNull(_name) available(_name.toLower()) {
        uint256 PRICE_USD = getAmountToPay(_name, _years);
        if (isPartner[_partner] == false && dBalance[msg.sender] > 0) {
            PRICE_USD = workDiscount(PRICE_USD);
        }
        string memory soldBy = "CLET INC.";
        uint256 partnercut = 0;
        if (msg.value.getConversionRate(priceFeed) < PRICE_USD) {
            revert CletPay__InsufficientFunds();
        } else {
            if (isPartner[_partner] == true) {
                soldBy = Strings.toHexString(uint256(uint160(_partner)), 20);
                partnercut = (msg.value * PARTNER_COMMISSION) / 100;
                uint256 remainder = msg.value - partnercut;
                payable(CLDGR).transfer(remainder);
                payable(_partner).transfer(partnercut);
            } else {
                payable(CLDGR).transfer(msg.value);
            }
            unlock(_name, _years, msg.sender, PRICE_USD, soldBy, partnercut);
        }
    }

    /// @notice Unlocks any available name on the SKALE Chain (non-partner)
    function pay(string memory _name, uint256 _years) public payable {
        pay(_name, _years, 0x0000000000000000000000000000000000000000);
    }

    function unlock(
        string memory _name,
        uint256 _years,
        address _address,
        uint256 _amountPaid,
        string memory _soldBy,
        uint256 _partnerCut
    ) private {
        name_Exists[_name] = true;
        name_ToOwner[_name] = _address;
        nameForSale[_name] = false;
        name_ToPrice[_name] = 0;
        name_ToExpiry[_name] = block.timestamp + (_years * 365 days);
        emit Paid(
            _name,
            _years,
            _address,
            _soldBy,
            _amountPaid / TenPow18,
            _partnerCut
        );
    }

    /// @notice Used by Clet Token Pay contracts
    function externalUnlock(
        string memory _name,
        uint256 _years,
        address _address,
        uint256 _amountPaid
    ) public onlyOwner available(_name.toLower()) {
        unlock(_name, _years, _address, _amountPaid, "CLET INC.", 0);
    }

    /// @notice Adds specified number of years to an existing name
    function addYears(string memory _name, uint256 _years)
        public
        payable
        noNull(_name)
    {
        if (name_Exists[_name.toLower()] == true) {
            uint256 PRICE_USD = getAmountToPay(_name, _years);
            if (dBalance[msg.sender] > 0) {
                PRICE_USD = workDiscount(PRICE_USD);
            }
            if (msg.value.getConversionRate(priceFeed) < PRICE_USD) {
                revert CletPay__InsufficientFunds();
            } else {
                payable(CLDGR).transfer(msg.value);
                name_ToExpiry[_name] =
                    (_years * 365 days) +
                    name_ToExpiry[_name];
            }
        } else {
            revert CletPay__NameUnavailable();
        }
    }

    /// @notice Returns the price of a name based on number of years
    function getAmountToPay(string memory _name, uint256 _years)
        public
        view
        returns (uint256)
    {
        uint256 _name_count = bytes(_name).length;
        uint256 PRICE_USD = NC5_ * TenPow18;
        if (_name_count == 1) {
            PRICE_USD = NC1 * TenPow18;
        } else if (_name_count == 2) {
            PRICE_USD = NC2 * TenPow18;
        } else if (_name_count == 3) {
            PRICE_USD = NC3 * TenPow18;
        } else if (_name_count == 4) {
            PRICE_USD = NC4 * TenPow18;
        }
        PRICE_USD = PRICE_USD * _years;
        return PRICE_USD;
    }

    /// @notice Returns the current ETH value in USD
    function getEthPrice() public view returns (uint256) {
        return TenPow18.getConversionRate(priceFeed);
    }

    /// @notice Allows a user to set the cost price of an owned name
    function setListingPrice(string memory _name, uint256 _amount)
        public
        isNameOwner(name_ToOwner[_name])
        nonExpired(_name.toLower())
    {
        nameForSale[_name] = true;
        name_ToPrice[_name] = _amount * TenPow18;
    }

    // @notice Delists an existing owned name
    function delistName(string memory _name)
        public
        isNameOwner(name_ToOwner[_name.toLower()])
    {
        if (nameForSale[_name] == true) {
            nameForSale[_name] = false;
            name_ToPrice[_name] = 0;
        }
    }

    /// @notice Acquires a non-expired listed name
    function buyListedName(string memory _name)
        public
        payable
        nonExpired(_name.toLower())
    {
        if (nameForSale[_name] == true) {
            uint256 amtBroughtForward = msg.value.getConversionRate(priceFeed);
            if (amtBroughtForward < name_ToPrice[_name]) {
                revert CletPay__InsufficientFunds();
            } else {
                uint256 cletcut = (msg.value * LISTING_FEE) / 100;
                uint256 remainder = msg.value - cletcut;
                payable(CLDGR).transfer(cletcut);
                payable(name_ToOwner[_name]).transfer(remainder);
                address seller = name_ToOwner[_name];
                name_ToOwner[_name] = msg.sender;
                nameForSale[_name] = false;
                name_ToPrice[_name] = 0;
                emit AcquireListed(
                    _name,
                    msg.sender,
                    seller,
                    amtBroughtForward / TenPow18,
                    remainder,
                    cletcut
                );
            }
        } else {
            revert CletPay__NotForSale();
        }
    }

    // @notice Transfers an owned name to a new owner
    // @dev Call this function before transfer on SKALE Chain
    function transferName(string memory _name, address _newOwner)
        public
        isNameOwner(name_ToOwner[_name.toLower()])
        nonExpired(_name.toLower())
    {
        name_ToOwner[_name] = _newOwner;
        nameForSale[_name] = false;
        name_ToPrice[_name] = 0;
    }

    // @notice Checks if a name is owned
    function nameExists(string memory _name) public view returns (bool) {
        return name_Exists[_name];
    }

    function updatePrice(uint256 _index, uint256 _newAmount) public onlyOwner {
        if (_index == 1) {
            NC1 = _newAmount;
        } else if (_index == 2) {
            NC2 = _newAmount;
        } else if (_index == 3) {
            NC3 = _newAmount;
        } else if (_index == 4) {
            NC4 = _newAmount;
        } else if (_index == 5) {
            NC5_ = _newAmount;
        }
    }

    function setCommision(uint256 _commisionPercentage) public onlyOwner {
        PARTNER_COMMISSION = _commisionPercentage;
    }

    function setPartner(address _partner, bool _validity) public onlyOwner {
        isPartner[_partner] = _validity;
    }

    function withdraw() public onlyOwner {
        payable(CLDGR).transfer(address(this).balance);
    }

    function expiryCheck(string memory _name) private {
        if (block.timestamp >= name_ToExpiry[_name]) {
            name_Exists[_name] = false;
            nameForSale[_name] = false;
            name_ToPrice[_name] = 0;
        }
    }

    function isExpired(string memory _name) public view returns (bool) {
        bool res = false;
        if (block.timestamp >= name_ToExpiry[_name]) {
            res = true;
        }
        return res;
    }

    modifier isNameOwner(address _address) {
        if (_address != msg.sender) {
            revert CletPay__Unauthorized();
        }
        _;
    }

    modifier available(string memory _name) {
        expiryCheck(_name);
        if (name_Exists[_name] == true) {
            revert CletPay__NameUnavailable();
        }
        _;
    }

    modifier nonExpired(string memory _name) {
        expiryCheck(_name);
        if (block.timestamp >= name_ToExpiry[_name]) {
            revert CletPay__Expired();
        }
        _;
    }

    modifier noNull(string memory _string) {
        if (_string.isEqual("")) {
            revert CletPay__Empty();
        }
        if (_string.hasEmptyString() == true) {
            revert CletPay__Empty();
        }
        _;
    }

    function workDiscount(uint256 _price) private returns (uint256) {
        uint256 PRICE_USD = 0;
        if (_price > dBalance[msg.sender]) {
            PRICE_USD = _price - dBalance[msg.sender];
            dBalance[msg.sender] = 0;
        } else {
            dBalance[msg.sender] = dBalance[msg.sender] - _price;
            PRICE_USD = 0;
        }
        return PRICE_USD;
    }

    function creditAccount(uint256 _amount, address _address) public onlyOwner {
        dBalance[_address] = dBalance[_address] + (_amount * TenPow18);
    }
}