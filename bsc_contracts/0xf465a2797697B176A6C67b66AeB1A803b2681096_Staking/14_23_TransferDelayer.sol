//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @title TransferDelayer
    @author iMe Lab

    @notice Contract fragment, responsible for token transfer delay
 */
abstract contract TransferDelayer {
    struct DelayedTransfer {
        /**
            @notice Amount of tokens to send, integer

            @dev uint192 is used in order to optimize gas costs
         */
        uint192 amount;
        /**
            @notice Timestamp to perform the transfer
         */
        uint64 notBefore;
    }

    mapping(address => DelayedTransfer[]) private _transfers;
    uint256 private _delayedValue = 0;

    function _delayTransfer(
        address recipient,
        uint256 amount,
        uint64 notBefore
    ) internal {
        assert(amount < 2 ** 192);
        _transfers[recipient].push(DelayedTransfer(uint192(amount), notBefore));
        _delayedValue += amount;
    }

    /**
        @notice Finalize transfers, which are ready, for certain user

        @dev Be sure to perform a real token transfer
     */
    function _finalizeDelayedTransfers(
        address recipient,
        uint64 moment
    ) internal returns (uint256) {
        DelayedTransfer[] memory transfers = _transfers[recipient];
        uint256 i = 0; // Index of the last transfer to perform
        uint256 tokensToSend = 0;

        for (; i < transfers.length && moment >= transfers[i].notBefore; i++)
            tokensToSend += transfers[i].amount;

        if (i == 0) {
            return 0;
        } else if (i == transfers.length) {
            delete _transfers[recipient];
        } else {
            for (uint256 k = 0; k < i; k++) {
                _transfers[recipient][k] = transfers[k + i];
                _transfers[recipient].pop();
            }
        }

        _delayedValue -= tokensToSend;
        return tokensToSend;
    }

    /**
        @notice Yields amount of delayed tokens for a certain user

        @return pending Amount of tokens, which cannot be transferred yet
        @return ready Amount of tokens, ready to be transferred
     */
    function _delayedTokensFor(
        address recipient,
        uint256 moment
    ) internal view returns (uint256 pending, uint256 ready) {
        DelayedTransfer[] memory transfers = _transfers[recipient];
        uint256 i = 0;
        for (; i < transfers.length && transfers[i].notBefore < moment; i++)
            ready += transfers[i].amount;

        for (; i < transfers.length; i++) pending += transfers[i].amount;
    }

    function _totalDelayed() internal view returns (uint256) {
        return _delayedValue;
    }
}