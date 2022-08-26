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
import "openzeppelin-contracts/contracts/utils/Strings.sol";

contract NFDPOAP is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private tokenCounter;
    string private baseURI = "https://c-mrlx.github.io/feisty-anniversary/";
    mapping(uint256 => bool) isRDP;

    constructor() ERC721("NFD POAP", "POAP") {}

    function mint(address to, bool _isRDP) public onlyOwner {
        uint256 tokenId = nextTokenId();
        isRDP[tokenId] = _isRDP;
        _safeMint(to, tokenId);
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Such revert wow");
        return string(abi.encodePacked(baseURI, _tokenURI(tokenId)));
    }

    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        if (isRDP[tokenId]) {
            return string(abi.encodePacked("rdp/metadata/", Strings.toString(tokenId), ".json"));
        } else {
            return "KatD/POAP_OG.json";
        }
    }

    function nextTokenId() private returns (uint256) {
        tokenCounter.increment();
        return tokenCounter.current();
    }
}