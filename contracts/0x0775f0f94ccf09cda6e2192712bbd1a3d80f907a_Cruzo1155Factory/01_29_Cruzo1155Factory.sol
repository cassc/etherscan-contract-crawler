//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../tokens/Cruzo1155.sol";

contract Cruzo1155Factory is Context, Ownable {
    event NewTokenCreated(
        address indexed tokenAddress,
        address indexed creator,
        bool isPublic
    );

    address public beacon;
    address public transferProxy;

    constructor(address _beacon, address _transferProxy) {
        beacon = _beacon;
        transferProxy = _transferProxy;
    }

    function create(
        string calldata _name,
        string calldata _symbol,
        string calldata _baseURI,
        string calldata _contractURI,
        bool _publiclyMintable
    ) external returns (address) {
        BeaconProxy proxy = new BeaconProxy(
            address(beacon),
            abi.encodeWithSelector(
                Cruzo1155.initialize.selector,
                _name,
                _symbol,
                _baseURI,
                _contractURI,
                transferProxy,
                _publiclyMintable
            )
        );
        Cruzo1155(address(proxy)).transferOwnership(_msgSender());
        emit NewTokenCreated(address(proxy), _msgSender(), _publiclyMintable);
        return address(proxy);
    }
}