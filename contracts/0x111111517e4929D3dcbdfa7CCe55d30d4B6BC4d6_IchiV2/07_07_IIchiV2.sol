// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/drafts/IERC20Permit.sol";

interface IIchiV2 is IERC20, IERC20Permit {

    // EIP-20 token name for this token
    function name() external view returns(string memory);

    // EIP-20 token symbol for this token
    function symbol() external view returns(string memory);

    // EIP-20 token decimals for this token
    function decimals() external view returns(uint8);

    // ICHI V1 address
    function ichiV1() external view returns(address);

    // Address which may mint inflationary tokens
    function minter() external view returns(address);

    // The timestamp after which inflationary minting may occur
    function mintingAllowedAfter() external view returns(uint256);

    // Minimum time between inflationary mints
    function minimumTimeBetweenMints() external view returns(uint32);

    // Cap on the percentage of totalSupply that can be minted at each inflationary mint
    function mintCap() external view returns(uint8);

    // ICHI V2 to ICHI V1 conversion fee (default is 0%)
    function conversionFee() external view returns(uint256);

    // A record of each accounts delegate
    function delegates(address) external view returns(address);

    // A record of votes checkpoints for each account, by index
    function checkpoints(address, uint32) external view returns(uint32, uint96);

    // The number of checkpoints for each account
    function numCheckpoints(address) external view returns(uint32);

    // The EIP-712 typehash for the contract's domain
    function DOMAIN_TYPEHASH() external view returns(bytes32);

    // The EIP-712 typehash for the delegation struct used by the contract
    function DELEGATION_TYPEHASH() external view returns(bytes32);

    // The EIP-712 typehash for the permit struct used by the contract
    function PERMIT_TYPEHASH() external view returns(bytes32);

    // An event thats emitted when the minter address is changed
    event MinterChanged(address minter, address newMinter);

    // An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    // An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    // An event thats emitted when ICHI V1 tokens are converted into ICHI V2 tokens
    event ConvertedToV2(address indexed from, uint256 amountIn, uint256 amountOut);

    // An event thats emitted when ICHI V2 tokens are converted into ICHI V1 tokens
    event ConvertedToV1(address indexed from, uint256 amountIn, uint256 amountOut);

    // An event thats emitted when the conversion fee is changed
    event ConversionFeeChanged(address minter, uint256 fee);

    /**
     * @notice Change the minter address
     * @param minter_ The address of the new minter
     */
    function setMinter(address minter_) external;

    /**
     * @notice Mint new tokens
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to be minted
     */
    function mint(address dst, uint256 rawAmount) external;

    /**
     * @notice Change the ICHI V2 to ICHI V1 conversion fee
     * @param fee_ New conversion fee
     */
    function setConversionFee(uint256 fee_) external;

    /**
     * @notice Convert ICHI V1 tokens to ICHI V2 tokens
     * @param rawAmount The number of ICHI V1 tokens to be converted (using 9 decimals representation)
     */
    function convertToV2(uint256 rawAmount) external;

    /**
     * @notice Convert ICHI V2 tokens back to ICHI V1 tokens
     * @param rawAmount The number of ICHI V2 tokens to be converted (using 18 decimals representation)
     */
    function convertToV1(uint256 rawAmount) external;

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external;

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96);

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);

}