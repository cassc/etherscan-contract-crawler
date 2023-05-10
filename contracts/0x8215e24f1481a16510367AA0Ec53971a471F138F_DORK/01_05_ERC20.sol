// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract DORK is ERC20 {

    // 20 bil supply
    address private constant liquidity = 0xB342d10DdED17B898433488a1ABEE9118467248C; // 80%
    address private constant team1 = 0x0D2eAa5E47bB3CBD71BA8F9E88EE7aC020f59EBF; // 10%
    address private constant team2 = 0x047ad76E3b38Ac8e526a98274a2Ee29C7C17Ef7c; // 5%
    address private constant team3 = 0x343dBd5cB5C2e3021f639bB7c5087ee5A4547bE7; // 4%
    address private constant team4 = 0x27A831Bb73811349537BA7A5121671189A40b82C; // 0.5%
    address private constant team5 = 0xfcc34D4d7f52c7DA88765604Ae4198c3468A85F2; // 0.25%
    address private constant team6 = 0x2c731f1De0251c974a3DC4b61Ec6C8555cB12888; // 0.25%


    constructor() ERC20("$DORK", "$DORK") {
        _mint(liquidity, 16000000000 * (10**18));
        _mint(team1, 2000000000 * (10**18));
        _mint(team2, 1000000000 * (10**18));
        _mint(team3, 800000000 * (10**18));
        _mint(team4, 100000000 * (10**18));
        _mint(team5, 50000000 * (10**18));
        _mint(team6, 50000000 * (10**18));
    }

}