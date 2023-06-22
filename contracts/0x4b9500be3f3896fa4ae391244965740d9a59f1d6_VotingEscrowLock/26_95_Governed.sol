//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "../../utils/Utils.sol";

contract Governed {
    using Utils for address[];

    bool private _initialized;
    address internal _gov;
    uint256 private _anarchizedAt = 0;
    uint256 private _forceAnarchizeAt = 0;

    event NewGovernance(
        address indexed _prevGovernance,
        address indexed _newGovernance
    );
    event Anarchized();

    constructor() {}

    modifier governed {
        require(msg.sender == _gov, "Not authorized");
        _;
    }

    function initialize(address gov_) public {
        require(!_initialized, "Initialized");
        _initialized = true;
        _gov = gov_;
    }

    function setGovernance(address gov_) public governed {
        require(gov_ != address(0), "Use anarchize() instead.");
        _setGovernance(gov_);
    }

    function setAnarchyPoint(uint256 timestamp) public governed {
        require(_forceAnarchizeAt == 0, "Cannot update.");
        require(
            timestamp >= block.timestamp,
            "Timepoint should be in the future."
        );
        _forceAnarchizeAt = timestamp;
    }

    function anarchize() public governed {
        _anarchize();
    }

    function forceAnarchize() public {
        require(_forceAnarchizeAt != 0, "Cannot disband the gov");
        require(block.timestamp >= _forceAnarchizeAt, "Cannot disband the gov");
        _anarchize();
    }

    function gov() public view returns (address) {
        return _gov;
    }

    function anarchizedAt() public view returns (uint256) {
        return _anarchizedAt;
    }

    function forceAnarchizeAt() public view returns (uint256) {
        return _forceAnarchizeAt;
    }

    function _anarchize() internal {
        _setGovernance(address(0));
        _anarchizedAt = block.timestamp;
        emit Anarchized();
    }

    function _setGovernance(address gov_) internal {
        emit NewGovernance(_gov, gov_);
        _gov = gov_;
    }
}