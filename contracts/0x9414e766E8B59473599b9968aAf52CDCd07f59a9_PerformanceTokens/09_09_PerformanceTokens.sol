// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PerformanceTokens is ERC20, ReentrancyGuard {
    using SafeERC20 for ERC20;

    /// @dev Constants used across the contract.
    uint256 constant TEN_THOUSAND = 10000;
    uint256 constant MAX_FEE = 10000;
    uint256 constant ONE_YEAR = 31556952;

    address public token;
    address public owner;

    string internal _name;
    string internal _symbol;

    uint256 internal perfFee; // basis points
    uint256 internal lastInterest;

    uint256 internal perfEarned;

    event FeeAccrued(uint256 feeAccrued, uint256 perfEarned);

    constructor(address _token, string memory name_, string memory symbol_, address _owner) ERC20(name_, symbol_) {
        token = _token;
        owner=_owner;
        _name=name_;
        _symbol=symbol_;
        perfFee=50;
    }

    function setName(string memory name) public onlyOwner() {
        _name=name;
    }

    function setSymbol(string memory symbol) public onlyOwner() {
        _symbol=symbol;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function transferOwnership(address _owner) public onlyOwner() {
        owner = _owner;
    }

    function updatePerformanceFee(uint256 _perfFee) public onlyOwner() {
        require(_perfFee<=MAX_FEE, "updatePerformanceFee: must be below max fee");
        perfFee=_perfFee;
    }

    modifier onlyOwner() {
        require(msg.sender==owner, "onlyOwner: not owned.");
        _;
    }

    function accruePerformanceFee() public {
        if (lastInterest != 0 && perfFee > 0) {
            uint256 currentTime = block.timestamp;
            uint256 amount = totalSupply()-perfEarned;
            uint256 timeDelta = currentTime - lastInterest;
            uint256 feeAccrued = (((perfFee * amount) * timeDelta) / ONE_YEAR) / TEN_THOUSAND;
            perfEarned=perfEarned+feeAccrued;
            _mint(owner, feeAccrued);
            emit FeeAccrued(feeAccrued, perfEarned);
        }
        lastInterest = block.timestamp;
    }

    // Enter the bar. Pay some tokens. Earn some shares.
    // Locks Token and mints xToken
    function enter(uint256 _amount) public nonReentrant {
        accruePerformanceFee();

        uint256 totalBalance = ERC20(token).balanceOf(address(this));

        uint256 totalShares = totalSupply();

        if (totalShares == 0 || totalBalance == 0) {
            _mint(msg.sender, _amount);
        } 
        else {
            uint256 what = ( _amount * totalShares ) / (totalBalance);
            _mint(msg.sender, what);
        }

        ERC20(token).transferFrom(msg.sender, address(this), _amount);
    }

    function calculateUnderlying(uint256 _share) public view returns(uint256) {
        uint256 totalShares = totalSupply();
        uint256 what = ( _share * (ERC20(token).balanceOf(address(this)))) / (totalShares);
        return what;
    }

    function leave(uint256 _share) public nonReentrant {
        require(msg.sender != owner, "msg.sender == owner"); //Owner should use withdrawFee instead
        accruePerformanceFee();
        uint256 what = calculateUnderlying(_share);
        _burn(msg.sender, _share);
        ERC20(token).transfer(msg.sender, what);
    }

    function withdrawFee() public onlyOwner() {
        uint256 ownerHeld = balanceOf(owner);
        uint256 what = calculateUnderlying(ownerHeld);
        _burn(msg.sender, ownerHeld);
        ERC20(token).transfer(msg.sender, what);
        perfEarned=0;
    }

    function transferToken(address to, address token_, uint256 amountToken) external onlyOwner() {
        require(token_!=token, "transferToken: cannot transfer principal token.");
        ERC20(token_).transfer(to, amountToken);
    }

    function getPerformanceFee() public view returns(uint256) {
        return perfFee;
    }
}