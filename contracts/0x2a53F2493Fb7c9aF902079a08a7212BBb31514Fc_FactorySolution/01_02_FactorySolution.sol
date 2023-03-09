pragma solidity >=0.8.4 <0.9.0;

import {Solution} from './Solution.sol';

contract FactorySolution {
    function createSolutionContract(bytes32 _salt) public returns (address _resAddress) {
        Solution _solution = new Solution{salt: _salt}();
        _resAddress = address(_solution);
    }
}