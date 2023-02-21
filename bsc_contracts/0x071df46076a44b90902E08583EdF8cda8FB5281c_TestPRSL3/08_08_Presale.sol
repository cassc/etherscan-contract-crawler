// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TestPRSL3 is Ownable {
    using SafeERC20 for IERC20Metadata;

    IERC20Metadata constant raiseToken =
        IERC20Metadata(0x55d398326f99059fF775485246999027B3197955);
    uint16 constant totalRatio = 1000;
    address[] public receivers;
    mapping(address => uint16) public receiversRatio;
    uint16 public lockRatio;
    uint256 unlockDate;

    event Bought(address indexed buyer, address token, uint256 value);
    event RatioUpdated(address[] receivers, uint16[] ratios);

    constructor(
        address[] memory _receivers,
        uint16[] memory _ratios,
        uint256 _unlockDate
    ) {
        require(
            _receivers.length == _ratios.length,
            "not same receiver and ratio count"
        );
        receivers = _receivers;
        uint16 _totalRatio;
        for (uint256 i = 0; i < _receivers.length; i++) {
            receiversRatio[_receivers[i]] = _ratios[i];
            _totalRatio += _ratios[i];
        }
        require(
            _totalRatio <= totalRatio,
            "sum of receiver ration should be equal or smaller than 1000"
        );
        lockRatio = totalRatio - _totalRatio;
        unlockDate = _unlockDate;
        emit RatioUpdated(_receivers, _ratios);
    }

    function updateRatio(address[] memory _receivers, uint16[] memory _ratios)
        external
        onlyOwner
    {
        require(
            _receivers.length == _ratios.length,
            "not same receiver and ratio count"
        );
        receivers = _receivers;
        uint16 _totalRatio;
        for (uint256 i = 0; i < _receivers.length; i++) {
            receiversRatio[_receivers[i]] = _ratios[i];
            _totalRatio += _ratios[i];
        }
        require(
            _totalRatio <= totalRatio,
            "sum of receiver ration should be equal or smaller than 1000"
        );
        lockRatio = totalRatio - _totalRatio;
        emit RatioUpdated(_receivers, _ratios);
    }

    function unlock(address to) external onlyOwner {
        require(unlockDate < block.timestamp, "Lock period is not over yet!");
        raiseToken.safeTransfer(to, raiseToken.balanceOf(address(this)));
        (bool success, ) = address(to).call{value: address(this).balance}("");
        require(success, "Refund Failed");
    }

    function buyWithETH() external payable {
        require(msg.value > 0, "Amount should be greater than 0!");
        for (uint256 i = 0; i < receivers.length; i++) {
            if (receiversRatio[receivers[i]] > 0) {
                (bool success, ) = address(receivers[i]).call{
                    value: (msg.value * receiversRatio[receivers[i]]) /
                        totalRatio
                }("");
                require(success, "Transfer Failed");
            }
        }
        emit Bought(msg.sender, address(0x0), msg.value);
    }

    function buyWithToken(uint256 _amount) external {
        require(_amount > 0, "Amount should be greater than 0!");
        raiseToken.safeTransferFrom(msg.sender, address(this), _amount);
        for (uint256 i = 0; i < receivers.length; i++) {
            if (receiversRatio[receivers[i]] > 0) {
                raiseToken.safeTransfer(
                    receivers[i],
                    (_amount * receiversRatio[receivers[i]]) / totalRatio
                );
            }
        }
        emit Bought(msg.sender, address(raiseToken), _amount);
    }
}