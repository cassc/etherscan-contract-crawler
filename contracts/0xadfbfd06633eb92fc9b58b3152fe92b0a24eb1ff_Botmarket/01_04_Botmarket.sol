// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

import "src/weiroll/VM.sol";
import "solady/utils/SafeTransferLib.sol";

/// @title  Botmarket
/// @notice Contract recipient from sdToken bounties on Votemarket.
/// @author Stake DAO
/// @custom:contact [email protected]
contract Botmarket {
    using SafeTransferLib for address;

    /// @notice Address of the governance contract.
    address public governance;

    /// @notice Address of the future governance contract.
    address public futureGovernance;

    /// @notice Address authorized to call the execute function.
    mapping(address => bool) public isAllowed;

    ////////////////////////////////////////////////////////////////
    /// --- EVENTS & ERRORS
    ///////////////////////////////////////////////////////////////

    /// @notice Event emitted when a new governance is proposed.
    event GovernanceProposed(address indexed newGovernance);

    /// @notice Event emitted when the governance is changed.
    event GovernanceChanged(address indexed newGovernance);

    /// @notice Throws if caller is not the governance.
    error GOVERNANCE();

    /// @notice Throws if caller is not allowed.
    error NOT_ALLOWED();

    /// @notice Throws if the length of the tokens and amounts arrays are not equal.
    error WRONG_LENGTH();

    ////////////////////////////////////////////////////////////////
    /// --- MODIFIERS
    ///////////////////////////////////////////////////////////////

    modifier onlyGovernance() {
        if (msg.sender != governance) revert GOVERNANCE();
        _;
    }

    modifier onlyAllowed() {
        if (!isAllowed[msg.sender]) revert NOT_ALLOWED();
        _;
    }

    constructor(address _governance) {
        governance = _governance;
    }

    ////////////////////////////////////////////////////////////////
    /// --- ADMIN FUNCTIONS
    ///////////////////////////////////////////////////////////////

    /// @notice Allow an address to call the execute function.
    /// @param _address Address to allow.
    function allowAddress(address _address) external onlyGovernance {
        isAllowed[_address] = true;
    }

    /// @notice Disallow an address to call the execute function.
    /// @param _address Address to disallow.
    function disallowAddress(address _address) external onlyGovernance {
        isAllowed[_address] = false;
    }

    /// @notice Transfer the governance to a new address.
    /// @param _governance Address of the new governance.
    function transferGovernance(address _governance) external onlyGovernance {
        emit GovernanceProposed(futureGovernance = _governance);
    }

    /// @notice Accept the governance transfer.
    function acceptGovernance() external {
        if (msg.sender != futureGovernance) revert GOVERNANCE();
        emit GovernanceChanged(governance = msg.sender);
    }

    /// @notice Withdraw ETH or ERC20 tokens from the contract.
    function withdraw(address[] calldata _tokens, uint256[] calldata _amount, address _recipient)
        external
        onlyAllowed
    {
        if (_tokens.length != _amount.length) revert WRONG_LENGTH();

        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i] == address(0)) {
                SafeTransferLib.safeTransferETH(_recipient, _amount[i]);
            } else {
                SafeTransferLib.safeTransfer(_tokens[i], _recipient, _amount[i]);
            }
        }
    }

    receive() external payable {}
}