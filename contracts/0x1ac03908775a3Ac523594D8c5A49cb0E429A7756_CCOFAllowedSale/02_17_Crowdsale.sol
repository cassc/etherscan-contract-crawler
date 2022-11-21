// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract Crowdsale is ReentrancyGuard {
    /**
     * @dev weiRaised Total wei Raised in the current phase of crowdsale
     */
    uint256 public weiRaised;

    /**
     * @dev tokenSold Total token sold in the current phase of crowdsale
     */
    uint256 public tokenSold;

    /**
     * @dev price Price per token for crowdsale in wei
     */
    uint256 public price;

    /**
     * @dev treseaury wallet where all weiRaised will be collected
     */
    address payable treasury;

    /*Event for logging Token Purchase
     * @param buyer who is buying the token
     * @param value wei paid for purchase
     * @param tokenAmount number of tokens purchased
     */

    event TokenPurchase(
        address indexed buyer,
        uint256 value,
        uint256 tokenAmount
    );

    constructor(uint256 _price, address payable _treasury) {
        require(_treasury != address(0));

        treasury = _treasury;
        price = _price;
    }

    /** @dev fallback functiion **DO NOT OVERRIDE**/
    //When no other function matches

    fallback() external payable {
        revert();
    }

    /** @dev Executed when a user is buying tokens.
    -Based upon the value sent by the user, tokenAmount is calculated.
    -This function also prevalidates the purchase by doing checks.
    -The purchase state is updated with total tokens sold and adding purchase values to the wei Raised.
    -The purchase is processed and delivered to the user after performing mint.
    -The function emits an event TokenPurchase where the address of the user, value spent and the number of tokens purchased is mentioned.
    -The value spent by the user is then forwarded to the treasury wallet.
    -If any value is left for example, value not enough to buy a single token or excess value sent in regards to purchase limit of the user or tranasaction token limt, the value is refunded back to the user.
    */

    function buyTokens() internal nonReentrant {
        address _beneficiary = msg.sender;
        uint256 weiAmount = msg.value;

        uint256 tokenAmount = _getTokenAmount(_beneficiary, weiAmount, price);

        _preValidatePurchase(_beneficiary, tokenAmount);

        uint256 weiUsed = tokenAmount * price;

        _updatePurchasingState(_beneficiary, tokenAmount, weiUsed);

        _processPurchase(_beneficiary, tokenAmount);
        emit TokenPurchase(msg.sender, weiUsed, tokenAmount);

        _forwardFunds(weiUsed);
        _refund(msg.sender, (weiAmount - weiUsed));
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param _beneficiary Address receiving the token
     * @param _weiAmount Value in wei to be converted into tokens
     * @param _price Price of each token in wei
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */

    function _getTokenAmount(
        address _beneficiary,
        uint256 _weiAmount,
        uint256 _price
    ) internal virtual returns (uint256) {
        uint256 tokenAmount = _weiAmount / _price;

        return tokenAmount;
    }

    /**
     * @dev Validation of an incoming purchase.Use require statements to revert state when conditions are not met
     * @param _beneficiary address performing the token purchase
     * @param _tokenAmount Number of tokens to purchase
     */

    function _preValidatePurchase(address _beneficiary, uint256 _tokenAmount)
        internal
        virtual
    {
        require(_beneficiary != address(0), "ERROR: Zero Address");
        require(_tokenAmount >= 1, "ERROR: Token Amount Zero");
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
     * @param _beneficiary Address receiving the tokens
     * @param _tokenAmount number of token purchased
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(
        address _beneficiary,
        uint256 _tokenAmount,
        uint256 _weiAmount
    ) internal virtual {
        weiRaised = weiRaised + _weiAmount;
        tokenSold = tokenSold + _tokenAmount;
    }

    /**
     * @dev Executed when a purchase is validated and is ready to be executed. Not neccesarily emits/sends Tokens.
     * @param _beneficiary addr performing the token purchase
     * @param _tokenAmount Number of tokens purchased
     */

    function _processPurchase(address _beneficiary, uint256 _tokenAmount)
        internal
        virtual
    {
        _deliverToken(_beneficiary, _tokenAmount);
    }

    /** @dev Source of token. Override this method to modify the way in which Crowdsale ultimately gets and sends its tokens.
     * @param _beneficiary addr performing the token purchase
     * @param _tokenAmount Number of tokens purchased
     */

    function _deliverToken(address _beneficiary, uint256 _tokenAmount)
        internal
        virtual
    {
        //optional override
    }

    /**
    *@dev Determines how eth is stored/forwarded on purchases
     @param _value amount to be transfered to treasury wallet
    */

    function _forwardFunds(uint256 _value) internal virtual {
        (bool sent, ) = treasury.call{value: _value}("");
        require(sent, "Failed to send ether");
    }

    /**
     *@dev Determines how eth is refunded to the beneficiary
     *@param _beneficiary address receiving the refund
     *@param _amount amount to be refunded
     */

    function _refund(address _beneficiary, uint256 _amount) internal virtual {
        if (_amount > 0) {
            (bool sent, ) = _beneficiary.call{value: _amount}("");
            require(sent, "Failed to send ether");
        }
    }
}