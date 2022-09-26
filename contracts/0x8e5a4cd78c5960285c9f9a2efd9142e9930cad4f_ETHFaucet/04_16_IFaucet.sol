// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IFaucet is IERC721Upgradeable {
    struct FaucetDetails {
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 faucetStart;
        uint256 faucetExpiry;
        address faucetStrategy;
        address supplier;
        bool canBeRescinded;
    }

    /// @notice Cannot have more claimable than total faucet amount
    /// @param totalClaimableAmount Total amount that can be claimed
    /// @param totalAmount Total amount that is in the faucet
    error ClaimableOverflow(uint256 totalClaimableAmount, uint256 totalAmount);

    /// @notice Cannot mint with ETH value from ERC20 Faucet
    /// @param value msg.value
    error UnexpectedMsgValue(uint256 value);

    /// @notice msg.value and _amt must match
    /// @param value The provided msg.value
    /// @param amt The provided amot
    error MintValueMismatch(uint256 value, uint256 amt);

    /// @notice Cannot mint a faucet with no value
    error MintNoValue();

    /// @notice Cannot mint a faucet with no duration
    error MintNoDuration();

    /// @notice Provided strategy must support IFaucetStrategy interface
    /// @param strategy provided invalid strategy
    error MintInvalidStrategy(address strategy);

    /// @notice Only owner of token
    /// @param caller method caller
    /// @param owner current owner
    error OnlyOwner(address caller, address owner);

    /// @notice Only supplier of token
    /// @param caller method caller
    /// @param supplier current supplier
    error OnlySupplier(address caller, address supplier);

    /// @notice Faucet is not rescindable
    error RescindUnrescindable();

    /// @notice Faucet does not exist
    error FaucetDoesNotExist();

    /// @notice Create a new Faucet
    /// @param _to The address that can claim funds from the faucet
    /// @param _amt The total amount of tokens claimable in this faucet
    /// @param _faucetDuration The duration over which the faucet will vest
    /// @param _faucetStrategy The strategy to use for the faucet
    /// @param _canBeRescinded Whether or not the faucet can be canceled by the supplier
    /// @return The newly created faucet's token ID
    function mint(
        address _to,
        uint256 _amt,
        uint256 _faucetDuration,
        address _faucetStrategy,
        bool _canBeRescinded
    ) external payable returns (uint256);

    /// @notice Claim any available funds for a faucet
    /// @param _to Where to send the funds
    /// @param _tokenID Which faucet is being claimed
    function claim(address _to, uint256 _tokenID) external;

    /// @notice Rescind a faucet, sweeping any unclaimed funds and discarding the faucet information
    /// @param _remainingTokenDest The destination for any unclaimed funds
    /// @param _tokenID The faucet token ID
    function rescind(address _remainingTokenDest, uint256 _tokenID) external;

    /// @notice Get the total claimable amount of tokens for a given faucet at a given timestamp
    /// @param _tokenID The token ID of the faucet
    /// @param _timestamp The timestamp of the faucet
    /// @return The total claimable amount
    function claimableAmountForFaucet(uint256 _tokenID, uint256 _timestamp) external view returns (uint256);

    /// @param _tokenID The token ID for the faucet
    function getFaucetDetailsForToken(uint256 _tokenID) external view returns (FaucetDetails memory);

    /// @notice The underlying token address for this faucet
    function faucetTokenAddress() external view returns (address);
}