pragma solidity >=0.8.4;

import "../bnbregistrar/IPriceOracle.sol";
interface IETHRegistrarController {
    
    function rentPrice(string memory, uint)
        external
        view
        returns (uint);

    function available(string memory) external returns (bool);

    function makeCommitmentWithConfig(
        string memory,
        address,
        bytes32,
        address,
        address
    ) external pure returns (bytes32);

    function commit(bytes32) external;

    function register(
        string calldata,
        address,
        uint256,
        bytes32
    ) external payable;

    function renew(string calldata, uint256) external payable;

    function commitments(bytes32) external view returns (uint256);
}