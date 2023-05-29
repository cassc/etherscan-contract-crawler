// SPDX-License-Identifier: Unlicense

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./interfaces/IKaijuMartRedeemable.sol";

pragma solidity ^0.8.0;

abstract contract KaijuMartRedeemable is IKaijuMartRedeemable, ERC165 {
    /**
     * @dev Ensure this is only callable by Kaiju Mart
     */
    function kmartRedeem(uint256 lotId, uint32 amount, address to) public virtual override;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return interfaceId == type(IKaijuMartRedeemable).interfaceId || super.supportsInterface(interfaceId);
    }
}