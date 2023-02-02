// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/*
  ______                     ______                                 
 /      \                   /      \                                
|  ▓▓▓▓▓▓\ ______   ______ |  ▓▓▓▓▓▓\__   __   __  ______   ______  
| ▓▓__| ▓▓/      \ /      \| ▓▓___\▓▓  \ |  \ |  \|      \ /      \ 
| ▓▓    ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓    \| ▓▓ | ▓▓ | ▓▓ \▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓    ▓▓_\▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓/      ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓  \__| ▓▓ ▓▓_/ ▓▓_/ ▓▓  ▓▓▓▓▓▓▓ ▓▓__/ ▓▓
| ▓▓  | ▓▓ ▓▓    ▓▓\▓▓     \\▓▓    ▓▓\▓▓   ▓▓   ▓▓\▓▓    ▓▓ ▓▓    ▓▓
 \▓▓   \▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓\▓▓▓▓  \▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓ 
         | ▓▓                                             | ▓▓      
         | ▓▓                                             | ▓▓      
          \▓▓                                              \▓▓         
 * App:             https://ApeSwap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * Discord:         https://ApeSwap.click/discord
 * Reddit:          https://reddit.com/r/ApeSwap
 * Instagram:       https://instagram.com/ApeSwap.finance
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "./CustomBillFactoryBase.sol";

contract CustomBillFactory is CustomBillFactoryBase {
    constructor(
        BillDefaultConfig memory _billDefaultConfig,
        ICustomBill.BillAccounts memory _defaultBillAccounts,
        address _factoryStorage,
        address _billImplementationAddress,
        address _treasuryImplementationAddress,
        address[] memory _billCreators
    )
        CustomBillFactoryBase(
            _billDefaultConfig,
            _defaultBillAccounts,
            _factoryStorage,
            _billImplementationAddress,
            _treasuryImplementationAddress,
            _billCreators
        )
    {}

    /* ======== FACTORY FUNCTIONS ======== */

    /**
        @notice deploys ICustomTreasury and ICustomBill contracts and returns address of both
        @param _billCreationDetails ICustomBill.BillCreationDetails
        @param _billTerms ICustomBill.BillTerms
     */
    function createBillAndTreasury(
        ICustomBill.BillCreationDetails calldata _billCreationDetails,
        ICustomBill.BillTerms calldata _billTerms
    )
        external
        onlyRole(BILL_CREATOR_ROLE)
        returns (ICustomTreasury _customTreasury, ICustomBill _bill)
    {
        _customTreasury = _createTreasuryWithDefaults(
            _billCreationDetails.payoutToken,
            _billCreationDetails.initialOwner
        );

        return
            _createBillWithDefaults(
                _billCreationDetails,
                _billTerms,
                _customTreasury
            );
    }

    /**
        @notice deploys ICustomBill contract
        @param _billCreationDetails ICustomBill.BillCreationDetails
        @param _billTerms ICustomBill.BillTerms
        @param _customTreasury address of ICustomTreasury linked to this bill
     */
    function createBill(
        ICustomBill.BillCreationDetails calldata _billCreationDetails,
        ICustomBill.BillTerms calldata _billTerms,
        ICustomTreasury _customTreasury
    )
        external
        onlyRole(BILL_CREATOR_ROLE)
        returns (ICustomTreasury _treasury, ICustomBill _bill)
    {
        return
            _createBillWithDefaults(
                _billCreationDetails,
                _billTerms,
                _customTreasury
            );
    }

    /**
        @notice deploys ICustomTreasury and ICustomBill contracts
        @param _billCreationDetails ICustomBill.BillCreationDetails
        @param _billTerms ICustomBill.BillTerms
        @param _payoutAddress account which receives deposited tokens
        @param _billRefillers accounts allowed to refill the Treasury Bill contract with payout tokens
     */
    function createBillAndTreasury_CustomConfig(
        ICustomBill.BillCreationDetails calldata _billCreationDetails,
        ICustomBill.BillTerms calldata _billTerms,
        ICustomBill.BillAccounts calldata _billAccounts,
        address _payoutAddress,
        address[] calldata _billRefillers
    )
        external
        onlyRole(BILL_CREATOR_ROLE)
        returns (ICustomTreasury _customTreasury, ICustomBill _bill)
    {
        _customTreasury = _createTreasury(
            _billCreationDetails.payoutToken,
            _billCreationDetails.initialOwner,
            _payoutAddress
        );

        return
            _createBill(
                _billCreationDetails,
                _billTerms,
                _billAccounts,
                _customTreasury,
                _billRefillers
            );
    }

    /**
        @notice deploys ICustomBill contract
        @param _billCreationDetails ICustomBill.BillCreationDetails
        @param _billTerms ICustomBill.BillTerms
        @param _customTreasury address of ICustomTreasury linked to this bill
        @param _billRefillers accounts allowed to refill the Treasury Bill contract with payout tokens
     */
    function createBill_CustomConfig(
        ICustomBill.BillCreationDetails calldata _billCreationDetails,
        ICustomBill.BillTerms calldata _billTerms,
        ICustomBill.BillAccounts calldata _billAccounts,
        ICustomTreasury _customTreasury,
        address[] calldata _billRefillers
    )
        external
        onlyRole(BILL_CREATOR_ROLE)
        returns (ICustomTreasury _treasury, ICustomBill _bill)
    {
        return
            _createBill(
                _billCreationDetails,
                _billTerms,
                _billAccounts,
                _customTreasury,
                _billRefillers
            );
    }

    /* ======== MANUAL FUNCTIONS ======== */

    /**
        @notice deploys ICustomTreasury and ICustomBill contracts and returns address of both
     */
    function createBillAndTreasury_Explorer(
        address _payoutToken,
        address _principalToken,
        address _initialOwner,
        IVestingCurve _vestingCurve,
        uint256[] calldata _tierCeilings,
        uint256[] calldata _fees,
        bool _feeInPayout,
        ICustomBill.BillTerms calldata _billTerms
    )
        external
        onlyRole(BILL_CREATOR_ROLE)
        returns (ICustomTreasury _customTreasury, ICustomBill _bill)
    {
        ICustomBill.BillCreationDetails
            memory billCreationDetails = getBillCreationDetails(
                _payoutToken,
                _principalToken,
                _initialOwner,
                _vestingCurve,
                _tierCeilings,
                _fees,
                _feeInPayout
            );

        _customTreasury = _createTreasuryWithDefaults(
            billCreationDetails.payoutToken,
            billCreationDetails.initialOwner
        );
        return
            _createBillWithDefaults(
                billCreationDetails,
                _billTerms,
                _customTreasury
            );
    }

    /**
        @notice deploys ICustomBill contract
     */
    function createBill_Explorer(
        address _payoutToken,
        address _principalToken,
        address _initialOwner,
        IVestingCurve _vestingCurve,
        uint256[] calldata _tierCeilings,
        uint256[] calldata _fees,
        bool _feeInPayout,
        ICustomBill.BillTerms calldata _billTerms,
        ICustomTreasury _customTreasury
    )
        external
        onlyRole(BILL_CREATOR_ROLE)
        returns (ICustomTreasury _treasury, ICustomBill _bill)
    {
        ICustomBill.BillCreationDetails
            memory billCreationDetails = getBillCreationDetails(
                _payoutToken,
                _principalToken,
                _initialOwner,
                _vestingCurve,
                _tierCeilings,
                _fees,
                _feeInPayout
            );

        return
            _createBillWithDefaults(
                billCreationDetails,
                _billTerms,
                _customTreasury
            );
    }

    /* ======== HELPER FUNCTIONS ======== */

    /**
     * @notice helper function to create an ICustomBill.BillCreationDetails tuple for CustomTreasury and CustomBill deployments
     */
    function getBillCreationDetails(
        address _payoutToken,
        address _principalToken,
        address _initialOwner,
        IVestingCurve _vestingCurve,
        uint256[] calldata _tierCeilings,
        uint256[] calldata _fees,
        bool _feeInPayout
    ) public pure returns (ICustomBill.BillCreationDetails memory) {
        return
            ICustomBill.BillCreationDetails({
                payoutToken: _payoutToken,
                principalToken: _principalToken,
                initialOwner: _initialOwner,
                vestingCurve: _vestingCurve,
                tierCeilings: _tierCeilings,
                fees: _fees,
                feeInPayout: _feeInPayout
            });
    }

    /**
     * @notice helper function to create an ICustomBill.BillTerms tuple for CustomTreasury and CustomBill deployments
     */
    function getBillTerms(
        uint256 _controlVariable,
        uint256 _vestingTerm,
        uint256 _minimumPrice,
        uint256 _maxPayout,
        uint256 _maxDebt,
        uint256 _maxTotalPayout,
        uint256 _initialDebt
    ) public pure returns (ICustomBill.BillTerms memory) {
        return
            ICustomBill.BillTerms({
                controlVariable: _controlVariable,
                vestingTerm: _vestingTerm,
                minimumPrice: _minimumPrice,
                maxPayout: _maxPayout,
                maxDebt: _maxDebt,
                maxTotalPayout: _maxTotalPayout,
                initialDebt: _initialDebt
            });
    }
}