// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IGooHolder } from "./interfaces/IGooHolder.sol";
import { IwGoo } from "./interfaces/IwGoo.sol";

contract wGooMinter is Ownable {
    using SafeERC20 for IERC20;

    IwGoo public immutable wGoo;
    IERC20 public immutable goo;
    IGooHolder public gooHolder;
    
    uint256 public wrapFeeRate = 0;
    uint256 public unWrapFeeRate = 30;

    uint256 private constant FEE_BASE = 1000;
    uint256 private constant MAX_WRAP_FEE = 100;
    uint256 private constant MAX_UNWRAP_FEE = 300;

    constructor (address _wGoo, address _goo, address _Holder) {
        wGoo = IwGoo(_wGoo);
        goo = IERC20(_goo);
        gooHolder = IGooHolder(_Holder);
    }

    function setGooHolder(address _Holder) external onlyOwner {
        require(_Holder != address(0), "Invalid reactor address");
        gooHolder = IGooHolder(_Holder);
    }

    function changeWrapFeeRate(uint256 newFee) external onlyOwner {
        require(newFee < MAX_WRAP_FEE, "too big");
        wrapFeeRate = newFee;
    }

    function changeunWrapFeeRate(uint256 newFee) external onlyOwner {
        require(newFee < MAX_UNWRAP_FEE, "too big");
        unWrapFeeRate = newFee;
    }

    function wrap(uint256 gooAmount) external {
        goo.safeTransferFrom(msg.sender, address(gooHolder), gooAmount);
        uint256 fee = gooAmount * wrapFeeRate/FEE_BASE;
        uint256 wGooAmount = gooAmount-fee;
        uint256 gooTotal = gooHolder.totalGoo();
        uint256 wGooTotal = wGoo.totalSupply();
        if (gooTotal > 0 && wGooTotal > 0) {
            wGooAmount = (gooAmount-fee) * wGooTotal / gooTotal; 
        } 
        gooHolder.depositGoo(gooAmount);
        gooHolder.addFee(fee);
        wGoo.mint(msg.sender, wGooAmount);
    }

    function unwrap(uint256 wGooAmount) external {
        uint256 noFeeAmount = wGooAmount * (FEE_BASE-unWrapFeeRate)/FEE_BASE;
        uint256 gooTotal = gooHolder.totalGoo();
        uint256 wGooTotal = wGoo.totalSupply();
        uint256 gooAmount = noFeeAmount * gooTotal / wGooTotal;   
        gooHolder.addFee((wGooAmount - noFeeAmount) * gooTotal/ wGooTotal);
        wGoo.burnFrom(msg.sender, wGooAmount);
        gooHolder.withdrawGoo(gooAmount, msg.sender);
    }

    function getWrappedAmount(uint256 gooAmount) external view returns(uint256) {
        if (wGoo.totalSupply() == 0 || gooHolder.totalGoo() == 0) {
            return gooAmount * (FEE_BASE-wrapFeeRate) / FEE_BASE;
        }
        return (gooAmount * wGoo.totalSupply() / gooHolder.totalGoo() * (FEE_BASE-wrapFeeRate) / FEE_BASE);
    }
    function getUnwrappedAmount(uint256 wGooAmount) external view returns(uint256) {
        return (wGooAmount * gooHolder.totalGoo() / wGoo.totalSupply() * (FEE_BASE-unWrapFeeRate) / FEE_BASE);
    }
}