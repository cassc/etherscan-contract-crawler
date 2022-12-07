// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../utils/RetrieveTokensFeature.sol';
import '../token/IERC20UpgradeableBurnable.sol';

contract Presale is RetrieveTokensFeature {

    enum State {
         Setup,
         Active,
         Closed
    }

    //The state of the sale
    State private _state;

    // ERC20 basic token contract being held
    IERC20UpgradeableBurnable private _token;

    // beneficiary of tokens (weis) after the sale ends
    address private _beneficiary;

    // How many token units a buyer gets per wei (wei)
    uint256 private _rate;

    // Supply of sale round in smallest token unit 
    uint256 private _totalSupply;
    // Current Supply of sale round in smallest token unit
    uint256 private _currentSupply;

    // Amount of wei raised
    uint256 private _weiRaised;

    /** 
    * Event Sale started
    * @param rate How many token units a buyer gets per wei
    * @param totalSupply of momos 
    */
    event Setup(uint256 rate, uint256 totalSupply);
    
    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchased(address indexed purchaser,
                        uint256 value,
                        uint256 amount);
    
    /**
     * Event for seedsale closed logging
     * @param burned amount of tokens
     */
    event Closed(uint256 burned);
 
    
    constructor() {
        _state = State.Setup;
    }
    


    function state() public view returns (State) {
        return _state;
    }
    function token() public view returns (IERC20UpgradeableBurnable) {
        return _token;
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
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @dev setup the sale
     * @param beneficiary_ beneficiary of tokens (weis) after the sale ends
     * @param rate_ How many momos a buyer gets per wei
     * @param token_ The token to be sold by the contract
     */
    function setup(IERC20UpgradeableBurnable token_,
                    address beneficiary_,
                    uint256 rate_
                ) public onlyOwner {
        require(_state == State.Setup, 'Sale already started');
        require(token_.balanceOf(address(this)) > 0, 'Sale has no Tokens');

        _token = token_;
        _beneficiary = beneficiary_;
        _rate = rate_; 
        _totalSupply = _token.balanceOf(address(this));
        _currentSupply = _token.balanceOf(address(this));
        _weiRaised = 0;
        _state = State.Active;

        emit Setup(_rate, _totalSupply);
    }

    /**
     * @dev buy Tokens according to the rate
     */
    function buyTokens() public payable {
        require(_state == State.Active, 'Sale not active');
        require(_msgSender() != address(0), 'Address 0 as sender is not allowed');
        uint256 weiAmount = msg.value;
        require(weiAmount != 0, 'Wei amount cant be zero');

        // calculate token amount for event, transfere them and update _currentSupply
        uint256 tokens = _getMomoAmount(weiAmount);
        require(tokens <= _currentSupply, 'Too little Tokens');
        _token.transfer(msg.sender, tokens);
        _currentSupply -= tokens;
        _weiRaised += weiAmount;


        emit TokenPurchased(_msgSender(), weiAmount, tokens);
    }
    
    /**
     * @dev close the sale, retrieve ETH to the beneficiary and burn remaining tokens 
     */
    function close() public onlyOwner {
        require(_state == State.Active, 'Seedsale needs to be active state');
        super.retrieveETH(payable(beneficiary()));
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
     * @param _weiAmount Value in wei to momos
     * @return Number of token (momo's) one receives for the _weiAmount
     */
    function _getMomoAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount * rate();
    }
}