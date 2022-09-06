// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "./MorphoUtils.sol";

/// @title MatchingEngine.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Smart contract managing the matching engine.
abstract contract MatchingEngine is MorphoUtils {
    using DoubleLinkedList for DoubleLinkedList.List;
    using CompoundMath for uint256;

    /// STRUCTS ///

    // Struct to avoid stack too deep.
    struct UnmatchVars {
        uint256 p2pIndex;
        uint256 toUnmatch;
        uint256 poolIndex;
        uint256 inUnderlying;
        uint256 gasLeftAtTheBeginning;
    }

    // Struct to avoid stack too deep.
    struct MatchVars {
        uint256 p2pIndex;
        uint256 toMatch;
        uint256 poolIndex;
        uint256 inUnderlying;
        uint256 gasLeftAtTheBeginning;
    }

    /// @notice Emitted when the position of a supplier is updated.
    /// @param _user The address of the supplier.
    /// @param _poolTokenAddress The address of the market.
    /// @param _balanceOnPool The supply balance on pool after update.
    /// @param _balanceInP2P The supply balance in peer-to-peer after update.
    event SupplierPositionUpdated(
        address indexed _user,
        address indexed _poolTokenAddress,
        uint256 _balanceOnPool,
        uint256 _balanceInP2P
    );

    /// @notice Emitted when the position of a borrower is updated.
    /// @param _user The address of the borrower.
    /// @param _poolTokenAddress The address of the market.
    /// @param _balanceOnPool The borrow balance on pool after update.
    /// @param _balanceInP2P The borrow balance in peer-to-peer after update.
    event BorrowerPositionUpdated(
        address indexed _user,
        address indexed _poolTokenAddress,
        uint256 _balanceOnPool,
        uint256 _balanceInP2P
    );

    /// INTERNAL ///

    /// @notice Matches suppliers' liquidity waiting on Compound up to the given `_amount` and moves it to peer-to-peer.
    /// @dev Note: This function expects Compound's exchange rate and peer-to-peer indexes to have been updated.
    /// @param _poolTokenAddress The address of the market from which to match suppliers.
    /// @param _amount The token amount to search for (in underlying).
    /// @param _maxGasForMatching The maximum amount of gas to consume within a matching engine loop.
    /// @return matched The amount of liquidity matched (in underlying).
    /// @return gasConsumedInMatching The amount of gas consumed within the matching loop.
    function _matchSuppliers(
        address _poolTokenAddress,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) internal returns (uint256 matched, uint256 gasConsumedInMatching) {
        if (_maxGasForMatching == 0) return (0, 0);

        MatchVars memory vars;
        vars.poolIndex = ICToken(_poolTokenAddress).exchangeRateStored(); // Exchange rate has already been updated.
        vars.p2pIndex = p2pSupplyIndex[_poolTokenAddress];
        address firstPoolSupplier;
        Types.SupplyBalance storage firstPoolSupplierBalance;

        vars.gasLeftAtTheBeginning = gasleft();
        while (
            matched < _amount &&
            (firstPoolSupplier = suppliersOnPool[_poolTokenAddress].getHead()) != address(0) &&
            vars.gasLeftAtTheBeginning - gasleft() < _maxGasForMatching
        ) {
            firstPoolSupplierBalance = supplyBalanceInOf[_poolTokenAddress][firstPoolSupplier];
            vars.inUnderlying = firstPoolSupplierBalance.onPool.mul(vars.poolIndex);

            uint256 newPoolSupplyBalance;
            uint256 newP2PSupplyBalance;
            uint256 maxToMatch = _amount - matched;

            if (vars.inUnderlying <= maxToMatch) {
                // newPoolSupplyBalance is 0.
                newP2PSupplyBalance =
                    firstPoolSupplierBalance.inP2P +
                    vars.inUnderlying.div(vars.p2pIndex);
                matched += vars.inUnderlying;
            } else {
                newPoolSupplyBalance =
                    firstPoolSupplierBalance.onPool -
                    maxToMatch.div(vars.poolIndex);
                newP2PSupplyBalance =
                    firstPoolSupplierBalance.inP2P +
                    maxToMatch.div(vars.p2pIndex);
                matched = _amount;
            }

            firstPoolSupplierBalance.onPool = newPoolSupplyBalance;
            firstPoolSupplierBalance.inP2P = newP2PSupplyBalance;
            _updateSupplierInDS(_poolTokenAddress, firstPoolSupplier);

            emit SupplierPositionUpdated(
                firstPoolSupplier,
                _poolTokenAddress,
                newPoolSupplyBalance,
                newP2PSupplyBalance
            );
        }

        gasConsumedInMatching = vars.gasLeftAtTheBeginning - gasleft();
    }

    /// @notice Unmatches suppliers' liquidity in peer-to-peer up to the given `_amount` and moves it to Compound.
    /// @dev Note: This function expects Compound's exchange rate and peer-to-peer indexes to have been updated.
    /// @param _poolTokenAddress The address of the market from which to unmatch suppliers.
    /// @param _amount The amount to search for (in underlying).
    /// @param _maxGasForMatching The maximum amount of gas to consume within a matching engine loop.
    /// @return The amount unmatched (in underlying).
    function _unmatchSuppliers(
        address _poolTokenAddress,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) internal returns (uint256) {
        if (_maxGasForMatching == 0) return 0;

        UnmatchVars memory vars;
        vars.poolIndex = ICToken(_poolTokenAddress).exchangeRateStored(); // Exchange rate has already been updated.
        vars.p2pIndex = p2pSupplyIndex[_poolTokenAddress];
        address firstP2PSupplier;
        Types.SupplyBalance storage firstP2PSupplierBalance;
        uint256 remainingToUnmatch = _amount;

        vars.gasLeftAtTheBeginning = gasleft();
        while (
            remainingToUnmatch > 0 &&
            (firstP2PSupplier = suppliersInP2P[_poolTokenAddress].getHead()) != address(0) &&
            vars.gasLeftAtTheBeginning - gasleft() < _maxGasForMatching
        ) {
            firstP2PSupplierBalance = supplyBalanceInOf[_poolTokenAddress][firstP2PSupplier];
            vars.inUnderlying = firstP2PSupplierBalance.inP2P.mul(vars.p2pIndex);

            uint256 newPoolSupplyBalance;
            uint256 newP2PSupplyBalance;

            if (vars.inUnderlying <= remainingToUnmatch) {
                // newP2PSupplyBalance is 0.
                newPoolSupplyBalance =
                    firstP2PSupplierBalance.onPool +
                    vars.inUnderlying.div(vars.poolIndex);
                remainingToUnmatch -= vars.inUnderlying;
            } else {
                newPoolSupplyBalance =
                    firstP2PSupplierBalance.onPool +
                    remainingToUnmatch.div(vars.poolIndex);
                newP2PSupplyBalance =
                    firstP2PSupplierBalance.inP2P -
                    remainingToUnmatch.div(vars.p2pIndex);
                remainingToUnmatch = 0;
            }

            firstP2PSupplierBalance.onPool = newPoolSupplyBalance;
            firstP2PSupplierBalance.inP2P = newP2PSupplyBalance;
            _updateSupplierInDS(_poolTokenAddress, firstP2PSupplier);

            emit SupplierPositionUpdated(
                firstP2PSupplier,
                _poolTokenAddress,
                newPoolSupplyBalance,
                newP2PSupplyBalance
            );
        }

        return _amount - remainingToUnmatch;
    }

    /// @notice Matches borrowers' liquidity waiting on Compound up to the given `_amount` and moves it to peer-to-peer.
    /// @dev Note: This function expects peer-to-peer indexes to have been updated..
    /// @param _poolTokenAddress The address of the market from which to match borrowers.
    /// @param _amount The amount to search for (in underlying).
    /// @param _maxGasForMatching The maximum amount of gas to consume within a matching engine loop.
    /// @return matched The amount of liquidity matched (in underlying).
    /// @return gasConsumedInMatching The amount of gas consumed within the matching loop.
    function _matchBorrowers(
        address _poolTokenAddress,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) internal returns (uint256 matched, uint256 gasConsumedInMatching) {
        if (_maxGasForMatching == 0) return (0, 0);

        MatchVars memory vars;
        vars.poolIndex = ICToken(_poolTokenAddress).borrowIndex();
        vars.p2pIndex = p2pBorrowIndex[_poolTokenAddress];
        address firstPoolBorrower;
        Types.BorrowBalance storage firstPoolBorrowerBalance;

        vars.gasLeftAtTheBeginning = gasleft();
        while (
            matched < _amount &&
            (firstPoolBorrower = borrowersOnPool[_poolTokenAddress].getHead()) != address(0) &&
            vars.gasLeftAtTheBeginning - gasleft() < _maxGasForMatching
        ) {
            firstPoolBorrowerBalance = borrowBalanceInOf[_poolTokenAddress][firstPoolBorrower];
            vars.inUnderlying = firstPoolBorrowerBalance.onPool.mul(vars.poolIndex);

            uint256 newPoolBorrowBalance;
            uint256 newP2PBorrowBalance;
            uint256 maxToMatch = _amount - matched;

            if (vars.inUnderlying <= maxToMatch) {
                // newPoolBorrowBalance is 0.
                newP2PBorrowBalance =
                    firstPoolBorrowerBalance.inP2P +
                    vars.inUnderlying.div(vars.p2pIndex);
                matched += vars.inUnderlying;
            } else {
                newPoolBorrowBalance =
                    firstPoolBorrowerBalance.onPool -
                    maxToMatch.div(vars.poolIndex);
                newP2PBorrowBalance =
                    firstPoolBorrowerBalance.inP2P +
                    maxToMatch.div(vars.p2pIndex);
                matched = _amount;
            }

            firstPoolBorrowerBalance.onPool = newPoolBorrowBalance;
            firstPoolBorrowerBalance.inP2P = newP2PBorrowBalance;
            _updateBorrowerInDS(_poolTokenAddress, firstPoolBorrower);

            emit BorrowerPositionUpdated(
                firstPoolBorrower,
                _poolTokenAddress,
                newPoolBorrowBalance,
                newP2PBorrowBalance
            );
        }

        gasConsumedInMatching = vars.gasLeftAtTheBeginning - gasleft();
    }

    /// @notice Unmatches borrowers' liquidity in peer-to-peer for the given `_amount` and moves it to Compound.
    /// @dev Note: This function expects and peer-to-peer indexes to have been updated.
    /// @param _poolTokenAddress The address of the market from which to unmatch borrowers.
    /// @param _amount The amount to unmatch (in underlying).
    /// @param _maxGasForMatching The maximum amount of gas to consume within a matching engine loop.
    /// @return The amount unmatched (in underlying).
    function _unmatchBorrowers(
        address _poolTokenAddress,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) internal returns (uint256) {
        if (_maxGasForMatching == 0) return 0;

        UnmatchVars memory vars;
        vars.poolIndex = ICToken(_poolTokenAddress).borrowIndex();
        vars.p2pIndex = p2pBorrowIndex[_poolTokenAddress];
        address firstP2PBorrower;
        Types.BorrowBalance storage firstP2PBorrowerBalance;
        uint256 remainingToUnmatch = _amount;

        vars.gasLeftAtTheBeginning = gasleft();
        while (
            remainingToUnmatch > 0 &&
            (firstP2PBorrower = borrowersInP2P[_poolTokenAddress].getHead()) != address(0) &&
            vars.gasLeftAtTheBeginning - gasleft() < _maxGasForMatching
        ) {
            firstP2PBorrowerBalance = borrowBalanceInOf[_poolTokenAddress][firstP2PBorrower];
            vars.inUnderlying = firstP2PBorrowerBalance.inP2P.mul(vars.p2pIndex);

            uint256 newPoolBorrowBalance;
            uint256 newP2PBorrowBalance;

            if (vars.inUnderlying <= remainingToUnmatch) {
                // newP2PBorrowBalance is 0.
                newPoolBorrowBalance =
                    firstP2PBorrowerBalance.onPool +
                    vars.inUnderlying.div(vars.poolIndex);
                remainingToUnmatch -= vars.inUnderlying;
            } else {
                newPoolBorrowBalance =
                    firstP2PBorrowerBalance.onPool +
                    remainingToUnmatch.div(vars.poolIndex);
                newP2PBorrowBalance =
                    firstP2PBorrowerBalance.inP2P -
                    remainingToUnmatch.div(vars.p2pIndex);
                remainingToUnmatch = 0;
            }

            firstP2PBorrowerBalance.onPool = newPoolBorrowBalance;
            firstP2PBorrowerBalance.inP2P = newP2PBorrowBalance;
            _updateBorrowerInDS(_poolTokenAddress, firstP2PBorrower);

            emit BorrowerPositionUpdated(
                firstP2PBorrower,
                _poolTokenAddress,
                newPoolBorrowBalance,
                newP2PBorrowBalance
            );
        }

        return _amount - remainingToUnmatch;
    }

    /// @notice Updates `_user` in the supplier data structures.
    /// @param _poolTokenAddress The address of the market on which to update the suppliers data structure.
    /// @param _user The address of the user.
    function _updateSupplierInDS(address _poolTokenAddress, address _user) internal {
        uint256 onPool = supplyBalanceInOf[_poolTokenAddress][_user].onPool;
        uint256 inP2P = supplyBalanceInOf[_poolTokenAddress][_user].inP2P;
        uint256 formerValueOnPool = suppliersOnPool[_poolTokenAddress].getValueOf(_user);
        uint256 formerValueInP2P = suppliersInP2P[_poolTokenAddress].getValueOf(_user);

        // Round pool balance to 0 if below threshold.
        if (onPool <= dustThreshold) {
            supplyBalanceInOf[_poolTokenAddress][_user].onPool = 0;
            onPool = 0;
        }
        if (formerValueOnPool != onPool) {
            if (formerValueOnPool > 0) suppliersOnPool[_poolTokenAddress].remove(_user);
            if (onPool > 0)
                suppliersOnPool[_poolTokenAddress].insertSorted(_user, onPool, maxSortedUsers);
        }

        // Round peer-to-peer balance to 0 if below threshold.
        if (inP2P <= dustThreshold) {
            supplyBalanceInOf[_poolTokenAddress][_user].inP2P = 0;
            inP2P = 0;
        }
        if (formerValueInP2P != inP2P) {
            if (formerValueInP2P > 0) suppliersInP2P[_poolTokenAddress].remove(_user);
            if (inP2P > 0)
                suppliersInP2P[_poolTokenAddress].insertSorted(_user, inP2P, maxSortedUsers);
        }

        if (address(rewardsManager) != address(0))
            rewardsManager.accrueUserSupplyUnclaimedRewards(
                _user,
                _poolTokenAddress,
                formerValueOnPool
            );
    }

    /// @notice Updates `_user` in the borrower data structures.
    /// @param _poolTokenAddress The address of the market on which to update the borrowers data structure.
    /// @param _user The address of the user.
    function _updateBorrowerInDS(address _poolTokenAddress, address _user) internal {
        uint256 onPool = borrowBalanceInOf[_poolTokenAddress][_user].onPool;
        uint256 inP2P = borrowBalanceInOf[_poolTokenAddress][_user].inP2P;
        uint256 formerValueOnPool = borrowersOnPool[_poolTokenAddress].getValueOf(_user);
        uint256 formerValueInP2P = borrowersInP2P[_poolTokenAddress].getValueOf(_user);

        // Round pool balance to 0 if below threshold.
        if (onPool <= dustThreshold) {
            borrowBalanceInOf[_poolTokenAddress][_user].onPool = 0;
            onPool = 0;
        }
        if (formerValueOnPool != onPool) {
            if (formerValueOnPool > 0) borrowersOnPool[_poolTokenAddress].remove(_user);
            if (onPool > 0)
                borrowersOnPool[_poolTokenAddress].insertSorted(_user, onPool, maxSortedUsers);
        }

        // Round peer-to-peer balance to 0 if below threshold.
        if (inP2P <= dustThreshold) {
            borrowBalanceInOf[_poolTokenAddress][_user].inP2P = 0;
            inP2P = 0;
        }
        if (formerValueInP2P != inP2P) {
            if (formerValueInP2P > 0) borrowersInP2P[_poolTokenAddress].remove(_user);
            if (inP2P > 0)
                borrowersInP2P[_poolTokenAddress].insertSorted(_user, inP2P, maxSortedUsers);
        }

        if (address(rewardsManager) != address(0))
            rewardsManager.accrueUserBorrowUnclaimedRewards(
                _user,
                _poolTokenAddress,
                formerValueOnPool
            );
    }
}