// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '../utils/RetrieveTokensFeature.sol';
import '../interfaces/IERC20UpgradeableBurnable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract SaleAffiliateERC20 is RetrieveTokensFeature {
    enum State {
        Setup,
        Active,
        Closed
    }

    //The state of the sale
    State private _state;

    // ERC20 basic token contract being held
    IERC20UpgradeableBurnable private _token;

    //Accepted currency
    IERC20 private _payToken;

    // beneficiary of tokens (payTokens) after the sale ends
    address private _beneficiary;

    // How many token units a buyer gets per payToken unit
    uint256 private _rate;

    // Supply of seed round
    uint256 private _totalSupply;
    // Current Supply of seed round
    uint256 private _currentSupply;

    // Amount of payToken raised
    uint256 private _payTokenRaised;

    // Amount of payToken paid to affiliates
    uint256 private _payTokenPaidToAffiliates;

    /**
     * Event Sale started
     * @param rate How many token s a buyer gets per payToken
     * @param totalSupply of the token to distribute
     */
    event Setup(uint256 rate, uint256 totalSupply);

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param value payTokens paid for purchase
     * @param valueAffiliate payTokens paid to affiliate
     * @param amount amount of tokens purchased
     */
    event TokenPurchased(
        address indexed purchaser,
        address indexed affiliate,
        uint256 value,
        uint256 valueAffiliate,
        uint256 amount
    );

    /**
     * Event for seedsale closed logging
     * @param burned amount of tokens
     */
    event Closed(uint256 burned);

    constructor() {
        _state = State.Setup;
    }

    //View functions
    function state() public view returns (State) {
        return _state;
    }

    function token() public view returns (IERC20UpgradeableBurnable) {
        return _token;
    }

    function payToken() public view returns (IERC20) {
        return _payToken;
    }

    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function currentSupply() public view returns (uint256) {
        return _currentSupply;
    }

    function rate() public view returns (uint256) {
        return _rate;
    }

    function payTokenRaised() public view returns (uint256) {
        return _payTokenRaised;
    }

    function payTokenPaidToAffiliates() public view returns (uint256) {
        return _payTokenPaidToAffiliates;
    }

    /**
     * @dev setup the sale
     * @param beneficiary_ beneficiary of tokens (payTokens) after the sale ends
     * @param rate_ How many token units a buyer gets per payToken
     * @param token_ The token to be sold by the contract
     */
    function setup(
        IERC20UpgradeableBurnable token_,
        IERC20 payToken_,
        address beneficiary_,
        uint256 rate_
    ) public onlyOwner {
        require(_state == State.Setup, 'Sale already started');
        require(token_.balanceOf(address(this)) > 0, 'Sale has no Tokens');

        _token = token_;
        _payToken = payToken_;
        _beneficiary = beneficiary_;
        _rate = rate_;
        _totalSupply = _token.balanceOf(address(this));
        _currentSupply = _token.balanceOf(address(this));
        _payTokenRaised = 0;
        _payTokenPaidToAffiliates = 0;
        _state = State.Active;

        emit Setup(_rate, _totalSupply);
    }

    /**
     * @dev buy Tokens according to the rate.
     * Before calling, msg.Sender needs to call _payToken.approve(x), where x is this contracts address
     * @param affiliate_ the address that gets a share of the invest
     * @param amount_ the amount of _payTokens for the invest
     */
    function buyTokens(address payable affiliate_, uint256 amount_) public {
        require(_state == State.Active, 'Sale not active');
        require(_msgSender() != address(0), 'Address 0 as sender is not allowed');
        require(amount_ != 0, 'Amount cant be zero');

        require(_payToken.allowance(_msgSender(), address(this)) >= amount_, 'insufficient allowance');
        require(_payToken.balanceOf(_msgSender()) >= amount_, 'insufficient funds');
        _payToken.transferFrom(_msgSender(), address(this), amount_);

        // calculate token amount for event, transfere them and update _currentSupply
        uint256 tokens = _getTokenAmount(amount_);
        require(tokens <= _currentSupply, 'Too little Tokens');
        _token.transfer(_msgSender(), tokens);
        _currentSupply -= tokens;

        uint256 payTokenAmountAffiliate = 0;
        if (affiliate_ != address(0)) {
            payTokenAmountAffiliate = (amount_ * 35) / 1000; //_rateAffiliate = 3.5%
            _payToken.transfer(affiliate_, payTokenAmountAffiliate);
            _payTokenPaidToAffiliates += payTokenAmountAffiliate;
        }

        _payTokenRaised += amount_;

        emit TokenPurchased(_msgSender(), affiliate_, amount_, payTokenAmountAffiliate, tokens);
    }

    //Send ETH to beneficiary and burn remaining tokens
    function close() public onlyOwner {
        require(_state == State.Active, 'Seedsale needs to be active state');
        _payToken.transfer(_beneficiary, _payToken.balanceOf(address(this)));
        //super.retrieveETH(payable(beneficiary()));
        uint256 burnAmount = _token.balanceOf(address(this));
        _token.burn(burnAmount);
        _state = State.Closed;
        emit Closed(burnAmount);
    }

    /**
     * @dev retrieve wrongly assigned tokens
     */
    function retrieveTokens(address to, address anotherToken) public override onlyOwner {
        require(address(_token) != anotherToken, 'You should only use this method to withdraw extraneous tokens.');
        super.retrieveTokens(to, anotherToken);
    }

    /**
     * @dev retrieve wrongly assigned tokens
     */
    function retrieveETH(address payable to) public override onlyOwner {
        require(_state == State.Closed, 'Only allowed when closed');
        require(to == beneficiary(), 'You can only transfer tokens to the beneficiary');
        super.retrieveETH(to);
    }

    /**
     * @param payTokenAmount Value in payToken
     * @return Number of token one receives for the payTokenAmount
     */
    function _getTokenAmount(uint256 payTokenAmount) internal view returns (uint256) {
        return payTokenAmount * rate();
    }
}