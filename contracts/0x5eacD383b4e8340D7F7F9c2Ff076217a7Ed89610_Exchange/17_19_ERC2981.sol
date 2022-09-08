pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import './IERC2981.sol';

abstract contract ERC2981 is ERC165, IERC2981 {
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        virtual
        override
        returns (address _receiver, uint256 _royaltyAmount);

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}