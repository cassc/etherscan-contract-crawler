// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "@openzeppelin/contracts/utils/Address.sol";


struct Config {
    string name;
    string symbol;
    uint256 maxSupply;
    address signer;
    string baseURI;
    uint256 publicMintLimit;
    uint256 publicMintPrice;
    bool publicMintEnabled;
    bool approveListMintingEnabled;
    address squshyLabsAddress;
    uint256 commission;
    address implementationAddress;
    address withdrawalAddress;
}


contract GeologieXBoozeBearsERC721a is Proxy {
    bytes32 internal constant _implementation_slot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(Config memory _config) {
        assert(_implementation_slot == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_implementation_slot).value = _config.implementationAddress;
        Address.functionDelegateCall(
            _config.implementationAddress,
            abi.encodeWithSignature("initialize((string,string,uint256,address,string,uint256,uint256,bool,bool,address,uint256,address,address))",
                _config
            )
        );
    }

    function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_implementation_slot).value;
    }

}


contract GeologieXBoozeBears is GeologieXBoozeBearsERC721a {
    constructor(Config memory _config) GeologieXBoozeBearsERC721a(_config) {}
}