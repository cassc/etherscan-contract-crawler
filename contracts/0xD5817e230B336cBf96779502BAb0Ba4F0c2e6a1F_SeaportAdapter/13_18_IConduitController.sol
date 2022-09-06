pragma solidity ^0.8.0;

interface IConduitController {

    function getConduit(bytes32 conduitKey) external view returns (address conduit, bool exists);

}