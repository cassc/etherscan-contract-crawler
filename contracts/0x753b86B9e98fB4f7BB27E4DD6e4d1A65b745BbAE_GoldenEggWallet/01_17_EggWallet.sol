//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GoldenEggWallet is PaymentSplitter {
    using Strings for uint;

    uint private teamLength;
    bool private locked = false;

    constructor(address[] memory _team, uint256[] memory _teamShares) PaymentSplitter(_team, _teamShares) {
        teamLength = _team.length;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier noZeroAddress(address _addr) {
        require(_addr != address(0), "Not valid address");
        _;
    }

    modifier noReentrancy() {
        require(!locked, "No reenterancy");

        locked = true;
        _;
        locked = false;
    }
    
    //ReleaseALL
    function releaseAll() external noReentrancy{
        for(uint i = 0 ; i < teamLength ; i++) {
            release(payable(payee(i)));
        }
    }

}