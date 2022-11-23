// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../lib/powerpool-agent-v2/lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/powerpool-agent-v2/lib/openzeppelin-contracts/contracts/utils/Create2.sol";
import "../lib/powerpool-agent-v2/lib/openzeppelin-contracts/contracts/utils/introspection/ERC1820Implementer.sol";

contract Create2Ownable is Ownable {
    function deploy(
        uint256 value,
        bytes32 salt,
        bytes memory code
    ) public onlyOwner {
        Create2.deploy(value, salt, code);
    }

    function deployERC1820Implementer(uint256 value, bytes32 salt) public onlyOwner {
        Create2.deploy(value, salt, type(ERC1820Implementer).creationCode);
    }

    function computeAddress(bytes32 salt, bytes32 codeHash) public view returns (address) {
        return Create2.computeAddress(salt, codeHash);
    }

    function computeAddressWithDeployer(
        bytes32 salt,
        bytes32 codeHash,
        address deployer
    ) public pure returns (address) {
        return Create2.computeAddress(salt, codeHash, deployer);
    }

    receive() external payable {}
}