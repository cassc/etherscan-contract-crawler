// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CloneFactory.sol";
import "./Position.sol";
import "./IFrankencoin.sol";

contract PositionFactory is CloneFactory {

    function createNewPosition(address _owner, address _zchf, address _collateral, 
        uint256 _minCollateral, uint256 _initialCollateral, 
        uint256 _initialLimit, uint256 _duration, uint256 _challengePeriod, 
        uint32 _mintingFeePPM, uint256 _liqPrice, uint32 _reserve) 
        external returns (address) 
    {
        return address(new Position(_owner, msg.sender, _zchf, _collateral, 
            _minCollateral, _initialCollateral, _initialLimit, _duration, 
            _challengePeriod, _mintingFeePPM, _liqPrice, _reserve));
    }

    /**
    * @notice clone an existing position. This can be a clone of another clone,
    * or an origin position. If it's another clone, then the liquidation price
    * is taken from the clone and the rest from the origin. Limit is "inherited"
    * (and adjusted) from the origin.
    * @param _existing     address of the position we want to clone
    * @return address of the newly created clone position
    */
    function clonePosition(address _existing) external returns (address) {
        Position existing = Position(_existing);
        Position clone = Position(createClone(existing.original()));
        return address(clone);
    }

}