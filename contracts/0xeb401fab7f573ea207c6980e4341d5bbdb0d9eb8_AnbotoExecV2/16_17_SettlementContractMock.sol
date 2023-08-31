// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

struct InteractionData {
    address target;
    uint256 value;
    bytes callData;
}

struct TradeData {
    uint256 sellTokenIndex;
    uint256 buyTokenIndex;
    address receiver;
    uint256 sellAmount;
    uint256 buyAmount;
}

contract SettlementContractMock {
    using SafeERC20 for IERC20;

    mapping(address => bool) public isSolver;

    constructor(address[] memory _solvers) {
        for (uint256 i = 0; i < _solvers.length; i++) {
            isSolver[_solvers[i]] = true;
        }
    }

    function settle(
        IERC20[] calldata _tokens,
        TradeData[] calldata _trades,
        InteractionData[] calldata _interactions
    ) external onlySolver {
        // get tokens in
        for (uint256 i = 0; i < _trades.length; i++) {
            TradeData memory trade = _trades[i];

            _tokens[trade.sellTokenIndex].safeTransferFrom(
                trade.receiver,
                address(this),
                trade.sellAmount
            );
        }

        // execute interactions
        for (uint256 i = 0; i < _interactions.length; i++) {
            InteractionData memory interaction = _interactions[i];

            (bool success, bytes memory data) = interaction.target.call{
                value: interaction.value
            }(interaction.callData);
            if (!success) revert("Interaction reverted");
        }

        // send tokens out
        for (uint256 i = 0; i < _trades.length; i++) {
            TradeData memory trade = _trades[i];

            _tokens[trade.buyTokenIndex].safeTransfer(trade.receiver, trade.buyAmount);
        }
    }

    function settleSimple(InteractionData[] calldata _interactions) external onlySolver {
        // execute interactions
        for (uint256 i = 0; i < _interactions.length; i++) {
            InteractionData memory interaction = _interactions[i];

            (bool success, bytes memory data) = interaction.target.call{
                value: interaction.value
            }(interaction.callData);
            if (!success) revert(_getRevertMsg(data));
        }
    }

    function setSolver(address _solver, bool _set) external {
        isSolver[_solver] = _set;
    }

    /**
     * @notice This function decodes transaction error message
     * @param _returnData encoded error message
     * @return Decoded revert message
     */
    function _getRevertMsg(bytes memory _returnData)
        private
        pure
        returns (string memory)
    {
        // if the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Interaction reverted.";
        assembly {
            // slice the sig hash
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // all that remains is the revert string
    }

    /* ========== RESTRICTION FUNCTIONS ========== */

    function _onlySolver() private view {
        require(isSolver[msg.sender], "Only solvers.");
    }

    /* ========== MODIFIERS ========== */

    modifier onlySolver() {
        _onlySolver();
        _;
    }
}