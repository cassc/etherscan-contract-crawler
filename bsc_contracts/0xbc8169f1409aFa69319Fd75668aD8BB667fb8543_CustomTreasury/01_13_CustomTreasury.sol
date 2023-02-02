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

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@ape.swap/contracts/contracts/v0.8/access/PendingOwnableUpgradeable.sol";
import "./interfaces/ICustomBill.sol";


contract CustomTreasury is Initializable, PendingOwnableUpgradeable {
    /* ======== DEPENDENCIES ======== */

    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ======== STATE VARIABLES ======== */

    IERC20MetadataUpgradeable public payoutToken;

    address public payoutAddress;

    mapping(address => bool) public billContract;

    /* ======== EVENTS ======== */

    event BillContractToggled(address indexed billContract, bool enabled);
    event Deposit(address indexed billContract, uint256 amountPrincipalToken, uint256 amountPayoutToken);
    event PayoutFee(address indexed billContract, address feeReceiver, uint256 amountPayoutToken);
    event Withdraw(address indexed token, address indexed destination, uint256 amount);

    /* ======== CONSTRUCTOR ======== */

    function initialize(IERC20MetadataUpgradeable _payoutToken, address _initialOwner, address _payoutAddress) public initializer {
        require(address(_payoutToken) != address(0), "Payout token cannot address zero");
        payoutToken = _payoutToken;
        require(_initialOwner != address(0), "initialOwner can't address 0");
        __Ownable_init();
        _transferOwnership(_initialOwner);
        require(_payoutAddress != address(0), "payoutAddress can't address 0");
        payoutAddress = _payoutAddress;
    }

    /* ======== BILL CONTRACT FUNCTION ======== */

    /**
     * @notice Access modifier allowing only whitelisted bill contracts
     * @dev Throws if called by any account other than a whitelisted Bill Contract.
     */
    modifier onlyBillContract() {
        require(billContract[msg.sender], "msg.sender not bill contract");
        _;
    }

    /**
     *  @notice deposit principalToken and receive back payoutToken supporting payoutToken fee
     *  @param _principalTokenAddress Address of the principalToken
     *  @param _amountPrincipalToken Amount of principalToken to transfer into the treasury
     *  @param _amountPayoutToken Amount of payoutToken to transfer to Bill Contract (msg.sender)
     */
    function deposit(
        IERC20Upgradeable _principalTokenAddress,
        uint256 _amountPrincipalToken,
        uint256 _amountPayoutToken
    ) external onlyBillContract() {
        _deposit(_principalTokenAddress, _amountPrincipalToken, _amountPayoutToken, 0, address(0));
    }

    /**
     *  @notice deposit principalToken and receive back payoutToken supporting payoutToken fee
     *  @param _principalTokenAddress Address of the principalToken
     *  @param _amountPrincipalToken Amount of principalToken to transfer into the treasury
     *  @param _amountPayoutToken Amount of payoutToken to transfer to Bill Contract (msg.sender)
     *  @param _feePayoutToken Amount of payoutToken to transfer as a fee
     *  @param _feeReceiver Address which Receives the payoutToken fee 
     */
    function deposit_FeeInPayout(
        IERC20Upgradeable _principalTokenAddress,
        uint256 _amountPrincipalToken,
        uint256 _amountPayoutToken,
        uint256 _feePayoutToken,
        address _feeReceiver
    ) external onlyBillContract() {
        _deposit(_principalTokenAddress, _amountPrincipalToken, _amountPayoutToken, _feePayoutToken, _feeReceiver);
    }

    /**
     *  @notice deposit principalToken and receive back payoutToken supporting payoutToken fee
     *  @param _principalTokenAddress Address of the principalToken
     *  @param _amountPrincipalToken Amount of principalToken to transfer into the treasury
     *  @param _amountPayoutToken Amount of payoutToken to transfer to Bill Contract (msg.sender)
     *  @param _feePayoutToken Amount of payoutToken to transfer as a fee
     *  @param _feeReceiver Address which Receives the payoutToken fee 
     */
    function _deposit(
        IERC20Upgradeable _principalTokenAddress,
        uint256 _amountPrincipalToken,
        uint256 _amountPayoutToken,
        uint256 _feePayoutToken,
        address _feeReceiver
    ) internal {
        _principalTokenAddress.safeTransferFrom(
            msg.sender,
            payoutAddress,
            _amountPrincipalToken
        );
        if(_feePayoutToken > 0) {
            require(_feeReceiver != address(0), "Fee cannot be sent to address(0)");
            IERC20Upgradeable(payoutToken).safeTransfer(_feeReceiver, _feePayoutToken);
            // Transferring directly from Bill to receiver to support fee-on-transfer tokens
            emit PayoutFee(msg.sender, _feeReceiver, _feePayoutToken);
        }
        IERC20Upgradeable(payoutToken).safeTransfer(msg.sender, _amountPayoutToken);
        emit Deposit(msg.sender, _amountPrincipalToken, _amountPayoutToken);
    }

    /* ======== VIEW FUNCTION ======== */

    /**
     *   @notice returns payoutToken valuation of principal
     *   @dev There is a limitation of this function when payoutToken decimals are too small
     *    compared to principalToken decimals. Recommend scaling _amount by 1e18.
     *   @param _principalTokenAddress principal token address 
     *   @param _amount uint principal token amount
     *   @return value_ uint Convert amount from principal decimals to payout decimals
     */
    function valueOfToken(IERC20MetadataUpgradeable _principalTokenAddress, uint256 _amount)
        external
        view
        returns (uint256 value_)
    {
        // convert amount to match payout token decimals
        value_ = (_amount * 10 ** payoutToken.decimals()) / 
        (10 ** _principalTokenAddress.decimals());
    }

    /* ======== OWNER FUNCTIONS ======== */

    /**
     *  @notice owner can withdraw ERC20 token to desired address
     *  @param _token address
     *  @param _destination address
     *  @param _amount uint
     */
    function withdraw(
        address _token,
        address _destination,
        uint256 _amount
    ) external onlyOwner {
        IERC20Upgradeable(_token).safeTransfer(_destination, _amount);

        emit Withdraw(_token, _destination, _amount);
    }

    /**
        @notice toggle bill contract
        @param _billContract Address of CustomBill
        @param _isActive Set the active state of the bill
     */
    function toggleBillContract(address _billContract, bool _isActive) external onlyOwner {
        bool isBillActive = billContract[_billContract];
        require(_isActive != isBillActive, "Bill state not changed");
        if(_isActive) {
            require(address(ICustomBill(_billContract).customTreasury()) == address(this), "Treasury address mismatch");
            require(ICustomBill(_billContract).payoutToken() == payoutToken, "Payout token address mismatch");
        }
        billContract[_billContract] = _isActive;
        emit BillContractToggled(_billContract, _isActive);
    }
}