// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.7;
pragma experimental ABIEncoderV2;

abstract contract PauseLike {
    function scheduleTransaction(address, bytes32, bytes calldata, uint256) external virtual;
    function executeTransaction(address, bytes32, bytes calldata, uint256) external virtual returns (bytes memory);
}

contract PauseExecutor {
    address owner;

    constructor() public {
        owner = msg.sender;
    }
    function executePauseTransaction(address pause, address usr, bytes calldata data) external returns (bytes memory) {
        require(msg.sender == owner, "unauthed");

        bytes32 codehash = getExtCodeHash(usr);
        PauseLike(pause).scheduleTransaction(
            usr,
            codehash,
            data,
            now
        );

        // execute
        return PauseLike(pause).executeTransaction(
            usr,
            codehash,
            data,
            now
        );
    }

    function getExtCodeHash(address usr)
        internal view
        returns (bytes32 codeHash)
    {
        assembly { codeHash := extcodehash(usr) }
    }    
}