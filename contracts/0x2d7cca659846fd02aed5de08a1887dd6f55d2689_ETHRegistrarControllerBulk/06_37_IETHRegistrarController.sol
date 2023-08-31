pragma solidity >=0.8.4;

import "./IPriceOracle.sol";

interface IETHRegistrarController {

    struct domain{
        string name;
        string tld;
    }

    function rentPrice(string memory, uint256, bytes32)
        external
        returns (IPriceOracle.Price memory);

    function NODES(string memory)
        external
        view
        returns (bytes32);

    function available(string memory, string memory) external returns (bool);

    function makeCommitment(
        domain calldata,
        address,
        uint256,
        bytes32,
        address,
        bytes[] calldata,
        bool,
        uint32
    ) external returns (bytes32);

    function commit(bytes32) external;

    function register(
        domain calldata,
        address,
        uint256,
        bytes32,
        address,
        bytes[] calldata,
        bool,
        uint32,
        uint64
    ) external payable;

    function renew(string calldata, uint256,string calldata tld) external payable;
}