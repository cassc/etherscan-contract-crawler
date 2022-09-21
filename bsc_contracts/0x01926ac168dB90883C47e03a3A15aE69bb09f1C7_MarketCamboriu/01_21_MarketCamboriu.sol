// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Master.sol";

contract MarketCamboriu is Ownable{

    IERC20 amt;
    IERC20 usdt;
    IERC20 btcb;
    Master master;

    address adminWallet;
    address addrAmt = 0x6Ae0A238a6f51Df8eEe084B1756A54dD8a8E85d3;
    address addrUsdt = 0x55d398326f99059fF775485246999027B3197955;
    address addrBtcb = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;

    uint256 precio;   // AMT equivalen a 1 USD

    constructor(address _adminWallet, uint256 _precio){
        amt = IERC20(addrAmt);
        usdt = IERC20(addrUsdt);
        adminWallet = _adminWallet;

        precio = _precio;
    }

    function buy(uint256 amount) public{ // amount en USDT
        require(amount > 10, "NO POSEE SUFICIENTE USDT");
        require(usdt.balanceOf(msg.sender) >= amount, "NO POSEE SUFICIENTE USDT");

        usdt.transferFrom(msg.sender, adminWallet, amount);
        amt.transfer(msg.sender, amount * precio);
    }

    function vaciarTienda() public onlyOwner{
        uint256 cantidadARetirar = amt.balanceOf(address(this));
        amt.transfer(msg.sender, cantidadARetirar );
    }

    function charge(uint256 snapId) public onlyOwner{
    
        uint256 amount = master.charge(snapId);
        btcb.transfer(msg.sender,amount);
    }

    function setMaster(address master_) public onlyOwner{
		master = Master(master_); 
	}
}