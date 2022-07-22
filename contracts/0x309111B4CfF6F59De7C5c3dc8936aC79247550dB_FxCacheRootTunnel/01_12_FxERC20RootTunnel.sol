// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {ERC20} from "../../lib/ERC20.sol";
import {FxBaseRootTunnel} from "../../tunnel/FxBaseRootTunnel.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title FxERC20RootTunnel
 */
contract FxCacheRootTunnel is FxBaseRootTunnel {
    using SafeERC20 for IERC20;
    // maybe DEPOSIT and MAP_TOKEN can be reduced to bytes4
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
    bytes32 public constant MAP_TOKEN = keccak256("MAP_TOKEN");

    mapping(address => address) public rootToChildTokens;

    event TokenMappedERC20(address indexed rootToken, address indexed childToken);
    event FxWithdrawERC20(
        address indexed rootToken,
        address indexed childToken,
        address indexed userAddress,
        uint256 amount
    );
    event FxDepositERC20(
        address indexed rootToken,
        address indexed depositor,
        address indexed userAddress,
        uint256 amount
    );

    constructor(
        address _checkpointManager,
        address _fxRoot
    ) FxBaseRootTunnel(_checkpointManager, _fxRoot) {
    }

    /**
     * @notice Map a token to enable its movement via the Polygon PoS network
     * @param rootToken address of token on root chain
     */
    function mapToken(address rootToken, address _childToken) public {
        // check if token is already mapped
        require(rootToChildTokens[rootToken] == address(0x0), "FxERC20RootTunnel: ALREADY_MAPPED");

        // MAP_TOKEN, encode(rootToken, _childToken)
        bytes memory message = abi.encode(MAP_TOKEN, abi.encode(rootToken, _childToken));
        _sendMessageToChild(message);

        // add into mapped tokens
        rootToChildTokens[rootToken] = _childToken;
        emit TokenMappedERC20(rootToken, _childToken);
    }

    function deposit(
        address rootToken,
        address childToken,
        address user,
        uint256 amount,
        bytes memory data
    ) public {
        // map token if not mapped
        if (rootToChildTokens[rootToken] == address(0x0)) {
            mapToken(rootToken, childToken);
        }

        // transfer from depositor to this contract
        IERC20(rootToken).safeTransferFrom(
            msg.sender, // depositor
            address(this), // manager contract
            amount
        );

        // DEPOSIT, encode(rootToken, depositor, user, amount, extra data)
        bytes memory message = abi.encode(DEPOSIT, abi.encode(rootToken, msg.sender, user, amount, data));
        _sendMessageToChild(message);
        emit FxDepositERC20(rootToken, msg.sender, user, amount);
    }

    // exit processor
    function _processMessageFromChild(bytes memory data) internal override {
        (address rootToken, address childToken, address to, uint256 amount) = abi.decode(
            data,
            (address, address, address, uint256)
        );
        // validate mapping for root to child
        require(rootToChildTokens[rootToken] == childToken, "FxERC20RootTunnel: INVALID_MAPPING_ON_EXIT");

        // transfer from tokens to
        IERC20(rootToken).safeTransfer(to, amount);
        emit FxWithdrawERC20(rootToken, childToken, to, amount);
    }
}