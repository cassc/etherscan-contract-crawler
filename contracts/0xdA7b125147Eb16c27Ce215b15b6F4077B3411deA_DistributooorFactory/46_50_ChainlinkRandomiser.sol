// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8;

import {TypeAndVersion} from "../interfaces/TypeAndVersion.sol";
import {VRFV2WrapperConsumerBase} from "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";
import {VRFV2Wrapper} from "@chainlink/contracts/src/v0.8/VRFV2Wrapper.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRandomiserCallback} from "../interfaces/IRandomiserCallback.sol";

/// @title ChainlinkRandomiser
/// @notice Consume Chainlink's one-shot VRFv2 wrapper to return a random number (works like VRFv1)
contract ChainlinkRandomiser is
    Ownable,
    VRFV2WrapperConsumerBase,
    TypeAndVersion
{
    /// @notice Gas limit used by Chainlink during callback with randomness
    uint32 public callbackGasLimit;
    /// @notice LINK token address, used only for withdrawal
    address public linkTokenAddress;
    /// @notice VRF coordinator
    address public coordinator;
    /// @notice VRFv2 one-shot wrapper
    address public wrapperAddress;

    /// @notice Keep track of requestId -> which contract address to callback
    mapping(uint256 => address) private requestIdToCallbackMap;
    /// @notice Whitelist of contracts that can use this randomiser
    mapping(address => bool) public authorisedContracts;

    constructor(
        address wrapperAddress_,
        address coordinator_,
        address linkTokenAddress_
    )
        VRFV2WrapperConsumerBase(
            linkTokenAddress_ /** link address */,
            wrapperAddress_ /** wrapperAddress */
        )
    {
        wrapperAddress = wrapperAddress_;
        coordinator = coordinator_;
        linkTokenAddress = linkTokenAddress_;
        callbackGasLimit = 400_000;

        authorisedContracts[msg.sender] = true;
    }

    /// @notice See {TypeAndVersion-typeAndVersion}
    function typeAndVersion() external pure override returns (string memory) {
        return "ChainlinkRandomiser 1.0.0";
    }

    /// @notice So peeps can't randomly spam the contract and use up our precious LINK
    modifier onlyAuthorised() {
        require(authorisedContracts[msg.sender], "Not authorised");
        _;
    }

    /// @notice Authorise an address that can call this contract
    /// @param account address to authorise
    function authorise(address account) public onlyAuthorised {
        authorisedContracts[account] = true;
    }

    /// @notice Deauthorise an address so that it can no longer call this contract
    /// @param account address to deauthorise
    function deauthorise(address account) external onlyAuthorised {
        authorisedContracts[account] = false;
    }

    function setCallbackGasLimit(uint32 gasLimit) external onlyOwner {
        callbackGasLimit = gasLimit;
    }

    /// @notice Request randomness from VRF
    function getRandomNumber(
        address callbackContract
    ) public onlyAuthorised returns (uint256 requestId) {
        requestId = requestRandomness(callbackGasLimit, 3, 1);
        requestIdToCallbackMap[requestId] = callbackContract;
    }

    /// @notice Callback function used by VRF Coordinator
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomness
    ) internal override {
        address callbackContract = requestIdToCallbackMap[requestId];
        delete requestIdToCallbackMap[requestId];
        IRandomiserCallback(callbackContract).receiveRandomWords(
            requestId,
            randomness
        );
    }

    /// @notice Withdraw an ERC20 token from the contract.
    function withdraw(address tokenContract) public onlyOwner {
        IERC20 token = IERC20(tokenContract);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(msg.sender, balance));
    }

    /// @notice Helper function: withdraw LINK token.
    function withdrawLINK() external onlyOwner {
        withdraw(linkTokenAddress);
    }
}