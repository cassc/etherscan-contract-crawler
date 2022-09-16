// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.4;

import "PolybitPriceOracle.sol";
import "Ownable.sol";

/**
 * @title Polybit Price Oracle Factory v0.0.4
 * @author Matt Leeburn
 * @notice An oracle factory to spawn new price oracles for on-chain price referencing.
 */

contract PolybitPriceOracleFactory is Ownable {
    PolybitPriceOracle[] internal oracleArray;
    address[] internal oracleAddressList;
    string public oracleVersion;

    constructor(address _oracleOwner, string memory _oracleVersion) {
        require(address(_oracleOwner) != address(0));
        _transferOwnership(_oracleOwner);
        oracleVersion = _oracleVersion;
    }

    event PriceOracleCreated(string msg, address ref);

    /**
     * @notice Creates a new Oracle and stores the address in the Oracle Factory's list.
     * @dev Only the Oracle Owner can create a new Oracle.
     */
    function createOracle(address tokenAddress) external onlyOwner {
        PolybitPriceOracle Oracle = new PolybitPriceOracle(
            oracleVersion,
            owner(),
            tokenAddress
        );
        oracleArray.push(Oracle);
        oracleAddressList.push(address(Oracle));
        emit PriceOracleCreated("New price oracle created", address(Oracle));
    }

    /**
     * @param index is the index number of the Oracle in the list of oracles.
     * @return oracleAddressList[index] is the Oracle address in the list of oracles.
     */
    function getOracle(uint256 index) external view returns (address) {
        return oracleAddressList[index];
    }

    // Returns an array of Oracle addresses.
    function getListOfOracles() external view returns (address[] memory) {
        return oracleAddressList;
    }
}