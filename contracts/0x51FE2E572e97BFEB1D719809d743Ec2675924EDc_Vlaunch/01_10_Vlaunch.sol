// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./TokenVesting.sol";

contract Vlaunch is ERC20 {
    
    struct Alocation {
        address privateSale;
        address ido;
        address marketmaker;
        address idoLocked;
        address community;
        address liquidity;
        address marketing;
        address partners;
        address staking;
        address activity;
        address reserve;
        address advisors;
        address team;
    }
    
    /**
     * @dev Mints total supply of tokens and transfers them to `owner`.
     *
     * See {ERC20-constructor}.
     */
    constructor(
        address owner,
        Alocation memory alocation
    ) ERC20("VLaunch", "VPAD") {
        _mint(alocation.privateSale, 100_000_000e18);
        _mint(alocation.ido, 30_000_000e18);
        _mint(alocation.marketmaker, 30_000_000e18);
        _mint(alocation.activity, 4_000_000e18);
        _mint(alocation.liquidity, 25_000_000e18);
        _mint(alocation.marketing, 6_250_000e18);
        _mint(alocation.partners, 2_500_000e18);
        _mint(alocation.staking, 180_000_000e18);
        _mint(alocation.advisors, 20_000_000e18);
        
        TokenVesting _idoLocked = new TokenVesting(owner, alocation.idoLocked, 1640383200, 365 days, 486 days, true);
        _mint(address(_idoLocked), 20_000_000e18);
        TokenVesting _community = new TokenVesting(owner, alocation.community, 1640383200, 365 days, 486 days, true);
        _mint(address(_community), 30_000_000e18);
        TokenVesting _liquidity = new TokenVesting(owner, alocation.liquidity, 1640383200, 0, 60 days, true);
        _mint(address(_liquidity), 25_000_000e18);
        TokenVesting _marketing = new TokenVesting(owner, alocation.marketing, 1640383200, 0, 730 days, true);
        _mint(address(_marketing), 143_750_000e18);
        TokenVesting _partners = new TokenVesting(owner, alocation.partners, 1640383200, 0, 730 days, true);
        _mint(address(_partners), 57_500_000e18);
        TokenVesting _activity = new TokenVesting(owner, alocation.activity, 1640383200, 0, 304 days, true);
        _mint(address(_activity), 36_000_000e18);
        TokenVesting _reserve = new TokenVesting(owner, alocation.reserve, 1640383200, 365 days, 1095 days, true);
        _mint(address(_reserve), 150_000_000e18);
        TokenVesting _team = new TokenVesting(owner, alocation.team, 1640383200, 365 days, 912 days, true);
        _mint(address(_team), 140_000_000e18);
    }
}