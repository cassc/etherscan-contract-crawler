// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import {AppStorage} from "../libraries/LibAppStorage.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IBase} from "../interfaces/IBase.sol";
import {ISecurity} from "../interfaces/ISecurity.sol";


abstract contract Base is IBase {
    AppStorage internal s;
    uint256 private constant MAX_UINT = type(uint256).max;

    modifier onlyEoA() {
         // solhint-disable-next-line avoid-tx-origin
        if(tx.origin != msg.sender) revert CallerNotEoA();
        _;
    }

    modifier isTransferable() {
        if(!s.nftStorage.transfersEnabled) revert TransfersPaused();
        _;
    }

    modifier tokenLocked(uint256 tokenId) {
        if(s.nftStorage.lockedTokens[tokenId]) revert ISecurity.TokenLocked();
        _;
    }

    /// @notice check that a String is NOT NULL
    /// @dev Explain to a developer any extra details
    /// @param string_ the string to check
    modifier isEmpty(string calldata string_) {
        if (bytes(string_).length == 0 ) revert EmptyString();
        _;
    }
}