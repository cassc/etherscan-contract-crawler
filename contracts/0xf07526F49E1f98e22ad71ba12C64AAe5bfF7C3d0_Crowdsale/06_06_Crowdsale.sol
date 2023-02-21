//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens that will be added in
 * a vesting scheme with variable duration, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropiate to concatenate
 * behavior.
 */
contract Crowdsale is Ownable {
    // The token being sold
    ERC20 public token;

    // Address where funds are collected
    address payable private wallet;

    // How many token units a buyer gets per wei
    uint256 private rate;

    // Amount of wei raised
    uint256 public weiRaised;

    bool private isPresaleActive = false;

    uint256 private constant VESTING_DURATION = 365 days; // The period of time (in seconds) over which the vesting occurs
    uint256 private startTime = 0; // The timestamp of activation, when vesting begins

    uint256 public totalAmount; // Sum of all grant amounts
    uint256 public totalClaimed; // Sum of all claimed tokens

    struct Grant {
        uint256 amount;
        uint256 claimed;
    }

    mapping(address => Grant) private grants;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );
    event GrantSet(address recipient, uint256 totalAmount, uint256 addedAmount);
    event GrantClaimed(address recipient, uint256 claimed);
    event VestingStarted(uint256 timestamp);

    /**
     * @param _rate Number of token units a buyer gets per eth
     * @param _wallet Address where collected funds will be forwarded to
     * @param _token Address of the token being sold
     */
    constructor(uint256 _rate, address payable _wallet, ERC20 _token) {
        require(_rate > 0);
        require(_wallet != address(0));

        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

    modifier hasToken() {
        uint256 crowdsaleBalance = token.balanceOf(address(this));
        require(crowdsaleBalance > 0, "Crowdsale: There is no more token!");
        _;
    }

    // -----------------------------------------
    // Crowdsale external interface
    // -----------------------------------------

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     */
    receive() external payable {
        buyTokens(msg.sender);
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * @param _beneficiary Address performing the token purchase
     */
    function buyTokens(address _beneficiary) public payable hasToken {
        require(isPresaleActive, "Crowdsale: presale not active!");
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        require(
            totalAmount + tokens <= token.balanceOf(address(this)),
            "Crowdsale: Token amount exceded the balance of this contract"
        );

        // update state
        weiRaised += weiAmount;

        setGrant(msg.sender, tokens);

        //_processPurchase(_beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

        _updatePurchasingState(_beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(_beneficiary, weiAmount);
    }

    // -----------------------------------------
    // Internal interface (extensible)
    // -----------------------------------------

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    ) pure internal {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    ) internal {
        // optional override
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(
        address _beneficiary,
        uint256 _tokenAmount
    ) internal {
        token.transfer(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
     * @param _beneficiary Address receiving the tokens
     * @param _tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(
        address _beneficiary,
        uint256 _tokenAmount
    ) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
     * @param _beneficiary Address receiving the tokens
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(
        address _beneficiary,
        uint256 _weiAmount
    ) internal {
        // optional override
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(
        uint256 _weiAmount
    ) internal view returns (uint256) {
        return _weiAmount * rate;
    }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    function setIsPresaleActiveOrNotActive(
        bool _isPresaleActive
    ) external onlyOwner {
        if (_isPresaleActive) {
            require(!isPresaleActive, "presale-already-active");
        } else {
            require(isPresaleActive, "presale-already-inactive");
        }
        isPresaleActive = _isPresaleActive;
    }

    function getPresaleState() public view returns (bool) {
        return isPresaleActive;
    }

    // ---------------------------
    // VESTING
    // ---------------------------

    function activate() external onlyOwner {
        require(startTime == 0, "vesting-simple-already-active");
        startTime = block.timestamp;

        emit VestingStarted(startTime);
    }

    function setGrant(address _recipient, uint256 _amount) private {
        Grant storage grant = grants[_recipient];
        require(
            grant.claimed <= (grant.amount + _amount),
            "vesting-simple-bad-amount"
        );

        totalAmount = totalAmount + _amount;
        grant.amount += _amount;

        emit GrantSet(_recipient, grant.amount, _amount);
    }

    function setGrants(
        address[] calldata _recipients,
        uint256[] calldata _amounts
    ) external onlyOwner {
        require(
            _recipients.length == _amounts.length,
            "vesting-simple-bad-inputs"
        );

        for (uint256 i; i < _recipients.length; i++) {
            setGrant(_recipients[i], _amounts[i]);
        }
    }

    function claimGrant() external {
        Grant storage grant = grants[msg.sender];
        uint256 claimable = getClaimable(grant.amount, block.timestamp) -
            grant.claimed;
        require(claimable > 0, "vesting-simple-nothing-to-claim");

        grant.claimed = grant.claimed + claimable;
        totalClaimed = totalClaimed + claimable;

        assert(grant.amount >= grant.claimed);
        assert(totalAmount >= totalClaimed);

        require(
            token.transfer(msg.sender, claimable),
            "vesting-simple-transfer-failed"
        );

        emit GrantClaimed(msg.sender, claimable);
    }

    function getClaimable(
        uint256 _amount,
        uint256 timestamp
    ) internal view returns (uint256) {
        if (timestamp < start() || start() == 0) {
            return 0;
        } else if (timestamp > start() + duration()) {
            return _amount;
        } else {
            return (_amount * (timestamp - start())) / duration();
        }
    }

    function getTokenAmount(address _holder) public view returns (uint256) {
        Grant storage grant = grants[_holder];
        return grant.amount;
    }

    function getTokenClaimed(address _holder) public view returns (uint256) {
        Grant storage grant = grants[_holder];
        return grant.claimed;
    }

    function start() public view returns (uint256) {
        return startTime;
    }

    function duration() public pure returns (uint256) {
        return VESTING_DURATION;
    }
}