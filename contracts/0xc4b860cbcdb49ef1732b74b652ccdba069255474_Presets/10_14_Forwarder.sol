// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {ERC721} from "lib/solmate/src/tokens/ERC721.sol";
import {ERC1155} from "lib/solmate/src/tokens/ERC1155.sol";

import {RuleChecker} from "./RuleChecker.sol";
import {IForwarder} from "./IForwarder.sol";

contract Forwarder is IForwarder {
    /// @notice Address of the rule
    address public immutable rule;

    constructor(address _rule) {
        require(_rule != address(0), "zero address");
        rule = _rule;
    }

    /// @notice Modifier to check if the caller is the rule,
    modifier onlyRule() {
        require(msg.sender == rule);
        _;
    }

    fallback() external payable {}

    receive() external payable {
        (address dest, uint256 value) = RuleChecker(rule).exec(address(this), address(this).balance, address(0));

        if (dest == address(0)) {
            return;
        }
        // zero address means that destionation can't be decided on-chain, so skip
        SafeTransferLib.safeTransferETH(dest, value);
    }

    /// @inheritdoc IForwarder
    function forward(address dest, uint256 value) public override onlyRule {
        if (dest == address(0)) {
            return;
        }
        SafeTransferLib.safeTransferETH(dest, value);
    }

    /// @inheritdoc IForwarder
    function forwardERC20(address tokenContractAddress, uint256 value, address dest)
        external
        virtual
        override
        onlyRule
    {
        if (dest == address(0)) {
            return;
        }
        SafeTransferLib.safeTransfer(ERC20(tokenContractAddress), dest, value);
    }

    /// @inheritdoc IForwarder
    function forwardERC721(address tokenContractAddress, uint256 id, address dest) external virtual override onlyRule {
        if (dest == address(0)) {
            return;
        }
        ERC721 instance = ERC721(tokenContractAddress);
        instance.safeTransferFrom(address(this), dest, id);
    }

    /// @inheritdoc IForwarder
    function forwardERC1155(address tokenContractAddress, uint256 id, uint256 value, address dest)
        external
        virtual
        override
        onlyRule
    {
        if (dest == address(0)) {
            return;
        }
        ERC1155 instance = ERC1155(tokenContractAddress);
        instance.safeTransferFrom(address(this), dest, id, value, "");
    }
}