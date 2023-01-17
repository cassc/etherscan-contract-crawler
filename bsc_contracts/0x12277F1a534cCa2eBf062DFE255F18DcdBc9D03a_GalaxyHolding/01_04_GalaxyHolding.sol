// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./interfaces/IERC20.sol";
import "./utils/Ownable.sol";

contract GalaxyHolding is Ownable {
    mapping(address => bool) public allowedBorrowers;

    modifier onlyBorrowers {
        require(allowedBorrowers[msg.sender] == true, "Only Borrowers");
        _;
    }

   function addBorrowers(address[] memory newBorrowers) public onlyOwner {
        for (uint i=0;i<newBorrowers.length;i++) {
            allowedBorrowers[newBorrowers[i]] = true;
        }
    }

    function removeBorrowers(address[] memory oldBorrowers) public onlyOwner {
        for (uint i=0;i<oldBorrowers.length;i++) {
            delete allowedBorrowers[oldBorrowers[i]];
        }
    }

    function takeLoan(address loanToken, uint256 amount) public onlyBorrowers {
        require(IERC20(loanToken).balanceOf(address(this)) >= amount, "Not enough loanToken in the contract");
        IERC20(loanToken).transfer(msg.sender, amount);
    }

    function loanPayment(address loanToken, address loanContract, uint256 amount) public onlyBorrowers {
        IERC20(loanToken).transferFrom(msg.sender, address(this), amount);
        IERC20(loanToken).transfer(loanContract, amount);
    }

    function withdrawToken(address token, uint256 amount) public onlyOwner {
        address to = this.owner();
        IERC20(token).transfer(to, amount);
    }

    function migrateTokens(address[] memory tokens, address newContract) public onlyOwner {
        for (uint256 i=0;i<tokens.length;i++) {
            uint256 balance = IERC20(tokens[i]).balanceOf(address(this));
            IERC20(tokens[i]).transfer(newContract, balance);
        }
    }
}