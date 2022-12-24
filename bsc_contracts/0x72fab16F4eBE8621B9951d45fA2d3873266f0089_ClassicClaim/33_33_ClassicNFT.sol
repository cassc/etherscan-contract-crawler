// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import '../interfaces/IMintableBurnableERC721V2.sol';
import '../core/SafeOwnable.sol';
import '../core/Mintable.sol';
import '../core/Burnable.sol';
import '../core/NFTCoreV3.sol';

contract ClassicNFT is SafeOwnable, NFTCoreV3, Mintable, Burnable {

    constructor(
        string memory _name, 
        string memory _symbol, 
        string memory _uri
    ) NFTCoreV3(_name, _symbol, _uri, type(uint256).max) Mintable(new address[](0), false) Burnable(new address[](0), false) {
    }

    function mint(address _to, uint _num) external onlyMinter {
        mintInternal(_to, _num);
    }

    function burn(address _user, uint256 _tokenId) external onlyBurner {
        burnInternal(_user, _tokenId);
    }
}