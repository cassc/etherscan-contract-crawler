// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Refer2Earn is Ownable, PaymentSplitter, ReentrancyGuard {

    using EnumerableSet for EnumerableSet.AddressSet;
    uint8 public fee = 1; // 1% fee, hard-coded

    event Referral(address indexed _contract, address indexed _referrer, uint256 _quantity, uint256 _commission);

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

    constructor(
        address[] memory _payees,
        uint256[] memory _shares,
        address _owner
    ) PaymentSplitter(_payees, _shares) {
        transferOwnership(_owner);
    }

    function addContract(address _contract, uint8 _percent) external onlyContractOwner(_contract) {
        require(commissions[_contract] == 0, "Contract exists");
        commissions[_contract] = _percent;
    }

    function updateContract(address _contract, uint8 _percent) external onlyContractOwner(_contract) {
        require(commissions[_contract] > 0, "Invalid contract");
        require(_percent > 0, "Invalid commission");
        commissions[_contract] = _percent;
    }

    function removeContract(address _contract) external onlyContractOwner(_contract) {
        require(commissions[_contract] > 0, "Invalid contract");
        delete commissions[_contract];
    }

    function addBonus(address _contract, uint8 _percent, address _referrer) external onlyContractOwner(_contract) {
        require(!referrers[_contract].contains(_referrer), "Referrer already exists");
        referrers[_contract].add(_referrer);
        bonuses[_contract][_referrer] = _percent;
    }

    function updateBonus(address _contract, uint8 _percent, address _referrer) external onlyContractOwner(_contract) {
        require(referrers[_contract].contains(_referrer), "Referrer doesn't exist");
        bonuses[_contract][_referrer] = _percent;
    }

    function removeBonus(address _contract, address _referrer) external onlyContractOwner(_contract) {
        require(referrers[_contract].contains(_referrer), "Referrer doesn't exist");
        referrers[_contract].remove(_referrer);
        delete bonuses[_contract][_referrer];
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
        (bool sent,) = _referrer.call{value: _commission}("");
        require(sent, "Failed to send");
    }
}