// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

import "./IPSYCHOLimited.sol";
import "./PSYCHOSetup.sol";

/// @title See {IPSYCHOLimited}
/// @notice See {IPSYCHOLimited}
contract PSYCHOLimited is IPSYCHOLimited, PSYCHOSetup {
    uint256 private _countMaster = 0;
    uint256 private _count = 0;

    /// @dev See {IPSYCHOLimited-extension}
    function extension(uint256 _avatarId, string memory _extension)
        public
        payable
        override(IPSYCHOLimited)
    {
        if (!_isApprovedOrOwner(msg.sender, _avatarId)) {
            revert NonApprovedNonOwner(
                isApprovedForAll(ownerOf(_avatarId), msg.sender),
                getApproved(_avatarId),
                ownerOf(_avatarId),
                msg.sender
            );
        }
        if (!_isApprovedOwnerOrOwnership(msg.sender)) {
            if (msg.value < _fee(1)) {
                revert FundAccountWith(_fee(1) - msg.value);
            }
        }
        _setCustomExtension(_extension, _avatarId);
    }

    /// @dev See {IPSYCHOLimited-fee}
    function fee(uint256 _multiplier)
        public
        view
        override(IPSYCHOLimited)
        returns (uint256)
    {
        return _fee(_multiplier);
    }

    /// @dev See {IPSYCHOLimited-stock}
    function stock() public view override(IPSYCHOLimited) returns (uint256) {
        if (_generative()) {
            return 1001 - _count;
        } else {
            return 0;
        }
    }

    /// @dev See {IPSYCHOLimited-mint}
    function mint(uint256 _quantity)
        public
        payable
        override(IPSYCHOLimited)
    {
        if (!_isApprovedOwnerOrOwnership(msg.sender)) {
            if (stock() == 0) {
                revert StockRemaining(stock());
            }
            if (msg.value < _fee(_quantity)) {
                revert FundAccountWith(_fee(_quantity) - msg.value);
            }
            if (_count + _quantity > 1001) {
                revert ExceedsGenerationLimitBy((_count + _quantity) - 1001);
            }
            if (_quantity > 20) {
                revert ExceedsGenerationLimitBy(_quantity - 20);
            }
            _count += _quantity;
        } else {
            if (_countMaster + _quantity > 99) {
                revert ExceedsGenerationLimitBy(
                    (_countMaster + _quantity) - 99
                );
            }
            _countMaster += _quantity;
        }
        _eoaMint(msg.sender, _quantity);
    }

    /// @dev See {IPSYCHOLimited-burn}
    function burn(uint256 _avatarId) public override(IPSYCHOLimited) {
        if (tx.origin != msg.sender) {
            revert TxOriginNonSender(tx.origin, msg.sender);
        }
        _burn(msg.sender, _avatarId);
        if (!_isApprovedOwnerOrOwnership(msg.sender)) {
            _count -= 1;
        } else {
            if (_count > 0) {
                _count -= 1;
            } else {
                _countMaster -= 1;
            }
        }
    }
}