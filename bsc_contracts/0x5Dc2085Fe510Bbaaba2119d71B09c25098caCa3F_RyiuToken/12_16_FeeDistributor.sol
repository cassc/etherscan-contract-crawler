// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract FeeDistributor is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _collectors;
    mapping(address => uint256) private _shares;
    uint256 public totalFeeCollectorsShares;

    event FeeCollectorAdded(address indexed account, uint256 share);
    event FeeCollectorUpdated(address indexed account, uint256 oldShare, uint256 newShare);
    event FeeCollectorRemoved(address indexed account);
    event FeeCollected(address indexed receiver, uint256 amount);

    function isFeeCollector(address account) public view returns (bool) {
        return _collectors.contains(account);
    }

    function feeCollectorShare(address account) public view returns (uint256) {
        return _shares[account];
    }

    function _addFeeCollector(address account, uint256 share) internal {
        require(!_collectors.contains(account), "Already fee collector");
        require(share > 0, "Invalid share");

        _collectors.add(account);
        _shares[account] = share;
        totalFeeCollectorsShares += share;

        emit FeeCollectorAdded(account, share);
    }

    function _removeFeeCollector(address account) internal {
        require(_collectors.contains(account), "Not fee collector");
        _collectors.remove(account);
        totalFeeCollectorsShares -= _shares[account];
        delete _shares[account];

        emit FeeCollectorRemoved(account);
    }

    function addFeeCollector(address account, uint256 share) external onlyOwner {
        _addFeeCollector(account, share);
    }

    function removeFeeCollector(address account) external onlyOwner {
        _removeFeeCollector(account);
    }

    function updateFeeCollectorShare(address account, uint256 share) external onlyOwner {
        require(_collectors.contains(account), "Not fee collector");
        require(share > 0, "Invalid share");

        uint256 oldShare = _shares[account];
        totalFeeCollectorsShares -= oldShare;

        _shares[account] = share;
        totalFeeCollectorsShares += share;

        emit FeeCollectorUpdated(account, oldShare, share);
    }

    function _distributeFees(uint256 amount) internal returns (bool) {
        if (amount == 0) return false;
        if (totalFeeCollectorsShares == 0) return false;

        uint256 distributed = 0;
        uint256 len = _collectors.length();
        for (uint256 i = 0; i < len; i++) {
            address collector = _collectors.at(i);
            uint256 share = i == len - 1
                ? amount - distributed
                : (amount * _shares[collector]) / totalFeeCollectorsShares;

            payable(collector).transfer(share);
            emit FeeCollected(collector, share);

            distributed += share;
        }

        return true;
    }

    function distributeFees(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Not enough balance");
        _distributeFees(amount);
    }
}