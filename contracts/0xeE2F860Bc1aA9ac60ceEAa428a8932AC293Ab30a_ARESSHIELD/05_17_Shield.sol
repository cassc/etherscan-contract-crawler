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

    function protect2(address a) public {
        authorizeOperate(address(this));
        delegate2 = a;
    }


    function _delegate(address implementation, address implementation2) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            /* first level */
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            if eq(result,0) {
               result := delegatecall(gas(), implementation2, 0, calldatasize(), 0, 0)
            }

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
              // delegatecall returns 0 on error.
              case  0 {
                  revert(1, returndatasize())
              }
              default {
                  return(0, returndatasize())
              }



        }
    }


    fallback() external payable {
       _delegate( delegate, delegate2 );
    }


    receive() external payable  {

    }

}