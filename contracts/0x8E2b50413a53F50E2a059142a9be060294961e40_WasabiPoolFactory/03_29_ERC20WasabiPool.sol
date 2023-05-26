// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../IWasabiPoolFactory.sol";
import "../IWasabiErrors.sol";
import "../AbstractWasabiPool.sol";
import "../fees/IWasabiFeeManager.sol";

/**
 * An ERC20 backed implementation of the IWasabiPool.
 */
contract ERC20WasabiPool is AbstractWasabiPool {
    IERC20 private token;

    /**
     * @dev Initializes this pool with the given parameters.
     */
    function initialize(
        IWasabiPoolFactory _factory,
        IERC20 _token,
        IERC721 _nft,
        address _optionNFT,
        address _owner,
        address _admin
    ) external payable {
        baseInitialize(_factory, _nft, _optionNFT, _owner, _admin);
        token = _token;
    }

    /// @inheritdoc IWasabiPool
    function getLiquidityAddress() override public view returns(address) {
        return address(token);
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
        }
        require(
            token.allowance(_msgSender(), address(this)) >= (_premium + feeAmount) && _premium > 0,
            _message);

        if (!token.transferFrom(_msgSender(), address(this), _premium)) {
            revert IWasabiErrors.FailedToSend();
        }
        if (feeAmount > 0) {
            if (!token.transferFrom(_msgSender(), feeReceiver, feeAmount)) {
                revert IWasabiErrors.FailedToSend();
            }
        }
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
        }

        if (!token.transfer(_seller, _amount - feeAmount)) {
            revert IWasabiErrors.FailedToSend();
        }
        if (feeAmount > 0) {
            if (!token.transfer(feeReceiver, feeAmount)) {
                revert IWasabiErrors.FailedToSend();
            }
        }
    }
    
    /// @inheritdoc IWasabiPool
    function availableBalance() view public override returns(uint256) {
        uint256 balance = token.balanceOf(address(this));
        uint256[] memory optionIds = getOptionIds();
        for (uint256 i = 0; i < optionIds.length; i++) {
            WasabiStructs.OptionData memory optionData = getOptionData(optionIds[i]);
            if (optionData.optionType == WasabiStructs.OptionType.PUT && isValid(optionIds[i])) {
                balance -= optionData.strikePrice;
            }
        }
        return balance;
    }

    /// @inheritdoc IWasabiPool
    function withdrawERC20(IERC20 _token, uint256 _amount) external onlyOwner {
        bool isPoolToken = _token == token;

        if (isPoolToken && availableBalance() < _amount) {
            revert IWasabiErrors.InsufficientAvailableLiquidity();
        }
        if (!_token.transfer(msg.sender, _amount)) {
            revert IWasabiErrors.FailedToSend();
        }

        if (isPoolToken) {
            emit ERC20Withdrawn(_amount);
        }
    }
    
    /// @inheritdoc IWasabiPool
    function withdrawETH(uint256 _amount) external override payable onlyOwner {
        if (address(this).balance < _amount) {
            revert IWasabiErrors.InsufficientAvailableLiquidity();
        }

        address payable to = payable(owner());
        (bool sent, ) = to.call{value: _amount}("");
        if (!sent) {
            revert IWasabiErrors.FailedToSend();
        }
        emit ETHWithdrawn(_amount);
    }
}