// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibObject } from "./LibObject.sol";

library LibTokenizedVault {
    /**
     * @dev Emitted when a token balance gets updated.
     * @param ownerId Id of owner
     * @param tokenId ID of token
     * @param newAmountOwned new amount owned
     * @param functionName Function name
     * @param msgSender msg.sender
     */
    event InternalTokenBalanceUpdate(bytes32 indexed ownerId, bytes32 tokenId, uint256 newAmountOwned, string functionName, address indexed msgSender);

    /**
     * @dev Emitted when a token supply gets updated.
     * @param tokenId ID of token
     * @param newTokenSupply New token supply
     * @param functionName Function name
     * @param msgSender msg.sender
     */
    event InternalTokenSupplyUpdate(bytes32 indexed tokenId, uint256 newTokenSupply, string functionName, address indexed msgSender);

    /**
     * @dev Emitted when a dividend gets payed out.
     * @param guid dividend distribution ID
     * @param from distribution initiator
     * @param to distribution receiver
     * @param amount distributed amount
     */
    event DividendDistribution(bytes32 indexed guid, bytes32 from, bytes32 to, bytes32 dividendTokenId, uint256 amount);

    function _internalBalanceOf(bytes32 _ownerId, bytes32 _tokenId) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.tokenBalances[_tokenId][_ownerId];
    }

    function _internalTokenSupply(bytes32 _objectId) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.tokenSupply[_objectId];
    }

    function _internalTransfer(
        bytes32 _from,
        bytes32 _to,
        bytes32 _tokenId,
        uint256 _amount
    ) internal returns (bool success) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(s.tokenBalances[_tokenId][_from] >= _amount, "_internalTransfer: insufficient balance");
        require(s.tokenBalances[_tokenId][_from] - s.lockedBalances[_from][_tokenId] >= _amount, "_internalTransfer: insufficient balance available, funds locked");

        _withdrawAllDividends(_from, _tokenId);

        s.tokenBalances[_tokenId][_from] -= _amount;
        s.tokenBalances[_tokenId][_to] += _amount;

        _normalizeDividends(_from, _to, _tokenId, _amount, false);

        emit InternalTokenBalanceUpdate(_from, _tokenId, s.tokenBalances[_tokenId][_from], "_internalTransfer", msg.sender);
        emit InternalTokenBalanceUpdate(_to, _tokenId, s.tokenBalances[_tokenId][_to], "_internalTransfer", msg.sender);

        success = true;
    }

    function _internalMint(
        bytes32 _to,
        bytes32 _tokenId,
        uint256 _amount
    ) internal {
        require(_to != "", "_internalMint: mint to zero address");
        require(_amount > 0, "_internalMint: mint zero tokens");

        AppStorage storage s = LibAppStorage.diamondStorage();

        _normalizeDividends(bytes32(0), _to, _tokenId, _amount, true);

        s.tokenSupply[_tokenId] += _amount;
        s.tokenBalances[_tokenId][_to] += _amount;

        emit InternalTokenSupplyUpdate(_tokenId, s.tokenSupply[_tokenId], "_internalMint", msg.sender);
        emit InternalTokenBalanceUpdate(_to, _tokenId, s.tokenBalances[_tokenId][_to], "_internalMint", msg.sender);
    }

    function _normalizeDividends(
        bytes32 _from,
        bytes32 _to,
        bytes32 _tokenId,
        uint256 _amount,
        bool _updateTotals
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 supply = _internalTokenSupply(_tokenId);

        // This must be done BEFORE the supply increases!!!
        // This will calculate the hypothetical dividends that would correspond to this number of shares.
        // It must be added to the withdrawn dividend for every denomination for the user who receives the minted tokens
        bytes32[] memory dividendDenominations = s.dividendDenominations[_tokenId];

        for (uint256 i = 0; i < dividendDenominations.length; ++i) {
            bytes32 dividendDenominationId = dividendDenominations[i];
            uint256 totalDividend = s.totalDividends[_tokenId][dividendDenominationId];

            // Dividend deduction for newly issued shares
            uint256 dividendDeductionIssued = _getWithdrawableDividendAndDeductionMath(_amount, supply, totalDividend, 0);

            // Scale total dividends and withdrawn dividend for new owner
            s.withdrawnDividendPerOwner[_tokenId][dividendDenominationId][_to] += dividendDeductionIssued;

            // Scale total dividends for the previous owner, if applicable
            if (_from != bytes32(0)) {
                s.withdrawnDividendPerOwner[_tokenId][dividendDenominationId][_from] -= dividendDeductionIssued;
            }

            if (_updateTotals) {
                s.totalDividends[_tokenId][dividendDenominationId] += (s.totalDividends[_tokenId][dividendDenominationId] * _amount) / supply;
            }
        }
    }

    function _internalBurn(
        bytes32 _from,
        bytes32 _tokenId,
        uint256 _amount
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(s.tokenBalances[_tokenId][_from] >= _amount, "_internalBurn: insufficient balance");
        require(s.tokenBalances[_tokenId][_from] - s.lockedBalances[_from][_tokenId] >= _amount, "_internalBurn: insufficient balance available, funds locked");

        _withdrawAllDividends(_from, _tokenId);

        s.tokenSupply[_tokenId] -= _amount;
        s.tokenBalances[_tokenId][_from] -= _amount;

        emit InternalTokenSupplyUpdate(_tokenId, s.tokenSupply[_tokenId], "_internalBurn", msg.sender);
        emit InternalTokenBalanceUpdate(_from, _tokenId, s.tokenBalances[_tokenId][_from], "_internalBurn", msg.sender);
    }

    //   DIVIDEND PAYOUT LOGIC
    //
    // When a dividend is payed, you divide by the total supply and add it to the totalDividendPerToken
    // Dividends are held by the diamond contract at: LibHelpers._stringToBytes32(LibConstants.DIVIDEND_BANK_IDENTIFIER)
    // When dividends are paid, they are transferred OUT of that same diamond contract ID.
    //
    // To calculate withdrawableDividend = ownedTokens * totalDividendPerToken - totalWithdrawnDividendPerOwner
    //
    // When a dividend is collected you set the totalWithdrawnDividendPerOwner to the total amount the owner withdrew
    //
    // When you transfer, you pay out all dividends to previous owner first, then transfer ownership
    // !!!YOU ALSO TRANSFER totalWithdrawnDividendPerOwner for those shares!!!
    // totalWithdrawnDividendPerOwner(for new owner) += numberOfSharesTransferred * totalDividendPerToken
    // totalWithdrawnDividendPerOwner(for previous owner) -= numberOfSharesTransferred * totalDividendPerToken (can be optimized)
    //
    // When minting
    // Add the token balance to the new owner
    // totalWithdrawnDividendPerOwner(for new owner) += numberOfSharesMinted * totalDividendPerToken
    //
    // When doing the division these will be dust. Leave the dust in the diamond!!!
    function _withdrawDividend(
        bytes32 _ownerId,
        bytes32 _tokenId,
        bytes32 _dividendTokenId
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes32 dividendBankId = LibHelpers._stringToBytes32(LibConstants.DIVIDEND_BANK_IDENTIFIER);

        uint256 amountOwned = s.tokenBalances[_tokenId][_ownerId];
        uint256 supply = _internalTokenSupply(_tokenId);
        uint256 totalDividend = s.totalDividends[_tokenId][_dividendTokenId];
        uint256 withdrawnSoFar = s.withdrawnDividendPerOwner[_tokenId][_dividendTokenId][_ownerId];

        uint256 withdrawableDividend = _getWithdrawableDividendAndDeductionMath(amountOwned, supply, totalDividend, withdrawnSoFar);
        if (withdrawableDividend > 0) {
            // Bump the withdrawn dividends for the owner
            s.withdrawnDividendPerOwner[_tokenId][_dividendTokenId][_ownerId] += withdrawableDividend;

            // Move the dividend
            s.tokenBalances[_dividendTokenId][dividendBankId] -= withdrawableDividend;
            s.tokenBalances[_dividendTokenId][_ownerId] += withdrawableDividend;

            emit InternalTokenBalanceUpdate(dividendBankId, _dividendTokenId, s.tokenBalances[_dividendTokenId][dividendBankId], "_withdrawDividend", msg.sender);
            emit InternalTokenBalanceUpdate(_ownerId, _dividendTokenId, s.tokenBalances[_dividendTokenId][_ownerId], "_withdrawDividend", msg.sender);
        }
    }

    function _getWithdrawableDividend(
        bytes32 _ownerId,
        bytes32 _tokenId,
        bytes32 _dividendTokenId
    ) internal view returns (uint256 withdrawableDividend_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 amount = s.tokenBalances[_tokenId][_ownerId];
        uint256 supply = _internalTokenSupply(_tokenId);
        uint256 totalDividend = s.totalDividends[_tokenId][_dividendTokenId];
        uint256 withdrawnSoFar = s.withdrawnDividendPerOwner[_tokenId][_dividendTokenId][_ownerId];

        withdrawableDividend_ = _getWithdrawableDividendAndDeductionMath(amount, supply, totalDividend, withdrawnSoFar);
    }

    function _withdrawAllDividends(bytes32 _ownerId, bytes32 _tokenId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes32[] memory dividendDenominations = s.dividendDenominations[_tokenId];

        for (uint256 i = 0; i < dividendDenominations.length; ++i) {
            _withdrawDividend(_ownerId, _tokenId, dividendDenominations[i]);
        }
    }

    function _payDividend(
        bytes32 _guid,
        bytes32 _from,
        bytes32 _to,
        bytes32 _dividendTokenId,
        uint256 _amount
    ) internal {
        require(_amount > 0, "dividend amount must be > 0");
        require(LibAdmin._isSupportedExternalToken(_dividendTokenId), "must be supported dividend token");
        require(!LibObject._isObject(_guid), "nonunique dividend distribution identifier");

        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes32 dividendBankId = LibHelpers._stringToBytes32(LibConstants.DIVIDEND_BANK_IDENTIFIER);

        // If no tokens are issued, then deposit directly.
        // note: This functionality is for the business case where we want to distribute dividends directly to entities.
        // How this functionality is implemented may be changed in the future.
        if (_internalTokenSupply(_to) == 0) {
            _internalTransfer(_from, _to, _dividendTokenId, _amount);
        }
        // Otherwise pay as dividend
        else {
            // issue dividend. if you are owed dividends on the _dividendTokenId, they will be collected
            // Check for possible infinite loop, but probably not
            _internalTransfer(_from, dividendBankId, _dividendTokenId, _amount);
            s.totalDividends[_to][_dividendTokenId] += _amount;

            // keep track of the dividend denominations
            // if dividend has not yet been issued in this token, add it to the list and update mappings
            if (s.dividendDenominationIndex[_to][_dividendTokenId] == 0 && s.dividendDenominationAtIndex[_to][0] != _dividendTokenId) {
                // We must limit the number of different tokens dividends are paid in
                if (s.dividendDenominations[_to].length >= LibAdmin._getMaxDividendDenominations()) {
                    revert("exceeds max div denominations");
                }

                s.dividendDenominationIndex[_to][_dividendTokenId] = uint8(s.dividendDenominations[_to].length);
                s.dividendDenominationAtIndex[_to][uint8(s.dividendDenominations[_to].length)] = _dividendTokenId;
                s.dividendDenominations[_to].push(_dividendTokenId);
            }
        }

        // prevent guid reuse/collision
        LibObject._createObject(_guid);

        // Events are emitted from the _internalTransfer()
        emit DividendDistribution(_guid, _from, _to, _dividendTokenId, _amount);
    }

    function _getWithdrawableDividendAndDeductionMath(
        uint256 _amount,
        uint256 _supply,
        uint256 _totalDividend,
        uint256 _withdrawnSoFar
    ) internal pure returns (uint256 _withdrawableDividend) {
        // The holder dividend is: holderDividend = (totalDividend/tokenSupply) * _amount. The remainder (dust) is lost.
        uint256 totalDividendTimesAmount = _totalDividend * _amount;
        uint256 holderDividend = _supply == 0 ? 0 : (totalDividendTimesAmount / _supply);

        _withdrawableDividend = (_withdrawnSoFar >= holderDividend) ? 0 : holderDividend - _withdrawnSoFar;
    }

    function _getLockedBalance(bytes32 _accountId, bytes32 _tokenId) internal view returns (uint256 amount) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.lockedBalances[_accountId][_tokenId];
    }
}