// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";


// -=-=-=- PONZI LINE v1 [king.code] -=-=-=- \\
contract PonziLine is Ownable{
    uint256 public constant PAY_RATE_PCT = 200;
    uint256 public constant PAY_MASTER_PCT = 10;

    uint256 public _investor_count;
    uint256 public _amt_input_total;
    uint256 public _amt_payout;
    uint256 public _pay_idx;

    bool public _is_open;

    Master public master;

    mapping(uint256 => Investor) public investors;

    struct Investor {
        address payable id;
        uint256 input;      // amount paid in
        uint256 due;        // amount due
        uint256 output;     // amount paid out
        uint256 collected;  // amount withdrawn

    }

    struct Master {
        address payable id;
        uint256 output;
    }

    constructor(){
        _is_open = true;
        _investor_count = 0;
        _amt_payout = 0;
        _pay_idx = 0;

        master.id = payable(msg.sender);
        master.output = 0;
    }

    function notContract(address _addr) private view returns (bool isContract){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size == 0);
    }

    function invest() public payable
    {
        require(_is_open, "Contract is closed");
        require(notContract(msg.sender), "Investor cannot be a contract");
        require(msg.value>0, "Message value must be positive");
        _investor_count += 1;

        investors[_investor_count] = Investor(
            payable(msg.sender),            // id
            msg.value,                      // input
            msg.value*PAY_RATE_PCT/100,     // due
            0,                              // output
            0                               // collected
        );

        _amt_input_total += msg.value;
        
        uint256 master_value = msg.value*PAY_MASTER_PCT/100;
        master.output += master_value;

        _amt_payout += msg.value-master_value;

        while( investors[_pay_idx].due <= _amt_payout){
            investors[_pay_idx].output = investors[_pay_idx].due;
            _amt_payout -= investors[_pay_idx].due;
            _pay_idx += 1;
        }

    }

    function withdraw(uint256 investor_idx) public{
        require(notContract(msg.sender), "Investor cannot be a contract");
        require(investors[investor_idx].id == msg.sender, "Sender is not the investor");
        require(investors[investor_idx].output == investors[investor_idx].due, "Investor has no payout");
        require(investors[investor_idx].collected==0, "Investor has already collected");

        investors[investor_idx].collected = investors[investor_idx].due;
        payable(investors[investor_idx].id).transfer(investors[investor_idx].due);
    }

    function withdrawMaster() public onlyOwner{
        require(master.output>0, "No value to withdraw");

        master.id.transfer(master.output);
        master.output = 0;
    }
}