pragma solidity ^0.8.16;

import "./DividedPool.sol";

contract DividedFactory {
    mapping(address => address) public pools;
    address public deployNftContract;

    event PoolCreated(address nftContract, address pool);

    function deploy(address nftContract) external returns (address) {
        deployNftContract = nftContract;
        address pool = address(new DividedPool{salt:keccak256(abi.encode(nftContract))}());
        pools[nftContract] = pool;
        emit PoolCreated(nftContract, pool);
        return pool;
    }
}