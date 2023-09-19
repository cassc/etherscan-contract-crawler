// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Vivid.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Factory is Ownable {
    
    address private _oldVividOwner;
    address private _oldVividContract;
    address private _admin;

    address public vividLogicContract;
    address public vividProxyContract;

    constructor(address oldVividOwner, address oldVividContract, address admin) {
        require(admin != oldVividOwner);
        _oldVividOwner =  oldVividOwner;
        _oldVividContract = oldVividContract;
        _admin = admin;
    }

    function resetStuff(address oldVividOwner, address oldVividContract, address admin) public onlyOwner {
        require(admin != oldVividOwner);
        _oldVividOwner =  oldVividOwner;
        _oldVividContract = oldVividContract;
        _admin = admin;
    }

    function migrateVivid() public {
        require(msg.sender == _oldVividOwner);
        address logicContract = address(new Vivid());
        address proxyContract = address(new TransparentUpgradeableProxy(
            logicContract,
            _admin,
            abi.encodeCall(Vivid.initialize, _oldVividContract)
        ));
        vividLogicContract = logicContract;
        vividProxyContract = proxyContract;
        Vivid(proxyContract).setBaseURI(
            "https://vivid.mypinata.cloud/ipfs/QmdJXNoTTzSkfdusFqidpYuDqDF6p7AMi7iZkmZpxPAByW/"
        );
        Vivid(proxyContract).transferOwnership(_oldVividOwner);
    }

}