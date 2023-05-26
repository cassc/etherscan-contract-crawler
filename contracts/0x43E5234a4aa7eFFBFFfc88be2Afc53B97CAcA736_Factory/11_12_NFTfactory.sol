// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "./NFTcontract.sol";

contract Factory {
    address public immutable implementation;
    event ContractDeployed(address owner, address clone);

    constructor() {
        implementation = address(new NFTcontract());
    }

    function genesis(
        address _collectAddress,
        address _deployer,
        string calldata _tokenName,
        string calldata _tokenSymbol,
        uint96 _royalty
    ) external returns (address) {
        address payable clone = payable(
            ClonesUpgradeable.clone(implementation)
        );
        NFTcontract mNFT = NFTcontract(clone);
        mNFT.initialize(
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