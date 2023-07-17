// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract MagicBag is Ownable, IERC20 {
    using SafeMath for uint256;

    string  private _name;
    string  private _symbol;
    uint8   private _decimals;
    uint256 private _totalSupply;

    uint256 public maxWalletLimit;
    uint256 public maxTxLimit;

    address payable public treasury;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 public buyTax;
    uint256 public sellTax;
    bool    public tradingActive;

    uint256 public totalBurned;
    uint256 public totalLpAdded;
    uint256 public totalReflected;
    uint256 public totalTreasury;
    bool    public burnStatus;
    bool    public autoLpStatus;
    bool    public reflectionStatus;
    bool    public treasuryStatus;

    uint256 public swapableRefection;
    uint256 public swapableTreasury;

    IUniswapV2Router02 public dexRouter; 
    address public lpPair;

    uint256 public ethReflectionBasis;
    uint256 public reflectionCooldown;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => uint256) public  lastReflectionBasis;
    mapping(address => uint256) public  totalClaimedReflection;
    mapping(address => uint256) public  lastReflectionCooldown;
    mapping(address => uint256) private _claimableReflection;
    mapping(address => bool)    private _reflectionExcluded;

    mapping(address => bool) public  lpPairs;
    mapping(address => bool) private _isExcludedFromTax;
    mapping(address => bool) private _bots;

    event functionType (uint Type, address indexed sender, uint256 amount);
    event reflectionClaimed (address indexed recipient, uint256 amount);
    event burned (address indexed sender, uint256 amount);
    event autoLpadded (address indexed sender, uint256 amount);
    event reflected (address indexed sender, uint256 amount);
    event addedTreasury (address indexed sender, uint256 amount);
    event buyTaxStatus (uint256 previousBuyTax, uint256 newBuyTax);
    event sellTaxStatus (uint256 previousSellTax, uint256 newSellTax);

    constructor(string memory name_, 
                string memory symbol_,
                uint256 totalSupply_,
                address payable _treasury,
                uint256 _reflectionCooldown,
                uint256 maxTxLimit_, 
                uint256 maxWalletLimit_) {
        _name              = name_;
        _symbol            = symbol_;
        _decimals          = 18;
        _totalSupply       = totalSupply_.mul(10 ** _decimals);
        _balances[owner()] = _balances[owner()].add(_totalSupply);

        treasury       = payable(_treasury);
        sellTax        = 40;
        buyTax         = 10;
        maxTxLimit     = maxTxLimit_;
        maxWalletLimit = maxWalletLimit_;
        reflectionCooldown = _reflectionCooldown; 

        // BSC Router: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        // ETH Router: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        dexRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        lpPair    = IUniswapV2Factory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());
        lpPairs[lpPair] = true;

        _approve(owner(), address(dexRouter), type(uint256).max);
        _approve(address(this), address(dexRouter), type(uint256).max);

        _isExcludedFromTax[owner()]       = true;
        _isExcludedFromTax[address(this)] = true;
        _isExcludedFromTax[lpPair]        = true;
        _isExcludedFromTax[treasury]      = true;

        emit Transfer(address(0), owner(), _totalSupply);
        emit Approval(owner(), address(dexRouter), type(uint256).max);
        emit Approval(address(this), address(dexRouter), type(uint256).max);
    }

    receive() external payable {}

    /// @notice ERC20 functionalities

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) internal {
        require(sender  != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function allowance(address sender, address spender) public override view returns (uint256) {
        return _allowances[sender][spender];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        address _sender = _msgSender();
        require(_sender   != address(0), "ERC20: Zero Address");
        require(recipient != address(0), "ERC20: Zero Address");
        require(recipient != DEAD, "ERC20: Dead Address");
        require(_balances[_sender] >= amount, "ERC20: Amount exceeds account balance");

        _transfer(_sender, recipient, amount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(sender    != address(0), "ERC20: Zero Address");
        require(recipient != address(0), "ERC20: Zero Address");
        require(recipient != DEAD, "ERC20: Dead Address");
        require(_allowances[sender][_msgSender()] >= amount, "ERC20: Insufficient allowance.");
        require(_balances[sender] >= amount, "ERC20: Amount exceeds sender's account balance");

        if (_allowances[sender][_msgSender()] != type(uint256).max) {
            _allowances[sender][_msgSender()]  = _allowances[sender][_msgSender()].sub(amount);
        }
        _transfer(sender, recipient, amount);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(_bots[sender] == false && _bots[recipient] == false, "ERC20: Bots can't trade");

        if (sender == owner() && lpPairs[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        }
        else if (lpPairs[sender] || lpPairs[recipient]){
            require(tradingActive == true, "ERC20: Trading is not active.");
            
            if (_isExcludedFromTax[sender] && !_isExcludedFromTax[recipient]){
                if (_checkMaxWalletLimit(recipient, amount) && _checkMaxTxLimit(amount)) {
                    _transferFromExcluded(sender, recipient, amount);//buy
                } 
            }   
            else if (!_isExcludedFromTax[sender] && _isExcludedFromTax[recipient]){
                if (_checkMaxTxLimit(amount)) {
                    _transferToExcluded(sender, recipient, amount);//sell
                }
            }
            else if (_isExcludedFromTax[sender] && _isExcludedFromTax[recipient]) {
                if (sender == owner() || recipient == owner() || sender == address(this) || recipient == address(this)) {
                    _transferBothExcluded(sender, recipient, amount);
                } else if (lpPairs[recipient]) {
                    if (_checkMaxTxLimit(amount)) {
                        _transferBothExcluded(sender, recipient, amount);
                    }
                } else if (_checkMaxWalletLimit(recipient, amount) && _checkMaxTxLimit(amount)){
                    _transferBothExcluded(sender, recipient, amount);
                }
            } 
        } else {
            if (sender == owner() || recipient == owner() || sender == address(this) || recipient == address(this)) {
                    _transferBothExcluded(sender, recipient, amount);
            } else if(_checkMaxWalletLimit(recipient, amount) && _checkMaxTxLimit(amount)){
                    _transferBothExcluded(sender, recipient, amount);
            }
        }
    }

    function _transferFromExcluded(address sender, address recipient, uint256 amount) private { //Buy
        uint256 _randomNumber = _generateRandomNumber();
        uint256 taxAmount     = amount.mul(buyTax).div(100);
        uint256 receiveAmount = amount.sub(taxAmount);

        _claimableReflection[recipient] = _claimableReflection[recipient].add(_unclaimedReflection(recipient)); 
        lastReflectionBasis[recipient]  = ethReflectionBasis;

        _balances[sender]    = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(receiveAmount);
        _balances[address(this)] = _balances[address(this)].add(taxAmount);

        if (_randomNumber == 1) {
            _balances[address(this)] = _balances[address(this)].sub(taxAmount);
            _burn(recipient, taxAmount);
        } else if (_randomNumber == 2) {
            _balances[address(this)] = _balances[address(this)].sub(taxAmount);
            _autoLp(recipient, taxAmount);
        } else if (_randomNumber == 3) {
            swapableRefection = swapableRefection.add(taxAmount);
            totalReflected    = totalReflected.add(taxAmount);
            emit reflected(recipient, taxAmount);
        } else if(_randomNumber == 4) {
            swapableTreasury = swapableTreasury.add(taxAmount);
            totalTreasury    = totalTreasury.add(taxAmount);
            emit addedTreasury(recipient, taxAmount);
        }

        emit functionType(_randomNumber, sender, taxAmount);
        emit Transfer(sender, recipient, amount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 amount) private { //Sell
        uint256 _randomNumber = _generateRandomNumber();
        uint256 taxAmount     = amount.mul(sellTax).div(100);
        uint256 sentAmount = amount.sub(taxAmount);

        _balances[sender]    = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(sentAmount);
        _balances[address(this)] = _balances[address(this)].add(taxAmount);

        if(_balances[sender] == 0) {
            _claimableReflection[recipient] = 0;
        }

        if (_randomNumber == 1) {
            _balances[address(this)] = _balances[address(this)].sub(taxAmount);
            _burn(sender, taxAmount);
        } else if (_randomNumber == 2) {
            _balances[address(this)] = _balances[address(this)].sub(taxAmount);
            _autoLp(sender, taxAmount);
        } else if (_randomNumber == 3) {
            swapableRefection = swapableRefection.add(taxAmount);
            totalReflected    = totalReflected.add(taxAmount);
            emit reflected(sender, taxAmount);
        } else if(_randomNumber == 4) {
            swapableTreasury = swapableTreasury.add(taxAmount);
            totalTreasury    = totalTreasury.add(taxAmount);
            emit addedTreasury(sender, taxAmount);
        }

        emit functionType(_randomNumber, sender, taxAmount);
        emit Transfer(sender, recipient, amount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 amount) private {
        if(recipient == owner() || recipient == address(this)){
            _balances[sender]    = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
        } else {
            _claimableReflection[recipient] = _claimableReflection[recipient].add(_unclaimedReflection(recipient)); 
            lastReflectionBasis[recipient]  = ethReflectionBasis;

            _balances[sender]    = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
        }
        emit Transfer(sender, recipient, amount);
    }

    /// @notice Burn Functionalities

    function burn(uint256 amount) public returns (bool) {
        address sender = _msgSender();
        require(_balances[sender] >= amount, "ERC20: Burn Amount exceeds account balance");
        require(amount > 0, "ERC20: Enter some amount to burn");

        _balances[sender] = _balances[sender].sub(amount);
        _burn(sender, amount);

        return true;
    }

    function _burn(address from, uint256 amount) internal {
        _totalSupply = _totalSupply.sub(amount);
        totalBurned  = totalBurned.add(amount);

        emit Transfer(from, address(0), amount);
        emit burned(from, amount);
    }

    /// @notice AutoLp Functionalities

    function _autoLp(address from, uint256 amount) private {
        if (amount > 0) {
            _balances[lpPair]  = _balances[lpPair].add(amount);
            totalLpAdded = totalLpAdded.add(amount);

            emit Transfer(from, lpPair, amount);
            emit autoLpadded(from, amount);
        }
    }

    /// @notice Reflection Functionalities

    function addReflection() public payable returns (bool) {
        ethReflectionBasis = ethReflectionBasis.add(msg.value);
        return true;
    }

    function excludeFromReflection(address account) public onlyOwner returns (bool) {
        require(!_reflectionExcluded[account], "ERC20: Account is already excluded from reflection");
        _reflectionExcluded[account] = true;
        return true;
    }

    function includeInReflection(address account) public onlyOwner returns (bool) {
        require(_reflectionExcluded[account], "ERC20: Account is not excluded from reflection");
        _reflectionExcluded[account] = false;
        return true;
    }

    function isReflectionExcluded(address account) public view returns (bool) {
        return _reflectionExcluded[account];
    }

    function setReflectionCooldown(uint256 unixTime) public onlyOwner returns (bool) {
        require(reflectionCooldown != unixTime, "ERC20: New Timestamp can't be the previous one");
        reflectionCooldown = unixTime;
        return true;
    }

    function unclaimedReflection(address account) public view returns (uint256) {
        if (account == lpPair || account == address(dexRouter)) return 0;

        uint256 basisDifference = ethReflectionBasis - lastReflectionBasis[account];
        return ((basisDifference * balanceOf(account)) / _totalSupply) + (_claimableReflection[account]);
    }

    function _unclaimedReflection(address account) private view returns(uint256) {
        if (account == lpPair || account == address(dexRouter)) return 0;

        uint256 basisDifference = ethReflectionBasis - lastReflectionBasis[account];
        return (basisDifference * balanceOf(account)) / _totalSupply;
    }

    function claimReflection() external returns (bool) {
        address sender = _msgSender(); 
        require(!_isContract(sender), "ERC20: Sender can't be a contract"); 
        require(lastReflectionCooldown[sender] + reflectionCooldown <= block.timestamp, "ERC20: Reflection cool down is implemented, try again later");
        _claimReflection(payable(sender));
        return true;
    }

    function _claimReflection(address payable account) private {
        uint256 unclaimed = unclaimedReflection(account);
        require(unclaimed > 0, "ERC20: Claim amount should be more then 0");
        require(isReflectionExcluded(account) == false, "ERC20: Address is excluded to claim reflection");
        
        lastReflectionBasis[account]  = ethReflectionBasis;
        lastReflectionCooldown[account] = block.timestamp;
        _claimableReflection[account] = 0;
        account.transfer(unclaimed);

        totalClaimedReflection[account] = totalClaimedReflection[account].add(unclaimed);
        emit reflectionClaimed(account, unclaimed);
    }

    /// @notice Magic Bag Functionalities

    function enableTrading() public onlyOwner returns (bool) {
        require(tradingActive == false, "ERC20: Trading is already active");
        tradingActive = true;
        return true;
    }

    function disableTrading() public onlyOwner returns (bool) {
        require(tradingActive == true, "ERC20: Trading is already un-active");
        tradingActive = false;
        return true;
    }

    function setBuyTax(uint256 _buyTax) public onlyOwner returns (bool) {
        require(_buyTax <= 15, "ERC20: The buy tax can't be more then 15 percentage");
        uint256 _prevBuyTax = buyTax;
        buyTax = _buyTax;

        emit buyTaxStatus(_prevBuyTax, buyTax);
        return true;
    }

    function setSellTax(uint256 _sellTax) public onlyOwner returns (bool) {
        require(_sellTax <= 15, "ERC20: The sell tax can't be more then 15 percentage");
        uint256 _prevSellTax = sellTax;
        sellTax = _sellTax;

        emit sellTaxStatus(_prevSellTax, sellTax);
        return true;
    }

    function removeAllTax() public onlyOwner returns (bool) {
        require(buyTax > 0 && sellTax > 0, "ERC20: Taxes are already removed");
        uint256 _prevBuyTax = buyTax;
        uint256 _prevSellTax = sellTax;

        buyTax  = 0;
        sellTax = 0;

        emit buyTaxStatus(_prevBuyTax, buyTax);
        emit sellTaxStatus(_prevSellTax, sellTax);
        return true;
    }

    function reduceTaxes() public onlyOwner returns (bool) {
        uint256 _prevBuyTax = buyTax;
        uint256 _prevSellTax = sellTax;

        buyTax  = 5;
        sellTax = 5;

        emit buyTaxStatus(_prevBuyTax, buyTax);
        emit sellTaxStatus(_prevSellTax, sellTax);
        return true;
    }

    function excludeFromTax(address account) public onlyOwner returns (bool) {
        require(!_isExcludedFromTax[account], "ERC20: Account is already excluded from tax");
        _isExcludedFromTax[account] = true;
        return true;
    }

    function includeInTax(address account) public onlyOwner returns (bool) {
        require(_isExcludedFromTax[account], "ERC20: Account is already included from tax");
        _isExcludedFromTax[account] = false;
        return true;
    }

    function isExcludedFromTax(address account) public view returns (bool) {
        return _isExcludedFromTax[account];
    }

    function setTreasuryAddress(address payable account) public onlyOwner returns (bool) {
        require(treasury != account, "ERC20: Account is already treasury address");
        treasury = account;
        return true;
    }

    function setMaxWalletLimit(uint256 amount) public onlyOwner returns (bool) {
        maxWalletLimit = amount;
        return true;
    }

    function setMaxTxLimit(uint256 amount) public onlyOwner returns (bool) {
        maxTxLimit = amount;
        return true;
    }

    function addBot(address botAccount) public onlyOwner returns (bool) {
        _bots[botAccount] = true;
        return true;
    }

    function addBotsInBulk(address[] memory botsAccounts) public onlyOwner returns (bool) {
        for(uint i = 0; i < botsAccounts.length; i++) {
            _bots[botsAccounts[i]] = true;
        }
        return true;
    }

    function removeBot(address botAccount) public onlyOwner returns (bool) {
        _bots[botAccount] = false;
        return true;
    }

    function isBot(address botAccount) public view returns (bool) {
        return _bots[botAccount];
    }

    function setLpPair(address LpAddress, bool status) public onlyOwner returns (bool) {
        lpPairs[LpAddress] = status;
        _isExcludedFromTax[LpAddress] = status;

        return true;
    }

    function swapReflection(uint256 amount) public onlyOwner returns (bool) {
        require(swapableRefection > 0, "ERC20: There are no tokens to swap");
        require(swapableRefection >= amount, "ERC20: Low swapable reflection");
 
        uint256 currentBalance = address(this).balance;
        _swap(address(this), amount);
        swapableRefection = swapableRefection - amount;

        uint256 ethTransfer = (address(this).balance).sub(currentBalance);
        ethReflectionBasis  = ethReflectionBasis.add(ethTransfer);
        return true;
    }

    function swapTreasury(uint256 amount) public returns (bool) { // add only owner
        require(swapableTreasury > 0, "ERC20: There are no tokens to swap");
        require(swapableTreasury >= amount, "ERC20: Low swapable reflection");

        _swap(treasury, amount);
        swapableTreasury = swapableTreasury - amount;

        return true;
    }

    function recoverAllEth(address to) public onlyOwner returns (bool) {
        payable(to).transfer(address(this).balance);
        return true;
    }

    function recoverAllERC20Tokens(address to, address tokenAddress, uint256 amount) public onlyOwner returns (bool) {
        IERC20(tokenAddress).transfer(to, amount);
        return true;
    }

    /// @notice Magical Functionalities

    function pauseBurn() public onlyOwner returns (bool) {
        require(burnStatus == false, "ERC20: Token Burn is already paused");

        if(autoLpStatus == true && reflectionStatus == true && treasuryStatus == true) {
            revert("ERC20: All four functionalities can't get paused at the same time");
        } else {
            burnStatus = true;
        }
        return true;
    }

    function pauseAutoLp() public onlyOwner returns (bool) {
        require(autoLpStatus == false, "ERC20: Auto LP is already paused");

        if(burnStatus == true && reflectionStatus == true && treasuryStatus == true) {
            revert("ERC20: All four functionalities can't get paused at the same time");
        } else {
            autoLpStatus = true;
        }
        return true;
    }

    function pauseReflection() public onlyOwner returns (bool) {
        require(reflectionStatus == false, "ERC20: Reflection is already paused");

        if(burnStatus == true && autoLpStatus == true && treasuryStatus == true) {
            revert("ERC20: All four functionalities can't get paused at the same time");
        } else {
            reflectionStatus = true;
        }
        return true;
    }

    function pauseTreasury() public onlyOwner returns (bool) {
        require(treasuryStatus == false, "ERC20: Treasury is already paused");

        if(burnStatus == true && autoLpStatus == true && reflectionStatus == true) {
            revert("ERC20: All four functionalities can't get paused at the same time");
        } else {
            treasuryStatus = true;
        }
        return true;
    }

    function unpauseBurn() public onlyOwner returns (bool) {
        require(burnStatus == true, "ERC20: Token Burn is already not paused");
        burnStatus = false;
        return true;
    }

    function unpauseAutoLp() public onlyOwner returns (bool) {
        require(autoLpStatus == true, "ERC20: Auto LP is already not paused");
        autoLpStatus = false;
        return true;
    }

    function unpauseReflection() public onlyOwner returns (bool) {
        require(reflectionStatus == true, "ERC20: Reflection is already not paused");
        reflectionStatus = false;
        return true;
    }

    function unpauseTreasury() public onlyOwner returns (bool) {
        require(treasuryStatus == true, "ERC20: Treasury is already paused");
        treasuryStatus = false;
        return true;
    }

    /// @notice Private Functionalities 

    function _generateRandomNumber() private view returns (uint256) {
        uint256 returnNumber;
        uint256 rem1 = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.gaslimit, tx.origin, block.number, tx.gasprice))) % 2;
        uint256 rem2 = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.gaslimit, tx.origin, block.number, tx.gasprice))) % 3; 

        if(burnStatus == true && autoLpStatus == true && reflectionStatus == true) { 
            returnNumber = 4;
        } 
        else if(burnStatus == true && autoLpStatus == true && treasuryStatus == true) {
            returnNumber = 3;
        } 
        else if(burnStatus == true && reflectionStatus == true && treasuryStatus == true) {
            returnNumber = 2;
        } 
        else if(autoLpStatus == true && reflectionStatus == true && treasuryStatus == true) {
            returnNumber = 1;
        } 
        
        else if(burnStatus == true && autoLpStatus == true) {
            if (rem1 == 0) {returnNumber = 3;}
            else if (rem1 == 1) {returnNumber = 4;}
        } 
        else if(burnStatus == true && reflectionStatus == true) {
            if (rem1 == 0) {returnNumber = 2;}
            else if (rem1 == 1) {returnNumber = 4;}
        } 
        else if(burnStatus == true && treasuryStatus == true) {
            if (rem1 == 0) {returnNumber = 2;}
            else if (rem1 == 1) {returnNumber = 3;}
        } 
        else if(autoLpStatus == true && reflectionStatus == true) {
            if (rem1 == 0) {returnNumber = 1;}
            else if (rem1 == 1) {returnNumber = 4;}
        } else if(autoLpStatus == true && treasuryStatus == true) {
            if (rem1 == 0) {returnNumber = 1;}
            else if (rem1 == 1) {returnNumber = 3;}
        } 
        else if(reflectionStatus == true && treasuryStatus == true) {
            if (rem1 == 0) {returnNumber = 1;}
            else if (rem1 == 1) {returnNumber = 2;}
        } 

        else if(burnStatus == true) {
            returnNumber = (uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.gaslimit, tx.origin, block.number, tx.gasprice))) % 3) + 2;
        }
        else if(autoLpStatus == true) {
            if(rem2 == 0) {returnNumber = 1;}
            else if(rem2 == 1) {returnNumber = 3;}
            else if(rem2 == 2) {returnNumber = 4;}
        }
        else if(reflectionStatus == true) {
            if(rem2 == 0) {returnNumber = 1;}
            else if(rem2 == 1) {returnNumber = 2;}
            else if(rem2 == 2) {returnNumber = 4;}
        }
        else if(treasuryStatus == true) {
            returnNumber = (uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.gaslimit, tx.origin, block.number, tx.gasprice))) % 3) + 1;
        }
        else {
            returnNumber = (uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.gaslimit, tx.origin, block.number, tx.gasprice))) % 4) + 1;
        }

        return returnNumber;
    }

    function _checkMaxWalletLimit(address recipient, uint256 amount) private view returns (bool) {
        require(maxWalletLimit >= balanceOf(recipient).add(amount), "ERC20: Wallet limit exceeds");
        return true;
    }

    function _checkMaxTxLimit(uint256 amount) private view returns (bool) {
        require(amount <= maxTxLimit, "ERC20: Transaction limit exceeds");
        return true;
    }

    function _isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function _swap(address recipient, uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        dexRouter.swapExactTokensForETH(
            amount,
            0,
            path,
            recipient, 
            block.timestamp
        );
    }
}