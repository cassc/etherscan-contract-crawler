// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract NemesisPriceTracker is Ownable{

    using SafeMath for uint256;

    uint256 public lastUpdate;
    uint lastPriceHistoryIndex;

    bool public isInit;

    uint[] internal priceHistory = new uint[](540);
    uint[] public avgPrice;

    mapping(address => bool) public admins;

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not admin");
        _;
    }

    function setInitialPrice(uint[540] calldata _prices) external onlyOwner{
        require(isInit == false, "Already init");
        uint _avgPrice;
        for (uint i = 0; i < 540; i++) {
            priceHistory[i] = _prices[i];
            _avgPrice = _avgPrice.add(_prices[i]);
        }
        _avgPrice = _avgPrice.div(540);
        avgPrice.push(_avgPrice);
        lastUpdate = block.timestamp;
        isInit = true;
    }

    function updatePrice(uint _price) external onlyAdmin {
        uint _removePrice = priceHistory[lastPriceHistoryIndex];
        priceHistory[lastPriceHistoryIndex] = _price;
        uint _avgPrice = (avgPrice[avgPrice.length - 1].mul(540).add(_price).sub(_removePrice)).div(540);
        avgPrice.push(_avgPrice);
        lastPriceHistoryIndex = lastPriceHistoryIndex.add(1) % 540;
        lastUpdate = block.timestamp;
    }

    function updateAdmins(address[] calldata _users, bool _isEnabled) external onlyOwner {
        for (uint i = 0; i < _users.length; i++) {
            admins[_users[i]] = _isEnabled;
        }
    }

    function getAvgPriceArray(uint _startIndex, uint _endIndex) external view returns(uint[] memory){
        uint[] memory _avgPriceArray = new uint[](_endIndex - _startIndex);
        for (uint i = _startIndex; i < _endIndex; i++) {
            _avgPriceArray[i] = avgPrice[i];
        }
        return _avgPriceArray;
    }

    function getPriceHistoryArray() external view returns(uint[540] memory){
        uint[540] memory _priceHistoryArray;
        for (uint i = 0; i < 540; i++) {
            _priceHistoryArray[i] = priceHistory[lastPriceHistoryIndex.add(i) % 540];
        }
        return _priceHistoryArray;
    }

    function getLatestAvgPrice() external view returns(uint){
        return avgPrice[avgPrice.length - 1];
    }
}