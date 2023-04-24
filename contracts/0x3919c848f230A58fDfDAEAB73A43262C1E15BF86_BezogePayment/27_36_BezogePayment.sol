//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../accessControl/AccessProtectedUpgradable.sol";
import "../wrapper/Conversion.sol";
import "../tokens/Zogi.sol";
import "./MBLKIDOV2.sol";


contract BezogePayment is PausableUpgradeable, AccessProtectedUpgradable{

    Conversion  public  Wrapper;
    ZOGI        public  Zogi;
    IERC20      public  Bezoge;
    MBLKIDOV2   public  Ido;
    bool        private initialized;

    event MblkBoughtUsingBezoge(address user, uint256 bezogeAmount, uint256 zogiAmount);

    function init(address wrapper_, address zogi_, address bezoge_, address ido_)external initializer{
       require(!initialized);

       Zogi     = ZOGI(zogi_);
       Wrapper  = Conversion(wrapper_);
       Ido      = MBLKIDOV2(ido_); 
       Bezoge   = IERC20(bezoge_);

       __Ownable_init();
       __Pausable_init();
       initialized = true;
    }

    function approveTokens(uint256 amount)public onlyOwner{
        Bezoge.approve(address(Wrapper), amount);
        Zogi.approve(address(Ido), amount);
    }

    function getMBLKAllocationByBezoge(uint256 bezogeAmount_, address beneficiary_, string memory refId_) public 
    {
        require(Bezoge.transferFrom(msg.sender, address(this), bezogeAmount_), "Bezoge transfer failed");
        uint256 zogiBalanceBefore = Zogi.balanceOf(address(this));
        uint256 bezogeWrapAmount = (bezogeAmount_ * 98)/100;
        Wrapper.wrapBezoge(bezogeWrapAmount);
        uint256 zogiBalanceAfter = Zogi.balanceOf(address(this));
        Ido.getMBLKAllocation(2, beneficiary_, (zogiBalanceAfter - zogiBalanceBefore), refId_);

        emit MblkBoughtUsingBezoge(beneficiary_, bezogeAmount_, (zogiBalanceAfter - zogiBalanceBefore));
    }

    function withdrawBezoge(uint256 amount_)public onlyOwner{
        Bezoge.transfer(msg.sender, amount_);
    }

    function withdrawZogi(uint256 amount_)public onlyOwner{
        Zogi.transfer(msg.sender, amount_);
    }

}