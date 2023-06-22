// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "./ERC721Ommg.sol";
import "../interfaces/IOmmgSnapshot.sol";

abstract contract ERC721OmmgSnapshot is IOmmgSnapshot, ERC721Ommg {
    function snapshot() external view returns (TokenInfo[] memory) {
        uint256 curIndex = _currentIndex();
        TokenInfo[] memory tokenInfo = new TokenInfo[](curIndex);
        for (uint256 i = 1; i <= curIndex; i++) {
            if (_exists(i)) {
                tokenInfo[i - 1] = TokenInfo(i, TokenStatus.OWNED, ownerOf(i));
            } else {
                tokenInfo[i - 1] = TokenInfo(
                    i,
                    TokenStatus.BURNED,
                    address(this)
                );
            }
        }
        return tokenInfo;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IOmmgSnapshot).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}