// SPDX-License-Identifier: proprietary
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./ISelfkeyGovernance.sol";

contract SelfkeyGovernance is ISelfkeyGovernance, Initializable, OwnableUpgradeable  {

    bool public entryFeeStatus;
    mapping (address => PaymentCurrency) private _currencies;
    address[] private _currencyEntries;

    mapping(uint256 => address) public addresses;
    mapping(uint256 => uint256) public numbers;
    mapping(uint256 => bytes32) public data;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    function setEntryFreeStatus(bool _status) public onlyOwner {
        entryFeeStatus = _status;
        emit EntryFeeStatusUpdated(_status);
    }

    function updatePaymentCurrency(string memory _name, address _tokenAddress, uint8 _decimals, uint256 _amount, bool _native, bool _active, uint256 _discount) public onlyOwner {
        if (!currencyExists(_tokenAddress)) {
            _currencyEntries.push(_tokenAddress);
        }
        _currencies[_tokenAddress] = PaymentCurrency(_name, _tokenAddress, _decimals, _amount, _native, _active, _discount);
        emit PaymentCurrencyUpdated(_name, _tokenAddress, _decimals, _amount, _native, _active, _discount);
    }

    function getCurrencies() external view returns (PaymentCurrency[] memory) {
        uint _count = _currencyEntries.length;
        PaymentCurrency[] memory _activeCurrencies = new PaymentCurrency[](6);
        for(uint i=0; i<_count; i++) {
            PaymentCurrency memory record = _currencies[_currencyEntries[i]];
             _activeCurrencies[i] = record;
        }
        return _activeCurrencies;
    }

    function getCurrency(address _tokenAddress) external view returns (PaymentCurrency memory) {
        return _currencies[_tokenAddress];
    }

    function setAddress(uint256 addressIndex, address newAddress) public onlyOwner {
        address oldAddress = addresses[addressIndex];
        addresses[addressIndex] = newAddress;
        emit AddressUpdated(msg.sender, addressIndex, oldAddress, newAddress);
    }

    function setNumber(uint256 index, uint256 newNumber) public onlyOwner {
        uint256 oldNumber = numbers[index];
        numbers[index] = newNumber;
        emit NumberUpdated(msg.sender, index, oldNumber, newNumber);
    }

    function setData(uint256 index, bytes32 newData) public onlyOwner {
        bytes32 oldData = data[index];
        data[index] = newData;
        emit DataUpdated(msg.sender, index, oldData, newData);
    }

    function currencyExists(address _tokenAddress) private view returns (bool) {
        uint _count = _currencyEntries.length;
        for (uint i = 0; i < _count; i++) {
            if (_currencies[_currencyEntries[i]].tokenAddress == _tokenAddress) {
                return true;
            }
        }
        return false;
    }
}