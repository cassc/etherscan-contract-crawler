// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9.0;

import "https://github.com/Arachnid/solidity-stringutils/blob/master/src/strings.sol";
import "https://github.com/ensdomains/ens-contracts/blob/v0.0.8/contracts/registry/ENS.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct Account {
    string name;
    address addr;
    bool resolved;
    string avatar;
}

interface IRegistrar  {
     function node(address _addr) external view returns (bytes32);
}

interface IResolver {
    function name(bytes32 _node) external view returns (string memory);
}

interface IPublicResolver {
    function text(bytes32 node, string calldata text) external view returns(string memory);
    function addr(bytes32 node) external view returns(address);
}

contract AddressLookup is Ownable {
    using strings for *;

    address REVERSE_REGISTRAR_ADDRESS = 0x084b1c3C81545d370f3634392De611CaaBFf8148;
    address REVERSE_RESOLVER_ADDRESS = 0xA2C122BE93b0074270ebeE7f6b7292C7deB45047;
    address ENS_ADDRESS = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;

    IResolver  reverse_resolver  = IResolver(REVERSE_RESOLVER_ADDRESS);
    IRegistrar reverse_registrar = IRegistrar(REVERSE_REGISTRAR_ADDRESS);
    ENS public ens = ENS(ENS_ADDRESS);

    function setReverseResolver(address _new) external onlyOwner {
        REVERSE_RESOLVER_ADDRESS = _new;
    }

    function setReverseRegsitrar(address _new) external onlyOwner {
        REVERSE_REGISTRAR_ADDRESS = _new;
    }

    function setENS(address _new) external onlyOwner {
        ENS_ADDRESS = _new;
    }

    function getAccountNames(address[] memory _addr) public view returns(Account[] memory) { //Account[] memory

        Account[] memory names = new Account[](_addr.length);

        for(uint256 i; i < _addr.length;){

            address currentAddress = _addr[i];
            bytes32 reverse_node = reverse_registrar.node(currentAddress);
            string memory name = reverse_resolver.name(reverse_node);
            bytes32 node = getDomainHash(name);

            address resolverAddr = ens.resolver(node);

            if (resolverAddr == address(0)){
                // no resolver = no avatar || address
                names[i] = Account(name, currentAddress, false, "null");
            }else {
                // has resolver
                IPublicResolver resolv = IPublicResolver(resolverAddr);
                address nameAddress = resolv.addr(node);
                string memory avatar = resolv.text(node, "avatar");

                if (nameAddress == currentAddress){
                    names[i] = Account(name, currentAddress, true, avatar);
                }else{
                    names[i] = Account(name, currentAddress, false, avatar);
                }

            }
            unchecked { ++i; }
        }
        return names;
    }

    function getParts(string memory _string) public view returns(string[] memory) {
        strings.slice memory delim = ".".toSlice();
        strings.slice memory _string = _string.toSlice();
        uint256 count = _string.count(delim);

        if (count == 0){
            string[] memory x = new string[](0);
            return x;
        }

        string[] memory parts = new string[](_string.count(delim) + 1);
        for(uint i = 0; i < parts.length; i++) {
            parts[i] = _string.split(delim).toString();
        }
        return parts;
    }

    ///this is the correct method for creating a 2 level ENS namehash
    function getDomainHash(string memory _ensName) public view returns (bytes32 namehash) {
        string[] memory _arr = getParts(_ensName);
        namehash = 0x0;

        for(uint256 i; i < _arr.length;){
            unchecked{ ++i; }
            namehash = keccak256(abi.encodePacked(namehash, keccak256(abi.encodePacked(_arr[_arr.length - i]))));               
        }
        return namehash;
    }
    
}