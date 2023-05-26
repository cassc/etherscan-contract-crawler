// This code was taken from the chainbridge-solidity project listed below,
// licensed under GPL v3. We've made slight modifications, branched from
// the v1.0.0 tag. 
// 
// https://github.com/ChainSafe/chainbridge-solidity.git

pragma solidity ^0.6.0;

/**
    @title Interface for Bridge contract.
    @author ChainSafe Systems.
 */
interface IBridge {
    /**
        @notice Exposing getter for {_chainID} instead of forcing the use of call.
        @return uint8 The {_chainID} that is currently set for the Bridge contract.
     */
    function _chainID() external returns (uint8);
}