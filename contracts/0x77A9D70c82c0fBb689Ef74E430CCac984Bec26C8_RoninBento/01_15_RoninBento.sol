// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

import "./Kitsune.sol";
import "./interfaces/IRoninPartial.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";

contract RoninBento is IERC721Receiver{
    IRoninPartial ronin;
    Kitsune kitsune;

    constructor(address _ronin, address _kitsune){
        ronin = IRoninPartial(_ronin);
        kitsune = Kitsune(_kitsune);
    }

    function mintBento(uint _count) public payable{
        uint lastId = ronin.tokenCount();
        uint lastKitsune = kitsune.totalSupply();

        ronin.mint{value: msg.value}(_count);

        uint[] memory tokenIds = new uint256[](_count);
        for(uint i = 0; i < _count; i++){
            tokenIds[i] = lastId + i + 1;
        }
        kitsune.claimMultiple(tokenIds);

        for(uint i = 0; i < _count; i++){
            ronin.transferFrom(address(this),msg.sender,lastId + i + 1);
            kitsune.transferFrom(address(this),msg.sender,lastKitsune + i + 1);

        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override pure returns (bytes4){
        operator;from;tokenId;data;
        return IERC721Receiver.onERC721Received.selector;
    }
}