// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './ShurikenRenderer.sol';

contract ShurikenMetadata is Ownable {
    using Strings for uint256;

    ShurikenRenderer public renderer;

    constructor(ShurikenRenderer _renderer) {
        renderer = _renderer;
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'data:application/json;,',
                    '{"name": "#',
                    tokenId.toString(),
                    '","image": "',
                    renderer.get(),
                    '","description": "After purchasing a Shuriken NFTs, you can directly \\"support\\" the production activities by staking your Shuriken NFT to each project. In addition, when there are multiple projects, you can be involved in the direction of the production by staking your Shuriken NFTs to the projects that you would like to see realized. Shuriken NFTs that have not been used for staking can be sold and purchased through secondary distribution, but shuriken that have been used for staking will have a black background and will not be available for sale or purchase through secondary distribution.","attributes": [{"trait_type": "Status","value":"before staking"},{"trait_type": "Color","value":"multicolor"}]}'
                )
            );
    }

    function setRenderer(ShurikenRenderer _renderer) external onlyOwner {
        renderer = _renderer;
    }
}