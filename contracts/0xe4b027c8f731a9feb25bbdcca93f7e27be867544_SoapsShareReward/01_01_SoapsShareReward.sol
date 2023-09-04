/**
Welcome to the Soaps Tech.

Website: https://soaps.tech/
Telegram: https://t.me/soapstech
X: https://x.com/soapstech

*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;

contract SoapsShareReward {
    function shareReward(
        address[] memory _listUser,
        uint256 _totalReward
    ) public payable {
        uint256 _reward = _totalReward / _listUser.length;
        for (uint i = 0; i < _listUser.length; i++) {
            bool sent = payable(_listUser[i]).send(_reward);
            require(sent, "Failed to send ETH");
        }
    }

    receive() external payable {}
}