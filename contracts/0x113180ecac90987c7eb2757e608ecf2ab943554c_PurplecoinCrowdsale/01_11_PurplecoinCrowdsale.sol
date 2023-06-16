pragma solidity ^0.4.24;

/// @custom:security-contact [email protected]

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import './MathHelp.sol';
import "./Ownable.sol";

contract Purplecoin is ERC20Detailed, ERC20Mintable, ERC20Burnable {
    constructor() public ERC20Detailed("Purplecoin", "XPU", 18) {}

    /**
     * Event for burning tokens
     * @param burner The address burning the tokens
     * @param value amount of tokens burnt
     * @param message burn additional data
     */
    event TokenBurn(
        address burner,
        uint256 value,
        string message
    );

    /**
     * @dev Burn tokens with message. Used to transfer coins to the main chain when message is a Purplecoin address.
     * @param value amount of tokens to be burnt
     * @param message additional data
     */
    function burn(uint256 value, string message) public {
        super.burn(value);
        emit TokenBurn(msg.sender, value, message);
    }

    /**
     * @dev Burn tokens from address with message. Used to transfer coins to the main chain when message is a Purplecoin address.
     * @param account account to burn tokens from
     * @param value amount of tokens to be burnt
     * @param message additional data
     */
    function burnFrom(address account, uint256 value, string message) public {
        super.burnFrom(account, value);
        emit TokenBurn(account, value, message);
    }
}

contract PurplecoinCrowdsale is Ownable {
    using SafeMath for uint256;

    uint256 stage = 0;

    // Mapping of KYC authorisations
    mapping(address => bool) public kyc_authorised;

    // Mapping of Pending purchases 
    mapping(address => bool) public pending;

    // Mapping of pending Wei
    mapping(address => uint256) public pending_wei;

    // Mapping of pending psats 
    mapping(address => uint256) public pending_psats;

    // Balances
    mapping(address => uint256) private _balances;

    // Wei raised per address
    mapping(address => uint256) private _wei_raised_per_address;

    MathHelp math = new MathHelp();

    // Amount sold, refunded, and in escrow
    // --------------------------
    uint256 public totalPsatsInEscrow;
    uint256 public totalWeiInEscrow;
    uint256 public totalSoldPsats;
    uint256 public totalWeiInSettledEscrow;

    // -----------------------
    uint256 public tokensCap;
    uint256 public individualTokensCap;
    uint256 private bonus;
    uint256[] private WAVE_CAPS;
    uint256[] private WAVE_BONUSES;
    bool public isFinalized;
    ERC20Mintable public token;

    // Address where funds are collected
    address public wallet;

    // How many token units a buyer gets per wei
    uint256 public rate;

    // Amount of wei raised
    uint256 public weiRaised;

    // Minimum buy amount
    uint256 public minBuy;

    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor(uint256 _rate, uint256 _coins, uint256[] _waveCaps, uint256[] _waveBonuses, address _wallet) public {
        wallet = _wallet;
        uint256 decimals = 10 ** 18; // 18 decimal places
        tokensCap = _coins * decimals;
        _waveCaps[0] = 37999000000000000000000000;
        _waveCaps[1] = 75998000000000000000000000;
        _waveCaps[2] = 113997001000000000000000000;
        individualTokensCap = 500000000000000000000000; // Max 500,000 XPU per person 
        minBuy = 10000000000000000; // 0.01 ETH min buy
        rate = _rate;
        token = createTokenContract();
        WAVE_CAPS = _waveCaps;
        WAVE_BONUSES = _waveBonuses;
        setCrowdsaleStage(0); //set in pre Sale stage

        // Init balances
        _balances[0x25E320b95316bAA3d300155aD82A0aEBEE400E66] = 1821600000000000000000; // https://etherscan.io/tx/0x7ae5653adfdeb4f0ec8c7d1e3de11edbc84cac4c0a6fbf5141a9c49b5481497b

        // Dev fund, 0.5% of the supply
        _balances[0x130fCeAD624C57aB46EF073bd1a940ACF8Bf2c85] = 11399700000000000000000000;

        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    // ==============================

    // Events
    // ---------------------
    event EthTransferred(uint256 amount);
    event PurchaseCancelled(address indexed beneficiary);
    event KycAuthorised(address indexed beneficiary);
    event IncrementWave(uint256 newWave);
    event TokenMint(address indexed beneficiary, uint256 amount);
    event CrowdsaleFinalized();

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
        bool authorised,
        uint256 value,
        uint256 amount
    );

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer fund with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */
    function () external payable {
        buyTokens(msg.sender);
    }

    /**
     * @dev Reverts if beneficiary is not authorized. Can be used when extending this contract.
     * @param _beneficiary beneficiary address
     */
    modifier isAuthorised(address _beneficiary) {
        require(kyc_authorised[_beneficiary]);
        _;
    }

    /**
     * @dev Reverts if beneficiary is not pending. Can be used when extending this contract.
     */
    modifier isPending(address _beneficiary) {
        require(pending[_beneficiary]);
        _;
    }

    // Reentrancy Guard
    // -----------------------

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }

    // Post delivery
    // -----------------------

    /**
     * @dev Withdraw tokens only after crowdsale ends.
     * @param _beneficiary Whose tokens will be withdrawn.
     */
    function withdrawTokens(address _beneficiary) nonReentrant public {
        require(isFinalized);
        uint256 amount = _balances[_beneficiary];
        require(amount > 0);
        _balances[_beneficiary] = 0;
        _deliverTokens(_beneficiary, amount);
    }

    /**
     * @return the balance of an account.
     */
    function balanceOf(address account) public view returns(uint256) {
        return _balances[account];
    }

    // Crowdsale Stages
    // -----------------------

    // Change Crowdsale Stage.
    function setCrowdsaleStage(uint256 _stage) private {
        setCurrentBonus(WAVE_BONUSES[_stage]);
        stage = _stage;
    }

    function getCurrentStage() public constant returns (uint256){
        return stage;
    }


    function currentWaveCap() public constant returns (uint256) {
        return WAVE_CAPS[stage];
    }

    function incrementWave() private {
        stage = stage + 1;
        emit IncrementWave(stage);
        return;
    }

    // Change the current bonus
    function setCurrentBonus(uint256 _bonus) private {
        bonus = _bonus;
        return;
    }

    //---------------------------end stages----------------------------------

    // creates the token to be sold.
    // override this method to have crowdsale of a specific ERC20Mintable token.
    function createTokenContract() internal returns (ERC20Mintable) {
        return new Purplecoin();
    }

    function _shouldIncrementWave(uint256 _currentWaveCap) constant internal returns (bool){
        return totalSoldPsats.add(totalPsatsInEscrow) >= _currentWaveCap;
    }

    // Override to execute any logic once the crowdsale finalizes
    // Requires a call to the public finalize method
    function finalization() internal {
        // mint the rest of the tokens
        // if (token.totalSupply() < tokensCap) {
        //     mintTokens(remainingTokensWallet, tokensCap.sub(token.totalSupply()));
        // }
        //no more tokens from now on
        //token.finishMinting();
        emit CrowdsaleFinalized();
    }

    function finalize() public onlyOwner {
        require(!isFinalized);
        finalization();
        isFinalized = true;
    }

    function clearWeiInSettledEscrow() public onlyOwner {
        require(totalWeiInSettledEscrow > 0);
        wallet.transfer(totalWeiInSettledEscrow);
        emit EthTransferred(totalWeiInSettledEscrow);
        totalWeiInSettledEscrow = 0;
    }


    function mintTokens(address _beneficiary, uint256 tokens) internal {
        require(_beneficiary != 0x0);
        // Cannot mint before sale is closed
        require(isFinalized);
        token.mint(_beneficiary, tokens);
        emit TokenMint(_beneficiary, tokens);
    }

    /**
     * @dev Update the rate
     * @param _rate new rate
     */
    function updateRate(uint256 _rate) public onlyOwner {
        require(!isFinalized);
        rate = _rate;
    }

    /**
     * @dev Update the minBuy
     * @param _minBuy new minBuy
     */
    function updateMinBuy(uint256 _minBuy) public onlyOwner {
        require(!isFinalized);
        minBuy = _minBuy;
    }

    /**
     * @dev Update the individualTokensCap
     * @param _individualTokensCap new individualTokensCap
     */
    function updateIndividualTokensCap(uint256 _individualTokensCap) public onlyOwner {
        require(!isFinalized);
        individualTokensCap = _individualTokensCap;
    }

    // KYC
    // -----------------------

    /**
     * @dev Authorise token transfer for address.
     * @param _beneficiary beneficiary address
     */
    function authorise(address _beneficiary) public nonReentrant isPending(_beneficiary) onlyOwner {
        emit KycAuthorised(_beneficiary);
        _forwardPendingFunds(_beneficiary);
    }

    /**
     * @dev Authorise token transfers for a batch of addresses.
     * @param _beneficiaries Beneficiaries array
     */
    function authoriseMany(address[] _beneficiaries) external nonReentrant onlyOwner {
        for(uint256 i=0; i < _beneficiaries.length; i++) {
            authorise(_beneficiaries[i]);
        }
    }

    function withdrawalAllowed(address _beneficiary) public view returns(bool) {
        return kyc_authorised[_beneficiary];
    }

    // Crowdsale overrides
    // -----------------------

    // Override this method to have a way to add business logic to your crowdsale when buying
    // Returns weiAmount times rate by default
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return rate.mul(weiAmount.add(math.getPercentAmount(weiAmount, bonus, 18)));
    }

    function cancelPurchase() public nonReentrant isPending(msg.sender) {
        require(pending_wei[msg.sender] != 0);
        uint256 to_refund = pending_wei[msg.sender];
        totalWeiInEscrow = totalWeiInEscrow.sub(pending_wei[msg.sender]);
        totalPsatsInEscrow = totalPsatsInEscrow.sub(pending_psats[msg.sender]);
        pending[msg.sender] = false;
        pending_wei[msg.sender] = 0;
        pending_psats[msg.sender] = 0;
        msg.sender.transfer(to_refund);
        emit PurchaseCancelled(msg.sender);
    }

    function cancelPurchaseFor(address _beneficiary) public nonReentrant isPending(_beneficiary) onlyOwner {
        require(pending_wei[_beneficiary] != 0);
        uint256 to_refund = pending_wei[_beneficiary];
        totalWeiInEscrow = totalWeiInEscrow.sub(pending_wei[_beneficiary]);
        totalPsatsInEscrow = totalPsatsInEscrow.sub(pending_psats[_beneficiary]);
        pending[_beneficiary] = false;
        pending_wei[_beneficiary] = 0;
        pending_psats[_beneficiary] = 0;
        _beneficiary.transfer(to_refund);
        emit PurchaseCancelled(_beneficiary);
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * @param _beneficiary Address performing the token purchase
     */
    function buyTokens(address _beneficiary) public nonReentrant payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, kyc_authorised[_beneficiary], weiAmount, tokens);

        _forwardFunds(_beneficiary);
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *   super._preValidatePurchase(beneficiary, weiAmount);
     *   require(weiRaised().add(weiAmount) <= cap);
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
    */
    function _preValidatePurchase(
        address beneficiary,
        uint256 weiAmount
    )
        internal
        view
    {
        uint256 tokenAmount = _getTokenAmount(weiAmount);
        require(beneficiary != address(0));
        require(_wei_raised_per_address[beneficiary].add(pending_wei[beneficiary]).add(weiAmount) >= minBuy);    // Min buy
        require(!isFinalized);
        require(_balances[beneficiary].add(pending_psats[beneficiary]).add(tokenAmount) <= individualTokensCap); // Individual cap
        require(tokenAmount.add(totalSoldPsats).add(totalPsatsInEscrow) <= tokensCap);                           // Sale cap
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) 
        internal 
        isAuthorised(_beneficiary) 
    {
        mintTokens(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
     * @param _beneficiary Address receiving the tokens
     * @param _tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount)
        internal
    {
        if (kyc_authorised[_beneficiary]) {
            weiRaised = weiRaised.add(msg.value);
            _wei_raised_per_address[_beneficiary] = _wei_raised_per_address[_beneficiary].add(msg.value);
            _balances[_beneficiary] = _balances[_beneficiary].add(_tokenAmount);
            totalSoldPsats = totalSoldPsats.add(_tokenAmount);
        } else {
            kyc_authorised[_beneficiary] = false;
            pending[_beneficiary] = true;
            pending_psats[_beneficiary] = pending_psats[_beneficiary].add(_tokenAmount);
            totalPsatsInEscrow = totalPsatsInEscrow.add(_tokenAmount);
            if (_shouldIncrementWave(currentWaveCap())) {
                incrementWave();
            }
        }
    }

    // Override to create custom fund forwarding mechanisms
    // Forwards funds to the specified wallet by default
    function _forwardFunds(address _beneficiary) internal {
        if (kyc_authorised[_beneficiary]) {
            if (_shouldIncrementWave(currentWaveCap())) {
                incrementWave();
            }
            totalWeiInSettledEscrow = totalWeiInSettledEscrow.add(msg.value);
        } else {
            pending_wei[_beneficiary] = pending_wei[_beneficiary].add(msg.value);
            totalWeiInEscrow = totalWeiInEscrow.add(msg.value);
        }
    }

    // Override to create custom pending fund forwarding mechanisms
    // Forwards funds to the specified wallet by default
    function _forwardPendingFunds(address _beneficiary) internal {
        weiRaised = weiRaised.add(pending_wei[_beneficiary]);
        _wei_raised_per_address[_beneficiary] = _wei_raised_per_address[_beneficiary].add(pending_wei[_beneficiary]);
        totalWeiInEscrow = totalWeiInEscrow.sub(pending_wei[_beneficiary]);
        totalSoldPsats = totalSoldPsats.add(pending_psats[_beneficiary]);
        totalPsatsInEscrow = totalPsatsInEscrow.sub(pending_psats[_beneficiary]);
        
        _balances[_beneficiary] = _balances[_beneficiary].add(pending_psats[_beneficiary]);
        wallet.transfer(pending_wei[_beneficiary]);
        emit EthTransferred(pending_wei[_beneficiary]);

        pending_wei[_beneficiary] = 0;
        pending_psats[_beneficiary] = 0;
        kyc_authorised[_beneficiary] = true;
        pending[_beneficiary] = false;
    }
}