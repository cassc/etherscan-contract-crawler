// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SignedSafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/ICertToken.sol";
import "../interfaces/IinternetBond_R3.sol";
import "../libraries/ERC20BondBase.sol";

contract aMATICb_R7 is OwnableUpgradeable, ERC20BondBase, IinternetBond_R3 {

    using SafeMathUpgradeable for uint256;
    using MathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;

    event RatioUpdate(uint256 newRatio);
    event LastConfirmedRatioUpdate(uint256 newRatio);

    address private _operator;
    address private _crossChainBridge;
    address private _polygonPool;
    // ratio should be base on 1 MATIC, if ratio is 0.9, this variable should be 9e17
    uint256 private _ratio;
    int256 private _lockedShares;

    mapping(address => uint256) private _pendingBurn;
    uint256 private _pendingBurnsTotal;

    uint256 private _collectableFee;

    string private _name;
    string private _symbol;

    // Added in R3
    address public certToken; // aMATICc

    address public swapFeeOperator;
    uint256 public swapFeeRatio;

    function initialize(address operator) public initializer {
        __Ownable_init();
        __ERC20_init("Ankr MATIC Reward Earning Bond", "aMATICb");
        _operator = operator;
        _ratio = 1e18;
    }

    function ratio() public override view returns (uint256) {
        return _ratio;
    }

    function isRebasing() public pure returns (bool) {
        return true;
    }

    function updateRatio(uint256 newRatio) public onlyOperator {
        //        // 0.002 * ratio
        //        uint256 threshold = _ratio.div(500);
        //        require(newRatio < _ratio.add(threshold) || newRatio > _ratio.sub(threshold), "New ratio should be in limits");
        require(newRatio <= 1e18, "new ratio should be less or equal to 1e18");
        _ratio = newRatio;
        emit RatioUpdate(_ratio);
    }

    function repairRatio(uint256 newRatio) public onlyOwner {
        _ratio = newRatio;
        emit RatioUpdate(_ratio);
    }

    function collectableFee() public view returns (uint256) {
        return _collectableFee;
    }

    function repairCollectableFee(uint256 newFee) public onlyOwner {
        _collectableFee = newFee;
    }

    function updateRatioAndFee(uint256 newRatio, uint256 newFee) public onlyOperator {
        // 0.002 * ratio
        uint256 threshold = _ratio.div(500);
        require(newRatio < _ratio.add(threshold) || newRatio > _ratio.sub(threshold), "New ratio should be in limits");
        require(newRatio <= 1e18, "new ratio should be less or equal to 1e18");
        _ratio = newRatio;
        _collectableFee = newFee;
        emit RatioUpdate(_ratio);
    }

    function totalSupply() public view override returns (uint256) {
        uint256 supply = totalSharesSupply();
        return _sharesToBonds(supply);
    }

    function totalSharesSupply() public view override returns (uint256) {
        return super.totalSupply();
    }

    function totalSharesSupplyWithBurns() public view override returns (uint256) {
        return totalSharesSupply().add(_bondsToShares(_pendingBurnsTotal));
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 shares = super.balanceOf(account);
        return _sharesToBonds(shares);
    }

    function sharesOf(address account) public view override returns (uint256) {
        return super.balanceOf(account);
    }

    function mintBonds(address account, uint256 amount) public override onlyBondMinter {
        uint256 shares = _bondsToShares(amount);
        _mint(account, shares);
        emit Transfer(address(0), account, _sharesToBonds(shares));
    }

    function mint(address account, uint256 shares) public onlyMinter {
        require(_lockedShares.sub(int256(shares)) <= _lockedShares, "aMATICb: lockedShares overflow");
        _lockedShares = _lockedShares.sub(int256(shares));
        _mint(account, shares);
        emit Transfer(address(0), account, _sharesToBonds(shares));
    }

    function burn(address account, uint256 amount) public override onlyMinter {
        uint256 shares = _bondsToShares(amount);
        _lockedShares = _lockedShares.add(int256(shares));
        _burn(account, shares);
        emit Transfer(account, address(0), _sharesToBonds(shares));
    }

    function _mint(address account, uint256 shares) internal override {
        super._mint(account, shares);
        ICertToken(certToken).mint(address(this), shares);
    }

    function _burn(address account, uint256 shares) internal override {
        super._burn(account, shares);
        ICertToken(certToken).burn(address(this), shares);
    }

    function pendingBurn(address account) external view override returns (uint256) {
        return _pendingBurn[account];
    }

    function burnBonds(address burner, address recipient, uint256 amount) external override onlyBondMinter {
        _pendingBurn[recipient] = _pendingBurn[recipient].add(amount);
        _pendingBurnsTotal = _pendingBurnsTotal.add(amount);
        uint256 shares = _bondsToShares(amount);
        _burn(burner, shares);
        emit Transfer(burner, address(0), _sharesToBonds(shares));
    }

    function commitBurn(address account, uint256 amount) public override onlyBondMinter {
        require(_pendingBurnsTotal >= amount, "aMATICb: total pending burn is less than amount");
        require(_pendingBurn[account] >= amount, "aMATICb: pending burn is less than amount");
        _pendingBurn[account] = _pendingBurn[account].sub(amount);
        _pendingBurnsTotal = _pendingBurnsTotal.sub(amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 shares = _bondsToShares(amount);
        super.transfer(recipient, shares);
        emit Transfer(msg.sender, recipient, _sharesToBonds(shares));
        return true;
    }

    function transferShares(address sender, address recipient, uint256 shares) internal returns (bool) {
        super._transfer(sender, recipient, shares);
        emit Transfer(sender, recipient, _sharesToBonds(shares));
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _sharesToBonds(super.allowance(owner, spender));
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        uint256 shares = _bondsToShares(amount);
        super.approve(spender, shares);
        emit Approval(msg.sender, spender, allowance(msg.sender, spender));
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 shares = _bondsToShares(amount);
        super.transferFrom(sender, recipient, shares);
        emit Transfer(sender, recipient, _sharesToBonds(shares));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
        uint256 shares = _bondsToShares(addedValue);
        super.increaseAllowance(spender, shares);
        emit Approval(msg.sender, spender, allowance(msg.sender, spender));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {
        uint256 shares = _bondsToShares(subtractedValue);
        super.decreaseAllowance(spender, shares);
        emit Approval(msg.sender, spender, allowance(msg.sender, spender));
        return true;
    }

    function _bondsToShares(uint256 amount) internal view returns (uint256) {
        return safeCeilMultiplyAndDivide(amount, _ratio, 1e18);
    }

    function _sharesToBonds(uint256 amount) internal view returns (uint256) {
        return safeFloorMultiplyAndDivide(amount, 1e18, _ratio);
    }

    modifier onlyOperator() {
        require(msg.sender == owner() || msg.sender == _operator, "Operator: not allowed");
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == _crossChainBridge, "Minter: not allowed");
        _;
    }

    modifier onlyBondMinter() {
        require(msg.sender == _polygonPool, "Minter: not allowed");
        _;
    }

    function changeOperator(address operator) public onlyOwner {
        _operator = operator;
    }

    function changePolygonPool(address polygonPool) public onlyOwner {
        _polygonPool = polygonPool;
    }

    function changeCrossChainBridge(address crossChainBridge) public onlyOwner {
        _crossChainBridge = crossChainBridge;
    }

    function lockedSupply() public view returns (int256) {
        return _lockedShares;
    }

    function name() public view override returns (string memory) {
        if (bytes(_name).length != 0) {
            return _name;
        }
        return super.name();
    }

    function symbol() public view override returns (string memory) {
        if (bytes(_symbol).length != 0) {
            return _symbol;
        }
        return super.symbol();
    }

    function setNameAndSymbol(string memory new_name, string memory new_symbol) public onlyOperator {
        _name = new_name;
        _symbol = new_symbol;
    }

    /*** Added in version R3 ***/

    function sharesToBalance(uint256 amount) public override view returns (uint256) {
        return _sharesToBonds(amount);
    }

    function balanceToShares(uint256 amount) public override view returns (uint256) {
        return _bondsToShares(amount);
    }

    function getSwapFeeInBonds(uint256 bonds) public view override returns(uint256) {
        uint256 shares = balanceToShares(bonds);
        uint256 feeInShares = getSwapFeeInShares(shares);
        return sharesToBalance(feeInShares);
    }

    function getSwapFeeInShares(uint256 shares) public view override returns(uint256) {
        return safeCeilMultiplyAndDivide(shares, swapFeeRatio, 1e18);
    }

    function changeCertToken(address newCertToken) external override onlyOwner {
        address oldCertToken = certToken;
        certToken = newCertToken;
        emit CertTokenChanged(oldCertToken, newCertToken);
    }

    function changeSwapFeeOperator(address newSwapFeeOperator) external override onlyOwner {
        address oldSwapFeeOperator = swapFeeOperator;
        swapFeeOperator = newSwapFeeOperator;
        emit SwapFeeOperatorChanged(oldSwapFeeOperator, newSwapFeeOperator);
    }

    function updateSwapFeeRatio(uint256 newRatio) external override onlyOwner {
        require(newRatio <= 1e16, "swapFee must be not greater that 1%");
        swapFeeRatio = newRatio;
        emit SwapFeeRatioUpdate(newRatio);
    }

    function unlockShares(uint256 shares) external override {
        _unlockShares(msg.sender, shares, true);
    }

    function unlockSharesFor(address account, uint256 bonds) external override onlyBondMinter {
        uint256 shares = balanceToShares(bonds);
        _unlockShares(account, shares, false);
    }

    function _unlockShares(address account, uint256 shares, bool takeFee) internal {
        require(sharesOf(account) >= shares, "Insufficient aMATICb balance");

        uint256 fee = 0;
        if (takeFee) {
            fee = getSwapFeeInShares(shares);
        }

        // address(this) hols aFTMb that are unlocked to aFTMc. This address can be accessed only by aFTMb contract.
        transferShares(account, address(this), shares - fee);
        if (fee != 0) {
            transferShares(account, swapFeeOperator, fee);
        }

        ICertToken(certToken).bondTransferTo(account, shares - fee);
    }

    function lockShares(uint256 shares) external override {
        _lockShares(msg.sender, shares, true);
    }

    function lockSharesFor(address account, uint256 shares) external override onlyBondMinter {
        _lockShares(account, shares, false);
    }

    function _lockShares(address account, uint256 shares, bool takeFee) internal {
        require(IERC20Upgradeable(certToken).balanceOf(account) >= shares, "Insufficient aMATICc balance");

        uint256 fee = 0;
        if (takeFee) {
            fee = getSwapFeeInShares(shares);
        }

        ICertToken(certToken).bondTransferFrom(account, shares);
        transferShares(address(this), account, shares - fee); // can not fail as _balance[address(this)] always equals to amount of aFTMc minted
        if (fee != 0) {
            transferShares(address(this), swapFeeOperator, fee);
        }
    }

    function migrateBurnDelayed(address claimer, uint256 amount) external override onlyBondMinter {
        uint256 burnableAmount = _pendingBurn[claimer];
        require(burnableAmount >= amount, "aMATICb: pending burn greater than amount");
        require(_pendingBurnsTotal >= amount, "aMATICb: total burn greater than amount");
        uint256 shares = _bondsToShares(amount);
        _burn(claimer, shares);
        emit Transfer(claimer, address(0), _sharesToBonds(shares));
    }


    // utility functions

    // returns floor (a * b / c)
    function safeFloorMultiplyAndDivide(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        uint256 remainder = a.mod(c);
        uint256 result = a.div(c);
        bool safe;
        (safe, result) = result.tryMul(b);
        if (!safe) {
            return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }
        (safe, result) = result.tryAdd(remainder.mul(b).div(c));
        if (!safe) {
            return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }
        return result;
    }

    // return ceil (a * b / c)
    function safeCeilMultiplyAndDivide(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
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
}