pragma solidity ^0.8.16;

import "./DividedPool.sol";

contract DividedFactory {
    mapping(address => address) public pools;
    address public deployNftContract;

    function deploy(address nftContract) external returns (address) {
        deployNftContract = nftContract;
        DividedPool pool = new DividedPool{salt:keccak256(abi.encode(nftContract))}();
        pools[nftContract] = address(pool);
        return address(pool);
    }
}