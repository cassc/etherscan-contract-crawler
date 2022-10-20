// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SenseiStake} from "./SenseiStake.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ExtSenseiStake is IERC721Receiver, ReentrancyGuard {
    using Address for address;

    /// @notice SenseiStake contract definition for creating validator
    /// @return senseiStakeContract SenseiStake contract address
    SenseiStake public immutable senseiStakeContract;

    error InvalidAddress();
    error InvalidDepositAmount(uint256 value);
    error NotEnoughValidatorsAvailable(uint256 value);

    /// @notice Initializes the contract
    /// @dev Sets senseiStakeContract using address provided
    /// @param contract_ SenseiStake contract address
    constructor(address contract_) {
        if (contract_ == address(0)) {
            revert InvalidAddress();
        }
        senseiStakeContract = SenseiStake(contract_);
    }

    /// @notice Creates multiple validators based on eth amount sent
    /// @dev Since original contract enables single mint, this is a wrapper that mints and transfers to caller
    function createMultipleContracts() external payable nonReentrant {
        // check that ethers amount provided is multiple of 32
        if (msg.value == 0 || msg.value % 32 ether != 0) {
            revert InvalidDepositAmount(msg.value);
        }
        uint256 amount = msg.value / 32 ether;
        uint256 tokenId = senseiStakeContract.tokenIdCounter();
        // pre-check that we have enough validators loaded
        (bytes memory validatorPubKey, , ) = senseiStakeContract.validators(
            tokenId + amount
        );
        if (validatorPubKey.length == 0) {
            revert NotEnoughValidatorsAvailable(amount);
        }
        tokenId++; // tokenId that will be minted
        // mint token and transfer to user
        for (uint256 i = 0; i < amount; ) {
            // mint first
            senseiStakeContract.createContract{value: 32 ether}();
            // transfer to user
            senseiStakeContract.safeTransferFrom(
                address(this),
                msg.sender,
                tokenId + i
            );
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Required for enabling erc721 reception by the contract
    /// @return bytes4 Selector onERC721Received function
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}