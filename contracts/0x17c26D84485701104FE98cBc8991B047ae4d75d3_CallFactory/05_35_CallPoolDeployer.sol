// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;
pragma abicoder v2;

import './interfaces/ICallPoolDeployer.sol';
import './CallPool.sol';
import './NToken.sol';
import './CallToken.sol';

abstract contract CallPoolDeployer is ICallPoolDeployer {
        struct Parameters {
        address factory;
        address erc721token;
        address ntoken;
        address calltoken;
        address oracle;
        address premium;
    }

    Parameters public override parameters;

    address immutable nTokenFactory;
    address immutable callTokenFactory;

    constructor (address _nTokenFactory, address _callTokenFactory) {
        nTokenFactory = _nTokenFactory;
        callTokenFactory = _callTokenFactory;
    }

    function deploy(address factory, address erc721token, address oracle, address premium) internal returns (address pool) {
        parameters.factory = factory;
        parameters.erc721token = erc721token;
        parameters.oracle = oracle;
        parameters.premium = premium;
        (bool success1, bytes memory result1) = nTokenFactory.delegatecall(
            abi.encodeWithSignature('deployNToken(bytes32)', keccak256(abi.encode('ntoken', erc721token)))
        );
        require(success1);
        (address ntoken) = abi.decode(result1, (address));
        parameters.ntoken = ntoken;
        (bool success2, bytes memory result2) = callTokenFactory.delegatecall(
            abi.encodeWithSignature('deployCallToken(bytes32)', keccak256(abi.encode('calltoken', erc721token)))
        );
        require(success2);
        (address calltoken) = abi.decode(result2, (address));
        parameters.calltoken = calltoken;
        pool = address(new CallPool{salt: keccak256(abi.encode('callpool', erc721token, ntoken, calltoken, oracle, premium))}());
        NToken(ntoken).transferOwnership(pool);
        CallToken(calltoken).transferOwnership(pool);

        delete parameters;
    }
}