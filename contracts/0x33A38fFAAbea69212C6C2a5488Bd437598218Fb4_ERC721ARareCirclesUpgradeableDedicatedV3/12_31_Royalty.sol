// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LibPart.sol";

contract Royalty {
    LibPart.Part private royalty;
    uint96 constant _WEIGHT_VALUE = 1000000;

    event RoyaltySet(LibPart.Part royalty);

    struct Part {
        address payable account;
        uint96 value;
    }

    function getRoyalty() external view returns (LibPart.Part memory) {
        return royalty;
    }

    function royaltyInfo(uint256, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        if (_salePrice == 0) {
            return (address(0), 0);
        }
        require(royalty.value < 10000, "Royalties 2981, than 100%");
        uint256 amount = (_salePrice * 100 / _WEIGHT_VALUE) * royalty.value;
        return (royalty.account, amount);
    }

    function _onRoyaltySet(LibPart.Part memory _royalty) internal {
        emit RoyaltySet(_royalty);
    }

    function _saveRoyalty(LibPart.Part memory _royalty) internal {
        require(_royalty.value < 10000, "Royalty total value should be < 10000");
        royalty = _royalty;
        _onRoyaltySet(_royalty);
    }
}