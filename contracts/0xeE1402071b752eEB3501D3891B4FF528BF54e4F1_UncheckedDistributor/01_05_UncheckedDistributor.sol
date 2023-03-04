// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract UncheckedDistributor {
    IERC20  public immutable token;
    uint256 public immutable amount;

    mapping(address => bool) private _claims;

    constructor(IERC20 _token, uint256 _amount) {
        token  = _token;
        amount = _amount;
    }

    function hasClaimed(address user) public view returns (bool) {
        return _claims[user];
    }

    function claim() public {
        require(!hasClaimed(msg.sender), "User already claimed");
        _claims[msg.sender] = true;

        SafeERC20.safeTransfer(token, msg.sender, amount);
    }
}