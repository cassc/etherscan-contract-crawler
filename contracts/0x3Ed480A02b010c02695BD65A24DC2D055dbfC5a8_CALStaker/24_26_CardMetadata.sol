// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './CardRenderer.sol';

contract CardMetadata is Ownable {
    using Strings for uint256;

    CardRenderer public renderer;

    mapping(uint256 => string) nameMaster;

    constructor(CardRenderer _renderer) {
        renderer = _renderer;
        nameMaster[0] = 'GENESIS PASSPORT';
    }

    function tokenURI(
        uint256 tokenId,
        address owner,
        uint256 nameId
    ) public view virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'data:application/json;,',
                    '{"name": "#',
                    tokenId.toString(),
                    '","image": "',
                    renderer.get(nameMaster[nameId], owner, tokenId),
                    '","description": "\\"Passport NFT\\" a proof of membership, is a non transferable NFT (SBT type/format - Soul Bound Token). Lab members will be able to stake their \\"Shuriken NFTs\\" into anime projects or individual projects that they want to support and it will directly reflect to their passport. In addition, the \\"Passport NFT\\" will grow based on how many \\"Shuriken NFTs\\" are used. You can visualize how much support you have provided to the \\"Anime Project\\" based on the status and, receive \\"Special benefits such as limited NFTs\\" based on the growth of your \\"Passport NFT\\".","attributes": [{"trait_type": "Color","value":"',
                    renderer.getColor(owner),
                    '"},{"trait_type": "staking","value":',
                    renderer.getShurikenBalance(owner).toString(),
                    '}]}'
                )
            );
    }

    function setRenderer(CardRenderer _renderer) external onlyOwner {
        renderer = _renderer;
    }

    function setNameMaster(uint256 id, string memory name) external onlyOwner {
        nameMaster[id] = name;
    }
}