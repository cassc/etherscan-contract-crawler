// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ConfirmedOwner.sol";
import "KeeperCompatible.sol";
import "VestingWallet.sol";
import "Pausable.sol";

/**
 * @title The AutonomousDripper Contract
 * @author gosuto.eth
 * @notice A Chainlink Keeper-compatible version of OpenZeppelin's
 * VestingWallet; removing the need to monitor the interval and/or call release
 * manually. Also adds a (transferable) owner that can set the address of the
 * keeper's registry, pause/unpause the contract and sweep all ether/ERC-20
 * tokens.
 * Takes strong inspiration from https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/upkeeps/EthBalanceMonitor.sol
 */
contract AutonomousDripper is VestingWallet, KeeperCompatibleInterface, ConfirmedOwner, Pausable {
    event EtherSwept(uint256 amount);
    event ERC20Swept(address indexed token, uint256 amount);
    event KeeperRegistryAddressUpdated(address oldAddress, address newAddress);

    error OnlyKeeperRegistry();

    uint public lastTimestamp;
    uint public immutable interval;
    address[] public assetsWatchlist;
    address private _keeperRegistryAddress;

    constructor(
        address initialOwner,
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint intervalSeconds,
        address[] memory watchlistAddresses,
        address keeperRegistryAddress
    ) VestingWallet(
        beneficiaryAddress,
        startTimestamp,
        durationSeconds
    ) ConfirmedOwner(
        initialOwner
    ) {
        lastTimestamp = startTimestamp;
        interval = intervalSeconds;
        assetsWatchlist = watchlistAddresses;
        _keeperRegistryAddress = keeperRegistryAddress;
    }

    /**
     * @dev Setter for the list of ERC-20 token addresses to consider for
     * releasing. Can only be called by the current owner.
     */
    function setAssetsWatchlist(address[] calldata newAssetsWatchlist) public virtual onlyOwner {
        assetsWatchlist = newAssetsWatchlist;
    }

    /**
     * @dev Loop over the assetsWatchlist and check their local balance.
     * Returns a filtered version of the assetsWatchlist for which the local
     * balance is greater than zero.
     */
    function _getAssetsHeld() internal view returns (address[] memory) {
        address[] memory _assetsHeld = new address[](assetsWatchlist.length);
        uint256 count = 0;
        for (uint idx = 0; idx < assetsWatchlist.length; idx++) {
            uint256 balance = IERC20(assetsWatchlist[idx]).balanceOf(address(this));
            if (balance > 0) {
                _assetsHeld[count] = assetsWatchlist[idx];
                count++;
            }
        }
        if (count != assetsWatchlist.length) {
            // truncate length of _assetsHeld array by altering first slot
            assembly {
                mstore(_assetsHeld, count)
            }
        }
        return _assetsHeld;
    }

    /**
     * @dev Confirms that the `asset` given exists in `assetsWatchlist`.
     */
    function _assetWatched(address asset) internal view returns (bool) {
        uint256 numAssets = assetsWatchlist.length;
        for (uint idx = 0; idx < numAssets; ++idx) {
            if (assetsWatchlist[idx] == asset) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Runs off-chain at every block to determine if the `performUpkeep`
     * function should be called on-chain.
     */
    function checkUpkeep(bytes calldata) external view override whenNotPaused returns (
        bool upkeepNeeded, bytes memory checkData
    ) {
        if ((block.timestamp - lastTimestamp) > interval) {
            address[] memory assetsHeld = _getAssetsHeld();
            if (assetsHeld.length > 0) {
                return (true, abi.encode(assetsHeld));
            }
        }
    }

    /**
     * @dev Contains the logic that should be executed on-chain when
     * `checkUpkeep` returns true.
     */
    function performUpkeep(bytes calldata performData) external override onlyKeeperRegistry whenNotPaused {
        if ((block.timestamp - lastTimestamp) > interval) {
            address[] memory assetsHeld = abi.decode(performData, (address[]));
            bool dripped = false;
            for (uint idx = 0; idx < assetsHeld.length; idx++) {
                if (
                    _assetWatched(assetsHeld[idx]) &&
                    IERC20(assetsHeld[idx]).balanceOf(address(this)) > 0
                ) {
                    VestingWallet.release(assetsHeld[idx]);
                    dripped = true;
                }
            }
            if (dripped) {
                lastTimestamp = block.timestamp;
            }
        }
    }

    /**
     * @dev Sweep the full contract's ether balance to the current owner. Can
     * only be called by the current owner.
     */
    function sweep() public virtual onlyOwner {
        uint256 balance = address(this).balance;
        emit EtherSwept(balance);
        Address.sendValue(payable(super.owner()), balance);
    }

    /**
     * @dev Sweep the full contract's balance for an ERC-20 token to the
     * current owner. Can only be called by the current owner.
     */
    function sweep(address token) public virtual onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        emit ERC20Swept(token, balance);
        SafeERC20.safeTransfer(IERC20(token), super.owner(), balance);
    }

    /**
    * @dev Getter for the keeper registry address.
    */
    function getKeeperRegistryAddress() external view returns (address keeperRegistryAddress) {
        return _keeperRegistryAddress;
    }

    /**
    * @dev Setter for the keeper registry address.
    */
    function setKeeperRegistryAddress(address keeperRegistryAddress) public onlyOwner {
        emit KeeperRegistryAddressUpdated(_keeperRegistryAddress, keeperRegistryAddress);
        _keeperRegistryAddress = keeperRegistryAddress;
    }

    /**
    * @dev Pauses the contract, which prevents executing performUpkeep.
    */
    function pause() external onlyOwner {
        _pause();
    }

    /**
    * @dev Unpauses the contract.
    */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Release the native token (ether) that have already vested.
     *
     * Emits a {TokensReleased} event.
     */
    function release() public override onlyOwner {
        VestingWallet.release();
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {TokensReleased} event.
     */
    function release(address token) public override onlyOwner {
        VestingWallet.release(token);
    }

    modifier onlyKeeperRegistry() {
        if (msg.sender != _keeperRegistryAddress) {
            revert OnlyKeeperRegistry();
        }
        _;
    }
}