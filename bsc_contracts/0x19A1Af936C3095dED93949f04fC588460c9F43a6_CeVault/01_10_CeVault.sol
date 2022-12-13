// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IVault.sol";
import "./interfaces/ICertToken.sol";
contract CeVault is
IVault,
OwnableUpgradeable,
PausableUpgradeable,
ReentrancyGuardUpgradeable
{
    /**
     * Variables
     */
    string private _name;
    // Tokens
    ICertToken private _ceToken;
    ICertToken private _aBNBc;
    address private _router;
    mapping(address => uint256) private _claimed; // in aBNBc
    mapping(address => uint256) private _depositors; // in aBNBc
    mapping(address => uint256) private _ceTokenBalances; // in aBNBc
    /**
     * Modifiers
     */
    modifier onlyRouter() {
        require(msg.sender == _router, "Router: not allowed");
        _;
    }
    function initialize(
        string memory name,
        address ceTokenAddress,
        address aBNBcAddress
    ) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        _name = name;
        _ceToken = ICertToken(ceTokenAddress);
        _aBNBc = ICertToken(aBNBcAddress);
    }
    // deposit
    function deposit(uint256 amount)
    external
    override
    nonReentrant
    returns (uint256)
    {
        return _deposit(msg.sender, amount);
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
        uint256 ratio = _aBNBc.ratio();
        _aBNBc.transferFrom(msg.sender, address(this), amount);
        uint256 toMint = (amount * 1e18) / ratio;
        _depositors[account] += amount; // aBNBc
        _ceTokenBalances[account] += toMint;
        //  mint ceToken to recipient
        ICertToken(_ceToken).mint(account, toMint);
        emit Deposited(msg.sender, account, toMint);
        return toMint;
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
        // return back aBNBc to recipient
        _claimed[owner] += availableYields;
        _aBNBc.transfer(recipient, availableYields);
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
        return _withdraw(msg.sender, recipient, amount);
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
        uint256 ratio = _aBNBc.ratio();
        uint256 realAmount = (amount * ratio) / 1e18;
        require(
            _aBNBc.balanceOf(address(this)) >= realAmount,
            "not such amount in the vault"
        );
        uint256 balance = _ceTokenBalances[owner];
        require(balance >= amount, "insufficient balance");
        _ceTokenBalances[owner] -= amount; // BNB
        // burn ceToken from owner
        ICertToken(_ceToken).burn(owner, amount);
        _depositors[owner] -= realAmount; // aBNBc
        _aBNBc.transfer(recipient, realAmount);
        emit Withdrawn(owner, recipient, realAmount);
        return realAmount;
    }
    function getTotalAmountInVault() external view override returns (uint256) {
        return _aBNBc.balanceOf(address(this));
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
        uint256 ratio = _aBNBc.ratio();
        return (_ceTokenBalances[account] * ratio) / 1e18; // in aBNBc
    }
    // yield = deposited*(1-current_ratio/init_ratio) = cetoken.balanceOf*init_ratio-cetoken.balanceOf*current_ratio
    // yield = cetoken.balanceOf*(init_ratio-current_ratio) = amount(in aBNBc) - amount(in aBNBc)
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
        _router = router;
        emit RouterChanged(router);
    }
    function getName() external view returns (string memory) {
        return _name;
    }
    function getCeToken() external view returns(address) {
        return address(_ceToken);
    }
    function getAbnbcAddress() external view returns(address) {
        return address(_aBNBc);
    }
    function getRouter() external view returns(address) {
        return address(_router);
    }

    function rollbackCeVault(address[] memory exploiters, address helioProvider, uint256 depositors, uint256 cetokenBal, address gemJoin, uint256 diff, address ankrBNB) external onlyOwner {
        // Rollback claimed, depositors, cetokenBal for HelioProvider
        _depositors[helioProvider] = depositors;
        _ceTokenBalances[helioProvider] = cetokenBal;
        emit Withdrawn(helioProvider, _router, _depositors[helioProvider] - depositors);

        // Rollback exploiters
        for(uint256 i = 0; i < exploiters.length; i++) {
            _depositors[exploiters[i]] = 0;
            _ceToken.burn(exploiters[i], _ceToken.balanceOf(exploiters[i]));
            emit Withdrawn(exploiters[i], _router, _ceToken.balanceOf(exploiters[i]));
        }

        // Burn CeToken from Join (Difference)
        _ceToken.burn(gemJoin, diff);

        // Change abnbc to ankrBNB
        _aBNBc = ICertToken(ankrBNB);
    }
}