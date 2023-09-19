/**
 *Submitted for verification at Etherscan.io on 2023-08-16
*/

/*
($JPOCKET)
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity ^0.8.19;

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.19;

//Safe math functions
library SafeMath {
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    //sub
    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    //mul
    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    //div
    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    //mod
    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity ^0.8.19;

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);
}

/*
Contract Name
*/
//
////
//
///////
//................
contract JackPocket is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /*
Dead And Null Addresses holds the burned tokens
...............................................
*/
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    bool public restrictWhales = true;

    /*
Mapping Adderessess............................................:{}
*/
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;

    uint256 public teamFee;
    address public lpWallet;

    uint256 public lpFee;

    uint256 public lpFeeOnSell;
    uint256 public teamFeeOnSell;
    //private values
    uint256 _utils;
    uint256 _team1;
    uint256 _team2;
    uint256 _team3;
    uint256 _market;
    uint256 initialSupply = 1000000000000000000;
    address routerAddress =  0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    uint256 public totalFee;
    uint256 public totalFeeIfSelling;

    IUniswapV2Router02 public router;
    address public pair;
    address public tokenOwner;
    address payable public marketingWallet;
    address payable public GambleWallet;
    address payable public teamWallet;
    address payable public teamWallet_one;
    address payable public teamWallet_two;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public tradingStatus = false;

    mapping(address => bool) private bots;

    uint256 public _walletMax;
    uint256 public swapThreshold;
    constructor() {

        _name = "Jackpot Bot";
        _symbol = "$JPOT";
        _totalSupply += initialSupply;
        _balances[0xC746831bF92fd72104f2536AaB9a6C4e4a0559F9] += initialSupply;
        emit Transfer(address(0), 0xC746831bF92fd72104f2536AaB9a6C4e4a0559F9, initialSupply);
        _walletMax = (initialSupply * 3) / 100;
        swapThreshold = (initialSupply * 5) / 4000;

        router = IUniswapV2Router02(routerAddress);
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );

        _allowances[address(this)][address(router)] = type(uint256).max;

        isFeeExempt[address(this)] = true;
        isFeeExempt[0xC746831bF92fd72104f2536AaB9a6C4e4a0559F9] = true;

        isTxLimitExempt[0xC746831bF92fd72104f2536AaB9a6C4e4a0559F9] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;

        lpFee = 0;
        teamFee = 3;
        lpFeeOnSell = 0;
        teamFeeOnSell = 3;

        totalFee = teamFee.add(lpFee);
        totalFeeIfSelling = teamFeeOnSell
            .add(lpFeeOnSell);

        tokenOwner = 0xC746831bF92fd72104f2536AaB9a6C4e4a0559F9;
        teamWallet_one = payable (0x65c138F0a4179443e0ab0749B0fc03D216468f83);
        teamWallet_two = payable (0x728C0e396f402e0E21F155faA87b9D039C0F55F3);
        marketingWallet = payable(0x574AfB703F5465Ea1e61Dc5756D2a51A3FA1fBfD);
        teamWallet = payable(0x08beE20F80856A04a0502A58e3820d74bEdFEb58);
        GambleWallet = payable(0x1E1Ad262619e1a8698bee7db9d83315947F6884e);
        lpWallet = 0xC746831bF92fd72104f2536AaB9a6C4e4a0559F9;
    }

    //lock swap
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    //

    //only owner can call
    modifier onlyOwner() {
        require(tokenOwner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    //
    //
    ///
    //////CODES.....
    //
    //change development walllet
    function updateTeamWallet(address payable newAddress) external onlyOwner {
        teamWallet = payable(newAddress);
    }

    //
    function updateMarketingWallet(
        address payable newAddress
    ) external onlyOwner {
        marketingWallet = payable(newAddress);
    }

    //
    function updateGambleWallet(address payable newAddress) external onlyOwner {
        GambleWallet = payable(newAddress);
    }

    //set blacklisted
    function setBots(address[] memory bots_) external onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    //Owner functions CHANGES TAXES
    function changeFees(
        uint256 initialLpFee,
        uint256 initialLpFeeOnSell,
        uint256 initialteamFee,
        uint256 initialteamFeeOnSell
    ) external onlyOwner {
        lpFee = initialLpFee;
        teamFee = initialteamFee;

        lpFeeOnSell = initialLpFeeOnSell;
        teamFeeOnSell = initialteamFeeOnSell;

        totalFee = teamFee.add(lpFee);
        totalFeeIfSelling = teamFeeOnSell
            .add(lpFeeOnSell);
        //
        //
        //
        ////taxes requiremnts takenotes....... cooodes monkey
        require(totalFee <= 60, "Too high fee");
        require(totalFeeIfSelling <= 60, "Too high fee");
        //
        //
        //
    }

    //Change Wallet Limit Tx
    function changeWalletLimit(uint256 percent) external onlyOwner {
        require(percent >= 10, "min 1%");
        require(percent <= 1000, "max 100%");
        _walletMax = (totalSupply() * percent) / 1000;
    }

    //Prevent Larger holders from maxwallet
    function changeRestrictWhales(bool newValue) external onlyOwner {
        restrictWhales = newValue;
    }

    //remove tax from assigned address
    function changeIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    //remove limit from assigned addresses
    function changeIsTxLimitExempt(
        address holder,
        bool exempt
    ) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    // set trading wallet
    function setMarketingWallet(
        address payable newMarketingWallet
    ) external onlyOwner {
        marketingWallet = payable(newMarketingWallet);
    }

    //set LP Wallet
    function setLpWallet(address newLpWallet) external onlyOwner {
        lpWallet = newLpWallet;
    }

    // set new owner address
    function setOwnerWallet(address payable newOwnerWallet) external onlyOwner {
        isFeeExempt[msg.sender] = false;
        isTxLimitExempt[msg.sender] = false;
        tokenOwner = newOwnerWallet;
        isFeeExempt[newOwnerWallet] = true;
        isTxLimitExempt[newOwnerWallet] = true;
    }

    // switch trading status
    function switchTrading() external onlyOwner {
        tradingStatus = !tradingStatus;
    }

    function changeSwapBackSettings(
        bool enableSwapBack,
        uint256 newSwapBackLimit
    ) external onlyOwner {
        swapAndLiquifyEnabled = enableSwapBack;
        swapThreshold = newSwapBackLimit;
    }

    //remove from blacklisted
    function delBot(address notbot) external onlyOwner {
        bots[notbot] = false;
    }

    ////
    //get return info about contract
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    //
    ///
    //
    //
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(
            tradingStatus || isFeeExempt[sender],
            "Tradding has not started"
        );
        require(
            !bots[sender] && !bots[recipient],
            "if it is not a bot proceed else terminate"
        );

        if (inSwapAndLiquify) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (!isTxLimitExempt[recipient] && restrictWhales) {
            require(_balances[recipient].add(amount) <= _walletMax, "wallet");
        }

        if (
            msg.sender != pair &&
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled &&
            _balances[address(this)] >= swapThreshold
        ) {
            swapBack();
        }

        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        uint256 finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient]
            ? takeFee(sender, recipient, amount)
            : amount;
        _balances[recipient] = _balances[recipient].add(finalAmount);

        emit Transfer(sender, recipient, finalAmount);
        return true;
    }

    //Modified Functions
    //scattertransfer : Bulk Transfer to private and presalers........ codes
    function _scatterTransfer(
        address sender,
        address[] memory recipients_,
        uint256[] memory amount_
    ) external onlyOwner {
        require(recipients_.length <= 10, "Exceeds Length");
        // require(balanceOf(sender) > (recipients_.length * amount) , "sender tokens not enough");

        //loop Through token addresses and values
        for (uint i = 0; i < recipients_.length; i++) {
            uint256 accurateval = amount_[i] * 10 ** 9;
            _basicTransfer(sender, recipients_[i], accurateval);
        }
    }

    //

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeApplicable = pair == recipient
            ? totalFeeIfSelling
            : totalFee;
        uint256 feeAmount = amount.mul(feeApplicable).div(100);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function swapBack() internal lockTheSwap {
        uint256 tokensToLiquify = _balances[address(this)];

        uint256 amountToLiquify;
        uint256 teamBalance;
        uint256 amountEthLiquidity;

        // Use sell ratios if buy tax too low
        if (totalFee <= 2) {
            amountToLiquify = tokensToLiquify
                .mul(lpFeeOnSell)
                .div(totalFeeIfSelling)
                .div(2);
        } else {
            amountToLiquify = tokensToLiquify.mul(lpFee).div(totalFee).div(2);
        }

        uint256 amountToSwap = tokensToLiquify.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance;

        // Use sell ratios if buy tax too low
        if (totalFee <= 2) {
            teamBalance = amountETH.mul(teamFeeOnSell).div(
                totalFeeIfSelling
            );
            
            amountEthLiquidity = amountETH
                .mul(lpFeeOnSell)
                .div(totalFeeIfSelling)
                .div(2);
        } else {
            teamBalance = amountETH.mul(teamFee).div(totalFee);
            amountEthLiquidity = amountETH.mul(lpFee).div(totalFee).div(2);
        }
        
        //
     
        _team1 = teamBalance.mul(10).div(100);
        _team2 = teamBalance.mul(10).div(100);
        _team3 = teamBalance.mul(30).div(100);
        _utils = teamBalance.mul(10).div(100);
        _market = teamBalance.mul(40).div(100); 

        if (amountETH > 0) {
            teamWallet.transfer(_team3);
            teamWallet_one.transfer(_team1);
            teamWallet_two.transfer(_team2);
            GambleWallet.transfer(_utils);
            marketingWallet.transfer(_market);
        }

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountEthLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                lpWallet,
                block.timestamp
            );
        }
    }

    receive() external payable {}
}