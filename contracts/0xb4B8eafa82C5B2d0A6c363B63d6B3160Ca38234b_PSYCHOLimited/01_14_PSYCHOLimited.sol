// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interfaces/IPSYCHOLimited.sol";
import "./contracts/Supports.sol";

/**
 * @title PSYCHO Limited
 */
contract PSYCHOLimited is
    IPSYCHOLimited,
    Supports {

    // Avatar generation count
    uint256 private _count = 0;

    /**
     * @dev {IPSYCHOLimited-live}
     */
    function live(
    ) public view override(
        IPSYCHOLimited
    ) returns (bool) {
        return _live();
    }

    /**
     * @dev {IPSYCHOLimited-fee}
     */
    function fee(
        uint256 _multiplier
    ) public view override(
        IPSYCHOLimited
    ) returns (uint256) {
        return _fee(_multiplier);
    }

    /**
     * @dev {IPSYCHOLimited-generate}
     */
    function generate(
        uint256 _quantity
    ) public payable override(
        IPSYCHOLimited
    ) guard {
        if (msg.value < _fee(_quantity)) {
            revert PriceNotMet();
        }
        if (_live() == false) {
            revert InactiveGenesis();
        }
        if (_count + _quantity > 1001 ||
            _quantity > 20)
        {
            revert ExceedsGenesisLimit();
        }
        _count += _quantity;
        _generate(
            msg.sender,
            _quantity
        );
    }

    /**
     * @dev {IPSYCHOLimited-extension}
     */
    function extension(
        uint256 _select,
        uint256 _avatarId,
        string memory _image,
        string memory _animation
    ) public payable override(
        IPSYCHOLimited
    ) guard {
        if (!_isApprovedOrOwner(
            msg.sender,
            _avatarId
        )) {
            revert NonApprovedNonOwner();
        }
        if (_select != 0 &&
            msg.sender != owner())
        {
            if (msg.value < _fee(1)) {
                revert PriceNotMet();
            }
        }
        _extension(
            _select,
            _avatarId,
            _image,
            _animation
        );
    }

    /**
     * @dev {IPSYCHOLimited-metadata}
     */
    function metadata(
        uint256 _avatarId
    ) public view override(
        IPSYCHOLimited
    ) returns (string[4] memory) {
        return _metadata(_avatarId);
    }

    /**
     * @dev {IPSYCHOLimited-stone}
     */
    function stone(
    ) public view override(
        IPSYCHOLimited
    ) returns (bool) {
        return _stone();
    }
}