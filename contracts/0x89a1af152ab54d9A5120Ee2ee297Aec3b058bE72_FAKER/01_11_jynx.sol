// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";


contract FAKER is ERC20, Ownable { 
    using SafeMath for uint256;

    modifier lockSwap() { 
        _inSwap = true;
        _;
        _inSwap = false;
    }

    modifier liquidityAdd() { 
        _inLiquidityAdd = true;
        _;
        _inLiquidityAdd = false;
    }

    // =CONSTANTS ==
    uint256 public constant MAX_SUPPLY = 1_000_000_000 ether;
    uint256 public constant BPS_DENOMINATOR = 10_000;
    uint256 public constant SNIPE_BLOCKS = 1;

    // =TAXES ==
    //- @notice Buy devTax in BPS
    uint256 public buyDevTax = 200; //- 2%
    //- @notice Buy rewardsTax in BPS
    uint256 public buyRewardsTax = 0;
    //- @notice Sell devTax in BPS
    uint256 public sellDevTax = 300; //- 3%
    //- @notice Sell rewardsTax in BPS
    uint256 public sellRewardsTax = 0;
    //- @notice address that devTax is sent to
    address payable public devTaxRecipient;
    //- @notice address that rewardsTax is sent to
    address payable public rewardsTaxRecipient;
    //- @notice tokens currently allocated for devTax
    uint256 public totalDevTax;
    //- @notice tokens currently allocated for rewardsTax
    uint256 public totalRewardsTax;

    // =FLAGS ==
    //- @notice flag indicating whether initialDistribute() was successfully called
    bool public initialDistributeDone = false;
    //- @notice flag indicating Uniswap trading status
    bool public tradingActive = false;
    //- @notice flag indicating swapAll enabled
    bool public swapFees = true;

    // =UNISWAP ==
    IUniswapV2Router02 public router;
    address public pair;

    // =WALLET STATUSES ==
    //- @notice Maps each recipient to their tax exlcusion status
    mapping(address => bool) public taxExcluded;
    //- @notice Maps each recipient to the last timestamp they bought
    mapping(address => uint256) public lastBuy;
    //- @notice Maps each recipient to their blacklist status
    mapping(address => bool) public blacklist;

    // =MISC ==
    //- @notice Block when trading is first enabled
    uint256 public tradingBlock;
    //- @notice Contract token balance threshold before `_swap` is invoked
    uint256 public minTokenBalance = 1 ether;

    // =INTERNAL ==
    uint256 internal _totalSupply = 0;
    bool internal _inSwap = false;
    bool internal _inLiquidityAdd = false;
    mapping(address => uint256) private _balances;

    event DevTaxRecipientChanged(
        address previousRecipient,
        address nextRecipient
    );
    event RewardsTaxRecipientChanged(
        address previousRecipient,
        address nextRecipient
    );
    event BuyDevTaxChanged(uint256 previousTax, uint256 nextTax);
    event SellDevTaxChanged(uint256 previousTax, uint256 nextTax);
    event BuyRewardsTaxChanged(uint256 previousTax, uint256 nextTax);
    event SellRewardsTaxChanged(uint256 previousTax, uint256 nextTax);
    event DevTaxRescued(uint256 amount);
    event RewardsTaxRescued(uint256 amount);
    event TradingActiveChanged(bool enabled);
    event TaxExclusionChanged(address user, bool taxExcluded);
    event BlacklistUpdated(address user, bool previousStatus, bool nextStatus);
    event SwapFeesChanged(bool previousStatus, bool nextStatus);

    constructor(
        address _factory,
        address _router,
        address payable _devTaxRecipient,
        address payable _rewardsTaxRecipient
    ) ERC20("FAKER INU", "FAKER") Ownable() { 
        taxExcluded[owner()] = true;
        taxExcluded[address(0)] = true;
        taxExcluded[_devTaxRecipient] = true;
        taxExcluded[_rewardsTaxRecipient] = true;
        taxExcluded[address(this)] = true;

        devTaxRecipient = _devTaxRecipient;
        rewardsTaxRecipient = _rewardsTaxRecipient;

        router = IUniswapV2Router02(_router);
        IUniswapV2Factory factory = IUniswapV2Factory(_factory);
        pair = factory.createPair(address(this), router.WETH());

        _mint(msg.sender, MAX_SUPPLY);
    }

    function addLiquidity(uint256 tokens)
        external
        payable
        onlyOwner
        liquidityAdd
    { 
        _rawTransfer(msg.sender, address(this), tokens);
        _approve(address(this), address(router), tokens);

        router.addLiquidityETH{ value: msg.value}(
            address(this),
            tokens,
            0,
            0,
            owner(),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );
    }

    //- @notice Change the address of the devTax recipient
    //- @param _devTaxRecipient The new address of the devTax recipient
    function setDevTaxRecipient(address payable _devTaxRecipient)
        external
        onlyOwner
    { 
        emit DevTaxRecipientChanged(devTaxRecipient, _devTaxRecipient);
        devTaxRecipient = _devTaxRecipient;
    }

    //- @notice Change the address of the rewardTax recipient
    //- @param _rewardsTaxRecipient The new address of the rewardTax recipient
    function setRewardsTaxRecipient(address payable _rewardsTaxRecipient)
        external
        onlyOwner
    { 
        emit RewardsTaxRecipientChanged(
            rewardsTaxRecipient,
            _rewardsTaxRecipient
        );
        rewardsTaxRecipient = _rewardsTaxRecipient;
    }

    //- @notice Change the buy devTax rate
    //- @param _buyDevTax The new devTax rate
    function setBuyDevTax(uint256 _buyDevTax) external onlyOwner { 
        require(
            _buyDevTax <= BPS_DENOMINATOR,
            "_buyDevTax cannot exceed BPS_DENOMINATOR"
        );
        emit BuyDevTaxChanged(buyDevTax, _buyDevTax);
        buyDevTax = _buyDevTax;
    }

    //- @notice Change the buy devTax rate
    //- @param _sellDevTax The new devTax rate
    function setSellDevTax(uint256 _sellDevTax) external onlyOwner { 
        require(
            _sellDevTax <= BPS_DENOMINATOR,
            "_sellDevTax cannot exceed BPS_DENOMINATOR"
        );
        emit SellDevTaxChanged(sellDevTax, _sellDevTax);
        sellDevTax = _sellDevTax;
    }

    //- @notice Change the buy rewardsTax rate
    //- @param _buyRewardsTax The new buy rewardsTax rate
    function setBuyRewardsTax(uint256 _buyRewardsTax) external onlyOwner { 
        require(
            _buyRewardsTax <= BPS_DENOMINATOR,
            "_buyRewardsTax cannot exceed BPS_DENOMINATOR"
        );
        emit BuyRewardsTaxChanged(buyRewardsTax, _buyRewardsTax);
        buyRewardsTax = _buyRewardsTax;
    }

    //- @notice Change the sell rewardsTax rate
    //- @param _sellRewardsTax The new sell rewardsTax rate
    function setSellRewardsTax(uint256 _sellRewardsTax) external onlyOwner { 
        require(
            _sellRewardsTax <= BPS_DENOMINATOR,
            "_sellRewardsTax cannot exceed BPS_DENOMINATOR"
        );
        emit SellRewardsTaxChanged(sellRewardsTax, _sellRewardsTax);
        sellRewardsTax = _sellRewardsTax;
    }

    //- @notice Rescue ATI from the devTax amount
    //- @dev Should only be used in an emergency
    //- @param _amount The amount of ATI to rescue
    //- @param _recipient The recipient of the rescued ATI
    function rescueDevTaxTokens(uint256 _amount, address _recipient)
        external
        onlyOwner
    { 
        require(
            _amount <= totalDevTax,
            "Amount cannot be greater than totalDevTax"
        );
        _rawTransfer(address(this), _recipient, _amount);
        emit DevTaxRescued(_amount);
        totalDevTax -= _amount;
    }

    //- @notice Rescue ATI from the rewardsTax amount
    //- @dev Should only be used in an emergency
    //- @param _amount The amount of ATI to rescue
    //- @param _recipient The recipient of the rescued ATI
    function rescueRewardsTaxTokens(uint256 _amount, address _recipient)
        external
        onlyOwner
    { 
        require(
            _amount <= totalRewardsTax,
            "Amount cannot be greater than totalRewardsTax"
        );
        _rawTransfer(address(this), _recipient, _amount);
        emit RewardsTaxRescued(_amount);
        totalRewardsTax -= _amount;
    }

    //- @notice Admin function to update a recipient's blacklist status
    //- @param user the recipient
    //- @param status the new status
    function updateBlacklist(address user, bool status)
        external
        virtual
        onlyOwner
    { 
        _updateBlacklist(user, status);
    }

    function _updateBlacklist(address user, bool status) internal virtual { 
        emit BlacklistUpdated(user, blacklist[user], status);
        blacklist[user] = status;
    }

    //- @notice Enables trading on Uniswap
    function enableTrading() external onlyOwner { 
        tradingActive = true;
    }

    //- @notice Updates tax exclusion status
    //- @param _account Account to update the tax exclusion status of
    //- @param _taxExcluded If true, exclude taxes for this user
    function setTaxExcluded(address _account, bool _taxExcluded)
        public
        onlyOwner
    { 
        taxExcluded[_account] = _taxExcluded;
        emit TaxExclusionChanged(_account, _taxExcluded);
    }

    //- @notice Enable or disable whether swap occurs during `_transfer`
    //- @param _swapFees If true, enables swap during `_transfer`
    function setSwapFees(bool _swapFees) external onlyOwner { 
        emit SwapFeesChanged(swapFees, _swapFees);
        swapFees = _swapFees;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    { 
        return _balances[account];
    }

    function _addBalance(address account, uint256 amount) internal { 
        _balances[account] = _balances[account] + amount;
    }

    function _subtractBalance(address account, uint256 amount) internal { 
        _balances[account] = _balances[account] - amount;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override { 
        require(!blacklist[recipient], "Recipient is blacklisted");

        if (taxExcluded[sender] || taxExcluded[recipient]) { 
            _rawTransfer(sender, recipient, amount);
            return;
        }

        bool overMinTokenBalance = balanceOf(address(this)) >= minTokenBalance;
        if (overMinTokenBalance && !_inSwap && sender != pair && swapFees) { 
            swapAll();
        }

        uint256 send = amount;
        uint256 devTax;
        uint256 rewardsTax;
        if (sender == pair) { 
            require(tradingActive, "Trading is not yet active");
            if (block.number <= tradingBlock + SNIPE_BLOCKS) { 
                _updateBlacklist(recipient, true);
            }
            (send, devTax, rewardsTax) = _getTaxAmounts(amount, true);
        } else if (recipient == pair) { 
            require(tradingActive, "Trading is not yet active");
            (send, devTax, rewardsTax) = _getTaxAmounts(amount, false);
        } 
        _rawTransfer(sender, recipient, send);
        _takeTaxes(sender, devTax, rewardsTax);
    }

    //- @notice Peforms auto liquidity and tax distribution
    function swapAll() public { 
        if (!_inSwap) { 
            _swap(balanceOf(address(this)));
        }
    }

    //- @notice Perform a Uniswap v2 swap from token to ETH and handle tax distribution
    //- @param amount The amount of token to swap in wei
    //- @dev `amount` is always <= this contract's ETH balance.
    function _swap(uint256 amount) internal lockSwap { 
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), amount);

        uint256 contractEthBalance = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 tradeValue = address(this).balance - contractEthBalance;

        uint256 totalTaxes = totalDevTax.add(totalRewardsTax);
        uint256 devAmount = amount.mul(totalDevTax).div(totalTaxes);
        uint256 rewardsAmount = amount.mul(totalRewardsTax).div(totalTaxes);

        uint256 devEth = tradeValue.mul(totalDevTax).div(totalTaxes);
        uint256 rewardsEth = tradeValue.mul(totalRewardsTax).div(totalTaxes);

        // Update state
        totalDevTax = totalDevTax.sub(devAmount);
        totalRewardsTax = totalRewardsTax.sub(rewardsAmount);

        // Do transfer
        if (devEth > 0) { 
            devTaxRecipient.transfer(devEth);
        }
        if (rewardsEth > 0) { 
            rewardsTaxRecipient.transfer(rewardsEth);
        }
    }

    //- @notice Change the minimum contract ACAP balance before `_swap` gets invoked
    //- @param _minTokenBalance The new minimum balance
    function setMinTokenBalance(uint256 _minTokenBalance) external onlyOwner { 
        minTokenBalance = _minTokenBalance;
    }

    //- @notice Admin function to rescue ETH from the contract
    function rescueETH() external onlyOwner { 
        payable(owner()).transfer(address(this).balance);
    }

    //- @notice Transfers ATI from an account to this contract for taxes
    //- @param _account The account to transfer ATI from
    //- @param _devTaxAmount The amount of devTax tax to transfer
    function _takeTaxes(
        address _account,
        uint256 _devTaxAmount,
        uint256 _rewardsTaxAmount
    ) internal { 
        require(_account != address(0), "taxation from the zero address");

        uint256 totalAmount = _devTaxAmount.add(_rewardsTaxAmount);
        _rawTransfer(_account, address(this), totalAmount);
        totalDevTax += _devTaxAmount;
        totalRewardsTax += _rewardsTaxAmount;
    }

    //- @notice Get a breakdown of send and tax amounts
    //- @param amount The amount to tax in wei
    //- @return send The raw amount to send
    //- @return devTax The raw devTax tax amount
    function _getTaxAmounts(uint256 amount, bool buying)
        internal
        view
        returns (
            uint256 send,
            uint256 devTax,
            uint256 rewardsTax
        )
    { 
        if (buying) { 
            devTax = amount.mul(buyDevTax).div(BPS_DENOMINATOR);
            rewardsTax = amount.mul(buyRewardsTax).div(BPS_DENOMINATOR);
        } else { 
            devTax = amount.mul(sellDevTax).div(BPS_DENOMINATOR);
            rewardsTax = amount.mul(sellRewardsTax).div(BPS_DENOMINATOR);
        }
        send = amount.sub(devTax).sub(rewardsTax);
    }

    // modified from OpenZeppelin ERC20
    function _rawTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal { 
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");

        uint256 senderBalance = balanceOf(sender);
        require(senderBalance >= amount, "transfer amount exceeds balance");
        unchecked { 
            _subtractBalance(sender, amount);
        }
        _addBalance(recipient, amount);

        emit Transfer(sender, recipient, amount);
    }

    function totalSupply() public view override returns (uint256) { 
        return _totalSupply;
    }

    function _mint(address account, uint256 amount) internal override { 
        require(_totalSupply.add(amount) <= MAX_SUPPLY, "Max supply exceeded");
        _totalSupply += amount;
        _addBalance(account, amount);
        emit Transfer(address(0), account, amount);
    }

    receive() external payable { }
}