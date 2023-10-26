// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/IBeamToken.sol";

contract Migrator {

    IBeamToken public immutable source;
    IBeamToken public immutable destination;
    uint256 public immutable migrationRate;
    uint256 public constant DECIMAL_PRECISION = 1e18;

    event Migrated(address indexed migrant, uint256 indexed destinationAmount);

    constructor(address _source, address _destination, uint256 _migrationRate) {
        require(address(_source) != address(0), "Source cannot be zero address");
        require(address(_destination) != address(0), "Destination cannot be zero address");
        require(_migrationRate > 0, "Migration rate cannot be zero");
        source = IBeamToken(_source);
        destination = IBeamToken(_destination);
        migrationRate = _migrationRate;
    }

    function migrate(uint256 _sourceAmount) external {
        uint256 destinationAmount = _sourceAmount * migrationRate / DECIMAL_PRECISION;
        source.burn(msg.sender, _sourceAmount);
        destination.mint(msg.sender, destinationAmount);
        emit Migrated(msg.sender, destinationAmount);
    }
}