// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract ProxyMint2 {
    address public constant nftFactory = 0x612E2DadDc89d91409e40f946f9f7CfE422e777E;
    function mintNFTs(address collection, uint amount, string[] calldata tokenCID) public {
        uint256 Id;
        while ( Id < amount ) {
            (bool success,  ) = collection.delegatecall(
                abi.encodeWithSignature("mint(string)", tokenCID[Id])
            );
            require(success, "mintNFTs: delegatecall error");
            Id++;
        }
    }
}