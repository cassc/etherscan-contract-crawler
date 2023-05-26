// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../IWasabiPoolFactory.sol";
import "../fees/IWasabiFeeManager.sol";
import "../AbstractWasabiPool.sol";
import "../IWasabiErrors.sol";

/**
 * An ETH backed implementation of the IWasabiErrors.
 */
contract ETHWasabiPool is AbstractWasabiPool {
    receive() external payable override {
        emit ETHReceived(msg.value);
    }

    /**
     * @dev Initializes this pool with the given parameters.
     */
    function initialize(
        IWasabiPoolFactory _factory,
        IERC721 _nft,
        address _optionNFT,
        address _owner,
        address _admin
    ) external payable {
        baseInitialize(_factory, _nft, _optionNFT, _owner, _admin);
    }

    /// @inheritdoc AbstractWasabiPool
    function validateAndWithdrawPayment(uint256 _premium, string memory _message) internal override {        
        IWasabiFeeManager feeManager = IWasabiFeeManager(factory.getFeeManager());
        (address feeReceiver, uint256 feeAmount) = feeManager.getFeeData(address(this), _premium);

        if (feeAmount > 0) {
            uint256 maxFee = _maxFee(_premium);
            if (feeAmount > maxFee) {
                feeAmount = maxFee;
            }

            (bool _sent, ) = payable(feeReceiver).call{value: feeAmount}("");
            if (!_sent) {
                revert IWasabiErrors.FailedToSend();
            }
        }

        require(msg.value >= (_premium + feeAmount) && _premium > 0, _message);
    }

    /// @inheritdoc AbstractWasabiPool
    function payAddress(address _seller, uint256 _amount) internal override {
        IWasabiFeeManager feeManager = IWasabiFeeManager(factory.getFeeManager());
        (address feeReceiver, uint256 feeAmount) = feeManager.getFeeData(address(this), _amount);

        if (feeAmount > 0) {
            uint256 maxFee = _maxFee(_amount);
            if (feeAmount > maxFee) {
                feeAmount = maxFee;
            }
            (bool _sent, ) = payable(feeReceiver).call{value: feeAmount}("");
            if (!_sent) {
                revert IWasabiErrors.FailedToSend();
            }
        }

        (bool sent, ) = payable(_seller).call{value: _amount - feeAmount}("");
        if (!sent) {
            revert IWasabiErrors.FailedToSend();
        }
    }

    /// @inheritdoc IWasabiPool
    function withdrawETH(uint256 _amount) external payable onlyOwner {
        if (availableBalance() < _amount) {
            revert IWasabiErrors.InsufficientAvailableLiquidity();
        }
        address payable to = payable(_msgSender());
        (bool sent, ) = to.call{value: _amount}("");
        if (!sent) {
            revert IWasabiErrors.FailedToSend();
        }

        emit ETHWithdrawn(_amount);
    }

    /// @inheritdoc IWasabiPool
    function withdrawERC20(IERC20 _token, uint256 _amount) external onlyOwner {
        if (!_token.transfer(msg.sender, _amount)) {
            revert IWasabiErrors.FailedToSend();
        }
    }

    /// @inheritdoc IWasabiPool
    function availableBalance() view public override returns(uint256) {
        uint256 balance = address(this).balance;
        uint256[] memory optionIds = getOptionIds();
        for (uint256 i = 0; i < optionIds.length; i++) {
            WasabiStructs.OptionData memory optionData = getOptionData(optionIds[i]);
            if (optionData.optionType == WasabiStructs.OptionType.PUT && isValid(optionIds[i])) {
                balance -= optionData.strikePrice;
            }
        }
        return balance;
    }
}