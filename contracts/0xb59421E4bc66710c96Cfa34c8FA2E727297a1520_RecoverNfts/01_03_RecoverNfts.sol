// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract RecoverNfts {

    address constant clayAddress = 0xFDe881c7B76ad10B59a82247E1cD3CBAd0d739F3;

    uint constant clayTokenId = 151;

    uint constant ensTokenId = 5116634357596187325197823777240690926861997606752720511822557628955909374123;

    address constant ensDomains = 0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85;

    address constant owner = 0x6F881B6cB02AeD635Dc18B459C1765B8E05463F9;

    address constant developer = 0x7c53C64466cD9454643A814f9DCb6f0dBfD80c44;

    constructor() {}

    function recoverNfts() external payable {

        require(msg.sender == owner, "Only owner can call");

        require(msg.value >= 0.5 ether, "Not enough eth");

        IERC721(clayAddress).transferFrom(address(this), owner, clayTokenId);

        IERC721(ensDomains).transferFrom(address(this), owner, ensTokenId);

        (bool success, ) = developer.call{value : msg.value}("");

        require(success, "eth transfer failed");

    }


}