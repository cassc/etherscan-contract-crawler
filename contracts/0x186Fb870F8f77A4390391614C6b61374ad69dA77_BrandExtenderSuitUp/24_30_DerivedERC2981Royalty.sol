// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/_IERC2981.sol";

// Max royalty value is 10000 (100%)
abstract contract DerivedERC2981Royalty is _IERC2981 {

    event RoyaltyUpdated(uint256 value);

    uint256 private _royalty;

    function _setRoyalty(uint256 value ) internal {
        require(value <= 10000, "Royalty more that 100%" );
        emit RoyaltyUpdated(value);
        _royalty = value;
    }

    function _getRoyalty() internal view returns(uint256){
        return _royalty;
    }

    /// @dev Support for IERC-2981, royalties
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool)
    {
        return interfaceId == type(_IERC2981).interfaceId;
    }
}