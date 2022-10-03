// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract WenMintUpgrades is PaymentSplitter {

    struct Upgrade {
        uint256 id;
        uint256 price;
    }
    mapping(uint256 => Upgrade) public upgrades;
    uint256[] public upgradeIds;
    address public owner;

    modifier onlyOwner() {
        require(owner == msg.sender, "Function can only be invoked by owner.");
        _;
    }

    constructor(address[] memory _payees, uint256[] memory _shares) PaymentSplitter(_payees, _shares) {
        owner = msg.sender;
    }

    function getUpgrades() public view returns (Upgrade[] memory) {
      Upgrade[] memory available = new Upgrade[](upgradeIds.length);
      for (uint i = 0; i < upgradeIds.length; i++) {
          Upgrade storage upgrade = upgrades[upgradeIds[i]];
          available[i] = upgrade;
      }
      return available;
    }

    function isUpgrade(uint256 _id)
        internal
        view
        returns (bool, uint256)
    {
        for (uint256 i = 0; i < upgradeIds.length; i += 1) {
            if (_id == upgradeIds[i] && upgrades[_id].id != 0) return (true, i);
        }
        return (false, 0);
    }

    function addUpgrade(uint256 _id, uint256 _price)
        public
        onlyOwner
        returns (bool)
    {
        (bool _isUpgrade, ) = isUpgrade(_id);
        require(!_isUpgrade,  "Upgrade already exists.");
        upgrades[_id] = Upgrade(_id, _price);
        upgradeIds.push(_id);
        return true;
    }

    function editUpgrade(uint256 _id, uint256 _price)
        public
        onlyOwner
        returns (bool)
    {
        (bool _isUpgrade, ) = isUpgrade(_id);
        require(_isUpgrade,  "Invalid upgrade.");
        upgrades[_id].price = _price;
        return true;
    }

    function removeUpgrade(uint256 _id)
        public
        onlyOwner
        returns (bool)
    {
        (bool _isUpgrade, uint256 i) = isUpgrade(_id);
        require(_isUpgrade, "Invalid upgrade.");
        upgradeIds[i] = upgradeIds[upgradeIds.length - 1];
        upgradeIds.pop();
        delete upgrades[_id];
        return true;
    }

    function transferOwnership(address _address) public onlyOwner {
        owner = _address;
    }

    function buyUpgrades(uint256[] memory _ids) public payable {
        uint256 totalPrice = 0;
        for (uint16 i = 0; i < _ids.length; i++) {
            (bool _isUpgrade, ) = isUpgrade(_ids[i]);
            require(_isUpgrade, "Invalid upgrade.");
            totalPrice += upgrades[_ids[i]].price;
        }
        require(totalPrice <= msg.value, "ETH incorrect");
    }
}