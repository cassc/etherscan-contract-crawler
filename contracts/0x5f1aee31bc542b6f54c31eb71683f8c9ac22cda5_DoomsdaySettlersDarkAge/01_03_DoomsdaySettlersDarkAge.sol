// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

import "./interfaces/ISettlers.sol";
import "./interfaces/IDoomsdaySettlersDisasters.sol";

contract DoomsdaySettlersDarkAge {

    struct Structure {
        uint32 resources;
        uint32 effects;
        bytes5 lastDisaster;
    }

    int64 constant MAP_WIDTH         = 6_500_000;
    int64 constant MAP_HEIGHT        = 3_000_000;
    uint256 constant ENDGAME_SUPPLY = 8;
    address settlers;
    address disasters;

    mapping(uint32    => Structure) structuralData;

    constructor(){
        settlers = msg.sender;
        disasters = msg.sender;
    }

    function setSettlers(address _settlers) external {
        require(msg.sender == settlers,"access");
        settlers = _settlers;
    }
    function setDisasters(address _disasters) external {
        require(msg.sender == disasters,"access");
        disasters = _disasters;
    }

    function disaster(uint32 _tokenId, uint256 _totalSupply) external returns(uint8 _type, bool destroyed){
        require(msg.sender == settlers,"settlers");
        (
            int64[2] memory _coordinates,
            int64 _radius,
            uint8 __type,
            bytes5 _disasterId
        ) = IDoomsdaySettlersDisasters(disasters).currentDisaster();

        if(_totalSupply < ENDGAME_SUPPLY){
            IDoomsdaySettlersDisasters(disasters).recordDisaster();
        }
        _coordinates;_radius;_disasterId;
        _type = __type;

        require(checkVulnerable(_tokenId ),"vulnerable");
        unchecked{
            if(
                (structuralData[_tokenId].effects >> _type  * 8)%256 + 1
                    >
                (structuralData[_tokenId].resources >> _type  * 8)%256  ){
                    return (_type,true);
            }
            structuralData[_tokenId].effects =
                    structuralData[_tokenId].effects + (uint32(1) << _type * 8);
            structuralData[_tokenId].lastDisaster = _disasterId;
        }
        return (_type, false);
    }

    function reinforce(
        uint32 _tokenId,
        bytes32 _tokenHash,
        bool[4] memory _resources,
        bool _isDarkAge
    ) external returns (uint80 _cost){
        require(msg.sender == settlers,"settlers");
        if(_isDarkAge){
            require(!checkVulnerable(_tokenId ),"vulnerable");
        }
        require(!_resources[getGeography(_tokenHash)],"immune");
        unchecked {
            uint32 resources = structuralData[_tokenId].resources;
            for(uint8 i = 0; i < 4; ++i){
                if(_resources[i]){
                    _cost += uint80( 2 ** ( ( resources >> i  * 8 ) % 256 ) );
                    resources = resources + (uint32(1) << i * 8);
                }
            }
            structuralData[_tokenId].resources = resources;
        }
        return _cost;
    }

    function checkVulnerable(uint32 _tokenId) public view returns(bool _vulnerable){
        (
            int64[2] memory _coordinates,
            int64 _radius,
            uint8 _type,
            bytes5 _disasterId
        ) = IDoomsdaySettlersDisasters(disasters).currentDisaster();

        if(structuralData[_tokenId].lastDisaster == _disasterId) return false;
        bytes32 _hash = ISettlers(settlers).hashOf(_tokenId);
        if(getGeography(_hash) == _type) return false;
        unchecked{
            int64[2] memory _settlementLocation;
            (_settlementLocation[0], _settlementLocation[1]) = getCoordinates(_hash);

            for(int64 x = -1; x <= 1; ++x ){
                for(int64 y = -1; y <= 1; ++y){
                    int64 dx = _settlementLocation[0] - (_coordinates[0] + MAP_WIDTH * x);
                    int64 dy = _settlementLocation[1] - (_coordinates[1] + MAP_HEIGHT * y);
                    if(dx**2 + dy**2 < _radius**2) return true;
                }
            }
        }
        return false;
    }

    function getUnusedFees(uint32 _tokenId) external view returns (uint80){
        uint80 fees = 0;
        unchecked{
            uint32 resources    = structuralData[_tokenId].resources;
            uint32 effects      = structuralData[_tokenId].effects;
            for(uint8 i = 0; i < 4; ++i){
                uint32 resource = resources % 256;
                uint32 effect   = effects % 256;
                resources >>= 8;
                effects   >>= 8;
                if(effect < resource){
                    fees += uint80(resource - effect);
                }
            }
        }
        return fees;
    }

    function getStructuralData(uint32 _tokenId) external view returns(
        uint32 resources,
        uint32 effects,
        bytes5 lastDisaster
    ){
        return (
            structuralData[_tokenId].resources,
            structuralData[_tokenId].effects,
            structuralData[_tokenId].lastDisaster
        );
    }

    function getCoordinates(bytes32 _hash) public pure returns(int64 x, int64 y){
        unchecked{
            x = int64( uint64(   uint32( uint256(_hash)  >> 128    ) )   ) % MAP_WIDTH;
            y = int64( uint64(   uint32( uint256(_hash)  % 2** 128 ) )   ) % MAP_HEIGHT;
            return (x,y);
        }
    }

    function getGeography(bytes32 _hash) public pure returns(uint8){
        unchecked{
            return uint8(uint256(_hash)%4);
        }
    }
}