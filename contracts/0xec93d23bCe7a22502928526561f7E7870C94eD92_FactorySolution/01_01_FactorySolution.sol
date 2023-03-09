pragma solidity >=0.8.4 <0.9.0;

contract FactorySolution {
    function createSolutionContract(bytes32 _salt) public returns (address _resAddress) {
        Solution _solution = new Solution{salt: _salt}();
        _resAddress = address(_solution);
    }
}

contract Solution {
    function curtaPlayer() external view returns (address) {
        return 0x0DEdcE798692E8C668d67e430151106aBC9ABCe1;
    }
}