/**
 *Submitted for verification at Etherscan.io on 2023-08-10
*/

pragma solidity 0.8.17;

contract MyContracts {
   uint256 public myVars;
    function myFuncs(bytes32 myHash) public {
        myVars = _myFuncs(myHash);
    }

    function _myFuncs(bytes32 myHash) internal view returns (uint256) {
        for (uint256 i = 1; i < 100; i++) {
            if (blockhash(block.number - i) == myHash) {
                return i;
            }
        }
        return 1000;
    }
}