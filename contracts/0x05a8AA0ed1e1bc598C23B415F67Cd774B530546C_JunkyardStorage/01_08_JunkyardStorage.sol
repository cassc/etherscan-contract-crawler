// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {AxelarExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executables/AxelarExecutable.sol";

/**
 * @title JunkyardStorage
 * @author Razmo
 * @notice Deployed on Ethereum, this contract receives and sends the NFTs
 * @dev The transfer function is called by the Manager from Polygon through Axelar
 */
contract JunkyardStorage is AxelarExecutable, Ownable {
    string public managerChain;
    string public managerAddress;

    event TokenSent(address indexed, address, uint256); // To, collection, tokenId
    event ContractValueUpdate(string, string); // Value name, new value

    modifier isFromManager(
        string calldata _sourceChain,
        string calldata _sourceAddress
    ) {
        bytes32 source = keccak256(abi.encodePacked(_sourceChain, _sourceAddress));
        bytes32 manager = keccak256(abi.encodePacked(managerChain, managerAddress));

        require(source == manager, "Not allowed to call this contract");
        _;
    }

    constructor(address _gateway) AxelarExecutable(_gateway) {}

    /**
     * @notice Update the name of the chain of the Manager
     * @param newManagerChain New chain
     */
    function setManagerChain(string memory newManagerChain) external onlyOwner {
        managerChain = newManagerChain;

        emit ContractValueUpdate('managerChain', newManagerChain);
    }

    /**
     * @notice Update the address of the Manager
     * @param newManagerAddress New address
     */
    function setManagerAddress(string memory newManagerAddress) external onlyOwner {
        managerAddress = newManagerAddress;

        emit ContractValueUpdate('managerAddress', newManagerAddress);
    }

    /**
     * @notice Send an NFT to a Player
     * @dev Called by the Manager from Polygon after a verification
     * @param _sourceChain Chain name of the source transaction
     * @param _sourceAddress Address of the contract who calls this function
     * @param _payload Payload of token (uid, from, collection, tokenId, transferTx)
     */
    function _execute(
        string calldata _sourceChain,
        string calldata _sourceAddress,
        bytes calldata _payload
    ) internal override isFromManager(_sourceChain, _sourceAddress) {
        (address to, uint256 tokenId, address collection) = abi.decode(
            _payload,
            (address, uint256, address)
        );

        IERC721(collection).safeTransferFrom(address(this), to, tokenId);

        emit TokenSent(to, collection, tokenId);
    }
}