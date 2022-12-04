// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../IREUSD.sol";
import "./IREUSDMinterBase.sol";
import "../Library/CheapSafeERC20.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

using CheapSafeERC20 for IERC20;

abstract contract REUSDMinterBase is IREUSDMinterBase
{
    bytes32 private constant TotalMintedSlot = keccak256("SLOT:REUSDMinterBase:totalMinted");
    bytes32 private constant TotalReceivedSlotPrefix = keccak256("SLOT:REUSDMinterBase:totalReceived");

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IREUSD public immutable REUSD;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IREStablecoins public immutable stablecoins;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IRECustodian public immutable custodian;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IRECustodian _custodian, IREUSD _REUSD, IREStablecoins _stablecoins)
    {
        assert(_REUSD.isREUSD() && _stablecoins.isREStablecoins() && _custodian.isRECustodian());
        REUSD = _REUSD;
        stablecoins = _stablecoins;
        custodian = _custodian;
    }    

    function totalMinted() public view returns (uint256) { return StorageSlot.getUint256Slot(TotalMintedSlot).value; }
    function totalReceivedSlot(IERC20 paymentToken) private pure returns (StorageSlot.Uint256Slot storage) { return StorageSlot.getUint256Slot(keccak256(abi.encodePacked(TotalReceivedSlotPrefix, paymentToken))); }
    function totalReceived(IERC20 paymentToken) public view returns (uint256) { return totalReceivedSlot(paymentToken).value; }

    function getREUSDAmount(IERC20 paymentToken, uint256 paymentTokenAmount)
        public
        view
        returns (uint256 reusdAmount)
    {        
        return stablecoins.getStablecoinConfig(address(paymentToken)).decimals == 6 ? paymentTokenAmount * 10**12 : paymentTokenAmount;
    }

    function mintREUSDCore(address from, IERC20 paymentToken, address recipient, uint256 reusdAmount)
        internal
    {
        uint256 paymentAmount = stablecoins.getStablecoinConfig(address(paymentToken)).decimals == 6 ? reusdAmount / 10**12 : reusdAmount;
        paymentToken.safeTransferFrom(from, address(custodian), paymentAmount);
        REUSD.mint(recipient, reusdAmount);
        emit MintREUSD(from, paymentToken, reusdAmount);
        StorageSlot.getUint256Slot(TotalMintedSlot).value += reusdAmount;
        totalReceivedSlot(paymentToken).value += paymentAmount;
    }
}