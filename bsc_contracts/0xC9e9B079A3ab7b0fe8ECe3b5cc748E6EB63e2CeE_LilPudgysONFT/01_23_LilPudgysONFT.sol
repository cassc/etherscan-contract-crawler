// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

import "@layerzerolabs/solidity-examples/contracts/token/onft/ONFT721.sol";

contract LilPudgysONFT is ONFT721 {
    string public baseTokenURI;
    uint256 public constant MAX_ELEMENTS = 22222; //  MAX_RESERVE + MAX_CLAIM + MAX_AUCTION

    constructor(string memory baseURI, string memory _name, string memory _symbol, address _lzEndpoint) ONFT721(_name, _symbol, _lzEndpoint) {
        setBaseURI(baseURI);
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        if(tokenCount == 0){
            return tokensId;
        }

        uint256 key = 0;
        for (uint256 i = 0; i < MAX_ELEMENTS; i++) {
            if(rawOwnerOf(i) == _owner){
                tokensId[key] = i;
                key++;
                if(key == tokenCount){break;}
            }
        }

        return tokensId;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}