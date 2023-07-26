pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAdapter, IBridge, ISpender} from "contracts/interfaces/Exports.sol";
import {Constants} from "contracts/utils/Exports.sol";
import "./Spender.sol";

contract MetaBridge is IBridge, Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;

    ISpender public immutable spender;

    // Mapping of adapterId to adapter
    mapping(string => address) public adapters;
    mapping(string => bool) public adapterRemoved;

    constructor() {
        spender = new Spender();
    }

    /**
     * @notice Sets the adapter for an aggregator. It can't be changed later.
     * @param adapterId Aggregator's identifier
     * @param adapterAddress Address of the contract that contains the logic for this aggregator
     */
    function setAdapter(string calldata adapterId, address adapterAddress)
        external
        override
        onlyOwner
    {
        require(adapterAddress.isContract(), "ADAPTER_IS_NOT_A_CONTRACT");
        require(!adapterRemoved[adapterId], "ADAPTER_REMOVED");
        require(adapters[adapterId] == address(0), "ADAPTER_EXISTS");
        require(bytes(adapterId).length > 0, "INVALID_ADAPTED_ID");

        adapters[adapterId] = adapterAddress;
        emit AdapterSet(adapterId, adapterAddress);
    }

    /**
     * @notice Removes the adapter for an existing aggregator. This can't be undone.
     * @param adapterId Adapter's identifier
     */
    function removeAdapter(string calldata adapterId)
        external
        override
        onlyOwner
    {
        require(adapters[adapterId] != address(0), "ADAPTER_DOES_NOT_EXIST");
        delete adapters[adapterId];
        adapterRemoved[adapterId] = true;
        emit AdapterRemoved(adapterId);
    }

    /**
     * @notice Performs a bridge
     * @param adapterId Identifier of the aggregator to be used for the bridge
     * @param srcToken Identifier of the source chain
     * @param amount Amount of tokens to be transferred from the destination chain
     * @param data Dynamic data which is passed in to the delegatecall made to the adapter
     */
    function bridge(
        string calldata adapterId,
        address srcToken,
        uint256 amount,
        bytes calldata data
    ) external payable override whenNotPaused nonReentrant {
        address adapter = adapters[adapterId];
        require(adapter != address(0), "ADAPTER_NOT_FOUND");

        // Move ERC20 funds to the spender
        if (srcToken != Constants.NATIVE_TOKEN) {
            require(msg.value == 0, "NATIVE_ASSET_SENT");
            IERC20(srcToken).safeTransferFrom(
                msg.sender,
                address(spender),
                amount
            );
        } else {
            require(msg.value == amount, "MSGVALUE_AMOUNT_MISMATCH");
        }

        spender.bridge{value: msg.value}(
            adapter,
            abi.encodePacked(
                // bridge signature
                IAdapter.bridge.selector,
                abi.encode(msg.sender),
                data
            )
        );
    }

    /**
     * @notice Prevents the bridge function from being executed until the contract is unpaused.
     */
    function pauseBridge() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract to make the bridge function callable by owner.
     */
    function unpauseBridge() external onlyOwner {
        _unpause();
    }
}