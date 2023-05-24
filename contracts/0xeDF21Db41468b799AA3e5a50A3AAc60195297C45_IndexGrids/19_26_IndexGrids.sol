// SPDX-License-Identifier: GPL-3.0
// presented by Wildxyz

pragma solidity ^0.8.17;

import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {Base64} from '@openzeppelin/contracts/utils/Base64.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';
import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {WildNFTRandom} from '../common/WildNFTRandom.sol';

contract IndexGrids is WildNFTRandom {
    // track number of transfer per token in mapping
    mapping(uint256 => uint256) public transferCount;

    // array of palettes
    string[113] public palettes = [
        'Moonstone',
        'Moonstone',
        'Moonstone',
        'Moonstone',
        'Moonstone',
        'Moonstone',
        'Moonstone',
        'Moonstone',
        'Moonstone',
        'Moonstone',
        'Moonstone',
        'Moonstone',
        'Moonstone',
        'Moonstone',
        'Moonstone',
        'Moonstone',
        'Moonstone',
        'Moonstone',
        'Moonstone',
        'Moonstone',
        'Moonstone',
        'Dragon Scale ',
        'Lapis',
        'Lapis',
        'Agate ',
        'Agate',
        'Amethyst',
        'Amethyst',
        'Peridot',
        'Alexandrite',
        'Ruby Sapphire',
        'Charoite',
        'Smoky Quartz',
        'Unakite',
        'Crystal Spectrum',
        'Kyanite',
        'Crystal Spectrum',
        'Ammolite',
        'Smoky Quartz',
        'Smoky Quartz',
        'Smoky Quartz',
        'Crystal Spectrum',
        'Smoky Quartz',
        'Smoky Quartz',
        'Crystal Spectrum',
        'Charoite',
        'Charoite',
        'Charoite',
        'Charoite',
        'Alexandrite',
        'Alexandrite',
        'Pixel Crystal',
        'Charoite',
        'Charoite',
        'Charoite',
        'Charoite',
        'Charoite',
        'Charoite',
        'Rhodolite',
        'Aura',
        'Crystal Spectrum',
        'Crystal Spectrum',
        'Smoky Quartz',
        'Smoky Quartz',
        'Agate',
        'Agate',
        'Agate',
        'Agate',
        'Vayrvynenite',
        'Vayrvynenite',
        'Tigers Eye',
        'Tigers Eye',
        'Peridot',
        'Peridot',
        'Alexandrite',
        'Alexandrite',
        'Crystal Spectrum',
        'Kyanite',
        'Idocrase',
        'Vanadinite',
        'Crystal Spectrum',
        'Smoky Quartz',
        'Dragon Scale ',
        'Ammolite',
        'Crystal Spectrum',
        'Kyanite',
        'Smoky Quartz',
        'Smoky Quartz',
        'Smoky Quartz',
        'Amethsyt',
        'Smithsonite',
        'Dragon Scale ',
        'Mica',
        'Idocrase',
        'Smoky Quartz',
        'Crystal Spectrum',
        'Crystal Spectrum',
        'Eudialyte',
        'Eudialyte',
        'Smoky Quartz',
        'Aurora',
        'Dusky Amber',
        'Turquoise',
        'Smoky Quartz',
        'Fractal',
        'Ammolite',
        'Alexandrite',
        'Smoky Quartz',
        'Eudialyte',
        'Garnet Aurora',
        'Peridot',
        'Big Bang',
        'Eudialyte'
    ];

    // array of twins
    string[113] public twins = [
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        '46',
        '45',
        '48',
        '47',
        '50',
        '49',
        'None',
        '53',
        '52',
        '55',
        '54',
        '57',
        '56',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        '65',
        '64',
        '67',
        '66',
        '69',
        '68',
        '71',
        '70',
        '73',
        '72',
        '75',
        '74',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None',
        'None'
    ];

    string description =
        'With Index Grids, Andre Oshea explores the symbiotic, sometimes uneasy, and ultimately inextricably-linked relationship between the artwork, the artist, and the art market, a complex relationship that is only amplified by Web3 and its blockchain particularities. Each of the 113 tokens in Index Grids will evolve between four phases each time the token is transferred to a new owner. With this gesture, Oshea explores the potential of how the market affects artists output.';

    constructor(address _minter, uint256 _maxSupply, string memory _baseURI, address[] memory _payees, uint256[] memory _shares, uint96 _feeNumerator) WildNFTRandom('Index Grids', 'INDEXGRIDS', _minter, _maxSupply, _baseURI, _payees, _shares, _feeNumerator) {}

    // update 2981 royalty
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721) {
        // Don't count mint as a transfer
        if (from != address(0)) {
            transferCount[tokenId]++;
            emit MetadataUpdate(tokenId);
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function phaseStr(uint256 tokenId) public view returns (string memory) {
        uint256 transfers = transferCount[tokenId];
        uint256 phase = transfers % 4;
        if (phase == 0) {
            return 'PHASE_I';
        } else if (phase == 1) {
            return 'PHASE_II';
        } else if (phase == 2) {
            return 'PHASE_III';
        }
        return 'PHASE_IV';
    }

    // tokenURI function returns json metadata for the token
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'Token does not exist.');
        string memory imgUrl = 'https://static.wild.xyz/tokens/unrevealed/assets/unrevealed.webp';
        string memory name = string(abi.encodePacked('Index Grids #', Strings.toString(tokenId)));
        string memory phase = phaseStr(tokenId);
        string memory externalUrl = string.concat('https://wild.xyz/andre-oshea/index-grids/', Strings.toString(tokenId));
        string memory base = 'Onyx';
        string memory palette = palettes[tokenId];
        string memory twin = twins[tokenId];
        string memory attributesStr = '';
        if (tokenId < 21) {
            base = 'Opal';
        }
        if (bytes(baseURI).length > 0) {
            imgUrl = string(abi.encodePacked(baseURI, phase, '_', Strings.toString(tokenId), '.png'));
            attributesStr = string(abi.encodePacked(',"attributes":[{"trait_type":"Phase","value":"', phase, '"}, {"trait_type": "Base", "value":"', base, '"}, {"trait_type": "Palette", "value":"', palette, '"}, {"trait_type": "Twin", "value":"', twin, '"}]'));
        }
        string memory json = Base64.encode(bytes(abi.encodePacked('{"name":"', name, '", "description": "', description, '", "image": "', imgUrl, '", "external_url": "', externalUrl, '"', attributesStr, '}')));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }
}