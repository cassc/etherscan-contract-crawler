// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Zora Universal Minter
/// @notice Mints tokens on behalf of an account on any standard ER721 or ERC1155 contract, and collects fees for Zora and optionally a rewards for a finder
interface IZoraUniversalMinter {
    error MINT_EXECUTION_FAILED();
    error NOTHING_TO_WITHDRAW();
    error FORWARD_CALL_FAILED();
    error FAILED_TO_SEND();
    error INSUFFICIENT_VALUE(uint256 expectedValue, uint256 actualValue);

    event MintedBatch(
        address[] indexed targets,
        uint256[] values,
        uint256 tokensMinted,
        address finder,
        address indexed minter,
        uint256 indexed totalWithFees,
        uint256 zoraFee,
        uint256 finderFee
    );

    event Minted(
        address indexed target,
        uint256 value,
        uint256 tokensMinted,
        address finder,
        address indexed minter,
        uint256 indexed totalWithFees,
        uint256 zoraFee,
        uint256 finderFee
    );

    enum MintableTypes {
        NONE,
        ERC721,
        ERC1155,
        ERC1155_BATCH
    }

    /// Executes mint calls on a series of target ERC721 or ERC1155 contracts, then transfers the minted tokens to the calling account.
    /// Adds a mint fee to the msg.value sent to the contract.
    /// Assumes that the mint function for each target follows the ERC721 or ERC1155 standard for minting - which is that
    /// the a safe transfer is used to transfer tokens - and the corresponding safeTransfer callbacks on the receiving account are called AFTER minting the tokens.
    /// The value sent must include all the values to send to the minting contracts and the fees + reward amount.
    /// This can be determined by calling `fee`, and getting the requiredToSend parameter.
    /// @param _targets Addresses of contracts to call
    /// @param _calldatas Data to pass to the mint functions for each target
    /// @param _values Value to send to each target - must match the value required by the target's mint function.
    /// @param _tokensMinted Total number of tokens minted across all targets, used to calculate fees
    /// @param _finder Optional - address of finder that will receive a portion of the fees
    function mintBatch(
        address[] calldata _targets,
        bytes[] calldata _calldatas,
        uint256[] calldata _values,
        uint256 _tokensMinted,
        address _finder
    ) external payable;

    /// @notice Executes mint calls on a series of target ERC721 or ERC1155 contracts, then transfers the minted tokens to the calling account.
    /// Does not add a mint feee
    /// Assumes that the mint function for each target follows the ERC721 or ERC1155 standard for minting - which is that
    /// the a safe transfer is used to transfer tokens - and the corresponding safeTransfer callbacks on the receiving account are called AFTER minting the tokens.
    /// The value sent must equal the total values to send to the minting contracts.
    /// @param _targets Addresses of contracts to call
    /// @param _calldatas Data to pass to the mint functions for each target
    /// @param _values Value to send to each target - must match the value required by the target's mint function.
    function mintBatchWithoutFees(address[] calldata _targets, bytes[] calldata _calldatas, uint256[] calldata _values) external payable;

    /// Execute a mint call on a series a target ERC721 or ERC1155 contracts, then transfers the minted tokens to the calling account.
    /// Adds a mint fee to the msg.value sent to the contract.
    /// Assumes that the mint function for each target follows the ERC721 or ERC1155 standard for minting - which is that
    /// the a safe transfer is used to transfer tokens - and the corresponding safeTransfer callbacks on the receiving account are called AFTER minting the tokens.
    /// The value sent must include the value to send to the minting contract and the universal minter fee + finder reward amount.
    /// This can be determined by calling `fee`, and getting the requiredToSend parameter.
    /// @param _target Addresses of contract to call
    /// @param _calldata Data to pass to the mint function for the target
    /// @param _value Value to send to the target - must match the value required by the target's mint function.
    /// @param _tokensMinted Total number of tokens minted across all targets, used to calculate fees
    /// @param _finder Optional - address of finder that will receive a portion of the fees
    function mint(address _target, bytes calldata _calldata, uint256 _value, uint256 _tokensMinted, address _finder) external payable;

    /// Has a minter agent execute a transaction on behalf of the calling acccount.  The minter
    /// agent's address will be the same for the calling account as the address that was
    /// used to mint the tokens.  Can be used to recover tokens that may get accidentally locked in
    /// the minter agent's contract address.
    /// @param _target Address of contract to call
    /// @param _calldata Calldata for arguments to call.
    function forwardCallFromAgent(address _target, bytes calldata _calldata, uint256 _additionalValue) external payable;

    /// Withdraws any fees or rewards that have been allocated to the caller's address.  Fees can be withdrawn to any other specified address.
    /// @param to The address to withdraw to
    function withdraw(address to) external;

    /// Calculates the fees that will be collected for a given mint, based on the value and tokens minted.
    /// @param _mintValue Total value of the mint that is to be sent to external minting contracts
    /// @param _tokensMinted Quantity of tokens minted
    /// @param _finderAddress Address of the finder, if any.  If the finder is the zora fee recipient, then the finder fee is 0.
    /// @return zoraFee The fee that will be sent to the zora fee recipient
    /// @return finderReward The fee that will be sent to the finder
    /// @return requiredToSend The total value that must be sent to the contract, including fees
    function fee(
        uint256 _mintValue,
        uint256 _tokensMinted,
        address _finderAddress
    ) external view returns (uint256 zoraFee, uint256 finderReward, uint256 requiredToSend);

    /// Gets the deterministic address of the MinterAgent clone that gets created for a given recipient.
    /// @param recipient The account that the agent is cloned on behalf of.
    function agentAddress(address recipient) external view returns (address);
}