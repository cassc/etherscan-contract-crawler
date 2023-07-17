// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

import "./interfaces/ISettlers.sol";

contract DoomsdaySettlersDisasters {

    struct Disaster{
        int64[2] _coordinates;
        int64 _radius;
        uint8 _type;
    }

    uint256 constant MAP_WIDTH      = 6_500_000;
    int64 constant MAP_WIDTH_64     = 6_500_000;
    uint256 constant MAP_HEIGHT     = 3_000_000;
    int64 constant MAP_HEIGHT_64    = 3_000_000;
    uint256 constant BASE_DISASTER_RADIUS = 240_000;
    uint256   constant DISASTER_BLOCK_INTERVAL = 75;
    address immutable SETTLERS;
    address darkAge;
    mapping(bytes32 => Disaster) endTimes;

    constructor(address _settlers){
        SETTLERS = _settlers;
        darkAge = msg.sender;
    }

    function readDisaster() external view returns(
        int64[2] memory _coordinates,
        int64 _radius,
        uint8 _type,
        bytes5 _disasterId
    ){
        uint256 eliminationBlock = block.number - (block.number % DISASTER_BLOCK_INTERVAL) - 1;
        bytes32 _disasterHash = blockhash(eliminationBlock);
        _disasterId = bytes5( _disasterHash << 216);
        return (
            endTimes[_disasterHash]._coordinates,
            endTimes[_disasterHash]._radius,
            endTimes[_disasterHash]._type,
            _disasterId
        );
    }

    function recordDisaster() external {
        require(darkAge == msg.sender,"msg.sender");
        unchecked{
            uint256 eliminationBlock = block.number - (block.number % DISASTER_BLOCK_INTERVAL) - 1;
            bytes32 _disasterHash = blockhash(eliminationBlock);
            ( int64[2] memory _coordinates, int64 _radius, uint8 _type, bytes5 _disasterId ) = currentDisaster();
            _disasterId;

            if( endTimes[_disasterHash]._radius == 0){
                endTimes[_disasterHash]._coordinates  = _coordinates;
                endTimes[_disasterHash]._radius       = _radius;
                endTimes[_disasterHash]._type         = _type;
            }
        }
    }

    function currentDisaster() public view returns (
        int64[2] memory _coordinates,
        int64 _radius,
        uint8 _type,
        bytes5 _disasterId
    ){
        unchecked{
            uint256 eliminationBlock = block.number - (block.number % DISASTER_BLOCK_INTERVAL) - 1;
            bytes32 _disasterHash = blockhash(eliminationBlock);
            _disasterId = bytes5( _disasterHash << 216);
            if(endTimes[_disasterHash]._radius != 0){
                return (
                    endTimes[_disasterHash]._coordinates,
                    endTimes[_disasterHash]._radius,
                    endTimes[_disasterHash]._type,
                    _disasterId
                );
            }
            uint256 hash = uint256(_disasterHash);
            _type = getGeography(_disasterHash);

            uint256 _totalSupply = ISettlers(SETTLERS).totalSupply();
            uint256 o = 14 * MAP_HEIGHT/2/(_totalSupply+1) / 10;
            if(o < BASE_DISASTER_RADIUS){
                o = BASE_DISASTER_RADIUS;
            }

            (_coordinates[0],_coordinates[1]) = getCoordinates(_disasterHash);
            _radius = int64( uint64( (hash/MAP_WIDTH/MAP_HEIGHT)%o + o ) );
            return(_coordinates,_radius, _type, _disasterId);
        }
    }

    function setDarkAge(address _darkAge) public {
        require(msg.sender == darkAge,"msg.sender");
        darkAge = _darkAge;
    }

    function getCoordinates(bytes32 _hash) public pure returns(int64 x, int64 y){
        unchecked{
            x = int64( uint64(   uint32( uint256(_hash)  >> 128    ) )   ) % MAP_WIDTH_64;
            y = int64( uint64(   uint32( uint256(_hash)  % 2** 128 ) )   ) % MAP_HEIGHT_64;
            return (x,y);
        }
    }

    function getGeography(bytes32 _hash) public pure returns(uint8){
        unchecked{
            return uint8(uint256(_hash))%4;
        }
    }
}