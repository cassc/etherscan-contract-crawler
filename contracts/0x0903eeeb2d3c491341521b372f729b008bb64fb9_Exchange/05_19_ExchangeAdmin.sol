// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./lib/Whitelist.sol";

/// @title Contract with only admin methods
contract ExchangeAdmin is Whitelist {
    /// @dev In the form of exchange fee percent * 100
    /// @dev Example: 2.5% should be 250 (In order to support upto two decimal precisions, we multiply actual value by 100)
    uint16 public exchangeFee;
    /// @dev The account which receives fees. Default address is the contract deployer
    address public feeReceiver;
    bool public paused;

    /// @notice Emitted when the fee receiver is changed
    event FeeReceiverChanged(
        address indexed _prevFeeReceiver,
        address indexed _newFeeReceiver
    );

    /// @notice Emitted when the exchange fee is updated
    event ExchangeFeeUpdated(
        uint256 indexed _prevExchangeFee,
        uint256 indexed _newExchangeFee
    );

    /// @notice Emitted when the ETH in exchange contract is transferred to the fee receivers
    event TransferredEthToReceiver(uint256 _amount);

    /// @notice Emitted when the contract is paused
    event Paused();

    /// @notice Emitted when the contract is unpaused
    event Unpaused();

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    /// @notice Initializer for setting up exchange fee and fee receiver
    /// @dev Default fee receiver is the msg.sender
    /// @param _exchangeFee Exchange fee that will be deducted for each transaction
    function __Exchange_Admin_init_unchained(uint16 _exchangeFee) internal {
        exchangeFee = _exchangeFee;
        feeReceiver = msg.sender;
        paused = false;
    }

    /// @notice Update fee receiver to new address
    /// @param _newReceiver New fee receiver address
    /// @custom:modifier Only whitelist member can update the fee receiver address
    function changeFeeReceiver(address _newReceiver) external onlyWhitelist {
        require(_newReceiver != address(0), "Fee receiver can not be null");

        address _feeReceiver = feeReceiver;
        feeReceiver = _newReceiver;
        emit FeeReceiverChanged(_feeReceiver, _newReceiver);
    }

    /// @notice Update exchange fee to new fee
    /// @param _newExchangeFee New exchange fee in the form of fee * 100 to support two decimal precisions
    /// @custom:modifier Only whitelist member can update the exchange fee
    function updateExchangeFee(uint16 _newExchangeFee) external onlyWhitelist {
        uint16 _exchangeFee = exchangeFee;
        exchangeFee = _newExchangeFee;
        emit ExchangeFeeUpdated(_exchangeFee, exchangeFee);
    }

    /// @notice Transfer ETH from contract to the fee receiver address
    /// @param _amount Amount of eth that is to be transferred from contract to the fee receiver
    function transferEthToReceiver(uint256 _amount) external {
        require(msg.sender != address(0), "Null address check");
        emit TransferredEthToReceiver(_amount);
        payable(feeReceiver).transfer(_amount);
    }

    /// @notice Pause contract
    function pause() external onlyWhitelist {
        paused = true;
        emit Paused();
    }

    /// @notice unpause contract
    function unpause() external onlyWhitelist {
        paused = false;
        emit Unpaused();
    }
}