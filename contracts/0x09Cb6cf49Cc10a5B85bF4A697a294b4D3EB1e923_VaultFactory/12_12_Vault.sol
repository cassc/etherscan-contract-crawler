// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "./interfaces/IVault.sol";

contract Vault is IVault {

    /* ========== STATES ========== */

    IVaultFactory public immutable override factory;
    address public override owner;
    uint public override deposited;
    uint public override minted;

    /* ========== CONSTRUCTOR ========== */

    constructor() {
        factory = IVaultFactory(msg.sender);
    }

    // Called once by the factory on deployment
    function initialize(address _owner) external override {
        require(msg.sender == address(factory), '!factory');
        owner = _owner;
    }

    /* ========== VIEWS ========== */

    function availableBalance() public view override returns (uint) {
        if (factory.collateral().balanceOf(address(this)) < deposited) {
            // On extreme unlike scenario of multiple large negative rebases, vault balance can become < than deposited.
            // In this case vault owner need to transfer in stETH and make up for the diff before withdrawing.
            // This ensures collateral > debt at all times.
            return 0;
        } else {
            return deposited - minted;
        }
    }

    function pendingYield() public view override returns (uint) {
        uint balance = factory.collateral().balanceOf(address(this));
        return balance < deposited ? 0 : balance - deposited;
    }

    function mintRatio() public view override returns (uint) {
        if (deposited == 0) {
            return 0;
        }
        return minted * factory.PRECISION() / deposited;
    }

    // Calculate protocol fee based on mint ratio
    function protocolFee() public view override returns (uint) {
        return mintRatio() * factory.maxProtocolFee() / factory.PRECISION();
    }

    // Calculate redemption fee based on mint ratio
    function redemptionFee() public view override returns (uint) {
        return factory.minRedemptionFee() + factory.maxRedemptionAdjustment() * (factory.PRECISION() - mintRatio()) / factory.PRECISION();
    }

    /* ========== USER FUNCTIONS ========== */

    // Deposit collateral from msg.sender to vault
    function deposit(uint _amount) external override onlyManagerOrOwner() returns (uint) {
        claim();
        // stETH have known rounding error on transfers by 1-2 wei
        uint before = factory.collateral().balanceOf(address(this));
        factory.collateral().transferFrom(msg.sender, address(this), _amount);
        uint actualAmount = factory.collateral().balanceOf(address(this)) - before;
        deposited += actualAmount;
        emit Deposit(actualAmount);
        return actualAmount;
    }

    // Withdraw available collateral to owner
    function withdraw(uint _amount) external override onlyManagerOrOwner() {
        claim();
        _withdraw(_amount, owner);
        emit Withdraw(_amount);
    }

    // Mint token to vault owner using available collateral
    function mint(uint _amount) external override onlyManagerOrOwner() {
        claim();
        require(availableBalance() >= _amount, "!available");
        factory.token().mint(owner, _amount);
        minted += _amount;
        emit Mint(_amount);
    }

    // Burn token from msg.sender for vault
    function burn(uint _amount) external override onlyManagerOrOwner() {
        claim();
        _burn(_amount);
        emit Burn(_amount);
    }

    // Claim pending yield into deposited, pay protocol fee
    function claim() public override {
        uint yield = pendingYield();
        uint fee = yield * protocolFee() / factory.PRECISION();
        factory.collateral().transfer(factory.protocolFeeTo(), fee);
        deposited += yield - fee;
        emit Claim(yield - fee, fee);
    }

    // Redeem collateral from vault by burning token from msg.sender and paying redemption fee
    function redeem(uint _amount) external {
        uint fee = _amount * redemptionFee() / factory.PRECISION();
        claim();
        _burn(_amount);
        _withdraw(fee, factory.redemptionFeeTo());
        _withdraw(_amount - fee, msg.sender);
        emit Redeem(msg.sender, _amount, fee);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _burn(uint _amount) internal {
        require(minted >= _amount, "!minted");
        factory.token().transferFrom(msg.sender, address(this), _amount);
        factory.token().burn(_amount);
        minted -= _amount;
    }

    function _withdraw(uint _amount, address _recipient) internal {
        require(availableBalance() >= _amount, "!available");
        deposited -= _amount;
        factory.collateral().transfer(_recipient, _amount);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyManagerOrOwner() {
        require(msg.sender == owner || factory.isVaultManager(msg.sender), "!allowed");
        _;
    }

    /* ========== EVENTS ========== */

    event Deposit(uint amount);
    event Withdraw(uint amount);
    event Mint(uint amount);
    event Burn(uint amount);
    event Claim(uint yieldAfterProtocolFee, uint protocolFee);
    event Redeem(address indexed redeemer, uint amount, uint redemptionFee);
}