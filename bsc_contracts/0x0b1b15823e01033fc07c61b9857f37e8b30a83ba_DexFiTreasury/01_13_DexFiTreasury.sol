// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./abstracts/Constants.sol";
import "./../ETF/contracts/core/abstracts/OwnerSourceManagement.sol";
import "./interfaces/IDexFiTreasury.sol";

contract DexFiTreasury is IDexFiTreasury, Constants, OwnerSourceManagement, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _receivers;
    mapping(address => uint256) private _percents;

    function receivers(uint256 index) external view returns (address) {
        return _receivers.at(index);
    }

    function receiversCount() external view returns (uint256) {
        return _receivers.length();
    }

    function receiversContains(address receiver) external view returns (bool) {
        return _receivers.contains(receiver);
    }

    function receiversList(uint256 offset, uint256 limit) external view returns (address[] memory output) {
        uint256 receiversLength = _receivers.length();
        uint256 to = offset + limit;
        if (receiversLength < to) to = receiversLength;
        output = new address[](to - offset);
        for (uint256 i = offset; i < to; i++) output[i - offset] = _receivers.at(receiversLength - i - 1);
    }

    function receiverPercent(address receiver) external view returns (uint256) {
        return _percents[receiver];
    }

    constructor (address ownerSource_, FeeReceiverInfo[] memory _info) {
        _updateOwnerSource(ownerSource_);
        _updateFeeReceiversInfo(_info);
    }

    function claimTreasury(address[] memory tokens) external nonReentrant returns (bool) {
        for (uint256 j = 0; j < tokens.length; j++) {
            address token = tokens[j];
            uint256 balance = token == address(0) ? address(this).balance : IERC20(token).balanceOf(address(this));
            require(balance > 0, "DexFiTreasury: Token treasury is empty");
            uint256 amountSum = 0;
            for (uint256 i = 0; i < _receivers.length(); i++) {
                address receiver = _receivers.at(i);
                uint256 amount = i == _receivers.length() -1
                    ? balance - amountSum
                    : balance * _percents[receiver] / DIVIDER;
                amountSum += amount;
                if (token == address(0)) {
                    (bool success, ) = receiver.call{value: amount}("");
                    require(success, "DexFiTreasury: WNative transfer failed");
                } else IERC20(token).safeTransfer(receiver, amount);
            }
            emit TreasuryClaimed(token, amountSum);
        }
        return true;
    }

    function updateFeeReceiversInfo(FeeReceiverInfo[] memory info) external onlyOwner returns (bool) {
        _updateFeeReceiversInfo(info);
        return true; 
    }

    function _updateFeeReceiversInfo(FeeReceiverInfo[] memory _info) private {
        if (_receivers.length() > 0) {
            for (uint256 i = _receivers.length() - 1; i >=0; i--) {
                _receivers.remove(_receivers.at(i));
                if (i == 0) break;
            }
        }
        uint256 sumOfPercent = 0;
        for (uint256 i = 0; i < _info.length; i++) {
            require(_info[i].receiver != address(0), "DexFiTreasury: Receiver's address is zero");
            _receivers.add(_info[i].receiver);
            _percents[_info[i].receiver] = _info[i].percent;
            sumOfPercent += _info[i].percent;
        }
        require(sumOfPercent == DIVIDER, "DexFiTreasury: Receiver's persent's sum neq DIVIDER");
        require(_receivers.length() == _info.length, "DexFiTreasury: Info is incorrect");
        emit FeeReceiversInfoUpdated(_info);
    }
}