// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SwapGNS is ReentrancyGuard, Ownable {

    using SafeMath for uint256;

    address[] owners = [
        0x7bea2A322cD948B6056827a9a10C5e9B1063cBF0,  // 
        0xa94B4a7e5348649CCAa7a8ca372bDB4cB32F9654,   // 
        0x1F2Bce3162c0Ca51dCA54A71789F3f2673Ff6FFE,
        0x3FF38A7F852cF57F68A440CaE41cf171e44C61D0
    ];

    uint256[] percentages = [
        400,  //    4%
        50,    //  0.5%
        50,    //  0.5%
        10     //  0.1%
    ];

    address externalAIG;

    address public USDT;

    mapping(address => bool) admins;
    constructor( address _USDT,address _externalAIG) {
        admins[msg.sender] = true;
        USDT = _USDT;
        externalAIG = _externalAIG;
        transferOwnership(0x7bea2A322cD948B6056827a9a10C5e9B1063cBF0);
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not admin");
        _;
    }

    function sendtTokens(address _to, uint256 _amount) public onlyOwner {
        IERC20(USDT).transfer(_to, _amount);
    }

    function emergencyWithdraw(address token, uint256 amount) public onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    function ethEmergencyWithdraw(uint256 amount) public onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function sistemFunds(uint256 _amount, bool _usdt) onlyAdmin public {
        for (uint256 i = 0; i < percentages.length; i++) {
            uint256 amount = _amount.mul(percentages[i]).div(10000);
            if (_usdt) {
                IERC20(USDT).transfer(owners[i], amount);
            } else {
                IERC20(externalAIG).transfer(owners[i], amount);
            }
        }
    }
}