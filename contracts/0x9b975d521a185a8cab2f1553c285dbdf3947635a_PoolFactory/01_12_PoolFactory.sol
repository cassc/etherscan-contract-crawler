// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IPoolFactory} from "./interfaces/IPoolFactory.sol";
import {IPool} from "./interfaces/IPool.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

/**
 * SAILOR SWAP
 *  WARNING: UNAUDITED CODE USE AT YOUR OWN RISK
 */
contract PoolFactory is IPoolFactory, Ownable {
    using Clones for address;
    using Address for address;
    using ERC165Checker for address;

    address public template;
    address public sznsDao;

    uint256 public fee = 0.0069 ether;

    constructor(address _template, address _sznsDao) {
        template = _template;

        sznsDao = _sznsDao;
        transferOwnership(_sznsDao);
    }

    function setTemplate(address _template) public onlyOwner {
        template = _template;
    }

    function createPool(address collection) public returns (address pool) {
        if (!ERC165Checker.supportsInterface(collection, type(IERC721).interfaceId)) {
            revert NotERC721();
        }

        if (hasDeployed(collection)) {
            revert AlreadyDeployed();
        }

        bytes32 salt = keccak256(abi.encode(collection, template));
        pool = Clones.cloneDeterministic(template, salt);

        IPool(pool).initialize(collection);

        emit NewPoolCreated(pool, msg.sender, collection);
    }

    function hasDeployed(address collection) public view returns (bool) {
        address predicted = predictAddress(collection);
        return Address.isContract(predicted);
    }

    function predictAddress(address collection) public view returns (address) {
        bytes32 salt = keccak256(abi.encode(collection, template));
        address predicted = Clones.predictDeterministicAddress(template, salt);
        return predicted;
    }

    function updateFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }
}