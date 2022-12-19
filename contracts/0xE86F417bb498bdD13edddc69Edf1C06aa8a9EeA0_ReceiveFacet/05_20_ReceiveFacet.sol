//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IReceive} from "../../interfaces/IReceive.sol";
import {LibReceive} from "../../libraries/LibReceive.sol";
import {DiamondReentrancyGuard} from "../../access/DiamondReentrancyGuard.sol";

/// @author Amit Molek
/// @dev Please see `IReceive` for docs
contract ReceiveFacet is IReceive, DiamondReentrancyGuard {
    /// @dev Does not follow the standard diamond cut pattern. Must register the
    /// 0x00000000 selector instead of the function signature
    receive() external payable override {
        LibReceive._receive();
    }

    function withdraw() external override nonReentrant {
        LibReceive._withdraw();
    }

    function withdrawable(address member)
        external
        view
        override
        returns (uint256)
    {
        return LibReceive._withdrawable(member);
    }

    function totalWithdrawable() external view override returns (uint256) {
        return LibReceive._totalWithdrawable();
    }
}