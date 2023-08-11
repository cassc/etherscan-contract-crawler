// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}


contract Multicall {
    function getSelector(address _to, uint _value) public pure returns (bytes memory) {
        return abi.encodeCall(IERC20.transfer, (_to, _value));
    }

    function executeTokenTransferMulticall(address token, address[] calldata targets, uint256[] calldata amounts) external returns (bytes[] memory) {
        require(targets.length == amounts.length, "Length not equal");
        bytes[] memory results = new bytes[](targets.length);


        for (uint i = 0; i < targets.length; i++) {
            bytes memory data = getSelector(targets[i], amounts[i]);

            (bool sucess, bytes memory result) = token.call(data);

            require(sucess, "call failed");

            results[i] = (result);
        }

        return results;
    }

    function executeMulticall(address[] calldata targets, bytes[] calldata data) external returns (bytes[] memory) {
        require(targets.length == data.length, "Length not equal");
        bytes[] memory results = new bytes[](targets.length);


        for (uint i = 0; i < targets.length; i++) {
            (bool sucess, bytes memory result) = targets[i].call(data[i]);

            require(sucess, "call failed");

            results[i] = (result);
        }

        return results;
    }
}