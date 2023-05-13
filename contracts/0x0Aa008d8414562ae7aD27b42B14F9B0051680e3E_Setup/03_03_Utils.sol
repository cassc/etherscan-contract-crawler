// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.7;
pragma experimental ABIEncoderV2;

abstract contract AuthLike {
    function addAuthorization(address) external virtual;
    function setOwner(address) external virtual;
}

abstract contract PauseLike {
    function scheduleTransaction(address, bytes32, bytes calldata, uint256) external virtual;
    function executeTransaction(address, bytes32, bytes calldata, uint256) external virtual;
    function  proxy() external virtual returns (address);
}

contract Utils {
    mapping (string => address) public addr;
    string[] public addressList;
    event log_named_address(string key, address val);

    function addressListLength() public view returns (uint256) {return addressList.length;}

    function addAddress(string memory name, address val) internal {
        emit log_named_address(name, val);
        addressList.push(name);
        addr[name] = val;
    }

    function addAddress(string memory name, address val, address auth) internal {
        AuthLike(val).addAuthorization(auth);
        addAddress(name, val);
    }

    function getExtCodeHash(address usr)
        internal view
        returns (bytes32 codeHash)
    {
        assembly { codeHash := extcodehash(usr) }
    }

    function getChainID() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}