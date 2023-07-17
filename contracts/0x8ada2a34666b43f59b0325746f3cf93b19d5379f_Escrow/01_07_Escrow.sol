// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

// OpenZeppelin imports
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Local imports
import { IEscrow } from "./interfaces/IEscrow.sol";
import { Configurable } from "../utils/Configurable.sol";

/// @notice Escrow source contract used for cloning by FundraisingDiamond for each raise.
contract Escrow is Configurable, IEscrow {
    // -----------------------------------------------------------------------
    //                              Library usage
    // -----------------------------------------------------------------------

    using SafeERC20 for IERC20;

    // -----------------------------------------------------------------------
    //                              State variables
    // -----------------------------------------------------------------------

    /// @dev Pool keeper - authority that withdraws tokens.
    address public keeper;

    // -----------------------------------------------------------------------
    //                              Modifiers
    // -----------------------------------------------------------------------

    /// @dev Ensures only pool keeper can call.
    modifier onlyKeeper() {
        // check if sender is keeper
        if (msg.sender != keeper) {
            // revert
            revert InvalidSender(msg.sender, keeper);
        }

        // enter function
        _;
    }

    // -----------------------------------------------------------------------
    //                          External functions
    // -----------------------------------------------------------------------

    /// @dev Function for initializing keeper role.
    /// @dev Validation: Can only be called once in unconfigured state.
    /// @dev Events: Initialised(bytes arguments).
    /// @param _arguments Encoded keeper address
    function configure(bytes calldata _arguments) external override onlyInState(State.UNCONFIGURED) {
        // decode arguments
        address _keeper = abi.decode(_arguments, (address));

        // set storage
        keeper = _keeper;

        // set state
        state = State.CONFIGURED;

        // emit event
        emit Initialised(_arguments);
    }

    /// @dev Function to withdraw funds from pool to receiver.
    /// @dev Validation: Can be called only by escrow keeper.
    /// @dev Events: Withdraw(address receiver, uint256 amount).
    /// @param _token Address of ERC-20 token contract
    /// @param _receiverData Receiver data (address and amount)
    function withdraw(address _token, ReceiverData calldata _receiverData) external override onlyKeeper {
        // withdraw
        _withdraw(_token, _receiverData.receiver, _receiverData.amount);
    }

    /// @dev Function to withdraw funds in batch from pool to receivers.
    /// @dev Validation: Can be called only by escrow keeper.
    /// @dev Events: Withdraw(address receiver, uint256 amount).
    /// @param _token Address of ERC-20 token contract
    /// @param _receiverData Array of receivers data (addresses and amounts)
    function batchWithdraw(address _token, ReceiverData[] calldata _receiverData) external override onlyKeeper {
        uint256 receiversLength_ = _receiverData.length;

        for (uint256 i = 0; i < receiversLength_; i++) {
            _withdraw(_token, _receiverData[i].receiver, _receiverData[i].amount);
        }
    }

    /// @dev Private function is responsible for sending given amount of ERC-20 token to receiver.
    /// @dev Events: Withdraw(address token, address receiver, uint256 amount).
    /// @param _token Address of ERC-20 token contract
    /// @param _receiver Address of withdrawal recipient
    /// @param _amount Amount of withdrawn funds
    function _withdraw(address _token, address _receiver, uint256 _amount) private {
        // transfer
        IERC20(_token).safeTransfer(_receiver, _amount);

        // emit
        emit Withdraw(_token, _receiver, _amount);
    }
}