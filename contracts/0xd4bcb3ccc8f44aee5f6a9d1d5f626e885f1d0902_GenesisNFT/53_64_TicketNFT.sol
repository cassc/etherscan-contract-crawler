// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import '../interfaces/IMintableBurnableERC721.sol';
import '../core/SafeOwnable.sol';
import '../core/Mintable.sol';
import '../core/Burnable.sol';
import '../core/NFTCore.sol';

contract TicketNFT is SafeOwnable, NFTCore, Mintable, Burnable, IMintableBurnableERC721 {

    constructor(
        string memory _name, 
        string memory _symbol, 
        string memory _uri
    ) NFTCore(_name, _symbol, _uri, 15000) Mintable(new address[](0), false) Burnable(new address[](0), false) {
    }

    function mint(address _to, uint _num) external override onlyMinter {
        mintInternal(_to, _num);
    }

    function burn(address _user, uint256 _tokenId) external override onlyBurner {
        burnInternal(_user, _tokenId); 
    }
}