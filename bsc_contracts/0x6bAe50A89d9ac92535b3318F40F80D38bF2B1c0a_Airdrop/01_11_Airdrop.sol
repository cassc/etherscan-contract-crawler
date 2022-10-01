// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IAirdrop.sol";
import {SafeMath} from "../lib/SafeMath.sol";


contract Airdrop is IAirdrop, OwnableUpgradeable{
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20 public rewardToken;
    address public trader;

    modifier onlyTrader() {
        require(msg.sender == trader, "Only callable by trader");
        _;
    }

    function initialize(address _rewardToken) public reinitializer(1){
        rewardToken = IERC20(_rewardToken);

        __Ownable_init();
    }

    function dropTokens(address[] memory _recipients, uint256[] memory _amount, bool isTransferFrom) override public onlyTrader returns (bool) {
        require(_recipients.length == _amount.length, "length error");

        for (uint i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "recipient error");
            if(isTransferFrom) {
                rewardToken.safeTransferFrom(msg.sender, _recipients[i], _amount[i]);
            } else {
                rewardToken.safeTransfer(_recipients[i], _amount[i]);
            }
        }

        return true;
    }

    function dropEther(address[] memory _recipients, uint256[] memory _amount) override public payable onlyTrader returns (bool) {
        uint total = 0;

        for(uint j = 0; j < _amount.length; j++) {
            total = total.add(_amount[j]);
        }

        require(total <= msg.value, "value error");
        require(_recipients.length == _amount.length, "length error");


        for (uint i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "recipient error");

            payable(_recipients[i]).transfer(_amount[i]);

            emit EtherTransfer(_recipients[i], _amount[i]);
        }

        return true;
    }

    function updateRewardToken(address newRewardToken) override public onlyOwner {
        rewardToken = IERC20(newRewardToken);

        emit UpdateRewardToken(newRewardToken);
    }

    function withdrawTokens(address tokenAddr, address beneficiary) override public onlyOwner {
        uint balance = IERC20(tokenAddr).balanceOf(address(this));
        require(balance > 0, "balance error");
        IERC20(tokenAddr).safeTransfer(beneficiary, balance);
    }

    function withdrawEther(address payable beneficiary) override public onlyOwner {
        beneficiary.transfer(address(this).balance);
    }

    function setTrader(address _trader) external onlyOwner {
        trader = _trader;
    }
}