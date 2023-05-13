// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Presale.sol";

contract CFA is Context, Presale, Pausable {
    uint constant FEE = 500;
    uint constant ONE_HUNDRED_PERCENT = 10000;

    mapping(address => bool) private blockedBots;

    constructor(uint _startTime) 
    Presale(
        500000000 ether,
        500000000 ether,
        msg.sender,
        _startTime,
        "Chick Fil A Coin",
        "CFA"
    )
    {
        blockedBots[0x00004EC2008200e43b243a000590d4Cd46360000] = true;
        blockedBots[0x927300011e3E02C4858a1B000027cc007F000000] = true;
        blockedBots[0x3C005bA2000F0000ba000d69000AC8Ec003800BC] = true;
        blockedBots[0x758E8229Dd38cF11fA9E7c0D5f790b4CA16b3B16] = true;
        blockedBots[0x000000000005aF2DDC1a93A03e9b7014064d3b8D] = true;
        blockedBots[0x00000000003b3cc22aF3aE1EAc0440BcEe416B40] = true;
        blockedBots[0x26cE7c1976C5eec83eA6Ac22D83cB341B08850aF] = true;
        blockedBots[0x758E8229Dd38cF11fA9E7c0D5f790b4CA16b3B16] = true;
        blockedBots[0x1B1979f530C0A93c68F57F412C97Bf0FD5E69046] = true;
        blockedBots[0xC305000000Ff00002b001B6300dDA3f0bA56B1Bd] = true;
        _pause();
    }

    modifier notSunday(address recipient) {
        // make expections for transfers to owner for taxes
        require(
            paused() ||
            !(is_sunday() && recipient == pair)
        , "no sells are allowed on Sunday");
        _;
    }

    function endLGE() public virtual override onlyOwner{
        super.endLGE();
        if(paused()){
            _unpause();
        }
    }


    function togglePause() external onlyOwner{
        paused() ? _unpause() : _pause();
    }

    function _beforeTokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override notSunday(recipient){
        require(!blockedBots[sender] && !blockedBots[recipient], "Blacklisted");
    }

    function is_sunday() public view returns(bool){
        return (_is_sunday(block.timestamp));
    }

    function _transfer(address from, address to, uint amount) internal virtual override {
        if(!paused() && (to == pair || from == pair)){
            uint tax = amount * FEE / ONE_HUNDRED_PERCENT;
            // uint halfTax = tax/2;
            super._transfer(from, owner(), tax);
            // _burn(from, tax-halfTax);
            super._transfer(from, to, amount-tax);
        }else{
            super._transfer(from, to, amount);
        }
    }

    function _is_sunday(uint timestamp) public pure returns(bool){
        // Get the day of the week for the current timestamp
        // Sunday is represented by 0 (Saturday is represented by 6)
        uint256 dayOfWeek = ((timestamp / 86400) + 4) % 7;

        // Return true if it's a Sunday in GMT, false otherwise
        return dayOfWeek == 0;    }
}