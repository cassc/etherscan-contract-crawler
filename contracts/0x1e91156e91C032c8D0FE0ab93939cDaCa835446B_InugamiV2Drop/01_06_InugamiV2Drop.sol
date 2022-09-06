// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*                                                          
@@@  @@@  @@@  @@@  @@@   @@@@@@@@   @@@@@@   @@@@@@@@@@   @@@  
@@@  @@@@ @@@  @@@  @@@  @@@@@@@@@  @@@@@@@@  @@@@@@@@@@@  @@@  
@@!  @@[email protected][email protected]@@  @@!  @@@  [email protected]@        @@!  @@@  @@! @@! @@!  @@!  
[email protected]!  [email protected][email protected][email protected]!  [email protected]!  @[email protected]  [email protected]!        [email protected]!  @[email protected]  [email protected]! [email protected]! [email protected]!  [email protected]!  
[email protected]  @[email protected] [email protected]!  @[email protected]  [email protected]!  [email protected]! @[email protected][email protected]  @[email protected][email protected][email protected]!  @!! [email protected] @[email protected]  [email protected]  
!!!  [email protected]!  !!!  [email protected]!  !!!  !!! [email protected]!!  [email protected]!!!!  [email protected]!   ! [email protected]!  !!!  
!!:  !!:  !!!  !!:  !!!  :!!   !!:  !!:  !!!  !!:     !!:  !!:  
:!:  :!:  !:!  :!:  !:!  :!:   !::  :!:  !:!  :!:     :!:  :!:  
 ::   ::   ::  ::::: ::   ::: ::::  ::   :::  :::     ::    ::  
:    ::    :    : :  :    :: :: :    :   : :   :      :    :    

Contract - https://t.me/geimskip
*/

import "./Uniswap.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract InugamiV2Drop is Ownable {

    IERC20 public _oldInugamiContract;
    IERC20 public _newToken;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    mapping(address=>uint) public allowances;

    constructor (IERC20 newToken) {
        _oldInugamiContract = IERC20(0x5D8038644608d1f849eD2C6863A2Ea667e53371A);
        _newToken = newToken;
    }

    function setAllowance(address wallet, uint amount) external onlyOwner {
        allowances[wallet] = amount;
    }

    function setBurnAddress(address newBurnAddress) external onlyOwner {
        burnAddress = newBurnAddress;
    }

    function redeem() public {
        redeemOther(msg.sender);
    }

    function redeemOther(address wallet) public {
        uint256 amount = _oldInugamiContract.balanceOf(wallet);

        if (amount > 0) {
            require(_oldInugamiContract.allowance(wallet, address(this)) > amount, "Dropper is not approved for old tokens on this wallet.");
            _oldInugamiContract.transferFrom(wallet, burnAddress, amount);
        }

        if (allowances[wallet] > 0) {
            amount += allowances[wallet];
            allowances[wallet] = 0;
        }

        if (amount > 0) {
            _newToken.transfer(wallet, amount);      
        } 
    }

    function withdrawTokens(IERC20 token) external onlyOwner {
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    function getClaimableAmount(address wallet) public view returns (uint256) {
        uint256 amount = _oldInugamiContract.balanceOf(wallet);
        return amount + allowances[wallet];
    }
}