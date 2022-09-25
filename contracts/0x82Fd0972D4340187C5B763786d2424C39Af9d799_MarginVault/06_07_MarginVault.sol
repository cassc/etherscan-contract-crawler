// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { FPI } from "../libs/FixedPointInt256.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * MarginVault Error Codes
 * V1: invalid short onToken amount
 * V2: invalid short onToken index
 * V3: short onToken address mismatch
 * V4: invalid long onToken amount
 * V5: invalid long onToken index
 * V6: long onToken address mismatch
 * V7: invalid collateral amount
 * V8: invalid collateral token index
 * V9: collateral token address mismatch
 * V10: shortONtoken should be empty when performing addShort or the same as vault already have
 * V11: _collateralAssets and _amounts length mismatch
 * V12: _collateralAssets and vault.collateralAssets length mismatch
 * V13: _amount for withdrawing long is exceeding unused long amount in the vault
 * V14: amounts for withdrawing collaterals should be same length as collateral assets of vault
 */

/**
 * @title MarginVault
 * @notice A library that provides the Controller with a Vault struct and the functions that manipulate vaults.
 * Vaults describe discrete position combinations of long options, short options, and collateral assets that a user can have.
 */
library MarginVault {
    using SafeMath for uint256;
    using FPI for FPI.FixedPointInt;

    uint256 internal constant BASE = 8;

    // vault is a struct of 6 arrays that describe a position a user has, a user can have multiple vaults.
    struct Vault {
        address shortONtoken;
        // addresses of onTokens a user has shorted (i.e. written) against this vault
        // addresses of onTokens a user has bought and deposited in this vault
        // user can be long onTokens without opening a vault (e.g. by buying on a DEX)
        // generally, long onTokens will be 'deposited' in vaults to act as collateral in order to write onTokens against (i.e. in spreads)
        address longONtoken;
        // addresses of other ERC-20s a user has deposited as collateral in this vault
        address[] collateralAssets;
        // quantity of onTokens minted/written for each onToken address in onTokenAddress
        uint256 shortAmount;
        // quantity of onTokens owned and held in the vault for each onToken address in longONtokens
        uint256 longAmount;
        uint256 usedLongAmount;
        // quantity of ERC-20 deposited as collateral in the vault for each ERC-20 address in collateralAssets
        uint256[] collateralAmounts;
        // Collateral which is currently used for minting onTokens and can't be used until expiry
        uint256[] reservedCollateralAmounts;
        uint256[] usedCollateralValues;
        uint256[] availableCollateralAmounts;
    }

    /**
     * @dev increase the short onToken balance in a vault when a new onToken is minted
     * @param _vault vault to add or increase the short position in
     * @param _amount number of _shortONtoken being minted from the user's vault
     */
    function addShort(Vault storage _vault, uint256 _amount) external {
        require(_amount > 0, "V1");
        _vault.shortAmount = _vault.shortAmount.add(_amount);
    }

    /**
     * @dev decrease the short onToken balance in a vault when an onToken is burned
     * @param _vault vault to decrease short position in
     * @param _amount number of _shortONtoken being reduced in the user's vault
     * @param _newCollateralRatio ratio represents how much of already used collateral will be used after burn
     * @param _newUsedLongAmount new used long amount
     */
    function removeShort(
        Vault storage _vault,
        uint256 _amount,
        FPI.FixedPointInt memory _newCollateralRatio,
        uint256 _newUsedLongAmount
    ) external returns (uint256[] memory freedCollateralAmounts, uint256[] memory freedCollateralValues) {
        // check that the removed short onToken exists in the vault

        uint256 newShortAmount = _vault.shortAmount.sub(_amount);
        uint256 collateralAssetsLength = _vault.collateralAssets.length;

        uint256[] memory newReservedCollateralAmounts = new uint256[](collateralAssetsLength);
        uint256[] memory newUsedCollateralValues = new uint256[](collateralAssetsLength);
        freedCollateralAmounts = new uint256[](collateralAssetsLength);
        freedCollateralValues = new uint256[](collateralAssetsLength);
        uint256[] memory newAvailableCollateralAmounts = _vault.availableCollateralAmounts;
        // If new short amount is zero, just free all reserved collateral
        if (newShortAmount == 0) {
            newAvailableCollateralAmounts = _vault.collateralAmounts;

            newReservedCollateralAmounts = new uint256[](collateralAssetsLength);
            newUsedCollateralValues = new uint256[](collateralAssetsLength);
            freedCollateralAmounts = _vault.reservedCollateralAmounts;
            freedCollateralValues = _vault.usedCollateralValues;
        } else {
            // _newCollateralRatio is multiplier which is used to calculate the new used collateral values and used amounts
            for (uint256 i = 0; i < collateralAssetsLength; i++) {
                uint256 collateralDecimals = uint256(IERC20Metadata(_vault.collateralAssets[i]).decimals());
                newReservedCollateralAmounts[i] = toFPImulAndBack(
                    _vault.reservedCollateralAmounts[i],
                    collateralDecimals,
                    _newCollateralRatio,
                    true
                );

                newUsedCollateralValues[i] = toFPImulAndBack(
                    _vault.usedCollateralValues[i],
                    BASE,
                    _newCollateralRatio,
                    true
                );
                freedCollateralAmounts[i] = _vault.reservedCollateralAmounts[i].sub(newReservedCollateralAmounts[i]);
                freedCollateralValues[i] = _vault.usedCollateralValues[i].sub(newUsedCollateralValues[i]);
                newAvailableCollateralAmounts[i] = newAvailableCollateralAmounts[i].add(freedCollateralAmounts[i]);
            }
        }
        _vault.shortAmount = newShortAmount;
        _vault.reservedCollateralAmounts = newReservedCollateralAmounts;
        _vault.usedCollateralValues = newUsedCollateralValues;
        _vault.availableCollateralAmounts = newAvailableCollateralAmounts;
        _vault.usedLongAmount = _newUsedLongAmount;
    }

    /**
     * @dev helper function to transform uint256 to FPI multiply by another FPI and transform back to uint256
     */
    function toFPImulAndBack(
        uint256 _value,
        uint256 _decimals,
        FPI.FixedPointInt memory _multiplicator,
        bool roundDown
    ) internal pure returns (uint256) {
        return FPI.fromScaledUint(_value, _decimals).mul(_multiplicator).toScaledUint(_decimals, roundDown);
    }

    /**
     * @dev increase the long onToken balance in a vault when an onToken is deposited
     * @param _vault vault to add a long position to
     * @param _longONtoken address of the _longONtoken being added to the user's vault
     * @param _amount number of _longONtoken the protocol is adding to the user's vault
     */
    function addLong(
        Vault storage _vault,
        address _longONtoken,
        uint256 _amount
    ) external {
        require(_amount > 0, "V4");
        address existingLong = _vault.longONtoken;
        require((existingLong == _longONtoken) || (existingLong == address(0)), "V6");

        _vault.longAmount = _vault.longAmount.add(_amount);
        _vault.longONtoken = _longONtoken;
    }

    /**
     * @dev decrease the long onToken balance in a vault when an onToken is withdrawn
     * @param _vault vault to remove a long position from
     * @param _longONtoken address of the _longONtoken being removed from the user's vault
     * @param _amount number of _longONtoken the protocol is removing from the user's vault
     */
    function removeLong(
        Vault storage _vault,
        address _longONtoken,
        uint256 _amount
    ) external {
        // check that the removed long onToken exists in the vault at the specified index
        require(_vault.longONtoken == _longONtoken, "V6");

        uint256 vaultLongAmountBefore = _vault.longAmount;
        require((vaultLongAmountBefore - _vault.usedLongAmount) >= _amount, "V13");

        _vault.longAmount = vaultLongAmountBefore.sub(_amount);
    }

    /**
     * @dev increase the collaterals balances in a vault
     * @param _vault vault to add collateral to
     * @param _collateralAssets addresses of the _collateralAssets being added to the user's vault
     * @param _amounts number of _collateralAssets being added to the user's vault
     */
    function addCollaterals(
        Vault storage _vault,
        address[] calldata _collateralAssets,
        uint256[] calldata _amounts
    ) external {
        require(_collateralAssets.length == _amounts.length, "V11");
        require(_collateralAssets.length == _vault.collateralAssets.length, "V12");
        for (uint256 i = 0; i < _collateralAssets.length; i++) {
            _vault.collateralAmounts[i] = _vault.collateralAmounts[i].add(_amounts[i]);
            _vault.availableCollateralAmounts[i] = _vault.availableCollateralAmounts[i].add(_amounts[i]);
        }
    }

    /**
     * @dev decrease the collateral balance in a vault
     * @param _vault vault to remove collateral from
     * @param _amounts number of _collateralAssets being removed from the user's vault
     */
    function removeCollateral(Vault storage _vault, uint256[] memory _amounts) external {
        address[] memory collateralAssets = _vault.collateralAssets;
        require(_amounts.length == collateralAssets.length, "V14");

        uint256[] memory availableCollateralAmounts = _vault.availableCollateralAmounts;
        uint256[] memory collateralAmounts = _vault.collateralAmounts;
        for (uint256 i = 0; i < collateralAssets.length; i++) {
            collateralAmounts[i] = _vault.collateralAmounts[i].sub(_amounts[i]);
            availableCollateralAmounts[i] = availableCollateralAmounts[i].sub(_amounts[i]);
        }
        _vault.collateralAmounts = collateralAmounts;
        _vault.availableCollateralAmounts = availableCollateralAmounts;
    }

    /**
     * @dev decrease vaults avalaible collateral and long to update vaults used assets data
     * used when vaults mint option to lock provided assets
     * @param _vault vault to remove collateral from
     * @param _amounts amount of collateral assets being locked in the user's vault
     * @param _usedLongAmount amount of long onToken being locked in the user's vault
     * @param _usedCollateralValues values of collaterals amounts being locked
     */
    function useVaultsAssets(
        Vault storage _vault,
        uint256[] memory _amounts,
        uint256 _usedLongAmount,
        uint256[] memory _usedCollateralValues
    ) external {
        require(
            _amounts.length == _vault.collateralAssets.length,
            "Amounts for collateral is not same length as collateral assets"
        );

        for (uint256 i = 0; i < _amounts.length; i++) {
            uint256 newReservedCollateralAmount = _vault.reservedCollateralAmounts[i].add(_amounts[i]);

            _vault.reservedCollateralAmounts[i] = newReservedCollateralAmount;
            require(
                _vault.reservedCollateralAmounts[i] <= _vault.collateralAmounts[i],
                "Trying to use collateral which exceeds vault's balance"
            );
            _vault.availableCollateralAmounts[i] = _vault.collateralAmounts[i].sub(newReservedCollateralAmount);
            _vault.usedCollateralValues[i] = _vault.usedCollateralValues[i].add(_usedCollateralValues[i]);
        }

        _vault.usedLongAmount = _vault.usedLongAmount.add(_usedLongAmount);
    }
}