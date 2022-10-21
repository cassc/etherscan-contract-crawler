// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { TrancheData, TrancheDataHelpers, BondHelpers } from "../_utils/BondHelpers.sol";

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { ITranche } from "../_interfaces/buttonwood/ITranche.sol";
import { IDiscountStrategy } from "../_interfaces/IDiscountStrategy.sol";
import { IBondController } from "../_interfaces/buttonwood/IBondController.sol";

/*
 *  @title TrancheClassDiscountStrategy
 *
 *  @dev Discount factor defined for a particular "class" of tranches.
 *       Any tranche's class is defined as the unique combination of:
 *        - it's collateraToken
 *        - it's parent bond's trancheRatios
 *        - it's seniorityIDX.
 *
 *       For example:
 *        - All AMPL [35-65] bonds can be configured to have a discount of [1, 0] and
 *        => An AMPL-A tranche token from any [35-65] bond will be applied a discount factor of 1.
 *        - All AMPL [50-50] bonds can be configured to have a discount of [0.8,0]
 *        => An AMPL-A tranche token from any [50-50] bond will be applied a discount factor of 0.8.
 *
 */
contract TrancheClassDiscountStrategy is IDiscountStrategy, OwnableUpgradeable {
    using BondHelpers for IBondController;
    using TrancheDataHelpers for TrancheData;

    uint8 private constant DECIMALS = 18;

    /// @notice Mapping between a tranche class and the discount to be applied.
    mapping(bytes32 => uint256) private _trancheDiscounts;

    /// @notice Event emitted when the defined tranche discounts are updated.
    /// @param hash The tranche class hash.
    /// @param discount The discount factor for any tranche belonging to that class.
    event UpdatedDefinedTrancheDiscounts(bytes32 hash, uint256 discount);

    /// @notice Contract initializer.
    function init() public initializer {
        __Ownable_init();
    }

    /// @notice Updates the tranche class's discount.
    /// @param classHash The tranche class (hash(collteralToken, trancheRatios, seniority)).
    /// @param discount The discount factor.
    function updateDefinedDiscount(bytes32 classHash, uint256 discount) public onlyOwner {
        if (discount > 0) {
            _trancheDiscounts[classHash] = discount;
        } else {
            delete _trancheDiscounts[classHash];
        }
        emit UpdatedDefinedTrancheDiscounts(classHash, discount);
    }

    /// @inheritdoc IDiscountStrategy
    function computeTrancheDiscount(IERC20Upgradeable token) external view override returns (uint256) {
        return _trancheDiscounts[trancheClass(ITranche(address(token)))];
    }

    /// @inheritdoc IDiscountStrategy
    function decimals() external pure override returns (uint8) {
        return DECIMALS;
    }

    /// @notice The computes the class hash of a given tranche.
    /// @dev A given tranche's computed class is the hash(collateralToken, trancheRatios, seniority).
    ///      This is used to identify different tranche tokens instances of the same class
    /// @param tranche The address of the tranche token.
    /// @return The class hash.
    function trancheClass(ITranche tranche) public view returns (bytes32) {
        IBondController bond = IBondController(tranche.bond());
        TrancheData memory td = bond.getTrancheData();
        return keccak256(abi.encode(bond.collateralToken(), td.trancheRatios, td.getTrancheIndex(tranche)));
    }
}