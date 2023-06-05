//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

library Errors {
    // Admin error
    string public constant CALLER_NOT_ADMIN = '1'; // 'The caller must be the admin'
    string public constant CALLER_NOT_CONTROLLER = '29'; // 'The caller must be the admin or the controller'
    string public constant CALLER_NOT_ALLOWED_POOL = '30';  // 'The caller must be a palPool listed in the controller'
    string public constant CALLER_NOT_MINTER = '31';
    string public constant CALLER_NOT_IMPLEMENTATION = '35'; // 'The caller must be the pending Implementation'

    // ERC20 type errors
    string public constant FAIL_TRANSFER = '2';
    string public constant FAIL_TRANSFER_FROM = '3';
    string public constant BALANCE_TOO_LOW = '4';
    string public constant ALLOWANCE_TOO_LOW = '5';
    string public constant SELF_TRANSFER = '6';

    // PalPool errors
    string public constant INSUFFICIENT_CASH = '9';
    string public constant INSUFFICIENT_BALANCE = '10';
    string public constant FAIL_DEPOSIT = '11';
    string public constant FAIL_LOAN_INITIATE = '12';
    string public constant FAIL_BORROW = '13';
    string public constant ZERO_BORROW = '27';
    string public constant BORROW_INSUFFICIENT_FEES = '23';
    string public constant LOAN_CLOSED = '14';
    string public constant NOT_LOAN_OWNER = '15';
    string public constant LOAN_OWNER = '16';
    string public constant FAIL_LOAN_EXPAND = '17';
    string public constant NOT_KILLABLE = '18';
    string public constant RESERVE_FUNDS_INSUFFICIENT = '19';
    string public constant FAIL_MINT = '20';
    string public constant FAIL_BURN = '21';
    string public constant FAIL_WITHDRAW = '24';
    string public constant FAIL_CLOSE_BORROW = '25';
    string public constant FAIL_KILL_BORROW = '26';
    string public constant ZERO_ADDRESS = '22';
    string public constant INVALID_PARAMETERS = '28'; 
    string public constant FAIL_LOAN_DELEGATEE_CHANGE = '32';
    string public constant FAIL_LOAN_TOKEN_BURN = '33';
    string public constant FEES_ACCRUED_INSUFFICIENT = '34';


    //Controller errors
    string public constant LIST_SIZES_NOT_EQUAL = '36';
    string public constant POOL_LIST_ALREADY_SET = '37';
    string public constant POOL_ALREADY_LISTED = '38';
    string public constant POOL_NOT_LISTED = '39';
    string public constant CALLER_NOT_POOL = '40';
    string public constant REWARDS_CASH_TOO_LOW = '41';
    string public constant FAIL_BECOME_IMPLEMENTATION = '42';
    string public constant INSUFFICIENT_DEPOSITED = '43';
    string public constant NOT_CLAIMABLE = '44';
    string public constant LOCKED = '45';
}