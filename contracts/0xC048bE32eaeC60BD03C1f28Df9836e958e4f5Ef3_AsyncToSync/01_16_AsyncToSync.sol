// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import {IAsyncToSync} from "./interfaces/IAsyncToSync.sol";
import {IRenderer} from "./interfaces/IRenderer.sol";

contract AsyncToSync is IAsyncToSync, ERC721, ERC2981, Ownable {
    uint256 public totalSupply;

    uint256 public constant PRICE = 0.1 ether;
    bool public onSale;

    uint8 public maxDrawsCount = 128;
    uint8 public tokenRemaining = 128;
    mapping(uint256 => uint8) public seeds;
    mapping(uint8 => uint8) public drawCache;

    IRenderer public renderer;

    constructor(address rendererAddress) ERC721("Async to Sync", "A2S") {
        renderer = IRenderer(rendererAddress);
    }

    function setOnSale(bool _onSale) external onlyOwner {
        onSale = _onSale;
    }

    function setRenderer(address rendererAddress) external onlyOwner {
        renderer = IRenderer(rendererAddress);
    }

    function setRoyalty(address royaltyReceiver, uint96 royaltyFeeNumerator) external onlyOwner {
        _setDefaultRoyalty(royaltyReceiver, royaltyFeeNumerator);
    }

    function mintByOwner(address to) external onlyOwner {
        require(totalSupply <= maxDrawsCount, "all minted");
        uint256 tokenId = ++totalSupply;
        seeds[tokenId] = drawSeed();
        _mint(to, tokenId);
    }

    function mintExtraByOwner(address to) external onlyOwner {
        require(totalSupply < 256, "all minted");
        uint256 tokenId = ++totalSupply;
        seeds[tokenId] = uint8(uint256(blockhash(block.number - 1)) % (maxDrawsCount - 4)) + 4;
        _mint(to, tokenId);
    }

    function mint(address to) external payable {
        require(tokenRemaining > 0, "all minted");
        require(onSale, "not on sale");
        require(msg.value == PRICE, "invalid value");
        uint256 tokenId = ++totalSupply;
        seeds[tokenId] = drawSeed();
        _safeMint(to, tokenId);
    }

    function batchMint(address to, uint256 count) external payable {
        require(tokenRemaining >= count, "not enough left");
        require(onSale, "not on sale");
        require(msg.value == PRICE * count, "invalid value");
        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = ++totalSupply;
            seeds[tokenId] = drawSeed();
            _safeMint(to, tokenId);
        }
    }

    // Original code by Ping Chen. https://medium.com/taipei-ethereum-meetup/gas-efficient-card-drawing-in-solidity-af49bb135a08
    function drawSeed() private returns (uint8 seed) {
        uint160 seedFromOwner = uint160(_ownerOf(totalSupply - 1));
        uint256 seedFromBlock = uint256(blockhash(block.number - 1));
        uint8 i = uint8((seedFromOwner + seedFromBlock) % tokenRemaining);
        seed = drawCache[i] == 0 ? i : drawCache[i];
        tokenRemaining--;
        drawCache[i] = drawCache[tokenRemaining] == 0 ? tokenRemaining : drawCache[tokenRemaining];
    }

    function musicParam(uint256 tokenId) public view returns (IAsyncToSync.MusicParam memory) {
        uint8 seed = seeds[tokenId] % maxDrawsCount;
        if (seed == 0) {
            return IAsyncToSync.MusicParam(IAsyncToSync.Rarity.OneOfOne, IAsyncToSync.Rhythm.Glitch, IAsyncToSync.Lyric.LittleBoy, IAsyncToSync.Oscillator.Glitch, IAsyncToSync.ADSR.Lead);
        } else if (seed == 1) {
            return IAsyncToSync.MusicParam(IAsyncToSync.Rarity.OneOfOne, IAsyncToSync.Rhythm.HiFi, IAsyncToSync.Lyric.FussyMan, IAsyncToSync.Oscillator.LFO, IAsyncToSync.ADSR.Pluck);
        } else if (seed == 2) {
            return IAsyncToSync.MusicParam(IAsyncToSync.Rarity.OneOfOne, IAsyncToSync.Rhythm.LoFi, IAsyncToSync.Lyric.OldMan, IAsyncToSync.Oscillator.Freak, IAsyncToSync.ADSR.Pad);
        } else if (seed == 3) {
            return IAsyncToSync.MusicParam(IAsyncToSync.Rarity.OneOfOne, IAsyncToSync.Rhythm.Thick, IAsyncToSync.Lyric.LittleGirl, IAsyncToSync.Oscillator.Lyra, IAsyncToSync.ADSR.Piano);
        } else if (seed < 10) {
            return IAsyncToSync.MusicParam(IAsyncToSync.Rarity.UltraRare, IAsyncToSync.Rhythm.Shuffle, IAsyncToSync.Lyric.Shuffle, IAsyncToSync.Oscillator.Shuffle, IAsyncToSync.ADSR.Shuffle);
        } else if (seed < 30) {
            IAsyncToSync.Rhythm rhythm = seed % 4 == 0 ? IAsyncToSync.Rhythm.Thick : seed % 4 == 1 ? IAsyncToSync.Rhythm.LoFi : seed % 4 == 2 ? IAsyncToSync.Rhythm.HiFi : IAsyncToSync.Rhythm.Glitch;
            return IAsyncToSync.MusicParam(IAsyncToSync.Rarity.SuperRare, rhythm, IAsyncToSync.Lyric.Shuffle, IAsyncToSync.Oscillator.Shuffle, IAsyncToSync.ADSR.Shuffle);
        } else if (seed < 54) {
            IAsyncToSync.Rhythm rhythm = seed % 4 == 0 ? IAsyncToSync.Rhythm.Thick : seed % 4 == 1 ? IAsyncToSync.Rhythm.LoFi : seed % 4 == 2 ? IAsyncToSync.Rhythm.HiFi : IAsyncToSync.Rhythm.Glitch;
            IAsyncToSync.ADSR adsr = seed % 4 == 0 ? IAsyncToSync.ADSR.Piano : seed % 4 == 1 ? IAsyncToSync.ADSR.Pad : seed % 4 == 2 ? IAsyncToSync.ADSR.Pluck : IAsyncToSync.ADSR.Lead;
            return IAsyncToSync.MusicParam(IAsyncToSync.Rarity.Rare, rhythm, IAsyncToSync.Lyric.Shuffle, IAsyncToSync.Oscillator.Shuffle, adsr);
        } else {
            return IAsyncToSync.MusicParam(IAsyncToSync.Rarity.Common, IAsyncToSync.Rhythm.Glitch, IAsyncToSync.Lyric.Shuffle, IAsyncToSync.Oscillator.Glitch, IAsyncToSync.ADSR.Lead);
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "not exists");
        return renderer.tokenURI(tokenId, musicParam(tokenId));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function withdrawETH(address payable recipient) external onlyOwner {
        Address.sendValue(recipient, address(this).balance);
    }
}