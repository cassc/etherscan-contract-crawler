// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "../interfaces/ISlippageProvider.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @author YLDR <[email protected]>
contract ConstantSlippageProvider is ISlippageProvider, Ownable {
    uint8 public slippage;

    constructor(uint8 _slippage) {
        slippage = _slippage;
    }

    function updateSlippage(uint8 _slippage) external onlyOwner {
        slippage = _slippage;
    }

    function getMinDepositSlippage(address asset, uint256 value) external view returns (uint8 minSlippage) {
        return slippage;
    }

    function getMinRedeemSlippage(uint256 shares) external view returns (uint8 minSlippage) {
        return slippage;
    }
}