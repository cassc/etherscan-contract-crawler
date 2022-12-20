import "./02_02_Address.sol";
pragma solidity <=0.8.17;

// SPDX-License-Identifier: MIT

contract DezyMulticall {
    //@dev we permission this to only EOA to safeguard state mutation when called by a contract
    function multiDcall(address[] calldata addresses, bytes[] calldata data)
        external virtual
        returns (bytes[] memory results)
    {
        require(msg.sender == tx.origin, "multiDcall: only EOA");
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(addresses[i], data[i]);
        }
        return results;
    }

    function multicall(address[] calldata addresses, bytes[] calldata data)
        external
        virtual
        view
        returns (bytes[] memory results)
    {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionStaticCall(addresses[i], data[i]);
        }
        return results;
    }
}