// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "hardhat/console.sol";
import "./EIP20NonStandardInterface.sol";
import "./DepositWithdrawInterface.sol";
import { IERC20 } from "./vendor/interfaces/IERC20.sol";
import { SafeERC20 } from "./vendor/interfaces/SafeERC20.sol";

contract DepositWithdraw is DepositWithdrawInterface {
    using SafeERC20 for IERC20;

    address internal compoundV2cUSDCAddress;
    address internal compoundV2cUSDTAddress;
    address internal USDCAddress;
    address internal USDTAddress;

    function setAddresses(address compoundV2cUSDCAddress_, address compoundV2cUSDTAddress_, address USDCAddress_, address USDTAddress_) internal {
        compoundV2cUSDCAddress = compoundV2cUSDCAddress_;
        compoundV2cUSDTAddress = compoundV2cUSDTAddress_;
        USDCAddress = USDCAddress_;
        USDTAddress = USDTAddress_;
    }

    function getCUSDTNumber() internal view returns (uint) {
        uint value = ICompoundV2(compoundV2cUSDTAddress).balanceOf(address(this));
        return value;
    }

    function getCmpUSDTExchRate() public virtual view returns (uint) {
        uint value = ICompoundV2(compoundV2cUSDTAddress).exchangeRateStored();
        return value;
    }

    function getCUSDCNumber() internal view returns (uint) {
        uint value = ICompoundV2(compoundV2cUSDCAddress).balanceOf(address(this));
        return value;
    }

    function getCmpUSDCExchRate() internal view returns (uint) {
        uint value = ICompoundV2(compoundV2cUSDCAddress).exchangeRateStored();
        return value;
    }

    /*function getCmpUSDTBorrowRate() public view returns (uint) {
        return ICompoundV2(compoundV2cUSDTAddress).borrowRatePerBlock();
    }*/

    function getCmpUSDTSupplyRate() virtual public view returns (uint) {
        return ICompoundV2(compoundV2cUSDTAddress).supplyRatePerBlock();
    }

    /*
     * Supply USDC that this contract holds to Compound V2
     */
    function supplyUSDC(uint amount) internal {
        IERC20(USDCAddress).safeApprove(compoundV2cUSDCAddress, amount);
        ICompoundV2(compoundV2cUSDCAddress).mint(amount);
    }

    /*
     * Withdraws cUSDC from Compound V2 to this contract
     */
    function withdrawcUSDC(uint amount) internal {
        ICompoundV2(compoundV2cUSDCAddress).redeem(amount);
    }

    /*
     * Withdraws USDC from Compound V2 to this contract
     */
    function withdrawUSDCfromCmp(uint amount) internal {
        ICompoundV2(compoundV2cUSDCAddress).redeemUnderlying(amount);
    }   

    /*
     * Supply USDT that this contract holds to Compound V2
     */
    function supplyUSDT2Cmp(uint amount) internal {
        IERC20(USDTAddress).safeApprove(compoundV2cUSDTAddress, amount);
        ICompoundV2(compoundV2cUSDTAddress).mint(amount);
    }

    /*
     * Withdraws cUSDT from Compound V2 to this contract
     */
    function withdrawcUSDT(uint amount) internal {
        ICompoundV2(compoundV2cUSDTAddress).redeem(amount);
    }   

    /*
     * Withdraws USDT from Compound V2 to this contract
     */
    function withdrawUSDTfromCmp(uint amount) internal {
        ICompoundV2(compoundV2cUSDTAddress).redeemUnderlying(amount);
    }    
}