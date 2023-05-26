//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./access/Ownable.sol";
import "./utils/ECDSA.sol";

contract ChainIdValidators is Ownable {
    using ECDSA for bytes32;

    uint256[] public chainIds;

    function addChainId(uint256 _chainId) external onlyOwner {
        (bool found,) = indexOfChainId(_chainId);
        require(!found, 'ChainId already added');
        chainIds.push(_chainId);
    }

    function removeChainId(uint256 _chainId) external onlyOwner {
        (bool found, uint256 index) = indexOfChainId(_chainId);
        require(found, 'ChainId not found');
        if (chainIds.length > 1) {
            chainIds[index] = chainIds[chainIds.length - 1];
        }
        chainIds.pop();
    }

    function getListChainIds() public view returns (uint256[] memory) {
        return chainIds;
    }

    function indexOfChainId(uint256 _chainId) public view returns (bool found, uint256 index) {
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (chainIds[i] == _chainId) {
                return (true, i);
            }
        }
        return (false, 0);
    }
}