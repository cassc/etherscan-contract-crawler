// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 *  @dev whitelist/publicsale state engine
 */
abstract contract ERC721WhitelistEssentials is Ownable, ERC721Metadata {
    using ECDSA for bytes32;

    enum ContractState {
        init,
        whitelist,
        publicsale,
        saleended,
        locked
    }

    ContractState public state;

    event ContractStateChanged(ContractState originalState, ContractState newState);

    /// @dev locks the metadata elements down. final state of the contract
    function lockMetadata() external onlyOwner {
        require(state == ContractState.saleended, "SALE_NOT_ENDED");
        state = ContractState.locked;
        emit ContractStateChanged(ContractState.saleended, state);
    }

    /**
     * @dev lets only do this if we haven't closed down the contract.
     */
    modifier notLocked() {
        require(state != ContractState.locked, "Contract metadata methods are locked");
        _;
    }

    /**
     * @dev allow you to set new baseUri
     */
    function setBaseUri(string memory _newBaseUri) public onlyOwner notLocked {
        _setBaseUri(_newBaseUri);
    }

    /**
     * @dev allow you to set new contractUri
     */
    function setContractURI(string memory _contractUri) public onlyOwner notLocked {
        _setContractURI(_contractUri);
    }

    /// @dev set the provenance hash for the nft collection
    function setProvenanceHash(string calldata hash) external onlyOwner notLocked {
        _setProvenanceHash(hash);
    }

    /**
     * @dev hash our message elements and return the hashed message.
     */
    function _hashTransaction(address sender, uint256 qty, string memory nonce) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(sender, qty, nonce)).toEthSignedMessageHash();
    }
}