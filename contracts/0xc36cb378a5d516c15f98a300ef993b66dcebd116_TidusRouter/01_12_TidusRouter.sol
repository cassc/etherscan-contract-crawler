//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;
import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "@rari-capital/solmate/src/tokens/ERC20.sol";
import "./routers/BaseAggregator.sol";

/// @title Rainbow swap aggregator contract
contract TidusRouter is BaseAggregator {
    /// @dev The address that is the current owner of this contract
    address public owner;

    /// @dev Event emitted when the owner changes
    event OwnerChanged(address indexed newOwner, address indexed oldOwner);

    /// @dev Event emitted when a swap target gets added
    event SwapTargetAdded(address indexed target);

    /// @dev Event emitted when a swap target gets removed
    event SwapTargetRemoved(address indexed target);

    /// @dev Event emitted when token fees are withdrawn
    event TokenWithdrawn(
        address indexed token,
        address indexed target,
        uint256 amount
    );

    /// @dev Event emitted when Treasury address changes
    event TidusTreasuryChanged(
        address indexed newTidusTreasury,
        address indexed oldTidusTreasury
    );

    /// @dev Event emitted when ETH fees are withdrawn
    event EthWithdrawn(address indexed target, uint256 amount);

    /// @dev modifier that ensures only the owner is allowed to call a specific method
    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    constructor(address payable _deployer, address _0xProxyAddress) BaseAggregator(_deployer) {
        require(_0xProxyAddress != address(0), "ZERO_ADDRESS");
        swapTargets[_0xProxyAddress] = true;
        owner = _deployer;
        status = 1;
    }

    /// @dev We don't want to accept any ETH, except refunds from aggregators
    /// or the owner (for testing purposes), which can also withdraw
    /// This is done by evaluating the value of status, which is set to 2
    /// only during swaps due to the "nonReentrant" modifier
    receive() external payable {
        require(status == 2 || msg.sender == owner, "NO_RECEIVE");
    }

    /// @dev method to add or remove swap targets from swapTargets
    /// This is required so we only approve "trusted" swap targets
    /// to transfer tokens out of this contract
    /// @param target address of the swap target to add
    /// @param add flag to add or remove the swap target
    function updateSwapTargets(address target, bool add) external onlyOwner {
        swapTargets[target] = add;
        if (add) {
            emit SwapTargetAdded(target);
        } else {
            emit SwapTargetRemoved(target);
        }
    }

    /// @dev method to withdraw ERC20 tokens (from the fees)
    /// @param token address of the token to withdraw
    /// @param to address that's receiving the tokens
    /// @param amount amount of tokens to withdraw
    function withdrawToken(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(to != address(0), "ZERO_ADDRESS");
        SafeTransferLib.safeTransfer(ERC20(token), to, amount);
        emit TokenWithdrawn(token, to, amount);
    }

    /// @dev method to withdraw ETH (from the fees)
    /// @param to address that's receiving the ETH
    /// @param amount amount of ETH to withdraw
    function withdrawEth(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "ZERO_ADDRESS");
        SafeTransferLib.safeTransferETH(to, amount);
        emit EthWithdrawn(to, amount);
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// @param newOwner address of the new owner
    /// Can only be called by the current owner.
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "ZERO_ADDRESS");
        require(newOwner != owner, "SAME_OWNER");
        address previousOwner = owner;
        owner = newOwner;
        emit OwnerChanged(newOwner, previousOwner);
    }

    /// @dev Changes the address of the Tidus Treasury
    /// @param newTidusTreasury address of the new Tidus Treasury
    /// Can only be called by the current owner.
    function changeTidusTreasury(address payable newTidusTreasury)
        external
        virtual
        onlyOwner
    {
        require(newTidusTreasury != address(0), "ZERO_ADDRESS");
        require(newTidusTreasury != tidusTreasury, "SAME_TIDUS_TREASURY");
        address previousTidusTreasury = tidusTreasury;
        tidusTreasury = newTidusTreasury;
        emit TidusTreasuryChanged(newTidusTreasury, previousTidusTreasury);
    }
}