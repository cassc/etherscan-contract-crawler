// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Swap is Ownable {
    mapping (string => bool) withdrawals;

    event Withdrawn(address indexed a, uint256 v, string n);
    
    function withdraw(address _tokenContract, uint256 _amount, address _to, string memory _note) external onlyOwner {
        require(!alreadyWithdrawn(_note));
        withdrawals[_note] = true;

        IERC20 tokenContract = IERC20(_tokenContract);

        tokenContract.approve(address(this), _amount);
        tokenContract.transferFrom(address(this), _to, _amount);

        emit Withdrawn(_to, _amount, _note);
    }

    function alreadyWithdrawn(string memory _note) public view returns (bool) {
        return withdrawals[_note] == true;
    }
}