// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {FunMint5} from "./FunMint5.sol";

contract FunMintFactory5 is Ownable {
    mapping(uint256 => MintConfig) public configs;
    mapping(bytes32 => bool) public minted;

    error AlreadyDeployed();
    error OnlyMinter();
    error InvalidId();

    event Deployed(bytes32 salt, address addr);

    function deploy(bytes32 salt, bytes memory code) internal returns (address) {
        address addr;
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }

        emit Deployed(salt, addr);
        return addr;
    }

    struct MintConfig {
        address allowedMinter;
        address owner;
        string name;
        string symbol;
        bytes32 salt;
    }

    function setConfig(uint256 id, MintConfig memory config) external onlyOwner {
        if (minted[config.salt]) revert AlreadyDeployed();
        configs[id] = config;
    }

    function create(uint256 id) public returns (address) {
        MintConfig memory conf = configs[id];
        if (conf.allowedMinter == address(0)) revert InvalidId();
        if (conf.allowedMinter != msg.sender) revert OnlyMinter();
        if (minted[conf.salt]) revert AlreadyDeployed();

        address deployed = deploy(conf.salt, type(FunMint5).creationCode);
        FunMint5(payable(deployed)).init(conf.name, conf.symbol, conf.owner);
        return deployed;
    }
}