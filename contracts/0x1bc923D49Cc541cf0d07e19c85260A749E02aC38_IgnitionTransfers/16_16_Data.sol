// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

/**
* @title IGNITION Events Contract
* @author Edgar Sucre
* @notice This Library abstraction methods for package data
*/
library Data {
     /**
    * @dev Insert bitwise boolean into package
    * @param _packageData bit holder
    * @param _value boolean to insert
    * @param _boolNumber bit position in package
    */
    function setPkgDtBoolean(uint256 _packageData, bool _value, uint _boolNumber)
    internal pure returns (uint256)
    {
        uint256 packageData;
        if (_value) {
			packageData = _packageData | uint256(1)<<_boolNumber;
		} else {
			packageData = _packageData & ~(uint256(1)<<_boolNumber);
		}
        return packageData;
    }

    /**
    * @dev Retrieve bitwise boolean from package
    * @param _packageData bit holder
    * @param _boolNumber bit position in package
    */
    function getPkgDtBoolean(uint256 _packageData, uint _boolNumber)
    internal pure returns (bool)
    {
        return (((_packageData>>_boolNumber) & uint256(1)) == 1 ? true : false);
    }
}