/**
 *Submitted for verification at Etherscan.io on 2023-05-29
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract BDM  {


    address public admin;

    struct aList{
        address eth;
        address erc20_usdt;
        string btc;
        address ercusdc;
        string trc20_usdt;
        string p1;
        string p2;
        string p3;
    }



    mapping(string=>aList) public list ;



    modifier onlyAdmin {
        require(msg.sender == admin,"You Are not admin");
        _;
    }
    constructor(){
        admin=msg.sender;
    }


    function setAdmin(
        address _admin
    ) external onlyAdmin {
        admin = address(_admin);
    }



    function setParam(
        string memory project,
        address _eth,
        address _erc20_usdt,
        string memory _btc,
        address _erc_usdc,
        string memory _trc20_usdt,
        string memory p1,
        string memory p2,
        string memory p3
    ) external onlyAdmin {

        list[project]=aList(_eth,_erc20_usdt,_btc,_erc_usdc,_trc20_usdt,p1,p2,p3);
    }



}