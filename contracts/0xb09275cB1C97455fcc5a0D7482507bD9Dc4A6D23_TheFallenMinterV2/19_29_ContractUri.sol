// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IContractUri.sol";

/**
 * @title ContractUri
 * @notice NFT Collection with ContractUri
 */
abstract contract ContractUri is Ownable, IContractUri {
    string public contractURI;

    function setContractURI(string memory _uri) external onlyOwner {
        contractURI = _uri;
    }
}