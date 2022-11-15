// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LeagueOfParaohs is ERC20, ERC20Burnable, Ownable {
    uint256 public constant MAX_SUPPLY = 10_000_000_000_000_000_000_000_000_000;

    constructor(   
        address _Play_to_Earn,
        address _Liquidity,
        address _Staking,
        address _Private,
        address _Team,
        address _Public,
        address _Marketing,
        address _NFT_Staking,
        address _Centralized_Exchange,
        address _Advisors,
        address _Community,
        address _Ecosystem_Fund
    )
     ERC20("LeagueOfParaohs", "LOP") {
    _mint(_Play_to_Earn , 2_500_000_000 * (10 ** decimals()));
    _mint(_Liquidity , 100_000_000 * (10 ** decimals()));
    _mint(_Staking , 1_500_000_000 * (10 ** decimals()));
    _mint(_Private , 1_000_000_000 * (10 ** decimals()));
    _mint(_Team , 2_000_000_000 * (10 ** decimals()));
    _mint(_Public , 200_000_000 * (10 ** decimals()));
    _mint(_Marketing , 500_000_000 * (10 ** decimals()));
    _mint(_NFT_Staking , 800_000_000 * (10 ** decimals()));
    _mint(_Centralized_Exchange , 500_000_000 * (10 ** decimals()));
    _mint(_Advisors , 400_000_000 * (10 ** decimals()));
    _mint(_Community , 100_000_000 * (10 ** decimals()));
    _mint(_Ecosystem_Fund , 400_000_000 * (10 ** decimals()));
    }
}