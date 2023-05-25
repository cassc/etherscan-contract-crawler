// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "erc-payable-token/contracts/token/ERC1363/ERC1363.sol";

contract KickToken is ERC1363, ERC20Permit, Pausable, AccessControl {
    uint8 private _decimals;
    uint256 private _tTotal; // token total
    uint256 private _rTotal; // reflection total

    mapping(address => uint256) private _rOwned; // reflection balance

    // no burn and distribution if transfer to these addresses
    mapping(address => bool) private _isNoIncomeFee;
    uint256 private _distributionPercent;
    uint256 private _burnPercent;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant UNPAUSED_ROLE = keccak256("UNPAUSED_ROLE");

    event DistributionPercentChanged(uint256 value);
    event BurnPercentChanged(uint256 value);
    event NoIncomeFeeRoleGranted(address indexed account);
    event NoIncomeFeeRoleRevoked(address indexed account);
    event Distribution(address indexed account, uint256 value);

    modifier notPaused() {
        if (paused()) {
            require(
                hasRole(UNPAUSED_ROLE, _msgSender()),
                "can't perform an action"
            );
        }
        _;
    }

    constructor(
        string memory name,
        string memory ticker,
        uint8 decimal,
        uint256 tTotal,
        uint256 dPercent,
        uint256 bPercent
    ) ERC20(name, ticker) ERC20Permit(name) {
        // init supply
        _decimals = decimal;
        _tTotal = tTotal * 10**decimal;
        _rTotal = (type(uint256).max - (type(uint256).max % _tTotal));

        // set fee percents
        require(10 <= dPercent && dPercent <= 100 && 10 <= bPercent && bPercent <= 100, 
            "incorrect fee percent"
        );
        _distributionPercent = dPercent;
        emit DistributionPercentChanged(dPercent);
        _burnPercent = bPercent;
        emit BurnPercentChanged(bPercent);

        // set roles
        _setRoleAdmin(ADMIN_ROLE, OWNER_ROLE);
        _setRoleAdmin(UNPAUSED_ROLE, ADMIN_ROLE);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(UNPAUSED_ROLE, _msgSender());

        // mint inital supply
        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    // base logic -------------------------------------------------------------
    // ------------------------------------------------------------------------

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    // transfer logic ---------------------------------------------------------
    // ------------------------------------------------------------------------

    function setDistributionPercent(uint256 percent) external onlyRole(OWNER_ROLE) {
        require(10 <= percent && percent <= 100, "incorrect fee percent"); // 1% <= percent <= 10%
        _distributionPercent = percent;
        emit DistributionPercentChanged(percent);
    }

    function setBurnPercent(uint256 percent) external onlyRole(OWNER_ROLE) {
        require(10 <= percent && percent <= 100, "incorrect fee percent"); // 1% <= percent <= 10%
        _burnPercent = percent;
        emit BurnPercentChanged(percent);
    }

    function distributionPercent() external view returns (uint256) {
        return _distributionPercent;
    }

    function burnPercent() external view returns (uint256) {
        return _burnPercent;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rBurnAmount) = _getBurnValues(tAmount);
            (, uint256 rTransferAmount, , ) = _getValues(tAmount);
            return rTransferAmount - rBurnAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function isNoIncomeFee(address account) external view returns (bool) {
        return _isNoIncomeFee[account];
    }

    function grantNoIncomeFee(address account) external onlyRole(ADMIN_ROLE) {
        require(!_isNoIncomeFee[account], "Account is already no income fee");
        _isNoIncomeFee[account] = true;
        emit NoIncomeFeeRoleGranted(account);
    }

    function revokeNoIncomeFee(address account) external onlyRole(ADMIN_ROLE) {
        require(_isNoIncomeFee[account], "Account is not no income fee");
        _isNoIncomeFee[account] = false;
        emit NoIncomeFeeRoleRevoked(account);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override(ERC20) notPaused {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if (_isNoIncomeFee[recipient]) {
            _transferWithoutFee(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 tBurnAmount, uint256 rBurnAmount) = _getBurnValues(tAmount);
        _tTotal -= tBurnAmount;
        _rTotal -= rBurnAmount;

        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount) = _getValues(tAmount);
        _rOwned[sender] -= rAmount;
        _rOwned[recipient] += rTransferAmount - rBurnAmount;

        // distribute fee
        _rTotal -= rFee;

        emit Transfer(sender, recipient, tTransferAmount - tBurnAmount);
        emit Transfer(sender, address(0), tBurnAmount);
        emit Distribution(sender, tAmount - tTransferAmount);
    }

    function _transferWithoutFee(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount * currentRate;
        _rOwned[sender] -= rAmount;
        _rOwned[recipient] += rAmount;
        emit Transfer(sender, recipient, tAmount);
    }

    function _getBurnValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tBurnAmount = (tAmount * _burnPercent) / 1000;
        uint256 currentRate = _getRate();
        uint256 rBurnAmount = tBurnAmount * currentRate;
        return (tBurnAmount, rBurnAmount);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = (tAmount * _distributionPercent) / 1000;
        uint256 tTransferAmount = tAmount - tFee;

        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rTransferAmount = rAmount - rFee;

        return (rAmount, rTransferAmount, rFee, tTransferAmount);
    }

    function _getRate() private view returns (uint256) {
        return _rTotal / _tTotal;
    }

    function transferAll(address recipient) external returns (bool) {
        _transfer(_msgSender(), recipient, tokenFromReflection(_rOwned[_msgSender()]));
        return true;
    }

    function transferAllFrom(address account, address recipient) external returns (bool) {
        uint256 tAmount = tokenFromReflection(_rOwned[account]);
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= tAmount, "transfer amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - tAmount);
        _transfer(account, recipient, tAmount);
        return true;
    }

    // for initial token distribution (swap from old token)
    function multisend(
        address[] memory recipients,
        uint256[] memory tAmounts
    ) external onlyRole(OWNER_ROLE) {
        require(recipients.length <= 200, "More than 200 recipients");

        uint256 rTotal;
        uint256 rAmount;
        uint256 currentRate = _getRate();

        uint8 i = 0;
        for (i; i < recipients.length; i++) {
            rAmount = tAmounts[i] * currentRate;
            rTotal += rAmount;
            _rOwned[recipients[i]] += rAmount;
            emit Transfer(_msgSender(), recipients[i], tAmounts[i]);
        }

        _rOwned[_msgSender()] -= rTotal;
    }

    // burn logic -------------------------------------------------------------
    // ------------------------------------------------------------------------

    function _burn(address account, uint256 tAmount) internal notPaused override {
        require(account != address(0), "burn from the zero address");

        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount * currentRate;
        _rOwned[account] -= rAmount;
        _rTotal -= rAmount;
        _tTotal -= tAmount;

        emit Transfer(account, address(0), tAmount);
    }

    function burn(uint256 tAmount) external {
        _burn(_msgSender(), tAmount);
    }

    function burnFrom(address account, uint256 tAmount) external {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= tAmount, "burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - tAmount);
        _burn(account, tAmount);
    }

    // distribute logic -------------------------------------------------------
    // ------------------------------------------------------------------------

    function _distribute(address account, uint256 tAmount) internal {
        (uint256 rAmount, , , ) = _getValues(tAmount);
        _rOwned[account] -= rAmount;
        _rTotal -= rAmount;
        emit Distribution(account, tAmount);
    }

    function distribute(uint256 tAmount) external {
        _distribute(_msgSender(), tAmount);
    }

    function distributeFrom(address account, uint256 tAmount) external {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= tAmount, "distribute amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - tAmount);
        _distribute(account, tAmount);
    }

    // denomination logic -----------------------------------------------------
    // ------------------------------------------------------------------------

    function denominate(uint256 rate) external onlyRole(OWNER_ROLE) {
        _tTotal /= rate;
    }

    // pause logic ------------------------------------------------------------
    // ------------------------------------------------------------------------

    function pauseTrigger() external onlyRole(OWNER_ROLE) {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    // interface support ------------------------------------------------------
    // ------------------------------------------------------------------------

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControl, ERC1363) returns (bool) {
        return AccessControl.supportsInterface(interfaceId) || ERC1363.supportsInterface(interfaceId);
    }

    // stuck funds ------------------------------------------------------------
    // ------------------------------------------------------------------------

    function stuckFundsTransfer(
        address token,
        address to,
        uint256 amount
    ) external onlyRole(OWNER_ROLE) returns (bool) {
        return IERC20(token).transfer(to, amount);
    }
}