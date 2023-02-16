// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

import "@layerzerolabs/solidity-examples/contracts/token/onft/ONFT721.sol";

contract MainLPONFT is ONFT721 {
    string public baseTokenURI;
    uint public constant MAX_ELEMENTS = 22222;

    constructor(
        string memory baseURI,
        string memory _name,
        string memory _symbol,
        uint _minGasToTransfer,
        address _lzEndpoint
    ) ONFT721(_name, _symbol, _minGasToTransfer, _lzEndpoint) {
        setBaseURI(baseURI);
    }

    function walletOfOwner(address _owner) external view returns (uint[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint[](tokenCount);

        if (tokenCount == 0) {
            return tokensId;
        }

        uint key = 0;
        for (uint i = 0; i < MAX_ELEMENTS; i++) {
            if (_ownerOf(i) == _owner) {
                tokensId[key] = i;
                key++;
                if (key == tokenCount) {
                    break;
                }
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