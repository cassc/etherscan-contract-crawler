// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/IERC20.sol";
import "./libraries/ERC20.sol";
import "./libraries/SafeMath.sol";

contract PlasmaStaking is ERC20("PlasmaStaking", "xPPAY") {
    using SafeMath for uint256;
    IERC20 public ppay;
    mapping(address => uint256) public startTime;
    uint256 public lockTime = 23 hours;

    // Define the ppay token contract
    constructor(IERC20 _ppay) public {
        ppay = _ppay;
    }

    function enter(uint256 _amount) public {
        // Gets the amount of ppay locked in the contract
        uint256 totalPPAY = ppay.balanceOf(address(this));
        // Gets the amount of xPPAY in existence
        uint256 totalShares = totalSupply();
        // If no xPPAY exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalPPAY == 0) {
            _mint(msg.sender, _amount);
        }
        // Calculate and mint the amount of xPPAY the ppay is worth. The ratio will change overtime, as xPPAY is burned/minted and ppay deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalPPAY);
            _mint(msg.sender, what);
        }
        // Lock the ppay in the contract
        ppay.transferFrom(msg.sender, address(this), _amount);
        startTime[msg.sender] = block.timestamp;
    }

    function leave(uint256 _share) public {
        uint256 duration = block.timestamp.sub(startTime[msg.sender]);
        require(duration >= lockTime, "PlasmaStaking: Lock not expired");
        // Gets the amount of xPPAY in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of ppay the xPPAY is worth
        uint256 what =
            _share.mul(ppay.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        ppay.transfer(msg.sender, what);
    }
}