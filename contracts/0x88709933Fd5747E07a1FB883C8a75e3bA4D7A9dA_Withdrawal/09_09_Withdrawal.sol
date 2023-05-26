// SPDX-License-Identifier: MIT

pragma solidity >0.8.0;

import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/access/Ownable.sol";

contract Withdrawal is Ownable {
    using SafeERC20 for IERC20;
    IERC20 _reward;
    address _sender;
    event WithdrawalToAddress(
        address indexed addr,
        uint reward,
        uint indexed pid
    );

    constructor(address rewardContract, address sender) {
        _reward = IERC20(rewardContract);
        _sender = sender;
    }

    modifier onlySender() {
        require(msg.sender == _sender, "only sender call");
        _;
    }

    function withdrawalToAddresses(
        address[] calldata addresses,
        uint[] calldata rewards,
        uint[] calldata pids,
        uint totalAmount
    ) public onlySender {
        require(
            addresses.length == rewards.length &&
                pids.length == addresses.length,
            "withdrawal data error"
        );
        require(
            _reward.balanceOf(msg.sender) >= totalAmount,
            "exceed sender balance"
        );
        require(
            _reward.allowance(msg.sender, address(this)) >= totalAmount,
            "exceed sender allowance"
        );

        for (uint i = 0; i < addresses.length; ) {
            address addr = addresses[i];
            uint reward = rewards[i];
            uint pid = pids[i];
            _reward.safeTransferFrom(msg.sender, addr, reward);
            emit WithdrawalToAddress(addr, reward, pid);
            unchecked {
                ++i;
            }
        }
    }

    function setRewardContract(address newRewardContract) public onlyOwner {
        _reward = IERC20(newRewardContract);
    }

    function setSender(address newSender) public onlyOwner {
        require(newSender != address(0), "sender cant zero address");
        _sender = newSender;
    }
}