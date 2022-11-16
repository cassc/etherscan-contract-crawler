// SPDX-License-Identifier: MIT
// Promos v1.0.0
// Creator: promos.wtf

pragma solidity ^0.8.0;

import "./IPromos.sol";
import "./PromosProxy.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract Promos is IPromos, ERC165 {
    address public promosProxyContract;

    modifier OnlyPromos(address _to) {
        address promosMintContract = PromosProxy(promosProxyContract)
            .promosMintAddress();
        require(_to != promosMintContract, "Not ERC721 reciever");
        require(msg.sender == promosMintContract, "Wrong msg.sender");
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165)
        returns (bool)
    {
        return
            interfaceId == type(IPromos).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}