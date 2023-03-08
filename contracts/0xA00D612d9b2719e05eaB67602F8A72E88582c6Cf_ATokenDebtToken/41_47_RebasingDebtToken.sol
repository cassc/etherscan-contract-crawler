// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IPool} from "../../interfaces/IPool.sol";
import {VariableDebtToken} from "./VariableDebtToken.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {SafeCast} from "../../dependencies/openzeppelin/contracts/SafeCast.sol";

/**
 * @title Rebasing Debt Token
 *
 * @notice Implementation of the interest bearing token for the ParaSpace protocol
 */
contract RebasingDebtToken is VariableDebtToken {
    using WadRayMath for uint256;
    using SafeCast for uint256;

    constructor(IPool pool) VariableDebtToken(pool) {
        //intentionally empty
    }

    /**
     * @dev Calculates the balance of the user: principal balance + debt interest accrued by the principal
     * @param user The user whose balance is calculated
     * @return The balance of the user
     **/
    function balanceOf(address user) public view override returns (uint256) {
        uint256 scaledBalance = _scaledBalanceOf(user, lastRebasingIndex());

        if (scaledBalance == 0) {
            return 0;
        }

        return
            scaledBalance.rayMul(
                POOL.getReserveNormalizedVariableDebt(_underlyingAsset)
            );
    }

    /**
     * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
     * updated stored balance divided by the reserve's liquidity index at the moment of the update
     * @param user The user whose balance is calculated
     * @return The scaled balance of the user
     **/
    function scaledBalanceOf(address user)
        public
        view
        override
        returns (uint256)
    {
        return _scaledBalanceOf(user, lastRebasingIndex());
    }

    /**
     * @dev Returns the scaled balance of the user and the scaled total supply.
     * @param user The address of the user
     * @return The scaled balance of the user
     * @return The scaled balance and the scaled total supply
     **/
    function getScaledUserBalanceAndSupply(address user)
        external
        view
        override
        returns (uint256, uint256)
    {
        uint256 rebasingIndex = lastRebasingIndex();
        return (
            _scaledBalanceOf(user, rebasingIndex),
            _scaledTotalSupply(rebasingIndex)
        );
    }

    /**
     * @dev calculates the total supply of the specific aToken
     * since the balance of every single user increases over time, the total supply
     * does that too.
     * @return the current total supply
     **/
    function totalSupply() public view override returns (uint256) {
        uint256 currentSupplyScaled = _scaledTotalSupply(lastRebasingIndex());

        if (currentSupplyScaled == 0) {
            return 0;
        }

        return
            currentSupplyScaled.rayMul(
                POOL.getReserveNormalizedVariableDebt(_underlyingAsset)
            );
    }

    /**
     * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
     * @return the scaled total supply
     **/
    function scaledTotalSupply()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _scaledTotalSupply(lastRebasingIndex());
    }

    function _scaledBalanceOf(address user, uint256 rebasingIndex)
        internal
        view
        returns (uint256)
    {
        uint256 scaledBalance = super.scaledBalanceOf(user);

        if (scaledBalance == 0) {
            return 0;
        }

        return scaledBalance.rayMul(rebasingIndex);
    }

    function _scaledTotalSupply(uint256 rebasingIndex)
        internal
        view
        returns (uint256)
    {
        uint256 scaledTotalSupply_ = super.scaledTotalSupply();

        return scaledTotalSupply_.rayMul(rebasingIndex);
    }

    /**
     * @return Current rebasing index in RAY
     **/
    function lastRebasingIndex() internal view virtual returns (uint256) {
        // returns 1 RAY by default which makes it identical to VariableDebtToken in behaviour
        return WadRayMath.RAY;
    }

    /**
     * @notice Implements the basic logic to mint a scaled balance token.
     * @param caller The address performing the mint
     * @param onBehalfOf The address of the user that will receive the scaled tokens
     * @param amount The amount of tokens getting minted
     * @param index The next liquidity index of the reserve
     * @return `true` if the the previous balance of the user was 0
     **/
    function _mintScaled(
        address caller,
        address onBehalfOf,
        uint256 amount,
        uint256 index
    ) internal virtual override returns (bool) {
        uint256 rebasingIndex = lastRebasingIndex();
        uint256 amountScaled = amount.rayDiv(index);
        uint256 amountRebased = amountScaled.rayDiv(rebasingIndex);
        require(amountRebased != 0, Errors.INVALID_MINT_AMOUNT);

        uint256 scaledBalance = _scaledBalanceOf(onBehalfOf, rebasingIndex);
        uint256 balanceIncrease = scaledBalance.rayMul(index) -
            scaledBalance.rayMul(_userState[onBehalfOf].additionalData);

        _userState[onBehalfOf].additionalData = index.toUint128();

        _mint(onBehalfOf, amountRebased.toUint128());

        uint256 amountToMint = amount + balanceIncrease;
        emit Transfer(address(0), onBehalfOf, amountToMint);
        emit Mint(caller, onBehalfOf, amountToMint, balanceIncrease, index);

        return (scaledBalance == 0);
    }

    /**
     * @notice Implements the basic logic to burn a scaled & rebased balance token.
     * @dev In some instances, a burn transaction will emit a mint event
     * if the amount to burn is less than the interest that the user accrued
     * @param user The user which debt is burnt
     * @param target The address that will receive the underlying, if any
     * @param amount The amount getting burned
     * @param index The variable debt index of the reserve
     **/
    function _burnScaled(
        address user,
        address target,
        uint256 amount,
        uint256 index
    ) internal virtual override {
        uint256 rebasingIndex = lastRebasingIndex();
        uint256 amountScaled = amount.rayDiv(index);
        uint256 amountRebased = amountScaled.rayDiv(rebasingIndex);
        require(amountRebased != 0, Errors.INVALID_BURN_AMOUNT);

        uint256 scaledBalance = _scaledBalanceOf(user, rebasingIndex);
        uint256 balanceIncrease = scaledBalance.rayMul(index) -
            scaledBalance.rayMul(_userState[user].additionalData);

        _userState[user].additionalData = index.toUint128();

        _burn(user, amountRebased.toUint128());

        if (balanceIncrease > amount) {
            uint256 amountToMint = balanceIncrease - amount;
            emit Transfer(address(0), user, amountToMint);
            emit Mint(user, user, amountToMint, balanceIncrease, index);
        } else {
            uint256 amountToBurn = amount - balanceIncrease;
            emit Transfer(user, address(0), amountToBurn);
            emit Burn(user, target, amountToBurn, balanceIncrease, index);
        }
    }
}