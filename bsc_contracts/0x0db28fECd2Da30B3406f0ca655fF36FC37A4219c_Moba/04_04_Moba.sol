// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Moba is Ownable {
    address public receiver1 = 0x36fB532184Ee16485Dd851a75fcaB08B9a0D57Ad;
    address public receiver2 = 0x32b7ED82F786bdcc1a33E3a524284762818C19D1;
    uint256 public receiver1_percent = 70;
    uint256 public receiver2_percent = 30;

    event DepositEvent(
        string username,
        address token,
        address wallet,
        uint256 amount,
        uint256 timestamp
    );

    event WithdrawEvent(
        string username,
        address token,
        uint256 amount,
        uint256 timestamp,
        string id
    );

    function deposit(
        address _tokenAddress,
        uint256 _amount,
        string memory _username
    ) public {
        uint256 receiver1_amount = (_amount * receiver1_percent) / 100;
        uint256 receiver2_amount = _amount - receiver1_amount;

        IERC20(_tokenAddress).transferFrom(
            msg.sender,
            receiver1,
            receiver1_amount
        );
        IERC20(_tokenAddress).transferFrom(
            msg.sender,
            receiver2,
            receiver2_amount
        );

        emit DepositEvent(
            _username,
            _tokenAddress,
            msg.sender,
            _amount,
            block.timestamp
        );
    }

    function withdraw(
        address _tokenAddress,
        uint256 _amount,
        string memory _username,
        string memory _id
    ) public onlyOwner {
        require(
            IERC20(_tokenAddress).balanceOf(address(this)) >= _amount,
            "Contract not enough balance"
        );

        IERC20(_tokenAddress).transfer(msg.sender, _amount);
        emit WithdrawEvent(
            _username,
            _tokenAddress,
            _amount,
            block.timestamp,
            _id
        );
    }

    function setPercent(
        uint256 _receiver1,
        uint256 _receiver2
    ) public onlyOwner {
        receiver1_percent = _receiver1;
        receiver2_percent = _receiver2;
    }

    function setReceiver(
        address _receiver1,
        address _receiver2
    ) public onlyOwner {
        receiver1 = _receiver1;
        receiver2 = _receiver2;
    }

    /**
	Clear unknow token
	*/
    function clearUnknownToken(address _tokenAddress) public onlyOwner {
        uint256 contractBalance = IERC20(_tokenAddress).balanceOf(
            address(this)
        );
        IERC20(_tokenAddress).transfer(address(msg.sender), contractBalance);
    }
}