// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./Lottery.sol";
import "./CrowdSale.sol";
import "./Lending.sol";

contract CryptoLottery is CrowdSale, Lending {
    /**
      Crypto Lottery 
      cryptolottery.top
    */
    
    uint private constant _ico_price = 200000000000; // one token price
    uint private constant _ico_soft_cap = 100 * 10 ** 18;
    uint private constant _interval = 86400;
    uint private constant _ticket_p = 10000000000000000;
    uint private constant _f = 20;
    uint private constant _ico_time = 86400 * 120;
    uint private constant _n_game_reward = 1000 * 10**18;
    uint private constant _ticket_p_cl = 10000 * 10**18;

    constructor() CrowdSale(
        _ico_price, 
        _interval, 
        _ticket_p, 
        _ticket_p_cl, 
        _f, 
        _ico_soft_cap, 
        _ico_time, 
        _n_game_reward
        ) {}
}