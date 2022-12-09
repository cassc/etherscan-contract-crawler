// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./GravitonTorrentERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Verifier.sol";

contract GravitonTorrentERC721Core is GravitonTorrentERC721 {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _signer
    ) GravitonTorrentERC721(
        _tokenName, _tokenSymbol, _signer, new address payable[](0), new uint96[](0)
    ) {}

    function mint(
        address receiver,
        string memory tokenURI,
        Fee[] memory fees,
        string memory torrentMagnetLink,
        Verifier.Signature memory signature
    ) public override returns (uint256) {
        return
            _mintTorrent(
                receiver,
                tokenURI,
                fees,
                torrentMagnetLink,
                signature
            );
    }
}