// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IPaymentSplitter.sol";

/**
 * @title PaymentSplitter
 * @author ChangeDao
 * @notice Implementation contract for royaltiesPSClones and fundingPSClones
 * @dev Modification of OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)
 */
contract PaymentSplitter is IPaymentSplitter, Ownable, Initializable {
    /* ============== Clone State Variables ============== */

    uint256 public override changeDaoShares;
    address payable public override changeDaoWallet;
    bytes32 private constant _CHANGEDAO_FUNDING = "CHANGEDAO_FUNDING";
    bytes32 private constant _CHANGEDAO_ROYALTIES = "CHANGEDAO_ROYALTIES";
    address private constant _ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    IERC20 public immutable override DAI_ADDRESS;
    IERC20 public immutable override USDC_ADDRESS;

    uint256 private _totalShares;
    mapping(address => uint256) private _shares;
    address[] private _payees;

    uint256 private _totalReleasedETH;
    mapping(address => uint256) private _recipientReleasedETH;

    mapping(IERC20 => uint256) private _totalReleasedERC20;
    mapping(IERC20 => mapping(address => uint256))
        private _recipientReleasedERC20;

    /* ============== Receive ============== */

    /**
     * @dev Accepts ETH sent directly to the contract
     */
    receive() external payable virtual override {
        emit ETHPaymentReceived(_msgSender(), msg.value);
    }

    /* ============== Constructor ============== */

    /**
     * @param _daiAddress DAI address
     * @param _usdcAddress USDC address
     */
    constructor(IERC20 _daiAddress, IERC20 _usdcAddress) payable initializer {
        DAI_ADDRESS = _daiAddress;
        USDC_ADDRESS = _usdcAddress;
    }

    /* ============== Initialize ============== */

    /**
     * @notice Initializes the paymentSplitter clone.
     * @param _changeMaker Address of the changeMaker that is making the project
     * @param _contractType Must be bytes32 "CHANGEDAO_FUNDING" or "CHANGEDAO_ROYALTIES"
     * @param _allocations FundingAllocations address
     * @param payees_ Array of recipient addresses
     * @param shares_ Array of share amounts for recipients
     */
    function initialize(
        address _changeMaker,
        bytes32 _contractType,
        IFundingAllocations _allocations,
        address[] memory payees_,
        uint256[] memory shares_
    ) public payable override initializer {
        /** Set changeDao's share amount based on values set per contract type in FundingAllocations contract */
        if (_contractType == _CHANGEDAO_FUNDING) {
            changeDaoShares = _allocations.changeDaoFunding();
        } else if (_contractType == _CHANGEDAO_ROYALTIES) {
            changeDaoShares = _allocations.changeDaoRoyalties();
        } else revert("PS: Invalid contract type");

        changeDaoWallet = payable(_allocations.changeDaoWallet());

        require(
            payees_.length == shares_.length,
            "PS: payees and shares length mismatch"
        );
        require(payees_.length > 0, "PS: no payees");
        require(payees_.length <= 35, "PS: payees exceed 35");
        uint256 sharesSum;

        for (uint256 i = 0; i < payees_.length; i++) {
            _addPayee(payees_[i], shares_[i]);
            sharesSum += shares_[i];
        }
        _addPayee(changeDaoWallet, changeDaoShares);
        sharesSum += changeDaoShares;
        require(sharesSum == 10000, "PS: total shares do not equal 10000");

        emit PaymentSplitterInitialized(
            _changeMaker,
            _contractType,
            IPaymentSplitter(this),
            changeDaoShares,
            changeDaoWallet,
            _allocations
        );
    }

    /* ============== Getter Functions ============== */

    /**
     * @dev Getter for the number of recipient addresses
     */
    function payeesLength() public view override returns (uint256) {
        return _payees.length;
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     * @param _index Index of payee address in _payees array
     */
    function getPayee(uint256 _index) public view override returns (address) {
        return _payees[_index];
    }

    /**
     * @dev Getter for the total shares held by all payees.
     */
    function totalShares() public view override returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleasedETH() public view override returns (uint256) {
        return _totalReleasedETH;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20 contract.
     * @param _token ERC20 token address
     */
    function totalReleasedERC20(IERC20 _token)
        public
        view
        override
        returns (uint256)
    {
        return _totalReleasedERC20[_token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     * @param _account Address of recipient
     */
    function shares(address _account) public view override returns (uint256) {
        return _shares[_account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     * @param _account Address of recipient
     */
    function recipientReleasedETH(address _account)
        public
        view
        override
        returns (uint256)
    {
        return _recipientReleasedETH[_account];
    }

    /**
   * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an IERC20 contract.
   * @param _token ERC20 token address
   * @param _account Address of recipient 

   */
    function recipientReleasedERC20(IERC20 _token, address _account)
        public
        view
        override
        returns (uint256)
    {
        return _recipientReleasedERC20[_token][_account];
    }

    /**
     * @dev Returns the amount of ETH held for a given shareholder.
     * @param _account Address of recipient
     */
    function pendingETHPayment(address _account)
        public
        view
        override
        returns (uint256)
    {
        require(_shares[_account] > 0, "PS: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleasedETH();
        uint256 payment = _pendingPayment(
            _account,
            totalReceived,
            recipientReleasedETH(_account)
        );
        return payment;
    }

    /**
     * @dev Returns the amount of DAI or USDC held for a given shareholder.
     * @param _token ERC20 token address
     * @param _account Address of recipient
     */
    function pendingERC20Payment(IERC20 _token, address _account)
        public
        view
        override
        returns (uint256)
    {
        require(_shares[_account] > 0, "PS: account has no shares");

        uint256 totalReceived = _token.balanceOf(address(this)) +
            totalReleasedERC20(_token);
        uint256 alreadyReleased = recipientReleasedERC20(_token, _account);

        uint256 payment = _pendingPayment(
            _account,
            totalReceived,
            alreadyReleased
        );
        return payment;
    }

    /* ============== Release Functions ============== */

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the total shares and their previous withdrawals.
     * @param _account Address of recipient
     */
    function releaseETH(address payable _account) public virtual override {
        require(_shares[_account] > 0, "PS: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleasedETH();
        uint256 payment = _pendingPayment(
            _account,
            totalReceived,
            recipientReleasedETH(_account)
        );

        if (payment == 0) return;

        _recipientReleasedETH[_account] += payment;
        _totalReleasedETH += payment;

        Address.sendValue(_account, payment);
        emit ETHPaymentReleased(_account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20 contract.
     * @param _token ERC20 token address
     * @param _account Address of recipient
     */
    function releaseERC20(IERC20 _token, address _account)
        public
        virtual
        override
    {
        require(_shares[_account] > 0, "PS: account has no shares");

        uint256 totalReceived = _token.balanceOf(address(this)) +
            totalReleasedERC20(_token);
        uint256 payment = _pendingPayment(
            _account,
            totalReceived,
            recipientReleasedERC20(_token, _account)
        );

        if (payment == 0) return;

        _recipientReleasedERC20[_token][_account] += payment;
        _totalReleasedERC20[_token] += payment;

        SafeERC20.safeTransfer(_token, _account, payment);
        emit StablecoinPaymentReleased(_token, _account, payment);
    }

    /**
     * @dev Convenience function to release an account's ETH, DAI and USDC in one call
     * @param _account Address of recipient
     */
    function releaseAll(address payable _account) public override {
        releaseERC20(DAI_ADDRESS, _account);
        releaseERC20(USDC_ADDRESS, _account);
        releaseETH(_account);
    }

    /**
     * @notice Convenience function to release ETH and ERC20 tokens (not just DAI and USDC)
     * @dev Caller should exclude any tokens with zero balance to avoide wasting gas
     * @dev Any non-ERC20 or ETH addresses will revert
     * @param _account Address of recipient
     * @param _fundingTokens Array of funding token addresses to be released to _account
     */
    function releaseAllFundingTypes(
        address[] memory _fundingTokens,
        address payable _account
    ) external override {
        for (uint256 i; i < _fundingTokens.length; i++) {
            if (_fundingTokens[i] != _ETH_ADDRESS) {
                releaseERC20(IERC20(_fundingTokens[i]), _account);
            } else {
                releaseETH(_account);
            }
        }
    }

    /**
     * @dev ChangeDao can release any funds inadvertently sent to the implementation contract
     */
    function ownerReleaseAll() external override onlyOwner {
        SafeERC20.safeTransfer(
            DAI_ADDRESS,
            owner(),
            DAI_ADDRESS.balanceOf(address(this))
        );
        SafeERC20.safeTransfer(
            USDC_ADDRESS,
            owner(),
            USDC_ADDRESS.balanceOf(address(this))
        );
        Address.sendValue(payable(owner()), address(this).balance);
    }

    /* ============== Internal Functions ============== */

    /**
     * @dev Internal logic for computing the pending payment of an `account` given the token historical balances and already released amounts.
     */
    function _pendingPayment(
        address _account,
        uint256 _totalReceived,
        uint256 _alreadyReleased
    ) private view returns (uint256) {
        return
            (_totalReceived * _shares[_account]) /
            _totalShares -
            _alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param _account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address _account, uint256 shares_) private {
        require(_account != address(0), "PS: account is the zero address");
        require(shares_ > 0, "PS: shares are 0");
        require(_shares[_account] == 0, "PS: account already has shares");

        _payees.push(_account);
        _shares[_account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(_account, shares_);
    }
}