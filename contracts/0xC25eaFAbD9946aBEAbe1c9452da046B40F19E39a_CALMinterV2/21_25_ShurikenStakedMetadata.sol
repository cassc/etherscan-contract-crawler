// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './ShurikenStakeRenderer.sol';

contract ShurikenStakedMetadata is Ownable {
    using Strings for uint256;

    ShurikenStakeRenderer public renderer;

    constructor(ShurikenStakeRenderer _renderer) {
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
                    '","description": "After purchasing a Shuriken NFTs, you can directly \\"support\\" the production activities by staking your Shuriken NFT to each project. In addition, when there are multiple projects, you can be involved in the direction of the production by staking your Shuriken NFTs to the projects that you would like to see realized. Shuriken NFTs that have not been used for staking can be sold and purchased through secondary distribution, but shuriken that have been used for staking will have a black background and will not be available for sale or purchase through secondary distribution.","attributes": [{"trait_type": "Status","value":"unstaking"},{"trait_type": "Color","value":"black"}]}'
                )
            );
    }

    function setRenderer(ShurikenStakeRenderer _renderer) external onlyOwner {
        renderer = _renderer;
    }
}