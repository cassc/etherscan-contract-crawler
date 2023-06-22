// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "../def/Shareholder.sol";

//  .----------------.  .----------------.  .----------------.  .----------------.
// | .--------------. || .--------------. || .--------------. || .--------------. |
// | |     ____     | || | ____    ____ | || | ____    ____ | || |    ______    | |
// | |   .'    `.   | || ||_   \  /   _|| || ||_   \  /   _|| || |  .' ___  |   | |
// | |  /  .--.  \  | || |  |   \/   |  | || |  |   \/   |  | || | / .'   \_|   | |
// | |  | |    | |  | || |  | |\  /| |  | || |  | |\  /| |  | || | | |    ____  | |
// | |  \  `--'  /  | || | _| |_\/_| |_ | || | _| |_\/_| |_ | || | \ `.___]  _| | |
// | |   `.____.'   | || ||_____||_____|| || ||_____||_____|| || |  `._____.'   | |
// | |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'

/// @title IOmmgWithdrawable
/// @author NotAMeme aka nxlogixnick
/// @notice An interface for automatic distribution of the contract balance
/// to shareholders based on their held shares
interface IOmmgWithdrawable {
    /// @notice triggers whenever a shareholder is added to the contract
    /// @param addr the address of the shareholder
    /// @param shares the number of shares held by the holder
    event ShareholderAdded(address indexed addr, uint256 shares);
    /// @notice triggers whenever a shareholder is added to the contract
    /// @param addr the address of the former shareholder
    /// @param shares the number of shares that was held by the former holder
    event ShareholderRemoved(address indexed addr, uint256 shares);
    /// @notice triggers whenever a shareholder is updated
    /// @param addr the address of the shareholder
    /// @param shares the new number of shares held by the holder
    event ShareholderUpdated(address indexed addr, uint256 shares);
    /// @notice triggers whenever funds are withdrawn
    /// @param txSender the sender of the transaction
    /// @param amount the amount of eth withdrawn
    event Withdrawn(address indexed txSender, uint256 amount);
    /// @notice triggers whenever an emergency withdraw is executed
    /// @param txSender the transaction sender
    /// @param amount the amount of eth withdrawn
    event EmergencyWithdrawn(address indexed txSender, uint256 amount);
    /// @notice triggers whenever a shareholder receives their share of a withdrawal
    /// @param txSender the address that initiated the withdrawal
    /// @param to the address of the shareholder receiving this part of the withdrawal
    /// @param amount the amount of eth received by `to`
    event PaidOut(
        address indexed txSender,
        address indexed to,
        uint256 amount
    );
    /// @notice fires whenever a shareholder already exists but is attempted to be added
    /// @param addr the address already added
    error ShareholderAlreadyExists(address addr);
    /// @notice fires whenever a shareholder does not exist but an access is attempted
    /// @param addr the address of the attempted shareholder acces
    error ShareholderDoesNotExist(address addr);

    /// @notice withdraws the current balance from this contract and distributes it to shareholders
    /// according to their held shares. Triggers a {Withdrawn} event and a {PaidOut} event per shareholder.
    function withdraw() external;

    /// @notice withdraws the current balance from this contract and sends it to the
    /// initiator of the transaction. Triggers an {EmergencyWithdrawn} event.
    function emergencyWithdraw() external;

    /// @notice Adds a shareholder to the contract. When `withdraw` is called,
    /// the shareholder will receive an amount of native tokens proportional to
    /// their shares. Triggers a {ShareholderAdded} event.
    /// Requires `walletAddress` to not be the ZeroAddress and for the shareholder to not already exist,
    /// as well as for `shares` to be greater than 0.
    /// @param walletAddress the address of the shareholder
    /// @param shares the number of shares assigned to that shareholder
    function addShareholder(address walletAddress, uint256 shares) external;

    /// @notice Removes a shareholder from the contract. Triggers a {ShareholderRemoved} event.
    /// Requires `walletAddress` to not be the ZeroAddress and for the shareholder to exist.
    /// @param walletAddress the address of the shareholder to remove
    function removeShareholder(address walletAddress) external;

    /// @notice Updates a shareholder of the contract. Triggers a {ShareholderUpdated} event.
    /// Requires `walletAddress` to not be the ZeroAddress and for the shareholder to exist.
    /// @param walletAddress the address of the shareholder to remove
    /// @param updatedShares the new amount of shares the shareholder will have
    function updateShareholder(address walletAddress, uint256 updatedShares)
        external;

    /// @notice returns a list of all shareholders with their shares
    /// @return shareholders An array of tuples [address, shares], see the {Shareholder} struct
    function shareholders()
        external
        view
        returns (Shareholder[] memory shareholders);

    /// @notice returns the total amount of shares that exist
    /// @return shares the total number of shares in the contract
    function totalShares() external view returns (uint256 shares);

    /// @notice returns the number of shares held by `shareholderAddress`
    /// @return shares the number of shares held by `shareholderAddress`
    function shares(address shareholderAddress)
        external
        view
        returns (uint256 shares);
}