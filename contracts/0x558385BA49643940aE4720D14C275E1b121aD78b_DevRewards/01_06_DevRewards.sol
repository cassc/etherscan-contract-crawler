//SPDX-License-Identifier: AFL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DevRewards is Ownable {

    using Address for address;
    using SafeMath for uint;

    IERC20 public _erc20;
    uint public _lastRewardsTime;
    address public _DEV;

    constructor(address DEV_) {
        _lastRewardsTime = block.timestamp;
        _DEV = DEV_;
    }

    function init(address erc20_) public {
        require(msg.sender == _DEV, "You can not do that");
        _erc20 = IERC20(erc20_);
    }

    function rewards(address to) public {

        require(msg.sender == _DEV, "You can not do that");
        require(block.timestamp > _lastRewardsTime + 86400 * 30, "Not the time to rewards");

        _lastRewardsTime = block.timestamp;

        uint all = 10500 ether;
        _erc20.transfer(to, all.div(36));
    }
}