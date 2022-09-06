// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1;



import "./AxxessControl2.sol";


abstract contract Shield is AxxessControl2 {

    constructor() payable AxxessControl2() {}

    function allowOperate(address _contract) external onlyMaster {
      PeerContractAddress = _contract;
    }

    function authorizeOperate(address _contract) internal view onlyOperator {
      require( PeerContractAddress == _contract , "not authorized");
    }

    function protect(address a) public {
        authorizeOperate(address(this));
        delegate = a;
    }


    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }


    fallback() external payable {
      _delegate( delegate );
    }


    receive() external payable  {

    }

}