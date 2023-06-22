// SPDX-License-Identifier: GPL-3.0
// presented by Wildxyz

pragma solidity ^0.8.17;

import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';

import {WildNFT} from '../common/WildNFT.sol';
import {KieyaMetadata} from './KieyaMetadata.sol';

contract Kieya is WildNFT {

    uint256 public CYCLE_SECONDS = 1814400; // 21 days * 24 hours * 60 minutes * 60 seconds

    KieyaMetadata public metadataContract;
    bool public JamaicaWeatherIsSunny = true;
    uint256 public lastWeatherUpdate = 0;
    address public admin; // Nygilias address

    constructor(address _minter, uint256 _maxSupply, string memory _baseURI, address[] memory _payees, uint256[] memory _shares, uint96 _feeNumerator ) WildNFT('KIEYA', 'KIEYA', _minter, _maxSupply, _baseURI, _payees, _shares, _feeNumerator) {}

    modifier onlyOwnerOrAdmin { 
        require(msg.sender == owner() || msg.sender == admin, 'Only owner or admin can call this function.');
        _; 
    }

    function setAdmin(address _admin) public onlyOwner {
        admin = _admin;
    }

    function setJamaicaWeather(bool _weather) public onlyOwnerOrAdmin {
        // weather in Portland, Jamaica is sunny or not
        // https://weather.com/weather/tenday/l/bf81551185fab030de85beba4c543d6e284188dfe739c21b6c6e3eeb4e4d15a1#
        require(block.timestamp - lastWeatherUpdate > CYCLE_SECONDS, 'You can only change the weather every 21 days.');
        JamaicaWeatherIsSunny = _weather;      
        lastWeatherUpdate = block.timestamp;  
        emit BatchMetadataUpdate(0, maxSupply - 1);
    }

    function setMetadataContract(KieyaMetadata _metadataContract) public onlyOwner {
        metadataContract = _metadataContract;
    }

    // update 2981 royalty
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // tokenURI function returns json metadata for the token
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'Token does not exist.');
        return metadataContract.generateTokenURI(tokenId, baseURI, JamaicaWeatherIsSunny, CYCLE_SECONDS);
    }

}