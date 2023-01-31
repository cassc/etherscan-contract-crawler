// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRuniverseLand {
    enum PlotSize {
        _8,
        _16,
        _32,
        _64,
        _128,
        _256,
        _512,
        _1024,
        _2048,
        _4096
    }

    event LandMinted(address to, uint256 tokenId, IRuniverseLand.PlotSize size);

    function mintTokenId(
        address recipient,
        uint256 tokenId,
        PlotSize size
    ) external;
}