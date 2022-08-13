/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FeeSplitterV2 {
    //Basic Parameters
    address payable public addr1;
    address payable public addr2;
    uint split1;

    modifier OnlyParticipants {
        require ((msg.sender == addr1) || (msg.sender == addr2));
        _;
    }

    constructor(address payable _addr1, uint _split1, address payable _addr2) {
        require(_split1 <= 100);

        addr1 = _addr1;
        addr2 = _addr2;
        split1 = _split1;
    }

    receive() external payable {
        //Accept Ether Deposits, tracked by contract balance
    }

    fallback() external payable {
        //Accept Ether Deposits, tracked by contract balance
    }

    //Withdraw Functions
    function WithdrawETH() public {
        uint v1;
        uint v2;
        (v1, v2) = split(address(this).balance);
        addr1.transfer(v1);
        addr2.transfer(v2);
    }

    function WithdrawERC20(address _ERC20Addr) public {
        ERC20 erc20token = ERC20(_ERC20Addr);

        uint v1;
        uint v2;
        (v1, v2) = split(erc20token.balanceOf(address(this)));
        erc20token.transfer(addr1, v1);
        erc20token.transfer(addr2, v2);
    }

    //Change Address Functions
    function ChangeAddress1(address payable _addr1) public {
        require (msg.sender == addr1);
        addr1 = _addr1;
    }

    function ChangeAddress2(address payable _addr2) public {
        require (msg.sender == addr2);
        addr2 = _addr2;
    }

    //View Functions
    function GetSplitPct() public view returns (uint, uint) {
        return (split1, 100 - split1);
    }

    function GetWithdrawableETH() public view returns (uint v1, uint v2) {
        (v1, v2) = split(address(this).balance);
    }

    function GetWithdrawableERC20(address _ERC20Addr) public view returns (uint v1, uint v2) {
        ERC20 erc20token = ERC20(_ERC20Addr);
        (v1, v2) = split(erc20token.balanceOf(address(this)));
    }

    //Internal Functions
    function split(uint bal) private view returns (uint v1, uint v2) {
        v1 = bal * split1 / 100;
        v2 = bal - v1;
    }
}