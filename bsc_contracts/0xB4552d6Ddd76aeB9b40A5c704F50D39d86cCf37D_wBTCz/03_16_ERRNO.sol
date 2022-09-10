// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
/*

ADMIN
BA00	Zero not allowed.
BA01	ONLY_MEMBER: Account does not belong to the group.
TOKEN
BT01	ONLY_MINTING_ADDRESS: Caller not minting address.
BT02	TRANSFER_TO_N: Must submit same addresses and amounts quantity.
BT03	TRANSFER: can't transfer from minting address.
BT04	TRANSFER: can't transfer to minting address.
BT05	UNWRAP: minting address can't unwrap
BT06	WRAP: can't wrap to minting address
BT07	CHANGE_MINTING_ADDRESS: please empty new minting address balance and re-submit last vote.
BT08    TRANSFER: transfer amount exceeds balance
BT09    
BT10    TRANSFER: can't transfer to zero address
BT11    TRANSFER: can't transfer from zero address
PROPOSAL
BP00	EXECUTE_ACTION: Invalid action.
BP01	EXECUTE_ACTION: Proposal not found.
BP02	GET_ACTION:	Action not found.
BP03	ADD_PROPOSAL: Pending user active proposal.
BP04	ADD_PROPOSAL: Group not active.
BP05	ADD_PROPOSAL: Too many voters.
BP06    ADD_PROPOSAL: Action not found.
BP07    VOTE: You have already voted this proposal.
BP08    VOTE: Invalid vote. 0: Disgree. 1:Agree.
BP09    ADD_MEMBER: Too many members in this group.
BP10    INVALID_PCT: Percentage must be from 1 to 100
BP11    PAUSABLE: token PAUSED
BP12    PAUSABLE: token UNPAUSED
SAFEMATH
SM00    SafeMath: addition overflow
SM01    SafeMath: subtraction overflow
SM02    SafeMath: multiplication overflow
SM03    SafeMath: division by zero
SM04    SafeMath: modulo by zero
BEP20
BE00    BEP20: decreased allowance below zero
BE01    BEP20: transfer amount exceeds allowance
BE02    BEP20: approve from the zero address
BE03    BEP20: approve to the zero address

*/
contract ERRNO {
    
    enum ErrNo{
        OK,
        BA00,
        BA01,
        BT01,
        BT02,
        BT03,
        BT04,
        BT05,
        BT06,
        BT07,
        BT08,
        BT09,
        BT10,
        BP00,
        BP01,
        BP02,
        BP03,
        BP04,
        BP05,
        BP06,
        BP07,
        BP08,
        BP09,
        BP10,
        BP11,
        BP12,
        SM00,
        SM01,
        SM02,
        SM03,
        SM04
    }
    string[50] ErrNoString=[
        "OK",
        "BA00",
        "BA01",
        "BT01",
        "BT02",
        "BT03",
        "BT04",
        "BT05",
        "BT06",
        "BT07",
        "BT08",
        "BT09",
        "BT10",
        "BP00",
        "BP01",
        "BP02",
        "BP03",
        "BP04",
        "BP05",
        "BP06",
        "BP07",
        "BP08",
        "BP09",
        "BP10",
        "BP11",
        "BP12",
        "SM00",
        "SM01",
        "SM02",
        "SM03",
        "SM04"
    ];
       
    constructor() {}
}