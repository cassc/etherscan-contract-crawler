//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/src/utils/SafeTransferLib.sol";

interface IPermissionedProxyDeployer {
    function proxyParameters()
        external
        returns (address payable owner, address payable delegate, ERC20[] memory tokens);
}

contract PermissionedProxy {
    using SafeTransferLib for ERC20;

    error OnlyDelegate();
    error OnlyOwner();
    error OnlyOwnerOrDelegate();

    address payable public immutable owner;
    address payable public immutable delegate;

    constructor() {
        ERC20[] memory tokens;
        (owner, delegate, tokens) = IPermissionedProxyDeployer(msg.sender).proxyParameters();

        // msg.sender should be careful with how many tokens are passed here to avoid DoS gas limit
        // https://consensys.github.io/smart-contract-best-practices/attacks/denial-of-service/#gas-limit-dos-on-a-contract-via-unbounded-operations
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i].safeApprove(owner, type(uint256).max);
        }
    }

    function approve(ERC20 token, address spender, uint256 amount) public onlyOwner {
        token.safeApprove(spender, amount);
    }

    function collectBalance(uint256 value) external onlyOwner {
        // restricted to owner, so no need to do a safe call
        owner.transfer(value);
    }

    fallback() external payable {
        _call();
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {
        /// @notice .send() and .transfer() only work for sending ETH to the owner (retrieved via .collectBalance())
        /// this is a deliberate decision, since any attempt to forward the transfer to either the owner or delegate
        /// spends more than the 2300 gas available
        if (msg.sender != delegate) revert OnlyDelegate();
    }

    /// @dev call version of https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/proxy/Proxy.sol#L22
    function _call() private {
        address implementation = _getImplementation();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := call(gas(), implementation, callvalue(), 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // call returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    function _getImplementation() private view returns (address payable implementation) {
        if (msg.sender == owner) {
            implementation = delegate;
        } else if (msg.sender == delegate) {
            implementation = owner;
        } else {
            revert OnlyOwnerOrDelegate();
        }
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyOwner();
        }
        _;
    }
}