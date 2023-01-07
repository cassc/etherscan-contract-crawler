// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./NFTcontract.sol";

contract Factory {
    event ContractDeployed(address owner, address clone);
    function genesis(
        address _owner,
        string calldata _tokenName,
        string calldata _tokenSymbol,
        uint256 _maxPublicMint,
        uint256 _publicMintPrice,
        address _collectAddress
    ) external returns (address) {
        NFTcontract newNFT = new NFTcontract(
            _owner,
            _tokenName,
            _tokenSymbol,
            _maxPublicMint,
            _publicMintPrice,
            _collectAddress
        );
        emit ContractDeployed(msg.sender, address(newNFT));
        return address(newNFT);
    }
}