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

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@ape.swap/contracts/contracts/v0.8/access/PendingOwnable.sol";
import "./interfaces/IFactoryStorage.sol";
import "./interfaces/ICustomBillRefillable.sol";
import "./interfaces/ICustomTreasury.sol";
import "./interfaces/IBillNft.sol";

contract CustomBillFactoryBase is PendingOwnable, AccessControlEnumerable {
    /* ======== STATE VARIABLES ======== */

    struct BillDefaultConfig {
        address treasuryPayoutAddress; // Account which receives Treasury Bill deposits
        address[] billRefillers;
    }

    BillDefaultConfig public billDefaultConfig;
    ICustomBill.BillAccounts public getBillDefaultAccounts;

    IFactoryStorage public immutable factoryStorage;
    ICustomBill public billImplementationAddress;
    ICustomTreasury public treasuryImplementationAddress;
    ICustomBill[] public deployedBills;
    ICustomTreasury[] public deployedTreasuries;

    bytes32 public constant BILL_CREATOR_ROLE = keccak256("BILL_CREATOR_ROLE");
    
    event CreatedTreasury(
        ICustomTreasury customTreasury,
        address payoutToken,
        address owner,
        address payoutAddress
    );

    event CreatedBill(
        ICustomBill.BillCreationDetails billCreationDetails,
        ICustomTreasury customTreasury,
        ICustomBill bill,
        address billNft
    );

    event SetTreasury(address newTreasury);
    event SetDao(address newDao);
    event SetBillNft(address newBillNftAddress);
    event SetBillImplementation(ICustomBill newBillImplementation);
    event SetTreasuryImplementation(ICustomTreasury newTreasuryImplementation);

    /* ======== CONSTRUCTION ======== */

    constructor(
        BillDefaultConfig memory _billDefaultConfig,
        ICustomBill.BillAccounts memory _defaultBillAccounts,
        address _factoryStorage,
        address _billImplementationAddress,
        address _treasuryImplementationAddress,
        address[] memory _billCreators
    ) {

        require(_defaultBillAccounts.feeTo != address(0), "Treasury cannot be zero address");
        require(address(_defaultBillAccounts.billNft) != address(0), "billNft cannot be zero address");
        require(_defaultBillAccounts.DAO != address(0), "DAO cannot be zero address");
        _transferOwnership(_defaultBillAccounts.DAO);
        getBillDefaultAccounts = _defaultBillAccounts;

        require(_billDefaultConfig.treasuryPayoutAddress != address(0), "payoutAddress cannot be zero address");
        billDefaultConfig = _billDefaultConfig;

        require(_factoryStorage != address(0), "factoryStorage cannot be zero address");
        factoryStorage = IFactoryStorage(_factoryStorage);
        require(_billImplementationAddress != address(0), "billImplementationAddress cannot be zero address");
        billImplementationAddress = ICustomBill(_billImplementationAddress);
        require(_treasuryImplementationAddress != address(0), "treasuryImplementationAddress cannot be zero address");
        treasuryImplementationAddress = ICustomTreasury(_treasuryImplementationAddress);

        for (uint i = 0; i < _billCreators.length; i++) {
            _grantRole(BILL_CREATOR_ROLE, _billCreators[i]);
        }
    }

    function totalDeployed() external view returns (uint256 _billsDeployed, uint256 _treasuriesDeployed) {
        return (deployedBills.length, deployedTreasuries.length);
    }

    function getBillDefaultConfig() external view returns (
        address _treasuryPayoutAddress,
        address _billFeeTo,
        address _billDAO,
        address _billNft,
        address[] memory _billRefillers
    ) {
        _treasuryPayoutAddress = billDefaultConfig.treasuryPayoutAddress;
        _billRefillers = billDefaultConfig.billRefillers;
        _billFeeTo = getBillDefaultAccounts.feeTo;
        _billDAO = getBillDefaultAccounts.DAO;
        _billNft = getBillDefaultAccounts.billNft;
    }

    /* ======== OWNER CONFIGURATIONS ======== */

    function setBillNft(IBillNft _billNft) external onlyOwner {
        getBillDefaultAccounts.billNft = address(_billNft);
        emit SetBillNft(address(_billNft));
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        getBillDefaultAccounts.feeTo = _feeTo;
        emit SetTreasury(_feeTo);
    }

    function setDao(address _DAO) external onlyOwner {
        getBillDefaultAccounts.DAO = _DAO;
        emit SetDao(_DAO);
    }

    /**
     * @notice Set the CustomBill implementation address
     * @param _billImplementation Implementation of CustomBill
     */
    function setBillImplementation(ICustomBill _billImplementation) external onlyOwner {
        billImplementationAddress = _billImplementation;
        emit SetBillImplementation(billImplementationAddress);
    }

    /**
     * @notice Set the CustomTreasury implementation address
     * @param _treasuryImplementation Implementation of CustomTreasury
     */
    function setTreasuryImplementation(ICustomTreasury _treasuryImplementation) external onlyOwner {
        treasuryImplementationAddress = _treasuryImplementation;
        emit SetTreasuryImplementation(treasuryImplementationAddress);
    }

    /**
     * @notice Replace the default accounts which are added as Bill Refillers when new bills are created
     * @param _billRefillers Array of addresses to replace
     */
    function setBillRefillers(address[] memory _billRefillers) external onlyOwner {
        billDefaultConfig.billRefillers = _billRefillers;
    }

    /**
     * @notice Grant the ability to create Treasury Bills
     * @param _billCreators Array of addresses to whitelist as bill creators
     */
    function grantBillCreatorRole(address[] calldata _billCreators) external onlyOwner {
        for (uint i = 0; i < _billCreators.length; i++) {
            _grantRole(BILL_CREATOR_ROLE, _billCreators[i]);
        }
    }

    /**
     * @notice Revoke the ability to create Treasury Bills
     * @param _billCreators Array of addresses to revoke as bill creators
     */
    function revokeBillCreatorRole(address[] calldata _billCreators) external onlyOwner {
        for (uint i = 0; i < _billCreators.length; i++) {
            _revokeRole(BILL_CREATOR_ROLE, _billCreators[i]);
        }
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    function _createTreasuryWithDefaults(
        address _payoutToken,
        address _owner
    ) internal returns (ICustomTreasury _customTreasury) {
        return _createTreasury(_payoutToken, _owner, billDefaultConfig.treasuryPayoutAddress);
    }

    function _createTreasury(
        address _payoutToken,
        address _owner,
        address _payoutAddress
    ) internal returns (ICustomTreasury _customTreasury) {
        _customTreasury = ICustomTreasury(Clones.clone(address(treasuryImplementationAddress)));
        _customTreasury.initialize(_payoutToken, _owner, _payoutAddress);

        deployedTreasuries.push(_customTreasury);
        emit CreatedTreasury(
            _customTreasury,
            _payoutToken,
            _owner,
            _payoutAddress
        );
    }

    /**
        @notice deploys custom bill contract and returns address of the bill and its treasury
        @param _billCreationDetails BillCreationDetails
        @param _customTreasury address
     */
    function _createBillWithDefaults(
        ICustomBill.BillCreationDetails memory _billCreationDetails,
        ICustomBill.BillTerms memory _billTerms,
        ICustomTreasury _customTreasury
    ) internal returns (ICustomTreasury _treasury, ICustomBill _bill) {
        return _createBill(
            _billCreationDetails,
            _billTerms,
            getBillDefaultAccounts,
            _customTreasury,
            billDefaultConfig.billRefillers
        );
    }

    /**
        @notice deploys custom bill contract and returns address of the bill and its treasury
        @param _billCreationDetails BillCreationDetails
        @param _customTreasury address
     */
    function _createBill(
        ICustomBill.BillCreationDetails memory _billCreationDetails,
        ICustomBill.BillTerms memory _billTerms,
        ICustomBill.BillAccounts memory _billAccounts,
        ICustomTreasury _customTreasury,
        address[] memory _billRefillers
    ) internal returns (ICustomTreasury _treasury, ICustomBill _bill) {
        require(_customTreasury.payoutToken() == _billCreationDetails.payoutToken, "payout token mismatch");
        ICustomBillRefillable bill = ICustomBillRefillable(Clones.clone(address(billImplementationAddress)));
        bill.initialize(
            _customTreasury,
            _billCreationDetails,
            _billTerms,
            _billAccounts,
            _billRefillers
        );

        IBillNft(_billAccounts.billNft).addMinter(address(bill));
        deployedBills.push(bill);

        emit CreatedBill(
            _billCreationDetails,
            _customTreasury,
            bill,
            _billAccounts.billNft
        );

        IFactoryStorage(factoryStorage).pushBill(
            _billCreationDetails, 
            address(_customTreasury), 
            address(bill), 
            _billAccounts.billNft
        );

        return (_customTreasury, ICustomBill(bill));
    }
}