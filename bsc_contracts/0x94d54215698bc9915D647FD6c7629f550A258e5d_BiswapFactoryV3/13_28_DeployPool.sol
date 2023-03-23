pragma solidity ^0.8.4;

import "../core/BiswapPoolV3.sol";

library DeployPool {

    function INIT_CODE_HASH() external pure returns(bytes32) {
        return keccak256(abi.encodePacked(type(BiswapPoolV3).creationCode));
    }

    function deployPool(bytes32 salt) external returns(address){
        return address(new BiswapPoolV3{salt: salt}());
    }
}