pragma solidity >=0.8.4 <0.9.0;

import {SmallRSolution} from './SmallRSolution.sol';

contract Factory {
    function createSolutionContract(bytes32 _salt) public returns (address _resAddress) {
        SmallRSolution _solution = new SmallRSolution{salt: _salt}();
        _resAddress = address(_solution);
    }
}