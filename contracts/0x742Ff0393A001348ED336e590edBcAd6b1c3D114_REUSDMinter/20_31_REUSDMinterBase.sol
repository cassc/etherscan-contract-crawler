// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "../IREUSD.sol";
import "./IREUSDMinterBase.sol";
import "../Library/CheapSafeERC20.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

using CheapSafeERC20 for IERC20;

/**
    Functionality for a contract that wants to mint REUSD

    It knows how to mint the correct amount and take payment from an accepted stablecoin
 */
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

    /** 
        Gets the amount of REUSD that will be minted for an amount of an acceptable payment token
        Reverts if the payment token is not accepted
        
        All accepted stablecoins have 6 or 18 decimals
    */
    function getREUSDAmount(IERC20 paymentToken, uint256 paymentTokenAmount)
        public
        view
        returns (uint256 reusdAmount)
    {        
        return stablecoins.getMultiplyFactor(paymentToken) * paymentTokenAmount;
    }

    /**
        This will:
            Take payment (or revert if the payment token is not acceptable)
            Send the payment to the custodian address
            Mint REUSD
     */
    function mintREUSDCore(address from, IERC20 paymentToken, address recipient, uint256 reusdAmount)
        internal
    {
        uint256 factor = stablecoins.getMultiplyFactor(paymentToken);
        uint256 paymentAmount = reusdAmount / factor;
        unchecked { if (paymentAmount * factor != reusdAmount) { ++paymentAmount; } }
        paymentToken.safeTransferFrom(from, address(custodian), paymentAmount);
        REUSD.mint(recipient, reusdAmount);
        emit MintREUSD(from, paymentToken, reusdAmount);
        StorageSlot.getUint256Slot(TotalMintedSlot).value += reusdAmount;
        totalReceivedSlot(paymentToken).value += paymentAmount;
    }
}