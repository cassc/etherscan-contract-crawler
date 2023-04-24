// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./NFTcontract.sol";

contract Factory {
    event ContractDeployed(address owner, address clone);
    function genesis(
        address _collectAddress,
        address _deployer,
        string calldata _tokenName,
        string calldata _tokenSymbol,
        uint96 _royalty
    ) external returns (address) {
        NFTcontract mNFT = new NFTcontract(
            _collectAddress,
            _deployer,
            _tokenName,
            _tokenSymbol,
            _royalty
        );
        emit ContractDeployed(msg.sender, address(mNFT));
        return address(mNFT);
    }
}