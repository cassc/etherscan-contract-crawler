// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract WASDistribution {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Events
    event Transfer(
        address indexed token,
        address indexed caller,
        uint256 recipientCount,
        uint256 totalTokensSent
    );

    function transfer(address _token, address[] calldata _addresses, uint256[] calldata _amounts) public {
        require(_addresses.length == _amounts.length, "Address array and values array must be same length");
        
        IERC20 token = IERC20(_token);

        uint256 totalTokensSent;
        for (uint i = 0; i < _addresses.length; i += 1) {
            require(_addresses[i] != address(0), "Address invalid");
            require(_amounts[i] > 0, "Value invalid");

            token.safeTransferFrom(msg.sender, _addresses[i], _amounts[i]);
            totalTokensSent = totalTokensSent.add(_amounts[i]);
        }

        emit Transfer(_token, msg.sender, _addresses.length, totalTokensSent);
    }
}