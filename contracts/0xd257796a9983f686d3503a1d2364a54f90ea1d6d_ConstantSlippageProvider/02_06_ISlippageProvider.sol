pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ISlippageProvider {
    function getMinDepositSlippage(address asset, uint256 value) external view returns (uint8 minSlippage);
    function getMinRedeemSlippage(uint256 shares) external view returns (uint8 minSlippage);
}