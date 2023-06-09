// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Refer2Earn is Ownable, ReentrancyGuard {

    using EnumerableSet for EnumerableSet.AddressSet;
    uint8 public fee = 1; // 1% fee, hard-coded

    event Referral(address indexed _contract, address indexed _referrer, uint256 _quantity, uint256 _commission);

    address payable public treasuryAddress;
    mapping(address => uint256) public commissions;
    mapping(address => EnumerableSet.AddressSet) private referrers;
    mapping(address => mapping(address => uint256)) public bonuses;

    modifier onlyContractOwner(address _contract) {
        require(Ownable(_contract).owner() == msg.sender, "Unauthorized");
        _;
    }

    modifier onlyContract() {
        require(commissions[msg.sender] > 0, "Unauthorized");
        _;
    }

    constructor(address payable _treasuryAddress) {
        treasuryAddress = _treasuryAddress;
    }

    function setTreasuryAddress(address payable _treasuryAddress) external onlyOwner {
        treasuryAddress = _treasuryAddress;
    }

    function setContract(address _contract, uint8 _percent) external onlyContractOwner(_contract) {
        require(_contract != address(0), "Bad contract");
        require(_percent <= 100, "Bad commission");
        if (_percent == 0) {
            delete commissions[_contract];
        } else {
            commissions[_contract] = _percent;
        }
    }

    function setBonus(address _contract, uint8 _percent, address _referrer) external onlyContractOwner(_contract) {
        require(_contract != address(0), "Bad contract");
        if (referrers[_contract].contains(_referrer)) {
            if (_percent == 0) {
                referrers[_contract].remove(_referrer);
                delete bonuses[_contract][_referrer];
            } else {
                bonuses[_contract][_referrer] = _percent;
            }
        } else {
            require(_percent + commissions[_contract] <= 100, "Bad bonus");
            referrers[_contract].add(_referrer);
            bonuses[_contract][_referrer] = _percent;
        }
    }

    function getCommission(address _contract, address _recipient, address _referrer, uint256 _value) public view returns (uint256, uint256) {
        uint256 _commission = commissions[_contract];
        if (_referrer != address(0) && _referrer != _recipient && _commission > 0) {
            if (referrers[_contract].contains(_referrer)) {
                _commission += bonuses[_contract][_referrer];
            }
            return ((_value * _commission) / 100, (_value * fee) / 100);
        } else {
            return (0, 0);
        }
    }

    function bonusesOf(address _contract)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        EnumerableSet.AddressSet storage _addressSet = referrers[_contract];
        address[] memory _referrers = new address[](_addressSet.length());
        uint256[] memory _bonuses = new uint256[](_addressSet.length());
        for (uint256 i; i < _addressSet.length(); i++) {
            _referrers[i] = _addressSet.at(i);
            _bonuses[i] = bonuses[_contract][_referrers[i]];
        }
        return (_referrers, _bonuses);
    }

    function payReferral(address _recipient, address payable _referrer, uint256 _quantity, uint256 _value) external payable nonReentrant onlyContract {
        (uint256 _commission, uint256 _fee) = getCommission(msg.sender, _recipient, _referrer, _value);
        require(msg.value >= _commission + _fee, "Invalid ETH");
        emit Referral(msg.sender, _referrer, _quantity, _commission);
        (bool sentCommisson,) = _referrer.call{value: _commission}("");
        (bool sentFee,) = treasuryAddress.call{value: _fee}("");
        require(sentCommisson, "Commission failed");
        require(sentFee, "Fee failed");
    }
}