//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "../../utils/SBImmutableArgs.sol";
import "../interfaces/IStagingBox.sol";

/**
 * @dev Staging Box for reinitializing a ConvertibleBondBox
 *
 * Invariants:
 *  - initialPrice should meet conditions needed to reinitialize CBB
 *  - I.e. initialPrice <= priceGranularity, and initialPrice != 0
 */

contract StagingBox is OwnableUpgradeable, SBImmutableArgs, IStagingBox {
    uint256 public s_reinitLendAmount;

    modifier beforeReinitialize() {
        if (convertibleBondBox().s_startDate() != 0) {
            revert CBBReinitialized({state: true, requiredState: false});
        }
        _;
    }

    function initialize(address _owner) external initializer {
        require(_owner != address(0), "StagingBox: invalid owner address");
        //check if valid initialPrice immutable arg
        if (initialPrice() > priceGranularity())
            revert InitialPriceTooHigh({
                given: initialPrice(),
                maxPrice: priceGranularity()
            });
        if (initialPrice() == 0)
            revert InitialPriceIsZero({given: 0, maxPrice: priceGranularity()});

        //Setup ownership
        __Ownable_init();
        transferOwnership(_owner);

        //Add event stuff
        emit Initialized(_owner);
    }

    function depositBorrow(address _borrower, uint256 _borrowAmount)
        external
        override
        beforeReinitialize
    {
        //- transfers `_safeTrancheAmount` of SafeTranche Tokens from msg.sender to SB

        uint256 safeTrancheAmount = (_borrowAmount *
            priceGranularity() *
            trancheDecimals()) /
            initialPrice() /
            stableDecimals();

        safeTranche().transferFrom(
            _msgSender(),
            address(this),
            safeTrancheAmount
        );

        //- transfers `_safeTrancheAmount * riskRatio() / safeRatio()`  of RiskTranches from msg.sender to SB

        riskTranche().transferFrom(
            _msgSender(),
            address(this),
            (safeTrancheAmount * riskRatio()) / safeRatio()
        );

        //- mints `_safeTrancheAmount` of BorrowerSlips to `_borrower`
        borrowSlip().mint(_borrower, _borrowAmount);

        //add event stuff
        emit BorrowDeposit(_borrower, _borrowAmount);
    }

    function depositLend(address _lender, uint256 _lendAmount)
        external
        override
        beforeReinitialize
    {
        //- transfers `_lendAmount`of Stable Tokens from msg.sender to SB
        TransferHelper.safeTransferFrom(
            address(stableToken()),
            _msgSender(),
            address(this),
            _lendAmount
        );

        //- mints `_lendAmount`of LenderSlips to `_lender`
        lendSlip().mint(_lender, _lendAmount);

        //add event stuff
        emit LendDeposit(_lender, _lendAmount);
    }

    function withdrawBorrow(uint256 _borrowSlipAmount) external override {
        //- Reverse of depositBorrow() function
        //- transfers `_borrowSlipAmount` of SafeTranche Tokens from SB to msg.sender

        uint256 safeTrancheAmount = (_borrowSlipAmount *
            priceGranularity() *
            trancheDecimals()) /
            initialPrice() /
            stableDecimals();

        safeTranche().transfer(_msgSender(), (safeTrancheAmount));

        //- transfers `_borrowSlipAmount*riskRatio()/safeRatio()` of RiskTranche Tokens from SB to msg.sender

        riskTranche().transfer(
            _msgSender(),
            (safeTrancheAmount * riskRatio()) / safeRatio()
        );

        //- burns `_borrowSlipAmount` of msg.sender’s BorrowSlips
        borrowSlip().burn(_msgSender(), _borrowSlipAmount);

        //event stuff
        emit BorrowWithdrawal(_msgSender(), _borrowSlipAmount);
    }

    function withdrawLend(uint256 _lendSlipAmount) external override {
        //- Reverse of depositBorrow() function

        //revert check for _lendSlipAmount after CBB reinitialized
        if (convertibleBondBox().s_startDate() != 0) {
            uint256 maxWithdrawAmount = stableToken().balanceOf(address(this)) -
                s_reinitLendAmount;
            if (_lendSlipAmount > maxWithdrawAmount) {
                revert WithdrawAmountTooHigh({
                    requestAmount: _lendSlipAmount,
                    maxAmount: maxWithdrawAmount
                });
            }
        }

        //- transfers `_lendSlipAmount` of Stable Tokens from SB to msg.sender
        TransferHelper.safeTransfer(
            address(stableToken()),
            _msgSender(),
            _lendSlipAmount
        );

        //- burns `_lendSlipAmount` of msg.sender’s LenderSlips
        lendSlip().burn(_msgSender(), _lendSlipAmount);

        //event stuff
        emit LendWithdrawal(_msgSender(), _lendSlipAmount);
    }

    function redeemBorrowSlip(uint256 _borrowSlipAmount) external override {
        //decrement s_reinitLendAmount
        s_reinitLendAmount -= _borrowSlipAmount;

        // Transfer `_borrowSlipAmount*riskRatio()/safeRatio()` of RiskSlips to msg.sender
        ISlip(riskSlipAddress()).transfer(
            _msgSender(),
            ((_borrowSlipAmount *
                priceGranularity() *
                riskRatio() *
                trancheDecimals()) /
                initialPrice() /
                safeRatio() /
                stableDecimals())
        );

        // Transfer `_borrowSlipAmount*initialPrice()/priceGranularity()` of StableToken to msg.sender
        TransferHelper.safeTransfer(
            address(stableToken()),
            _msgSender(),
            _borrowSlipAmount
        );

        // burns `_borrowSlipAmount` of msg.sender’s BorrowSlips
        borrowSlip().burn(_msgSender(), _borrowSlipAmount);

        //event stuff
        emit RedeemBorrowSlip(_msgSender(), _borrowSlipAmount);
    }

    function redeemLendSlip(uint256 _lendSlipAmount) external override {
        //- Transfer `_lendSlipAmount*priceGranularity()/initialPrice()`  of SafeSlips to msg.sender
        ISlip(safeSlipAddress()).transfer(
            _msgSender(),
            (_lendSlipAmount * priceGranularity() * trancheDecimals()) /
                initialPrice() /
                stableDecimals()
        );

        //- burns `_lendSlipAmount` of msg.sender’s LendSlips
        lendSlip().burn(_msgSender(), _lendSlipAmount);

        emit RedeemLendSlip(_msgSender(), _lendSlipAmount);
    }

    function transmitReInit(bool _isLend) external override onlyOwner {
        /*
        - calls `CBB.reinitialize(…)`
            - `Address(this)` as borrower + lender
            - if `_isLend` is true: calls CBB with balance of StableAmount
            - if `_isLend` is false: calls CBB with balance of SafeTrancheAmount
        */

        safeTranche().approve(address(convertibleBondBox()), type(uint256).max);
        riskTranche().approve(address(convertibleBondBox()), type(uint256).max);

        if (_isLend) {
            uint256 stableAmount = stableToken().balanceOf(address(this));
            s_reinitLendAmount = stableAmount;
            convertibleBondBox().reinitialize(initialPrice());
            convertibleBondBox().lend(
                address(this),
                address(this),
                stableAmount
            );
        } else {
            uint256 safeTrancheBalance = safeTranche().balanceOf(address(this));
            s_reinitLendAmount =
                (safeTrancheBalance * initialPrice() * stableDecimals()) /
                priceGranularity() /
                trancheDecimals();

            convertibleBondBox().reinitialize(initialPrice());

            convertibleBondBox().borrow(
                address(this),
                address(this),
                safeTrancheBalance
            );
        }

        //- calls `CBB.transferOwner(owner())` to transfer ownership of CBB back to Owner()
        convertibleBondBox().transferOwnership(owner());
    }

    function transferOwnership(address newOwner)
        public
        override(IStagingBox, OwnableUpgradeable)
        onlyOwner
    {
        _transferOwnership(newOwner);
    }

    function transferCBBOwnership(address newOwner) public override onlyOwner {
        convertibleBondBox().transferOwnership(newOwner);
    }
}