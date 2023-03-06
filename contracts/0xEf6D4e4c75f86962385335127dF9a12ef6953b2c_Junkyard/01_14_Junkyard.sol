// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import {AxelarExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executables/AxelarExecutable.sol";
import {IAxelarGateway} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import {StringToAddress, AddressToString} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/StringAddressUtils.sol";

/**
 * @title Junkyard
 * @author Razmo
 * @notice Deployed on Ethereum, this contract manages the fishing and claim attempts
 * @dev Ethereum and Polygon contracts are communicating through Axelar and the Junkbot
 */
contract Junkyard is Ownable, PaymentSplitter, Pausable, AxelarExecutable {
    using StringToAddress for string;
    using AddressToString for address;

    IAxelarGasService public immutable GAS_RECEIVER;

    string public managerAddress;
    string public managerChain;
    string public storageAddress;
    string public storageChain;
    uint256 internal fishingNonce = 0;

    uint8 private constant CLAIM_ACTION = 1;
    uint8 private constant VALIDATE_ACTION = 2;

    // List fishing quantity and price
    mapping(uint256 => uint256) public prices;

    event NewFishingEntry(address indexed, uint256, bytes32); // who, quantity, uid
    event PricesChange(uint256, uint256); // quantity, new price
    event NewClaim(uint256 indexed, address, uint256); // requestId, sender, tokenUID
    event ContractValueUpdate(string, string); // value name, new value

    constructor(
        address[] memory jkdPayees,
        uint256[] memory jkdShares,
        address _gateway,
        address _gasReceiver
    ) PaymentSplitter(jkdPayees, jkdShares) AxelarExecutable(_gateway) {
        if (_gasReceiver == address(0)) revert InvalidAddress();

        prices[1] = 0.01 ether;
        prices[3] = 0.02 ether;
        prices[7] = 0.04 ether;
        prices[15] = 0.06 ether;
        prices[40] = 0.12 ether;
        prices[60] = 0.15 ether;

        GAS_RECEIVER = IAxelarGasService(_gasReceiver);
    }

    /**
     * @notice Fishing attempt to win a valuable NFT, the player needs to pay an entry fee
     * @dev Emit an event intercepted by the Junkbot and call the Manager from Polygon through Axelar
     * @param _qt Quantity of NFTs selected by the player to be fished in the Junkyard
     */
    function fishing(uint256 _qt) external payable whenNotPaused {
        require(prices[_qt] != 0, "Quantity not available");
        require(msg.value == prices[_qt], "Entry fee is incorrect");

        bytes32 uid = getUID();

        bytes memory actionPayload = abi.encode(uid, msg.sender, _qt);
        bytes memory payload = abi.encode(VALIDATE_ACTION, actionPayload);

        GAS_RECEIVER.payNativeGasForContractCall{value: msg.value}(
            address(this),
            "Polygon",
            managerAddress,
            payload,
            address(this)
        );
        gateway.callContract("Polygon", managerAddress, payload);

        emit NewFishingEntry(msg.sender, _qt, uid);
    }

    /**
     * @notice Claim an NFT won by a player after a fishing attempt
     * @dev Call the Manager through Axelar for on-chain verification
     * @param requestId RequestId of the fishing attempt from which the player wants to claim the NFT
     * @param tokenUID Claimed NFT UID
     * @param tokenId Collection ID of the NFT
     * @param collection Collection address
     * @param gasForCallClaim Amount of gas to call the manager
     * @param gasForCallTransfer Amount of gas for the manager to call the storage
     */
    function claim(
        uint256 requestId,
        uint256 tokenUID,
        uint256 tokenId,
        address collection,
        uint256 gasForCallClaim,
        uint256 gasForCallTransfer
    ) external payable {
        require(gasForCallClaim > 0 && gasForCallTransfer > 0, "No gas amount defined");
        require(gasForCallClaim + gasForCallTransfer <= msg.value, "Not enough value for gas");

        bytes memory actionPayload = abi.encode(
            requestId,
            tokenUID,
            msg.sender
        );
        bytes memory payload = abi.encode(CLAIM_ACTION, actionPayload);
        bytes memory responsePayload = abi.encode(
            msg.sender,
            tokenId,
            collection
        );

        // Player pays for Polygon transaction on Axelar
        GAS_RECEIVER.payNativeGasForContractCall{value: gasForCallClaim}(
            address(this),
            managerChain,
            managerAddress,
            payload,
            msg.sender
        );

        // Player pays for Ethereum transaction on Axelar
        GAS_RECEIVER.payNativeGasForContractCall{
            value: gasForCallTransfer
        }(
            managerAddress.toAddress(),
            storageChain,
            storageAddress,
            responsePayload,
            msg.sender
        );

        gateway.callContract(managerChain, managerAddress, payload);

        emit NewClaim(requestId, msg.sender, tokenUID);
    }

    /**
     * @notice Change the fishing price
     * @param _qt Fishing quantity
     * @param _newPrice New price
     */
    function setPrice(uint256 _qt, uint256 _newPrice) external onlyOwner {
        prices[_qt] = _newPrice;

        emit PricesChange(_qt, _newPrice);
    }

    /**
     * @notice Update the address of the Manager
     * @param newManagerAddr New address
     */
    function setManagerAddress(string memory newManagerAddr)
        external
        onlyOwner
    {
        managerAddress = newManagerAddr;

        emit ContractValueUpdate('managerAddress', newManagerAddr);
    }

    /**
     * @notice Update the name of the chain of the Manager
     * @param newManagerChain New chain
     */
    function setManagerChain(string memory newManagerChain) external onlyOwner {
        managerChain = newManagerChain;

        emit ContractValueUpdate('managerChain', newManagerChain);
    }

    /**
     * @notice Update the address of the Storage
     * @param newStorageAddr New address
     */
    function setStorageAddress(string memory newStorageAddr)
        external
        onlyOwner
    {
        storageAddress = newStorageAddr;

        emit ContractValueUpdate('storageAddress', newStorageAddr);
    }

    /**
     * @notice Update the name of the chain of the Storage
     * @param newStorageChain New chain
     */
    function setStorageChain(string memory newStorageChain) external onlyOwner {
        storageChain = newStorageChain;

        emit ContractValueUpdate('storageChain', newStorageChain);
    }

    /// @notice Pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Generate an UID for each fishing entry
     */
    function getUID() private returns (bytes32) {
        bytes32 uid = (
            keccak256(
                abi.encodePacked(fishingNonce, block.number - 1, msg.sender)
            )
        );
        fishingNonce++;

        return uid;
    }
}