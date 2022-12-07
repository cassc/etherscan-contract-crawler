// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "contracts/interface/IPancake.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "hardhat/console.sol";

interface ILiquidityPool {
    function addReward(uint256 amount) external;
}

contract LymToken is Ownable, ERC20, ERC20Burnable {
    using Address for address;

    struct Meta {
        bool whiteContract;
        bool autoAddLiquidity;
        uint256 transactionFee;
        uint256 addLiquidityAmount;
        uint256 miniBalance;
        uint256 totalBurn;
        IPancakeHelper helper;
        ILiquidityPool miningPool;
        IPancakeRouter02 router;
        address pair;
        address foundation;
    }

    Meta public meta;

    mapping(address => bool) public whiteList;
    mapping(address => bool) public whiteContracts;

    constructor(address router_, address usdt_, address helper_, address pool_) ERC20("Lymex", "TLYM") {
        _mint(msg.sender, 1_000_000_000 ether);

        meta.router = IPancakeRouter02(router_);
        meta.pair = IPancakeFactory(meta.router.factory()).createPair(address(this), usdt_);
        meta.transactionFee = 5;

        meta.addLiquidityAmount = 1 ether / 10;
        meta.miningPool = ILiquidityPool(pool_);
        meta.helper = IPancakeHelper(helper_);
        whiteList[address(meta.helper)] = true;

        whiteContracts[address(meta.helper)] = true;
        whiteContracts[meta.pair] = true;
        whiteContracts[address(meta.router)] = true;
        whiteContracts[address(this)] = true;

        meta.autoAddLiquidity = true;
        meta.whiteContract = true;
    }

    // function mint(address to_, uint256 amount_) public onlyOwner {
    //     _mint(to_, amount_);
    // }

    function totalBurn() public view returns (uint256) {
        return meta.totalBurn;
    }

    function setContractStatus(bool status_) public onlyOwner {
        meta.whiteContract = status_;
    }

    function setAutoAddLiquidity(bool status_) public onlyOwner {
        meta.autoAddLiquidity = status_;
    }

    function setLiquidityHelper(address helper_) public onlyOwner {
        meta.helper = IPancakeHelper(helper_);
        whiteList[helper_] = true;
        whiteContracts[helper_] = true;
    }

    function setMiningPool(address pool_) public onlyOwner {
        meta.miningPool = ILiquidityPool(pool_);
        whiteList[pool_] = true;
        whiteContracts[pool_] = true;
    }

    function setFee(uint256 transactionFee_, uint256 addLiquidityAmount_) public onlyOwner {
        meta.transactionFee = transactionFee_;
        meta.addLiquidityAmount = addLiquidityAmount_;
    }

    function setWhiteList(address[] calldata accounts_, bool isAdd_) external onlyOwner {
        for (uint256 i; i < accounts_.length; i++) {
            whiteList[accounts_[i]] = isAdd_;
        }
    }

    function setWhiteContractList(address[] calldata accounts_, bool isAdd_) external onlyOwner {
        for (uint256 i; i < accounts_.length; i++) {
            whiteContracts[accounts_[i]] = isAdd_;
        }
    }

    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);
        meta.totalBurn += amount;

        if (meta.totalBurn >= 800_000_000 ether) {
            meta.transactionFee = 0;
        } else if (meta.totalBurn >= 120_000_000 ether) {
            meta.transactionFee = 2;
        } else if (meta.totalBurn > 30_000_000 ether) {
            meta.transactionFee = 3;
        }
    }

    function transfer(address recipient_, uint256 amount_) public virtual override returns (bool) {
        _processTransfer(_msgSender(), recipient_, amount_);
        return true;
    }

    function transferFrom(address sender_, address recipient_, uint256 amount_) public virtual override returns (bool) {
        _spendAllowance(sender_, _msgSender(), amount_);
        _processTransfer(sender_, recipient_, amount_);
        return true;
    }

    function _isSwap(address from, address to) private view returns (bool) {
        return from == meta.pair || to == meta.pair;
    }

    function _processTransfer(address from, address to, uint256 amount) private {
        if (meta.whiteContract) {
            require(!_msgSender().isContract() || whiteContracts[_msgSender()], "not white contract");
            require(!from.isContract() || whiteContracts[from], "not white contract");
            require(!to.isContract() || whiteContracts[to], "not white contract");
        }

        if (whiteList[from] || whiteList[to]) {
            _transfer(from, to, amount);
            return;
        }

        if (amount + meta.miniBalance >= balanceOf(from)) {
            require(amount > meta.miniBalance, "balance not enough");
            amount -= meta.miniBalance;
        }
        // require(amount + meta.miniBalance < balanceOf(from), "out of limit");

        if (meta.transactionFee != 0) {
            uint256 fee = (amount * meta.transactionFee) / 100;
            _transfer(from, address(meta.miningPool), fee / 4);
            _transfer(from, address(meta.helper), fee / 4);
            _transfer(from, address(meta.foundation), fee / 2);

            unchecked {
                meta.miningPool.addReward(fee / 4);
            }
            amount -= fee;
        }

        if (!_isSwap(from, to)) {
            if (meta.autoAddLiquidity && balanceOf(address(meta.helper)) >= meta.addLiquidityAmount) {
                meta.helper.addLiquidity();
            }
        }

        _transfer(from, to, amount);
    }

    function divest(address token_, address payee_, uint256 value_) external onlyOwner {
        if (token_ == address(0)) {
            payable(payee_).transfer(value_);
        } else {
            IERC20(token_).transfer(payee_, value_);
        }
    }
}