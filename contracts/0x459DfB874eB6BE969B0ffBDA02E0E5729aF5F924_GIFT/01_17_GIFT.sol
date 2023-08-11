// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../ERC20Snapshot.sol";
import "../ERC20Pausable.sol";
import "../IAccess.sol";
import "../por/IReserveConsumerV3.sol";


/**
 * insert token definition here
 */
contract GIFT is Initializable, OwnableUpgradeable, ERC20Pausable, ERC20Snapshot {

    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    address public supplyController;
    address public beneficiary;
    // Access control contract
    address public accessControl;
    address public reserveConsumer;


    mapping(address => bool) public _isExcludedFromFees;
    mapping(address => bool) public _isLiquidityPool;

    uint256 public tierOneTaxPercentage;
    uint256 public tierTwoTaxPercentage;
    uint256 public tierThreeTaxPercentage;
    uint256 public tierFourTaxPercentage;
    uint256 public tierFiveTaxPercentage;

    uint256 public tierOneMax;
    uint256 public tierTwoMax;
    uint256 public tierThreeMax;
    uint256 public tierFourMax;

    event UpdateTaxPercentages(
        uint256 tierOneTaxPercentage,
        uint256 tierTwoTaxPercentage,
        uint256 tierThreeTaxPercentage,
        uint256 tierFourTaxPercentage,
        uint256 tierFiveTaxPercentage
    );

    event UpdateTaxTiers(
        uint256 tierOneMax,
        uint256 tierTwoMax,
        uint256 tierThreeMax,
        uint256 tierFourMax
    );

    event NewSupplyController(address indexed newSupplyController);
    event NewBeneficiary(address indexed newBeneficiary);
    event DelegateTransfer(address sender, address delegator, address receiver, uint256 amount);
    event DelegateApprove(address sender, address delegator, address spender, uint256 amount);

    function initialize(address _accessControl, address _reserveConsumer, address _initialHolder) external initializer {
        __ERC20_init('GIFT', 'GIFT');
        __Ownable_init();
        __ERC20Pausable_init();
        __ERC20Snapshot_init();
        accessControl = _accessControl;

        reserveConsumer = _reserveConsumer;
        _isExcludedFromFees[owner()] = true;
        tierOneTaxPercentage = 1618; // for transferTaxPercentage 1000 is equal to 1%
        tierTwoTaxPercentage = 1200;
        tierThreeTaxPercentage = 1000;
        tierFourTaxPercentage = 500;
        tierFiveTaxPercentage = 300;

        tierOneMax = 2000 * 10**18;
        tierTwoMax = 10000 * 10**18;
        tierThreeMax = 20000 * 10**18;
        tierFourMax = 200000 * 10**18;
        super._mint(_initialHolder, 1000 * 10**18);
    }

    modifier onlySupplyController() {
        require(msg.sender == supplyController, "caller is not the supplyController");
        _;
    }

    modifier onlyManager() {
        require(
            IAccess(accessControl).isSender(msg.sender),
            "GIFT: Only managers is allowed"
        );
        _;
    }


    /**
    * allows specified owner to record all addresses and token balances for each address
    * at the block at which the function is called
    */
    function snapshot() public onlyOwner {
        _snapshot();
    }

    /**
    * computes amount which an address will be taxed upon transferring/selling their tokens
    * according to the amount being transferred (_transferAmount)
    */
    function computeTax(uint256 _transferAmount) public view returns(uint256) {
        uint256 taxPercentage;

        if (_transferAmount <= tierOneMax)
        {
            taxPercentage = tierOneTaxPercentage;
        }

        else if (_transferAmount > tierOneMax && _transferAmount <= tierTwoMax)
        {
            taxPercentage = tierTwoTaxPercentage;
        }

        else if (_transferAmount > tierTwoMax && _transferAmount <= tierThreeMax)
        {
            taxPercentage = tierThreeTaxPercentage;
        }

        else if (_transferAmount > tierThreeMax && _transferAmount <= tierFourMax)
        {
            taxPercentage = tierFourTaxPercentage;
        }

        else
        {
            taxPercentage = tierFiveTaxPercentage;
        }

        return _transferAmount.mul(taxPercentage).div(100000);
    }

    /**
     * @dev ID of the executing chain
     * @return uint value
     */
    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * @notice Get message for the users delegate transfer signature
     */
    function delegateTransferProof(
        bytes32 token,
        address delegator,
        address spender,
        uint256 amount,
        uint256 networkFee
    ) public view returns (bytes32 message) {
        message = keccak256(
            abi.encodePacked(
                getChainID(),
                token,
                amount,
                delegator,
                spender,
                networkFee
            )
        );
    }

    /**
    * allows owner to update tax percentage amounts for each tax tier
    *
    * emits UpdateTaxPercentages event upon calling
    */
    function updateTaxPercentages(
        uint256 _tierOneTaxPercentage,
        uint256 _tierTwoTaxPercentage,
        uint256 _tierThreeTaxPercentage,
        uint256 _tierFourTaxPercentage,
        uint256 _tierFiveTaxPercentage
    ) public onlyOwner {
        tierOneTaxPercentage = _tierOneTaxPercentage;
        tierTwoTaxPercentage = _tierTwoTaxPercentage;
        tierThreeTaxPercentage = _tierThreeTaxPercentage;
        tierFourTaxPercentage = _tierFourTaxPercentage;
        tierFiveTaxPercentage = _tierFiveTaxPercentage;
        emit UpdateTaxPercentages(
            tierOneTaxPercentage,
            tierTwoTaxPercentage,
            tierThreeTaxPercentage,
            tierFourTaxPercentage,
            tierFiveTaxPercentage
        );
    }

    /**
    * allows owner to update tax tier amounts
    *
    * emits UpdateTaxTiers event upon calling
    */
    function updateTaxTiers(
        uint256 _tierOneMax,
        uint256 _tierTwoMax,
        uint256 _tierThreeMax,
        uint256 _tierFourMax
    ) public onlyOwner {
        tierOneMax = _tierOneMax;
        tierTwoMax = _tierTwoMax;
        tierThreeMax = _tierThreeMax;
        tierFourMax = _tierFourMax;
        emit UpdateTaxTiers(
            tierOneMax,
            tierTwoMax,
            tierThreeMax,
            tierFourMax
        );
    }

    /**
    * allows owner to update reserveConsumer
    */
    function updateReserveConsumer(
        address _reserveConsumer
    ) public onlyOwner {
        reserveConsumer = _reserveConsumer;
    }

    /**
    * allows owner to set a supply controller which is a separate address
    * that manages the token total supply
    *
    * emits NewSupplyController event upon calling
    */
    function setSupplyController(address _newSupplyController) public onlyOwner {
        require(_newSupplyController != address(0), "cannot set supply controller to address zero");
        _isExcludedFromFees[supplyController] = false;
        supplyController = _newSupplyController;
        _isExcludedFromFees[supplyController] = true;
        emit NewSupplyController(supplyController);
    }

    /**
    * allows owner to set a beneficiary who will receive the taxes
    * from transfers and sells
    *
    * emits NewSupplyController event upon calling
    */
    function setBeneficiary(address _newBeneficiary) public onlyOwner {
        require(_newBeneficiary != address(0), "cannot set beneficiary to address zero");
        _isExcludedFromFees[beneficiary] = false;
        beneficiary = _newBeneficiary;
        _isExcludedFromFees[beneficiary] = true;
        emit NewBeneficiary(beneficiary);
    }

    /**
    * allows owner to set certain addresses to be excluded from transfer/sell fees
    */
    function setFeeExclusion(address _userAddress, bool _isExcluded) public onlyOwner { // if _isExcluded true, _userAddress will be excluded from fees
        _isExcludedFromFees[_userAddress] = _isExcluded;
    }

    /**
    * allows owner to set certain addresses to be recognized as liquidity pools.
    * This helps the smart contract to differentiate regular transfers from liquidity pool
    * sells and buys
    */
    function setLiquidityPools(address _liquidityPool, bool _isPool) public onlyOwner {
        _isLiquidityPool[_liquidityPool] = _isPool;
    }

    /**
    * allows supply controller to mint tokens to itself
    */
    function increaseSupply(uint256 _value) public onlySupplyController returns (bool success) {
        _mint(supplyController, _value);
        return true;
    }

    /**
    * allows supply controller to burn tokens from an address when they want to redeem
    * their tokens for gold
    */
    function redeemGold(address _userAddress, uint256 _value) public onlySupplyController returns (bool success) {
        _burn(_userAddress, _value);
        return true;
    }

    /**
    * allows owner to pause the contract which will prevent anyone from
    * transferring their tokens
    */
    function pause() public onlyOwner {
        _pause();
    }

    /**
    * allows owner to unpause the contract which will resume the allowance
    * of token transfers
    */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
    * standard ERC20 transfer() with extra functionality to support taxes
    */
    function transfer(
        address recipient,
        uint256 amount) public virtual override whenNotPaused returns (bool) {
        _transferGIFT(_msgSender(), recipient, amount);
        return true;
    }

    /**
    * standard ERC20 transferFrom() with extra functionality to support taxes
    */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override whenNotPaused returns (bool) {
        _transferGIFT(sender, recipient, amount);

        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
        _approve(sender, _msgSender(), currentAllowance - amount);
    }

        return true;
    }

    /**
     * @notice Delegate transfer.
     * @dev only manager can call this function
     * @param signature Sign of user who wants to delegate approve
     * @param delegator User who wants to delegate approve
     * @param spender Contract-spender of user funds
     * @param amount The amount of allowance
     * @param networkFee Commission for manager for delegate trx sending
     */
    function delegateTransfer(
        bytes memory signature,
        bytes32 token,
        address delegator,
        address spender,
        uint256 amount,
        uint256 networkFee
    )
    external
    whenNotPaused
    onlyManager
    returns (bool)
    {
        bytes32 message = delegateTransferProof(
            token,
            delegator,
            spender,
            amount,
            networkFee
        );
        address signer = IAccess(accessControl).preAuthValidations(
            message,
            token,
            signature
        );
        require(signer == delegator, "GIFT: Signer is not delegator");
        _transfer(delegator, msg.sender, networkFee);
        _transferGIFT(delegator, spender, amount);
        emit DelegateTransfer(msg.sender, delegator, spender, amount);
        return true;
    }

    /**
    * standard ERC20 internal transfer function with extra functionality to support taxes
    */
    function _transferGIFT(
        address sender,
        address recipient,
        uint256 amount) internal virtual returns (bool) {

        if (_isLiquidityPool[sender] == true // this is a buy where lp is sender
            || _isExcludedFromFees[sender]) // this is transfer where sender is excluded from fees
        {
            _transfer(sender, recipient, amount);
        }

        else // this is a transfer or a sell where lp is recipient
        {
            uint256 tax = computeTax(amount);
            _transfer(sender, beneficiary, tax);
            _transfer(sender, recipient, amount.sub(tax));
        }
        return true;
    }

    /**
    Standard ERC20 Hook that is called before any transfer of tokens. This includes
    minting and burning.
    */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Pausable, ERC20Snapshot) {
        ERC20Snapshot._beforeTokenTransfer(from, to, amount);

    }


    /**
     * @notice Overriden mint function that checks the specified proof-of-reserves feed to
     * ensure that the supply of the underlying assets is not greater than the reported
     * reserves.
     * @dev The proof-of-reserves check is bypassed if feed is not set.
     * @param account The address to mint tokens to
     * @param amount The amount of tokens to mint
     */
    function _mint(address account, uint256 amount) internal virtual override {
        if (reserveConsumer == address(0)) {
            super._mint(account, amount);
            return;
        }

        // Get latest proof-of-reserves from the feed
        int256 answer = IReserveConsumerV3(reserveConsumer).getLatestReserve();
        require(answer > 0, "GIFT reserve: Invalid answer from PoR feed");

        // Get required info about underlying/reserves supply & decimals
        uint256 reserves = uint256(answer);

        uint256 underlyingSupply = this.totalSupply();
        uint8 underlyingDecimals = this.decimals();
        uint8 reserveDecimals = IReserveConsumerV3(reserveConsumer).decimals();


        // Normalise underlying & reserve decimals
        if (underlyingDecimals < reserveDecimals) {
            underlyingSupply = underlyingSupply.mul(10**uint256(reserveDecimals - underlyingDecimals));
        } else if (underlyingDecimals > reserveDecimals) {
            reserves = reserves.mul(10**uint256(underlyingDecimals - reserveDecimals));
        }

        // Check that the minting does not exceed the reserves
        underlyingSupply = underlyingSupply.add(amount);
        // Check that the supply of underlying tokens is NOT greater than the supply
        // provided by the latest valid proof-of-reserves.
        require(underlyingSupply <= reserves, "GIFT reserve: underlying supply exceeds proof-of-reserves");
        super._mint(account, amount);
    }

}