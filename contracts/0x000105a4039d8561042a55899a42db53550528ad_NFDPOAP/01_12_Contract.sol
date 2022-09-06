// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//                   ▄              ▄
//                  ▌▒█           ▄▀▒▌
//                  ▌▒▒█        ▄▀▒▒▒▐
//                 ▐▄▀▒▒▀▀▀▀▄▄▄▀▒▒▒▒▒▐
//               ▄▄▀▒░▒▒▒▒▒▒▒▒▒█▒▒▄█▒▐
//             ▄▀▒▒▒░░░▒▒▒░░░▒▒▒▀██▀▒▌
//            ▐▒▒▒▄▄▒▒▒▒░░░▒▒▒▒▒▒▒▀▄▒▒▌
//            ▌░░▌█▀▒▒▒▒▒▄▀█▄▒▒▒▒▒▒▒█▒▐
//           ▐░░░▒▒▒▒▒▒▒▒▌██▀▒▒░░░▒▒▒▀▄▌
//           ▌░▒▄██▄▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▌
//          ▌▒▀▐▄█▄█▌▄░▀▒▒░░░░░░░░░░▒▒▒▐
//          ▐▒▒▐▀▐▀▒░▄▄▒▄▒▒▒▒▒▒░▒░▒░▒▒▒▒▌
//          ▐▒▒▒▀▀▄▄▒▒▒▄▒▒▒▒▒▒▒▒░▒░▒░▒▒▐
//           ▌▒▒▒▒▒▒▀▀▀▒▒▒▒▒▒░▒░▒░▒░▒▒▒▌
//           ▐▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒░▒░▒▒▄▒▒▐
//            ▀▄▒▒▒▒▒▒▒▒▒▒▒░▒░▒░▒▄▒▒▒▒▌
//              ▀▄▒▒▒▒▒▒▒▒▒▒▄▄▄▀▒▒▒▒▄▀
//                ▀▄▄▄▄▄▄▀▀▀▒▒▒▒▒▄▄▀
//                   ▒▒▒▒▒▒▒▒▒▒▀▀

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Counters.sol";

contract NFDPOAP is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private tokenCounter;
    string private baseURI;

    constructor() ERC721("NFD POAP", "POAP") {}

    function mintBatch(address[] memory to) external onlyOwner {
        uint256 length = to.length;
        for (uint256 i = 0; i < length; ) {
            uint256 tokenId = nextTokenId();
            _mint(to[i], tokenId);
            unchecked {
                ++i;
            }
        }
    }

    function mint(address to) public onlyOwner {
        uint256 tokenId = nextTokenId();
        _safeMint(to, tokenId);
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId));
        return baseURI;
    }

    function nextTokenId() private returns (uint256) {
        tokenCounter.increment();
        return tokenCounter.current();
    }
}