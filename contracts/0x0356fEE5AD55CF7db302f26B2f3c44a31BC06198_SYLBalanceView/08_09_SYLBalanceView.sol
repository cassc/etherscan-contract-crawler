// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SYLVestingWallet.sol";

contract SYLBalanceView {
    IERC20 public constant erc20 = IERC20(0x92925Acf2771Bc59143228499f9610FE5176eb9C);
    address public constant lpPool = 0xc134C1A24a054154a997152668291654ee98850B;

    SYLVestingWallet[] public vestingWallets;

    constructor() {
        // treasury
        vestingWallets.push(SYLVestingWallet(0x7bd26798937cF17956bBB05291C5D705F385A483));
        // team & dev
        vestingWallets.push(SYLVestingWallet(0x7621D3bb2b75bb6707f23DC79E804A6B9ECC8ED5));
        // private sale
        vestingWallets.push(SYLVestingWallet(0x7e4A90f5452Ab77442f1B9656eE2b38d348823e5));
        // marketing
        vestingWallets.push(SYLVestingWallet(0x00818215ae894f8dA60f68aB508D713E0F79f720));
        // future reserve
        vestingWallets.push(SYLVestingWallet(0x8Bfd9c8d31e1F009e3Bd17659595723Cce4c688d));
        // ecosystem
        vestingWallets.push(SYLVestingWallet(0xF1Cf01CC54BF67E6d7246765887347ba96c4D1fc));
    }

    // @return totalSupply, circulatingSupply, burntSupply, treasury, treasuryVested,
    // team, teamVested, privateSale, privateSaleVested, marketing, marketingVested,
    // futureReserve, futureReserveVested, ecosystem, ecosystemVested, lpPool
    function getBalances() public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](16);
        uint256 locked = 0;

        for (uint8 i = 0; i < vestingWallets.length; i++) {
            balances[(i + 2) * 2 - 1] = erc20.balanceOf(address(vestingWallets[i]));
            balances[(i + 2) * 2] = erc20.balanceOf(vestingWallets[i].beneficiary());
            locked += erc20.balanceOf(address(vestingWallets[i])) + erc20.balanceOf(vestingWallets[i].beneficiary());
        }
        balances[15] = erc20.balanceOf(lpPool);
        locked += erc20.balanceOf(lpPool);

        uint256 totalSupply = erc20.totalSupply();
        balances[0] = totalSupply;
        balances[1] = totalSupply - locked;
        balances[2] = 1e26 - totalSupply;

        return balances;
    }
}