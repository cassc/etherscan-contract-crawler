// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;

interface IClonable {
    function initialize() external;
    function version() external returns(uint256);  
}
abstract contract Clonable {

    function initialize() public virtual;

    function version() public pure virtual returns (uint256) {
        return 1;
    }

}