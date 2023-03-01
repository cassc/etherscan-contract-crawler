// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DragonBridge is Ownable {

    event ClaimAptosTokens(address claimer, uint amount, bytes32 aptosWallet);

    IERC721 dragons;

    function setDragons(IERC721 _dragons) external onlyOwner{
        dragons = _dragons;
    }

    function requestMigration(uint256[] calldata tokens, bytes32 aptosWallet) external{
        uint len = tokens.length;
        for(uint i = 0; i < len; i++){
            dragons.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, tokens[i]);
        }
        emit ClaimAptosTokens(msg.sender, len, aptosWallet);
    }
}