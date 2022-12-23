// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "UUPSUpgradeable.sol";
import "IERC20Upgradeable.sol";
import "SafeERC20Upgradeable.sol";
import "OwnableUpgradeable.sol";

contract CoboSubSafe is OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Event fired when fund is collected
    /// @dev Event fired when fund is collected via `collectFund` method
    /// @param erc20 the token being collected, zero address for chain asset
    /// @param tokenAmt the amount to be collected, 0 for balance
    /// @param to the receiver address, mostly to the parent safe
    event Collected(
        address indexed erc20,
        uint256 tokenAmt,
        address indexed to
    );

    /// @notice Constructor function for CoboArgusSubSafe
    /// @dev When this subSafe is deployed, its ownership will be automatically
    ///      transferred to the given Gnosis safe instance.
    /// @param _safe the Gnosis Safe (GnosisSafeProxy) instance's address
    function initialize(address payable _safe) initializer public {
        __CoboSubSafe_init(_safe);
    }

    function __CoboSubSafe_init(address payable _safe) internal onlyInitializing {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __CoboSubSafe_init_unchained(_safe);
    }

    function __CoboSubSafe_init_unchained(address payable _safe) internal onlyInitializing {
        require(_safe != address(0), "invalid safe address");

        // make the given safe the owner of the current module.
        _transferOwnership(_safe);
    }

    /**
     * @notice Collect fund from subSafe to Gnosis Safe.
     * @dev To collect the fund from subSafe to Gnosis Safe. If the `erc20` is the reward token,
     *      the commission is applied. If the `tokenAmt` is zero, all balance is collected.
     * @param erc20 Token Address(zero address for ETH).
     * @param tokenAmt Token Amount.
     */
    function collectFund(address erc20, uint256 tokenAmt)
        public
        onlyOwner
    {
        if (erc20 == address(0)) {
            uint256 maxAmt = address(this).balance;
            if (tokenAmt == 0) {
                tokenAmt = maxAmt;
            } else {
                tokenAmt = tokenAmt >= maxAmt ? maxAmt : tokenAmt;
            }
            // need check if work as expected
            payable(owner()).transfer(tokenAmt);
        } else {
            IERC20Upgradeable token = IERC20Upgradeable(erc20);
            uint256 maxAmt = token.balanceOf(address(this));
            if (tokenAmt == 0) {
                tokenAmt = maxAmt;
            } else {
                tokenAmt = tokenAmt >= maxAmt ? maxAmt : tokenAmt;
            }
            token.safeTransfer(owner(), tokenAmt);
        }

        emit Collected(erc20, tokenAmt, owner());
    }

    /// @notice Execute transaction via subSafe
    /// @dev Only owner are allowed to call this.
    /// @param to contract address to be called
    /// @param value value data associated with contract call
    /// @param data input data associated with contract call
    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable onlyOwner returns (bytes memory) {
         (bool success, bytes memory ret) = to.call{value: value}(data);
        require(success);
        return ret;
    }

    /// @notice Return the name of module
    /// @dev reflect the new name
    /// @return name
    function NAME() public pure returns (string memory) {
        return "Cobo SubSafe";
    }

    /// @notice Return the version of module
    /// @dev reflect the new version
    /// @return version
    function VERSION() public pure returns (string memory){
        return "0.1.0";
    }

    receive() external payable {}

    /// @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
    /// {upgradeTo} and {upgradeToAndCall}.
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}