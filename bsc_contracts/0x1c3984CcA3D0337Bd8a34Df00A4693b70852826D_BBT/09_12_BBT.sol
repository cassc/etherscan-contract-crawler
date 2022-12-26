// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/IRouter.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/ICollection.sol";

contract BBT is ERC20, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant MAX_SUPPLY = 1000000000 * 1e18;
    uint256 private constant MAX_TOP_HOLDERS_AMOUNT = 50;
    uint256 private constant BASE_PERCENT = 10000;
    
    address public immutable router;
    address public immutable pair;
    address public immutable bunniesBoom;
    address public immutable treasury;
    address public liquidityProvider;
    address public collection;
    uint256 public buyFee = 300;
    uint256 public sellFee = 500;
    uint256 public topHoldersAmount = 50;
    uint256 public thresholdAmount;
    uint256 public tradingEnabledBlockTimestamp;
    uint256 public buyFeeAmount;
    uint256 public sellFeeAmount;
    uint256 public holdersFeeAmount;
    bool public tradingEnabled;

    mapping (address => bool) public isExcludedFromFees;
    EnumerableSet.AddressSet private _blacklist;
    EnumerableSet.AddressSet private _nftHolders;

    modifier onlyCollection {
        require(
            msg.sender == collection,
            "BBT: caller is not the NFT collection contract"
        );
        _;
    }

    constructor(
        address router_,
        address bunniesBoom_,
        address treasury_
    ) 
        ERC20("Bunnies Battle Token", "BBT") 
    {
        _mint(msg.sender, MAX_SUPPLY);
        router = router_;
        pair = IFactory(IRouter(router_).factory()).createPair(IRouter(router_).WETH(), address(this));
        bunniesBoom = bunniesBoom_;
        treasury = treasury_;
        isExcludedFromFees[router_] = true;
        isExcludedFromFees[bunniesBoom_] = true;
        isExcludedFromFees[treasury_] = true;
        isExcludedFromFees[msg.sender] = true;
        isExcludedFromFees[address(this)] = true;
        _approve(msg.sender, router_, type(uint256).max);
        _approve(address(this), router_, type(uint256).max);
    }

    receive() external payable {}

    function setExcludedFromFeesStatus(address account_, bool status_) external onlyOwner {
        require(
            account_ != address(0),
            "BBT: invalid account address"
        );
        isExcludedFromFees[account_] = status_;
    }

    function setLiquidityProvider(address liquidityProvider_) external onlyOwner {
        require(
            liquidityProvider_ != owner() && liquidityProvider_ != address(0),
            "BBT: invalid liquidity provider address"
        );
        liquidityProvider = liquidityProvider_;
    }

    function removeFromBlacklist(address account_) external onlyOwner {
        require(
            account_ != address(0),
            "BBT: invalid account address"
        );
        require(
            _blacklist.remove(account_),
            "BBT: not blacklisted"
        );
    }

    function setCollection(address collection_) external onlyOwner {
        require(
            collection_ != address(this) && collection_ != address(0),
            "BBT: invalid collection address"
        );
        collection = collection_;
    }

    function setThresholdAmount(uint256 thresholdAmount_) external onlyOwner {
        thresholdAmount = thresholdAmount_;
    }

    function setTopHoldersAmount(uint256 topHoldersAmount_) external onlyOwner {
        require(
            topHoldersAmount_ <= MAX_TOP_HOLDERS_AMOUNT,
            "BBT: amount exceeds the maximum permissible value"
        );
        topHoldersAmount = topHoldersAmount_;
    }

    function nullifyFees() external onlyOwner {
        buyFee = 0;
        sellFee = 0;
    }

    function enableTrading() external onlyOwner {
        require(
            !tradingEnabled,
            "BBT: trading is already enabled"
        );
        tradingEnabled = true;
        tradingEnabledBlockTimestamp = block.timestamp;
    }

    function distributeTokensBetweenHolders(address[] calldata accounts_) external onlyOwner {
        require(
            accounts_.length == topHoldersAmount,
            "BBT: invalid array length"
        );
        uint256 fee = holdersFeeAmount;
        if (fee != 0) {
            uint256 amountToDistributeBetweenEachOfTopHolder = fee / (2 * topHoldersAmount);
            for (uint256 i = 0; i < accounts_.length; i++) {
                _transfer(address(this), accounts_[i], amountToDistributeBetweenEachOfTopHolder);
            }
            uint256 amountToDistributeBetweenNftHolders = fee / 2;
            uint256 supply = ICollection(collection).totalSupply();
            for (uint256 i = 0; i < _nftHolders.length(); i++) {
                address holder = _nftHolders.at(i);
                uint256 share = 
                    amountToDistributeBetweenNftHolders 
                    * ICollection(collection).balanceOf(holder)
                    / supply;
                _transfer(address(this), holder, share);
            }
        }
    }

    function addToNftHoldersList(address account_) external onlyCollection {
        require(
            _nftHolders.add(account_),
            "BBT: the account is already in the list of NFT holders"
        );
    }

    function removeFromNftHoldersList(address account_) external onlyCollection {
        require(
            _nftHolders.remove(account_),
            "BBT: the account is not in the list of NFT holders"
        );
    }

    function isNftHolder(address account_) external view returns (bool) {
        return _nftHolders.contains(account_);
    }

    function _transfer(
        address from_,
        address to_,
        uint256 amount_
    )
        internal
        override
    {
        require(
            from_ != address(0), 
            "BBT: transfer from the zero address"
        );
        require(
            to_ != address(0), 
            "BBT: transfer to the zero address"
        );
        require(
            amount_ > 0, 
            "BBT: transfer amount can not be 0"
        );
        if (block.timestamp - tradingEnabledBlockTimestamp <= 10) {
            _blacklist.add(tx.origin);
        }
        require(
            !_blacklist.contains(from_) || !_blacklist.contains(to_),
            "BBT: transfer from or to blacklisted address"
        );
        bool buy;
        bool sell;
        bool transfer;
        if (from_ == pair) {
            buy = true;
        } else if (to_ == pair) {
            sell = true;
        } else {
            transfer = true;
        }
        if (_hasLimits(from_, to_)) {
            require(
                tradingEnabled,
                "BBT: trading is not enabled"
            );
        }
        bool takeFee = true;
        if (isExcludedFromFees[from_] || isExcludedFromFees[to_]) {
            takeFee = false;
        }
        _balances[from_] -= amount_;
        uint256 amountToReceive = takeFee ? _takeFees(from_, amount_, buy, sell, transfer) : amount_;
        _balances[to_] += amountToReceive;
        emit Transfer(from_, to_, amountToReceive);
    }

    function _hasLimits(address from_, address to_) private view returns (bool) {
        address owner = owner();
        return
            from_ != owner &&
            from_ != address(this) &&
            from_ != liquidityProvider && 
            to_ != liquidityProvider &&
            to_ != owner &&
            tx.origin != owner;
    }

    function _takeFees(address from_, uint256 amount_, bool buy_, bool sell_, bool transfer_) private returns (uint256) {
        uint256 feeAmount;
        if (buy_) {
            feeAmount = amount_ * buyFee / BASE_PERCENT;
            if (feeAmount > 0) {
                uint256 buybackAmount = feeAmount / 3;
                buyFeeAmount += buybackAmount;
                holdersFeeAmount =  holdersFeeAmount + (feeAmount - buybackAmount);
                _balances[address(this)] += feeAmount;
                emit Transfer(from_, address(this), feeAmount);
            }
        } else if (sell_) {
            feeAmount = amount_ * sellFee / BASE_PERCENT;
            if (feeAmount > 0) {
                sellFeeAmount += feeAmount;
                _balances[address(this)] += feeAmount;
                emit Transfer(from_, address(this), feeAmount);
                if (sellFeeAmount + buyFeeAmount >= thresholdAmount) {
                    _swap();
                }
            }
        } else if (transfer_) {
            if (sellFeeAmount + buyFeeAmount >= thresholdAmount) {
                _swap();
            }
        }
        return amount_ - feeAmount;
    }

    function _swap() private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = IRouter(router).WETH();
        if (buyFeeAmount != 0) {
            IRouter(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
                buyFeeAmount,
                0,
                path,
                bunniesBoom,
                block.timestamp
            );
            buyFeeAmount = 0;
        }
        if (sellFeeAmount != 0) {
            IRouter(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
                sellFeeAmount,
                0,
                path,
                treasury,
                block.timestamp
            );
            sellFeeAmount = 0;
        }
    }
}