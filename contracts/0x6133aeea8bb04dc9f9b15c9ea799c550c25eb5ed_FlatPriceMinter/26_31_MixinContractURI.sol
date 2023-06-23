pragma solidity ^0.7.3;

import "./MixinOwnable.sol";

contract MixinContractURI is Ownable {
    string public contractURI;

    function setContractURI(string calldata newContractURI) external onlyOwner() {
        contractURI = newContractURI;
    }
}