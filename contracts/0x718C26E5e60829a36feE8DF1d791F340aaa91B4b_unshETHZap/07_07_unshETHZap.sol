// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "communal/ReentrancyGuard.sol";
import "communal/SafeERC20.sol";

interface ILSDVault {
    function deposit(address lsd, uint256 amount) external;
}

interface FRXETH {
    function submitAndDeposit(address recipient) payable external;
}

interface RETH {
    function swapTo(uint256 _uniswapPortion, uint256 _balancerPortion, uint256 _minTokensOut, uint256 _idealTokensOut) payable external;
}

contract unshETHZap is ReentrancyGuard  {
    using SafeERC20 for IERC20;

    address public lsdVaultAddress; // 0xE76Ffee8722c21b390eebe71b67D95602f58237F;
    address public unshETHAddress; //0x846982C0a47b0e9f4c13F3251ba972Bb8D32a8cA;

    address public wstETHAddress; //0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    address public frxETHAddress; //0xbafa44efe7901e04e39dad13167d089c559c1138;
    address public sfrxETHAddress; //0xac3e018457b222d93114458476f3e3416abbe38f;

    address public rETHRouterAddress; //0x16D5A408e807db8eF7c578279BEeEe6b228f1c1C;
    address public rETHAddress; //0xae78736cd615f374d3085123a210448e74fc6393;

    //constructor that sets up all the addresses
    constructor(address _lsdVaultAddress, address _unshETHAddress, address _wstETHAddress, address _frxETHAddress, address _sfrxETHAddress, address _rETHRouterAddress, address _rETHAddress) {
        lsdVaultAddress = _lsdVaultAddress;
        unshETHAddress = _unshETHAddress;
        wstETHAddress = _wstETHAddress;
        frxETHAddress = _frxETHAddress;
        sfrxETHAddress = _sfrxETHAddress;
        rETHRouterAddress = _rETHRouterAddress;
        rETHAddress = _rETHAddress;

        //give infinte approval for the lsd vault to spend the wstETH, sfrxETH, and rETH
        IERC20(wstETHAddress).approve(lsdVaultAddress, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        IERC20(sfrxETHAddress).approve(lsdVaultAddress, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        IERC20(rETHAddress).approve(lsdVaultAddress, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    }
    
    function mint_wstETH() external payable {

        // Mint wstETH
        (bool success, )= address(wstETHAddress).call{value:msg.value}("");
        
        // Check the success of the wstETH mint
        require(success, "wstETH minting failed");

        // Get balance of wstETH minted
        uint256 wstETHBalance = IERC20(wstETHAddress).balanceOf(address(this));

        // Call LSDVault to mint unshETH
        ILSDVault(lsdVaultAddress).deposit(wstETHAddress, wstETHBalance);

        // Send unsheth to the msg.sender
        IERC20(unshETHAddress).transfer(msg.sender, IERC20(unshETHAddress).balanceOf(address(this)));
    }

    function mint_sfrxETH() external payable {

        // Mint sfrxETH
        FRXETH(frxETHAddress).submitAndDeposit{value:msg.value}(address(this));

        // Get balance of sfrxETH minted
        uint256 sfrxETHBalance = IERC20(sfrxETHAddress).balanceOf(address(this));

        // Check to see that the balance minted is greater than 0
        require(sfrxETHBalance > 0, 'sfrxETH minting failed');

        // Call LSDVault to mint unshETH
        ILSDVault(lsdVaultAddress).deposit(sfrxETHAddress, sfrxETHBalance);

        // Send unsheth to the msg.sender
        IERC20(unshETHAddress).transfer(msg.sender, IERC20(unshETHAddress).balanceOf(address(this)));
    }

    function mint_rETH(uint256 _uniswapPortion, uint256 _balancerPortion, uint256 _minTokensOut, uint256 _idealTokensOut) external payable {

        //Mint rETH
        RETH(rETHRouterAddress).swapTo{value:msg.value}(_uniswapPortion, _balancerPortion, _minTokensOut, _idealTokensOut);

        // Get balance of sfrxETH minted
        uint256 rETHBalance = IERC20(rETHAddress).balanceOf(address(this));

        // Check to see that the balance minted is greater than or equal to the minTokensOut
        require(rETHBalance >= _minTokensOut, 'rETH minting failed');

        // Call LSDVault to mint unshETH
        ILSDVault(lsdVaultAddress).deposit(rETHAddress, rETHBalance);

        // Send unsheth to the msg.sender
        IERC20(unshETHAddress).transfer(msg.sender, IERC20(unshETHAddress).balanceOf(address(this)));
    }
}