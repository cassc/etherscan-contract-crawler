// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Node is Ownable {
    IERC20 public token;

    mapping(uint256 => uint256) public prices;
    mapping(uint256 => uint256) public amounts;
    mapping(uint256 => address) public teams;

    mapping(address => uint256) public nodes;

    constructor(address _token) {
        token = IERC20(_token);

        prices[1] = 2000 * 1e6;
        amounts[1] = 271;
        teams[1] = 0x4227f6FB60b42Cf180c9B6a5A6D7BD8BBEC1B854;

        prices[2] = 5000 * 1e6;
        amounts[2] = 139;
        teams[2] = 0x22d8F026e7D2B61EfAfAaf59c5193cEC87AE971d;

        prices[3] = 10000 * 1e6;
        amounts[3] = 68;
        teams[3] = 0x1D51d35290F93dA6c506e4b2F884f9146A627c14;
    }

    function update(uint256 _index, uint256 _price, uint256 _amount) public onlyOwner {
        prices[_index] = _price;
        amounts[_index] = _amount;
    }

    function claim(uint256 _index) public {
        if (nodes[msg.sender] != 0) revert();
        if (amounts[_index] == 0) revert();

        token.transferFrom(msg.sender, teams[_index], prices[_index]);

        amounts[_index]--;
        nodes[msg.sender] = _index;
    }

    function withdraw(address _to, address _token, uint256 _amount) public onlyOwner {
        if (_token == address(0)) {
            payable(_to).transfer(_amount);
            return;
        }

        IERC20(_token).transfer(_to, _amount);
    }
}