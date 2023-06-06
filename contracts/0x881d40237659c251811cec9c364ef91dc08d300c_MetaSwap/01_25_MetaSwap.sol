// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./ICHI.sol";
import "./Spender.sol";

/**
 * @title MetaSwap
 */
contract MetaSwap is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;

    struct Adapter {
        address addr; // adapter's address
        bytes4 selector;
        bytes data; // adapter's fixed data
    }

    ICHI public immutable chi;
    Spender public immutable spender;

    // Mapping of aggregatorId to aggregator
    mapping(string => Adapter) public adapters;
    mapping(string => bool) public adapterRemoved;

    event AdapterSet(
        string indexed aggregatorId,
        address indexed addr,
        bytes4 selector,
        bytes data
    );
    event AdapterRemoved(string indexed aggregatorId);
    event Swap(string indexed aggregatorId, address indexed sender);

    constructor(ICHI _chi) public {
        chi = _chi;
        spender = new Spender();
    }

    /**
     * @dev Sets the adapter for an aggregator. It can't be changed later.
     * @param aggregatorId Aggregator's identifier
     * @param addr Address of the contract that contains the logic for this aggregator
     * @param selector The function selector of the swap function in the adapter
     * @param data Fixed abi encoded data the will be passed in each delegatecall made to the adapter
     */
    function setAdapter(
        string calldata aggregatorId,
        address addr,
        bytes4 selector,
        bytes calldata data
    ) external onlyOwner {
        require(addr.isContract(), "ADAPTER_IS_NOT_A_CONTRACT");
        require(!adapterRemoved[aggregatorId], "ADAPTER_REMOVED");

        Adapter storage adapter = adapters[aggregatorId];
        require(adapter.addr == address(0), "ADAPTER_EXISTS");

        adapter.addr = addr;
        adapter.selector = selector;
        adapter.data = data;
        emit AdapterSet(aggregatorId, addr, selector, data);
    }

    /**
     * @dev Removes the adapter for an existing aggregator. This can't be undone.
     * @param aggregatorId Aggregator's identifier
     */
    function removeAdapter(string calldata aggregatorId) external onlyOwner {
        require(
            adapters[aggregatorId].addr != address(0),
            "ADAPTER_DOES_NOT_EXIST"
        );
        delete adapters[aggregatorId];
        adapterRemoved[aggregatorId] = true;
        emit AdapterRemoved(aggregatorId);
    }

    /**
     * @dev Performs a swap
     * @param aggregatorId Identifier of the aggregator to be used for the swap
     * @param data Dynamic data which is concatenated with the fixed aggregator's
     * data in the delecatecall made to the adapter
     */
    function swap(
        string calldata aggregatorId,
        IERC20 tokenFrom,
        uint256 amount,
        bytes calldata data
    ) external payable whenNotPaused nonReentrant {
        _swap(aggregatorId, tokenFrom, amount, data);
    }

    /**
     * @dev Performs a swap
     * @param aggregatorId Identifier of the aggregator to be used for the swap
     * @param data Dynamic data which is concatenated with the fixed aggregator's
     * data in the delecatecall made to the adapter
     */
    function swapUsingGasToken(
        string calldata aggregatorId,
        IERC20 tokenFrom,
        uint256 amount,
        bytes calldata data
    ) external payable whenNotPaused nonReentrant {
        uint256 gas = gasleft();

        _swap(aggregatorId, tokenFrom, amount, data);

        uint256 gasSpent = 21000 + gas - gasleft() + 16 * msg.data.length;
        chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41947);
    }

    function pauseSwaps() external onlyOwner {
        _pause();
    }

    function unpauseSwaps() external onlyOwner {
        _unpause();
    }

    function _swap(
        string calldata aggregatorId,
        IERC20 tokenFrom,
        uint256 amount,
        bytes calldata data
    ) internal {
        Adapter storage adapter = adapters[aggregatorId];

        if (address(tokenFrom) != Constants.ETH) {
            tokenFrom.safeTransferFrom(msg.sender, address(spender), amount);
        }

        spender.swap{value: msg.value}(
            adapter.addr,
            abi.encodePacked(
                adapter.selector,
                abi.encode(msg.sender),
                adapter.data,
                data
            )
        );

        emit Swap(aggregatorId, msg.sender);
    }
}