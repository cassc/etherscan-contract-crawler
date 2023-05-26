// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

abstract contract Migratable {

    event PrepareMigration(uint256 migrationTimestamp, address source, address destination);

    event ApproveMigration(uint256 migrationTimestamp, address source, address destination);

    event ExecuteMigration(uint256 migrationTimestamp, address source, address destination);

    address public controller;

    uint256 public migrationTimestamp;

    address public migrationDestination;

    bool public isMigrated;

    modifier _controller_() {
        require(msg.sender == controller, 'Migratable._controller_: can only called by controller');
        _;
    }

    modifier _valid_() {
        require(!isMigrated, 'Migratable._valid_: cannot proceed, this contract has been migrated');
        _;
    }

    function setController(address newController) public _controller_ _valid_ {
        require(newController != address(0), 'Migratable.setController: to 0 address');
        controller = newController;
    }

    function prepareMigration(address destination, uint256 graceDays) public _controller_ _valid_ {
        require(destination != address(0), 'Migratable.prepareMigration: to 0 address');
        require(graceDays >= 3 && graceDays <= 365, 'Migratable.prepareMigration: graceDays must be 3-365 days');

        migrationTimestamp = block.timestamp + graceDays * 1 days;
        migrationDestination = destination;

        emit PrepareMigration(migrationTimestamp, address(this), migrationDestination);
    }

    function approveMigration() public virtual;

    function executeMigration(address source) public virtual;

}