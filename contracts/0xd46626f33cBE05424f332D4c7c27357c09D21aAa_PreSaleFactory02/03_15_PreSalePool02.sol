// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
//import "../interfaces/IERC20.sol";
import "../interfaces/IPoolFactory.sol";
import "../libraries/TransferHelper.sol";
import "../libraries/Ownable.sol";
import "../libraries/ReentrancyGuard.sol";
//import "../libraries/SafeMath.sol";
import "../libraries/Pausable.sol";
import "../extensions/VispxWhitelist.sol";

contract PreSalePool02 is Ownable, ReentrancyGuard, Pausable, VispxWhitelist {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct OfferedCurrency {
        uint256 decimals;
        uint256 rate;
    }

    // The token being sold
    IERC20 public token;

    // The address of factory contract
    address public factory;

    // The address of signer account
    address public signer;

    // Address where funds are collected
    address public fundingWallet;

    // tax fee
    uint256 public constant ONE = 1e18;
    uint256 public taxRate = 0;

    // Max capacity of token for sale
    uint256 public maxCap = 0;

    // Amount of wei raised
    uint256 public weiRaised = 0;

    // Amount of token sold
    uint256 public tokenSold = 0;

    // Amount of token sold
    uint256 public totalUnclaimed = 0;

    // Number of token user purchased
    mapping(address => uint256) public userPurchased;

    // Number of token user claimed
    mapping(address => uint256) public userClaimed;

    // Number of token user purchased
    mapping(address => mapping(address => uint256)) public investedAmountOf;

    // Get offered currencies
    mapping(address => OfferedCurrency) public offeredCurrencies;

    // Pool extensions
    bool public useWhitelist = true;

    // -----------------------------------------
    // Lauchpad Starter's event
    // -----------------------------------------
    event PresalePoolCreated(
        address token,
        address offeredCurrency,
        uint256 offeredCurrencyDecimals,
        uint256 offeredCurrencyRate,
        uint256 taxRate,
        address wallet,
        address owner
    );
    event TokenPurchaseByEther(
        address indexed purchaser,
        uint256 value,
        uint256 taxFee,
        uint256 amount
    );
    event TokenPurchaseByToken(
        address indexed purchaser,
        address token,
        uint256 value,
        uint256 taxFee,
        uint256 amount
    );

    event TokenClaimed(address user, uint256 amount);
    event EmergencyWithdraw(address wallet, uint256 amount);
    event PoolStatsChanged();
    event CapacityChanged();
    event TokenChanged(address token);
    event SetTaxRate(uint256 taxRate);

    // -----------------------------------------
    // Constructor
    // -----------------------------------------
    constructor() {
        factory = msg.sender;
    }

    // -----------------------------------------
    // Red Kite external interface
    // -----------------------------------------

    /**
     * @dev fallback function
     */
    fallback() external {
        revert();
    }

    /**
     * @dev fallback function
     */
    receive() external payable {
        revert();
    }

    /**
     * @param _token Address of the token being sold
     * @param _offeredCurrency Address of offered token
     * @param _offeredCurrencyDecimals Decimals of offered token
     * @param _offeredRate Number of currency token units a buyer gets
     * @param _wallet Address where collected funds will be forwarded to
     * @param _signer Address where collected funds will be forwarded to
     */
    function initialize(
        address _token,
        address _offeredCurrency,
        uint256 _offeredRate,
        uint256 _offeredCurrencyDecimals,
        uint256 _taxRate,
        address _wallet,
        address _signer
    ) external {
        require(msg.sender == factory, "POOL::UNAUTHORIZED");

        token = IERC20(_token);
        fundingWallet = _wallet;
        owner = tx.origin;
        paused = false;
        signer = _signer;
        taxRate = _taxRate;

        offeredCurrencies[_offeredCurrency] = OfferedCurrency({
            rate: _offeredRate,
            decimals: _offeredCurrencyDecimals
        });

        emit PresalePoolCreated(
            _token,
            _offeredCurrency,
            _offeredCurrencyDecimals,
            _offeredRate,
            _taxRate,
            _wallet,
            owner
        );
    }

    /**
     * @notice Returns the conversion rate when user buy by offered token
     * @return Returns only a fixed number of rate.
     */
    function getOfferedCurrencyRate(address _token)
        public
        view
        returns (uint256)
    {
        return offeredCurrencies[_token].rate;
    }

    /**
     * @notice Returns the conversion rate decimals when user buy by offered token
     * @return Returns only a fixed number of decimals.
     */
    function getOfferedCurrencyDecimals(address _token)
        public
        view
        returns (uint256)
    {
        return offeredCurrencies[_token].decimals;
    }

    /**
     * @notice Return the available tokens for purchase
     * @return availableTokens Number of total available
     */
    function getAvailableTokensForSale()
        public
        view
        returns (uint256 availableTokens)
    {
        return maxCap.sub(tokenSold);
    }

    /**
     *  @notice set tax fee
     *  @param _taxRate rate want to set
     */
    function setTaxRate(uint256 _taxRate) external onlyOwner {
        taxRate = _taxRate;
        emit SetTaxRate(_taxRate);
    }

    /**
     * @notice Owner can set the offered token conversion rate. Receiver tokens = tradeTokens * tokenRate / 10 ** etherConversionRateDecimals
     * @param _rate Fixed number of ether rate
     * @param _decimals Fixed number of ether rate decimals
     */
    function setOfferedCurrencyRateAndDecimals(
        address _token,
        uint256 _rate,
        uint256 _decimals
    ) external onlyOwner {
        offeredCurrencies[_token].rate = _rate;
        offeredCurrencies[_token].decimals = _decimals;
        emit PoolStatsChanged();
    }

    /**
     * @notice Owner can set the offered token conversion rate. Receiver tokens = tradeTokens * tokenRate / 10 ** etherConversionRateDecimals
     * @param _rate Fixed number of rate
     */
    function setOfferedCurrencyRate(address _token, uint256 _rate)
        external
        onlyOwner
    {
        require(offeredCurrencies[_token].rate != _rate, "POOL::RATE_INVALID");
        offeredCurrencies[_token].rate = _rate;
        emit PoolStatsChanged();
    }

    /**
     * @notice Owner can set the offered token conversion rate. Receiver tokens = tradeTokens * tokenRate / 10 ** etherConversionRateDecimals
     * @param _newSigner Address of new signer
     */
    function setNewSigner(address _newSigner) external onlyOwner {
        require(signer != _newSigner, "POOL::SIGNER_INVALID");
        signer = _newSigner;
    }

    /**
     * @notice Owner can set the offered token conversion rate. Receiver tokens = tradeTokens * tokenRate / 10 ** etherConversionRateDecimals
     * @param _decimals Fixed number of decimals
     */
    function setOfferedCurrencyDecimals(address _token, uint256 _decimals)
        external
        onlyOwner
    {
        require(
            offeredCurrencies[_token].decimals != _decimals,
            "POOL::RATE_INVALID"
        );
        offeredCurrencies[_token].decimals = _decimals;
        emit PoolStatsChanged();
    }

    function setMaxCap(uint256 _maxCap) external onlyOwner {
        require(_maxCap > tokenSold, "POOL::INVALID_CAPACITY");
        maxCap = _maxCap;
        emit CapacityChanged();
    }

    /**
     * @notice Owner can set extentions.
     * @param _whitelist Value in bool. True if using whitelist
     */
    function setPoolExtentions(bool _whitelist) external onlyOwner {
        useWhitelist = _whitelist;
        emit PoolStatsChanged();
    }

    function changeSaleToken(address _token) external onlyOwner {
        require(_token != address(0));
        token = IERC20(_token);
        emit TokenChanged(_token);
    }

    function buyTokenByTokenWithPermission(
        address _token,
        uint256 _amount,
        address _candidate,
        bytes memory _signature
    ) public whenNotPaused nonReentrant {
        uint256 taxFee = _getTaxFee(_amount);

        require(
            offeredCurrencies[_token].rate != 0,
            "POOL::PURCHASE_METHOD_NOT_ALLOWED"
        );
        require(
            _verifyWhitelist(_candidate, _amount, _signature),
            "POOL:INVALID_SIGNATURE"
        );

        uint256 tokens = _getOfferedCurrencyToTokenAmount(_token, _amount);

        _forwardTokenFunds(_token, _amount.add(taxFee));

        _updatePurchasingState(_amount, tokens);

        investedAmountOf[_token][_candidate] = investedAmountOf[address(0)][
            _candidate
        ].add(_amount);

        emit TokenPurchaseByToken(msg.sender, _token, _amount, taxFee, tokens);
    }

    /**
     * @notice Emergency Mode: Owner can withdraw token
     * @dev  Can withdraw token in emergency mode
     * @param _wallet Address wallet who receive token
     */
    function emergencyWithdraw(address _wallet, uint256 _amount)
        external
        onlyOwner
    {
        require(
            token.balanceOf(address(this)) >= _amount,
            "POOL::INSUFFICIENT_BALANCE"
        );

        _deliverTokens(_wallet, _amount);
        emit EmergencyWithdraw(_wallet, _amount);
    }

    /**
     * @notice User can receive their tokens when pool finished
     */
    // user purchase: 2000
    // turn 1: 600 400
    /**
     turn 1: 600
     userPurchased = 1400

      */

    function claimTokens(
        address _candidate,
        uint256 _amount,
        bytes memory _signature
    ) public nonReentrant {
        require(
            _verifyClaimToken(_candidate, _amount, _signature),
            "POOL::NOT_ALLOW_TO_CLAIM"
        );
        require(
            _amount >= userClaimed[_candidate],
            "POOL::AMOUNT_MUST_GREATER_THAN_CLAIMED"
        ); // 400 600

        uint256 maxClaimAmount = userPurchased[_candidate].sub(
            userClaimed[_candidate]
        ); // 2000 1400

        uint256 claimAmount = _amount.sub(userClaimed[_candidate]); // 600 1000

        if (claimAmount > maxClaimAmount) {
            claimAmount = maxClaimAmount;
        }

        userClaimed[_candidate] = userClaimed[_candidate].add(claimAmount); // 600 1000

        _deliverTokens(msg.sender, claimAmount);

        totalUnclaimed = totalUnclaimed.sub(claimAmount);

        emit TokenClaimed(msg.sender, claimAmount);
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal
        pure
    {
        require(_beneficiary != address(0), "POOL::INVALID_BENEFICIARY");
        require(_weiAmount != 0, "POOL::INVALID_WEI_AMOUNT");
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param _amount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getOfferedCurrencyToTokenAmount(address _token, uint256 _amount)
        internal
        view
        returns (uint256)
    {
        uint256 rate = getOfferedCurrencyRate(_token);
        uint256 decimals = getOfferedCurrencyDecimals(_token);
        return _amount.mul(rate).div(10**decimals);
    }

    /**
     * @dev Source of tokens. Transfer / mint
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount)
        internal
    {
        require(
            token.balanceOf(address(this)) >= _tokenAmount,
            "POOL::INSUFFICIENT_FUND"
        );
        token.safeTransfer(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds(uint256 _value) internal {
        address payable wallet = address(uint160(fundingWallet));
        (bool success, ) = wallet.call{value: _value}("");
        require(success, "POOL::WALLET_TRANSFER_FAILED");
    }

    /**
     * @dev Determines how Token is stored/forwarded on purchases.
     */
    function _forwardTokenFunds(address _token, uint256 _amount) internal {
        TransferHelper.safeTransferFrom(
            _token,
            msg.sender,
            fundingWallet,
            _amount
        );
    }

    /**
     * @param _tokens Value of sold tokens
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(uint256 _weiAmount, uint256 _tokens)
        internal
    {
        weiRaised = weiRaised.add(_weiAmount);
        tokenSold = tokenSold.add(_tokens);
        userPurchased[msg.sender] = userPurchased[msg.sender].add(_tokens);
        totalUnclaimed = totalUnclaimed.add(_tokens);
    }

    /**vxcvxcvc
     * @dev Transfer eth to an address
     * @param _to Address receiving the eth
     * @param _amount Amount of wei to transfer
     */
    function _transfer(address _to, uint256 _amount) private {
        address payable payableAddress = address(uint160(_to));
        (bool success, ) = payableAddress.call{value: _amount}("");
        require(success, "POOL::TRANSFER_FEE_FAILED");
    }

    /**
     * @dev Verify permission of purchase
     * @param _candidate Address of buyer
     * @param _signature Signature of signers
     */
    function _verifyWhitelist(
        address _candidate,
        uint256 _amount,
        bytes memory _signature
    ) private view returns (bool) {
        require(msg.sender == _candidate, "POOL::WRONG_CANDIDATE");

        if (useWhitelist) {
            return (verify(signer, _candidate, _amount, _signature));
        }
        return true;
    }

    /**
     * @dev Verify permission of purchase
     * @param _candidate Address of buyer
     * @param _amount claimable amount
     * @param _signature Signature of signers
     */
    function _verifyClaimToken(
        address _candidate,
        uint256 _amount,
        bytes memory _signature
    ) private view returns (bool) {
        require(msg.sender == _candidate, "POOL::WRONG_CANDIDATE");

        return (verifyClaimToken(signer, _candidate, _amount, _signature));
    }

    function _getTaxFee(uint256 _amount) private view returns (uint256 fee) {
        fee = _amount.mul(taxRate).div(ONE);
    }
}