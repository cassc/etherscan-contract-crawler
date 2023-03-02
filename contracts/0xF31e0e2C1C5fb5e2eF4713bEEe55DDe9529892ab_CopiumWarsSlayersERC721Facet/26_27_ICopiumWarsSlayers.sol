// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;
import { IERC721AUpgradeable } from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import { IERC173 } from "@solidstate/contracts/interfaces/IERC173.sol";

interface ICopiumWarsSlayers is IERC721AUpgradeable, IERC173 {
    error MaxTotalSupplyBreached();
    error Unauthorized(address);
    error WrongBank();
    error TransferLocked(address account, uint256 transferAmount, uint256 lockedAmount);

    error ApprovalLocked(address account, uint256 lockedAmount);
    error WrongUnlockPayment(uint256 requiredPayment, uint256 actualPayment);
    error WrongUnlockQuantity(uint256 requestedQuantity);

    event MintTokenUsed(uint256 mintTokenId, address user, uint256 amount);
    event BalanceUnlocked(address account, uint256 amount);

    /**
     * @notice Set the base URI for this token's metadata
     * @param baseURI Base URI to be set
     */
    function setBaseURI(string calldata baseURI) external;

    /**
     * @notice Sets the only signer which can sign mint requests for this token
     * @dev This method should be accessible only by the owner
     * @param theExecutor The only signer approved for this contract
     */
    function setTheExecutor(address theExecutor) external;

    /**
     * @notice Allows minting token with the admin accoung
     * @dev This method should be accessible only by the owner
     * @param recipient Address of the recipient for the minted token(s)
     * @param amount Amount of token(s) to mint
     */
    function adminMint(address recipient, uint256 amount) external;

    /**
     * @notice Sets the bank where proceeds will be stored
     * @dev This method should be accessible only by the owner
     * @param copiumBank The bank where proceeds will be stored
     */
    function setCopiumBank(address payable copiumBank) external;

    /**
     * @notice It withdaws funds from the contract
     */
    function withdrawFunds() external;

    /**
     * @notice It pauses the contract
     */
    function pause() external;

    /**
     * @notice It unpauses the contract
     */
    function unpause() external;

    /**
     * @notice It enables transfer for the provided amount of tokens held
     * @param account Owner of the tokens
     * @param amount Amount to be unlocked
     */
    function unlockBalance(address account, uint256 amount) external payable;

    /**
     * @notice Allows minting a token(s) by using a token signature
     * @dev Signature should follow the EIP-712 schema
     * @param mintTokenId Id of the mint token
     * @param recipient Address of the recipient for the minted token(s)
     * @param amount Amount of token(s) to mint
     * @param signature EIP-712 signature
     */
    function mintWithToken(uint256 mintTokenId, address recipient, uint256 amount, bytes calldata signature) external;

    /**
     * @notice Returns the only signer which can sign mint requests for this token
     * @return The only signer approved for this contract
     */
    function theExecutor() external view returns (address);

    /**
     * @notice Returns the bank where proceeds will be stored
     * @return The bank where proceeds will be stored
     */
    function copiumBank() external view returns (address);

    /**
     * @notice Returns the time when this slayer was born
     * @param tokenId Id of the slayer
     * @return Block timestamp rounded to the hour
     */
    function birthTime(uint256 tokenId) external view returns (uint);

    /**
     * @notice Returns the current price for unlocking a single token
     */
    function unlockPrice() external view returns (uint256 price);

    /**
     * @notice Returns the current locked balance for the account
     */
    function lockedBalance(address account) external view returns (uint256 price);

    /**
     * @notice Returns true if the mint token id was used
     */
    function isMintTokenUsed(uint256 mintTokenId) external view returns (bool);
}