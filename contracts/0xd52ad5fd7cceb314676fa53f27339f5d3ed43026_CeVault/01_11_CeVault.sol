// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./interfaces/IVault.sol";
import "./interfaces/ICertToken.sol";
contract CeVault is
IVault,
OwnableUpgradeable,
PausableUpgradeable,
ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;

    /**
     * Variables
     */
    string private _name;
    // Tokens
    ICertToken private _ceToken;
    ICertToken private _aMATICc;
    address private _router;
    mapping(address => uint256) private _claimed; // in aMATICc
    mapping(address => uint256) private _depositors; // in aMATICc
    mapping(address => uint256) private _ceTokenBalances; // in aMATICc
    /**
     * Modifiers
     */
    modifier onlyRouter() {
        require(msg.sender == _router, "Router: not allowed");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    function initialize(
        string memory name,
        address ceTokenAddress,
        address aMATICcAddress
    ) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        _name = name;
        _ceToken = ICertToken(ceTokenAddress);
        _aMATICc = ICertToken(aMATICcAddress);
    }
    // deposit
    function deposit(uint256 amount)
    external
    override
    nonReentrant
    returns (uint256)
    {
        revert("not-allowed");
        // return _deposit(msg.sender, amount);
    }
    // deposit
    function depositFor(address recipient, uint256 amount)
    external
    override
    nonReentrant
    onlyRouter
    returns (uint256)
    {
        return _deposit(recipient, amount);
    }
    // deposit
    function _deposit(address account, uint256 amount)
    private
    returns (uint256)
    {
        uint256 ratio = _aMATICc.ratio();
        _aMATICc.transferFrom(msg.sender, address(this), amount);
        uint256 toMint = safeCeilMultiplyAndDivide(amount, 1e18, ratio);
        _depositors[account] += amount; // aMATICc
        _ceTokenBalances[account] += toMint;
        //  mint ceToken to recipient
        ICertToken(_ceToken).mint(account, toMint);
        emit Deposited(msg.sender, account, toMint);
        return toMint;
    }
    function safeCeilMultiplyAndDivide(uint256 a, uint256 b, uint256 c) 
    internal 
    pure 
    returns (uint256) 
    {

        // Ceil (a * b / c)
        uint256 remainder = a.mod(c);
        uint256 result = a.div(c);
        bool safe;
        (safe, result) = result.tryMul(b);
        if (!safe) {
            return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }
        (safe, result) = result.tryAdd(remainder.mul(b).add(c.sub(1)).div(c));
        if (!safe) {
            return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }
        return result;
    }
    function claimYieldsFor(address owner, address recipient)
    external
    override
    onlyRouter
    nonReentrant
    returns (uint256)
    {
        return _claimYields(owner, recipient);
    }
    // claimYields
    function claimYields(address recipient)
    external
    override
    nonReentrant
    returns (uint256)
    {
        return _claimYields(msg.sender, recipient);
    }
    function _claimYields(address owner, address recipient)
    private
    returns (uint256)
    {
        uint256 availableYields = this.getYieldFor(owner);
        require(availableYields > 0, "has not got yields to claim");
        // return back aMATICc to recipient
        _claimed[owner] += availableYields;
        _aMATICc.transfer(recipient, availableYields);
        emit Claimed(owner, recipient, availableYields);
        return availableYields;
    }
    // withdraw
    function withdraw(address recipient, uint256 amount)
    external
    override
    nonReentrant
    returns (uint256)
    {
        revert("not-allowed");
        // return _withdraw(msg.sender, recipient, amount);
    }
    // withdraw
    function withdrawFor(
        address owner,
        address recipient,
        uint256 amount
    ) external override nonReentrant onlyRouter returns (uint256) {
        return _withdraw(owner, recipient, amount);
    }
    function _withdraw(
        address owner,
        address recipient,
        uint256 amount
    ) private returns (uint256) {
        uint256 ratio = _aMATICc.ratio();
        uint256 realAmount = safeCeilMultiplyAndDivide(amount, ratio, 1e18);
        require(
            _aMATICc.balanceOf(address(this)) >= realAmount,
            "not such amount in the vault"
        );
        uint256 balance = _ceTokenBalances[owner];
        require(balance >= amount, "insufficient balance");
        _ceTokenBalances[owner] -= amount; // MATIC
        // burn ceToken from owner
        ICertToken(_ceToken).burn(owner, amount);
        _depositors[owner] -= realAmount; // aMATICc
        _aMATICc.transfer(recipient, realAmount);
        emit Withdrawn(owner, recipient, realAmount);
        return realAmount;
    }
    function getTotalAmountInVault() external view override returns (uint256) {
        return _aMATICc.balanceOf(address(this));
    }
    // yield + principal = deposited(before claim)
    // BUT after claim yields: available_yield + principal == deposited - claimed
    // available_yield = yield - claimed;
    // principal = deposited*(current_ratio/init_ratio)=cetoken.balanceOf(account)*current_ratio;
    function getPrincipalOf(address account)
    external
    view
    override
    returns (uint256)
    {
        uint256 ratio = _aMATICc.ratio();
        return (_ceTokenBalances[account] * ratio) / 1e18; // in aMATICc
    }
    // yield = deposited*(1-current_ratio/init_ratio) = cetoken.balanceOf*init_ratio-cetoken.balanceOf*current_ratio
    // yield = cetoken.balanceOf*(init_ratio-current_ratio) = amount(in aMATICc) - amount(in aMATICc)
    function getYieldFor(address account)
    external
    view
    override
    returns (uint256)
    {
        uint256 principal = this.getPrincipalOf(account);
        if (principal >= _depositors[account]) {
            return 0;
        }
        uint256 totalYields = _depositors[account] - principal;
        if (totalYields <= _claimed[account]) {
            return 0;
        }
        return totalYields - _claimed[account];
    }
    function getCeTokenBalanceOf(address account)
    external
    view
    returns (uint256)
    {
        return _ceTokenBalances[account];
    }
    function getDepositOf(address account) external view returns (uint256) {
        return _depositors[account];
    }
    function getClaimedOf(address account) external view returns (uint256) {
        return _claimed[account];
    }
    function changeRouter(address router) external onlyOwner {
        require(router != address(0));
        _router = router;
        emit RouterChanged(router);
    }
    function getName() external view returns (string memory) {
        return _name;
    }
    function getCeToken() external view returns(address) {
        return address(_ceToken);
    }
    function getAmaticcAddress() external view returns(address) {
        return address(_aMATICc);
    }
    function getRouter() external view returns(address) {
        return address(_router);
    }
}