// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import './ElasticERC20.sol';

abstract contract ElasticERC20RigidExtension is ElasticERC20 {
    using Math for uint256;

    mapping(address => uint256) private _balancesRigid;

    mapping(address => mapping(address => uint256)) private _allowancesRigid;

    uint256 private _totalSupplyRigid;

    uint256 private _lockedNominal;

    event ConvertedToElastic(address indexed owner, uint256 value, uint256 nominal);
    event ConvertedToRigid(address indexed owner, uint256 value, uint256 nominal);

    function containRigidAddress(address _rigidAddress) public view virtual returns (bool);

    function totalSupplyRigid() public view returns (uint256) {
        return _totalSupplyRigid;
    }

    function lockedNominalRigid() public view returns (uint256) {
        return _lockedNominal;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return super.totalSupply() + _totalSupplyRigid;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        if (!containRigidAddress(account)) return super.balanceOf(account);

        return _balancesRigid[account];
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (!containRigidAddress(owner)) return super.allowance(owner, spender);

        return _allowancesRigid[owner][spender];
    }

    function _convertRigidToElasticBalancePartially(address owner, uint256 amount) internal {
        _totalSupplyRigid -= amount;
        _balancesRigid[owner] -= amount;

        uint256 nominal = _convertToNominalWithCaching(amount, Math.Rounding.Up);
        _lockedNominal -= nominal;

        _increaseBalanceElastic(owner, nominal);

        emit ConvertedToElastic(owner, amount, nominal);
    }

    function _convertElasticToRigidBalancePartially(address owner, uint256 amount) internal {
        uint256 nominal = _convertToNominalWithCaching(amount, Math.Rounding.Up);
        _decreaseBalanceElastic(owner, nominal);

        _lockedNominal += nominal;

        _totalSupplyRigid += amount;
        _balancesRigid[owner] += amount;

        emit ConvertedToRigid(owner, amount, nominal);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();

        if (containRigidAddress(owner)) {
            _transferRigid(owner, to, amount);
            if (!containRigidAddress(to)) _convertRigidToElasticBalancePartially(to, amount);
        } else {
            super.transfer(to, amount);
            if (containRigidAddress(to)) _convertElasticToRigidBalancePartially(to, amount);
        }

        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();

        if (!containRigidAddress(owner)) return super.approve(spender, amount);

        _approveRigid(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        if (containRigidAddress(from)) {
            _spendAllowanceRigid(from, spender, amount);
            _transferRigid(from, to, amount);
            if (!containRigidAddress(to)) _convertRigidToElasticBalancePartially(to, amount);
        } else {
            super.transferFrom(from, to, amount);
            if (containRigidAddress(to)) _convertElasticToRigidBalancePartially(to, amount);
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();

        if (!containRigidAddress(owner)) return super.increaseAllowance(spender, addedValue);

        _approveRigid(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();

        if (!containRigidAddress(owner)) return super.decreaseAllowance(spender, subtractedValue);

        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            'RigidElasticERC20: decreased allowance below zero'
        );
        unchecked {
            _approveRigid(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transferRigid(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), 'RigidElasticERC20: transfer from the zero address');
        require(to != address(0), 'RigidElasticERC20: transfer to the zero address');

        uint256 fromBalance = _balancesRigid[from];
        require(fromBalance >= amount, 'RigidElasticERC20: transfer amount exceeds balance');
        unchecked {
            _balancesRigid[from] = fromBalance - amount;
        }
        _balancesRigid[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _approveRigid(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), 'RigidElasticERC20: approve from the zero address');
        require(spender != address(0), 'RigidElasticERC20: approve to the zero address');

        _allowancesRigid[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowanceRigid(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, 'RigidElasticERC20: insufficient allowance');
            unchecked {
                _approveRigid(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _mintElastic(
        address account,
        uint256 nominal,
        uint256 value
    ) internal virtual override {
        if (!containRigidAddress(account)) return super._mintElastic(account, nominal, value);
        revert("RigidElasticERC20: can't be minted");
    }

    function _burnElastic(
        address account,
        uint256 nominal,
        uint256 value
    ) internal virtual override {
        if (!containRigidAddress(account)) return super._burnElastic(account, nominal, value);
        revert("RigidElasticERC20: can't be burned");
    }

    function _decreaseLockedNominalRigidBy(uint256 nominal) internal {
        _lockedNominal -= nominal;
    }
}