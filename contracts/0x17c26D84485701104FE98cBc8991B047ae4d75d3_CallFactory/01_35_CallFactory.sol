// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import './interfaces/ICallFactory.sol';
import './interfaces/pool/ICallPoolImmutables.sol';
import './CallPoolDeployer.sol';
import './NoDelegateCall.sol';
import './CallPool.sol';


contract CallFactory is ICallFactory, CallPoolDeployer, NoDelegateCall, Ownable {

    mapping(address => address) public override getPool;

    constructor(address nTokenFactory, address callTokenFactory) Ownable() CallPoolDeployer(nTokenFactory, callTokenFactory) {
    }

    function createPool(
        address erc721token,
        address oracle,
        address premium
    ) external override noDelegateCall onlyOwner returns (address pool) {
        require(erc721token != address(0));
        require(oracle != address(0));
        require(premium != address(0));
        require(getPool[erc721token] == address(0));
        pool = deploy(address(this), erc721token, oracle, premium);
        // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
        getPool[erc721token] = pool;
        ICallPoolImmutables poolImmutables = ICallPoolImmutables(pool);
        emit PoolCreated(erc721token, oracle, pool, premium, poolImmutables.nToken(), poolImmutables.callToken());
    }
}