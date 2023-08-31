// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import "./interfaces/ISettlersBatchable.sol";

// Requires Approval
//  It takes the tokens, reinforces them, and then gives them back at the end of the tx. 
//   Sufficient msg.value must be provided. If you provide surplus msg.value, it refunds 
//    that at the end too. If anyone other than the Settlers contract sends it ETH, it
//     immediately refunds it.

contract DoomsdaySettlersBatchReinforceV2{

    ISettlersBatchable settlers;
    address immutable _setters;
    uint80 constant DAMAGE_FEE = 0.008 ether;

    constructor( address __settlers){
        settlers = ISettlersBatchable(__settlers);
        _setters = __settlers;
    }

    receive() external payable{
        if(msg.sender != _setters){
            payable(msg.sender).transfer(msg.value);
        }
    }

    function multiLevelReinforce(uint32 _tokenId, uint80[4] memory _currentLevels, uint80[4] memory _extraLevels, uint80 _highest, uint80 _baseCost) external payable{
        _multiLevelReinforce(_tokenId,_currentLevels,_extraLevels,_highest,_baseCost);

            require(gasleft() > 10000,"gas failsafe");
            if(address(this).balance > 0){
                payable(msg.sender).transfer(address(this).balance);
            }
    }


    function _multiLevelReinforce(uint32 _tokenId, uint80[4] memory _currentLevels, uint80[4] memory _extraLevels, uint80 _highest, uint80 _baseCost) private{
        settlers.transferFrom(msg.sender,address(this),_tokenId);

        for(uint80 i = 1; i <= _highest; i++){
            bool[4] memory __resources;
            uint80 _cost;

            uint80 reinforcementUnits;
            uint80 totalLevels;

            for(uint j = 0; j < 4; j++){
                if(_extraLevels[j] >= i){
                    __resources[j] = true;
                    reinforcementUnits += uint80(2) ** _currentLevels[j];
                    totalLevels++;

                    _currentLevels[j]++;

                }
            }

            _cost = reinforcementUnits * _baseCost + totalLevels * DAMAGE_FEE;

            settlers.reinforce{value: _cost}(_tokenId,__resources);

        }

        settlers.transferFrom(address(this),msg.sender,_tokenId);
    }


    function multiTokenReinforce(uint32[] memory _tokenIds, uint80[4][] memory _currentLevels, uint80[4][] memory _extraLevels, uint8[] memory _highest, uint80 _baseCost) external payable{
        require(_tokenIds.length > 0,"no tokens");
        
        for(uint i = 0; i < _tokenIds.length; i++){
            _multiLevelReinforce(_tokenIds[i],_currentLevels[i],_extraLevels[i],_highest[i],_baseCost);
        }
        
        require(gasleft() > 10000,"gas failsafe");
        if(address(this).balance > 0){
            payable(msg.sender).transfer(address(this).balance);
        }

    }






}