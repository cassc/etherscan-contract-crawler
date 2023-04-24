/**
 *Submitted for verification at BscScan.com on 2023-04-20
*/

/**
    THE MEME OF ALL MEMES! 
    2/2 TAX
    LP BURNT 
    CONTRACT RENOUNCED SHORTLY AFTER LAUNCH
    I haven't made a telegram, feel free to :) 

                                        .:^~!7?JY55PPPP55Y?~:                                    
                                      .:~?5GBBBBGGPPP555PGGPGB#B5!:                                 
                                   :~JPB#BGPYJJJ????????????JY5PB#BJ:                               
                                .!YB#BP5YJ?????????????????????JY5G#B?.                             
                              .7G#BPYJ????????????????????????????Y5G&G~                            
                             !G&GYJ????????????????????????????????JYP##7.                          
                           ^Y##5J????????????????????????????????????J5#&J.                         
                         .7B&G5J???????????????????????????????????????Y#&?                         
                        .J&#YJ??????????????????????????????????????????Y##!                        
                       .Y&BYJ????????????????????????????????????????????5&B^                       
                       J&#[email protected]                      
                      !&#5J???????????????????????????????????????????????J#&!                      
                     ^B&5J?????JJJJJJJJJJJ????????????????????JJJYYJJJJ?JJ?5&B:                     
                     [email protected]???JY55PPPPGGGGP5YJJJJ??????????JY55GBB######[email protected]                    
                    :B&Y???JPB#BBP5YYYY5GB##GYY5J???????J5B&&&B5J7!!!!?JP#&BP&&~                    
                    ~&BJ??5##57^:.      .:!Y&&PY5J?????JG&@B?~..        .^J#@@@5                    
                    [email protected]?JP&P~.             .7#@[email protected]&Y:               [email protected]@#:                   
                   .P&YJY&G:                [email protected]@PJJ??JJ#@P:                 ^[email protected]&~                   
                   .B&[email protected]                  ^[email protected]#YJ??JY&@?.                 [email protected]@7                   
                   .G&[email protected]   :~?J?~        [email protected]@[email protected]@7          ^7Y5Y~  [email protected]@?                   
                    [email protected]@B^   JG#&#G~       :[email protected]@[email protected]@?.        .PP#@&G: ~#@@7                   
                    [email protected]@@5:  7B&#PY:      .J&@&[email protected]@P:         7PBB57.^[email protected]@&~                   
                    ~&#JY#@@5^  ^!!^.     .^Y&@@[email protected]@&Y:         .::[email protected]@@#:                   
                    [email protected]&@@#J~.      .:!Y#@@@&[email protected]@@G7^..    ..:^7P&@@&@P.                   
                     [email protected]&@@@&BPYJJJ5G#&@@@@&[email protected]@@@#BP5555PGB&@@@&G#&!                    
                     ^#&Y?J5B&@@@@@@@@@@@@@@&BYJ????????J5B#&@@@@@@@@@@@@&B5P&5.                    
                     [email protected]?JJ5G#&@@@@@@@&&#G5JJ??????????YYY5PGB#&&&&&#BPYJY##~                     
                      ~##[email protected]                      
                       J&#Y?????JJJJJYYYJJJ??????????????????JJYYYYYJJJ???Y&B:                      
                       [email protected]???????JJYYYYJJJJ???????????JJJYY5PGGGBBGG5J?JB&7                       
                        .5&GJ???JYG##GBBBBBBBGGGGGPGGGGGGGPGBGG#PGB5P#&GJG&J.                       
                         .Y&[email protected]@@#&5YGP5BPY5B5JPBP5#G5YG#JG&GG&[email protected]@#G&5.                        
                          [email protected][email protected]@@&@&&@&#&Y?P&&BG&@&@@@@@&#@@@&#&@@@&&Y.                         
                           ^P&#PJ5&@#5&PP&@@@&&@@@@@@@@@@@@@@&&@#?P#&@@#?.                          
                            .7G&B55B#PBYY#5G#B&@@@@@@&@@@#BB&GY#BP#&&&P^                            
                              :7G&#PPGBBBBYGG?Y&#55B#Y#&&#P5BBG##&&#Y~.                             
                                .~YB#BGPPGBBBGBBBG5P#GBBBBBBBB#&#P7:                                
                                   .~JPBBBBGGGPPPPPGGGGBBB#BGPJ!:                                   
                                      ..:7JJYPP5YJ?Y55YJ?7~:.                                       
                                                              
*/

pragma solidity 0.8.16;
// SPDX-License-Identifier: Unlicensed

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface PancakeSwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface PancakeSwapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// Contracts and libraries

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        authorizations[_owner] = true;
        emit OwnershipTransferred(address(0), msgSender);
    }
    mapping (address => bool) internal authorizations;

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract SALADFINGERS is Ownable, IBEP20 {
    using SafeMath for uint256;

    uint8 public constant _decimals = 18;

    uint256 public _totalSupply = 100000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply * 1000 / 1000;
    uint256 public _walletMax = _totalSupply * 10 / 1000;
    address public DEAD_WALLET = 0x000000000000000000000000000000000000dEaD;
    address public ZERO_WALLET = 0x0000000000000000000000000000000000000000;
    address private wBNB;
    address public pancakeAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    string public constant _name = "Salad Fingers";
    string public constant _symbol = "SPOONS";

    bool public restrictWhales = true;

    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public _allowances;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;

    uint256 public liquidityFee = 1;
    uint256 public marketingFee = 1;
    uint256 public rewardsFee = 0;
    uint256 public treasuryFee = 0;

    uint256 public totalFee = 0;
    uint256 public totalFeeIfSelling = 0;

    address private autoLiquidityReceiver;
    address public marketingWallet;
    address private treasuryWallet;
    address private rewardsWallet;

    PancakeSwapRouter public router;
    address public pair;

    bool public tradingOpen = true;
    bool public blacklistMode = true;
    mapping(address => bool) public isBlacklisted;

    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyByLimitOnly = false;
    bool public takeBuyFee = true;
    bool public takeSellFee = true;
    bool public takeTransferFee = false;

    uint256 public swapThreshold = _totalSupply * 4 / 2000;

    event AutoLiquify(uint256 amountLPTOKEN, uint256 amountBOG);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        router = PancakeSwapRouter(pancakeAddress);
        wBNB = router.WETH();
        pair = PancakeSwapFactory(router.factory()).createPair(wBNB, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
        _allowances[address(this)][address(pair)] = type(uint256).max;

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[DEAD_WALLET] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[DEAD_WALLET] = true;

        autoLiquidityReceiver = msg.sender;
        marketingWallet = 0x97A1697C188D1c4aDc3990820AaE4208fD4E1F55;
        treasuryWallet = 0x97A1697C188D1c4aDc3990820AaE4208fD4E1F55;
        rewardsWallet = 0x97A1697C188D1c4aDc3990820AaE4208fD4E1F55;
        
        isFeeExempt[marketingWallet] = true;
        totalFee = liquidityFee.add(marketingFee).add(treasuryFee).add(rewardsFee);
        totalFeeIfSelling = totalFee;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function name() external pure override returns (string memory) {return _name;}

    function symbol() external pure override returns (string memory) {return _symbol;}

    function decimals() external pure override returns (uint8) {return _decimals;}

    function totalSupply() external view override returns (uint256) {return _totalSupply;}

    function getOwner() external view override returns (address) {return owner();}

    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}

    function allowance(address holder, address spender) external view override returns (uint256) {return _allowances[holder][spender];}

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD_WALLET)).sub(balanceOf(ZERO_WALLET));
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function fullWhitelist(address _address) public onlyOwner{
        isFeeExempt[_address] = true;
        isTxLimitExempt[_address] = true;
        authorizations[_address] = true;
    }

    function isAuth(address _address, bool status) public onlyOwner{
        authorizations[_address] = status;
    }
    
    function setFeeReceivers(address newMktWallet, address newTreasuryWallet, address newLpWallet, address newRewardsWallet) public onlyOwner{
        autoLiquidityReceiver = newLpWallet;
        marketingWallet = newMktWallet;
        treasuryWallet = newTreasuryWallet;
        rewardsWallet = newRewardsWallet;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (inSwapAndLiquify) {return _basicTransfer(sender, recipient, amount);}
        if(!authorizations[sender] && !authorizations[recipient]){
            require(tradingOpen, "Trading not open yet");
        }

        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
        if (msg.sender != pair && !inSwapAndLiquify && swapAndLiquifyEnabled && _balances[address(this)] >= swapThreshold) {marketingAndLiquidity();}

        // Blacklist
        if (blacklistMode) {
            require(!isBlacklisted[sender],"Blacklisted");
        }

        //Exchange tokens
         _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        if (!isTxLimitExempt[recipient] && restrictWhales) {
            require(_balances[recipient].add(amount) <= _walletMax, "Max wallet violated!");
        }

        uint256 finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient] ? extractFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(finalAmount);

        emit Transfer(sender, recipient, finalAmount);
        return true;
    }

    function marketingAndLiquidity() internal lockTheSwap {
        inSwapAndLiquify = true;

        uint256 tokensToLiquify = _balances[address(this)];
        uint256 amountToLiquify = tokensToLiquify.mul(liquidityFee).div(totalFee).div(2);
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

        uint256 amountBNB = address(this).balance;

        uint256 totalBNBFee = totalFee.sub(liquidityFee.div(2));

        uint256 amountBNBLiquidity = amountBNB.mul(liquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);
        uint256 amountBNBTreasury = amountBNB.mul(treasuryFee).div(totalBNBFee);
        uint256 amountBNBRewards = amountBNB.mul(rewardsFee).div(totalBNBFee);
        
        
        (bool tmpSuccess1,) = payable(marketingWallet).call{value : amountBNBMarketing, gas : 30000}("");

        (bool tmpSuccess2,) = payable(treasuryWallet).call{value : amountBNBTreasury, gas : 30000}("");

        (bool tmpSuccess3,) = payable(rewardsWallet).call{value : amountBNBRewards, gas : 30000}("");

        tmpSuccess1 = false;
        tmpSuccess2 = false;
        tmpSuccess3 = false;

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value : amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }

        inSwapAndLiquify = false;

    }

    function extractFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint feeApplicable = 0;
        if (recipient == pair && takeSellFee) {
            feeApplicable = totalFeeIfSelling;        
        }
        if (sender == pair && takeBuyFee) {
            feeApplicable = totalFee;        
        }
        if (sender != pair && recipient != pair){
            if (takeTransferFee){
                feeApplicable = totalFeeIfSelling; 
            }
            else{
                feeApplicable = 0;
            }
        }
        uint256 feeAmount = amount.mul(feeApplicable).div(100);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }


    // CONTRACT OWNER FUNCTIONS

    function setWalletLimitPercent1000(uint256 newLimit) external onlyOwner {
        _walletMax = _totalSupply * newLimit / 1000;
    }

    function tradingStatus(bool newStatus) public onlyOwner {
        tradingOpen = newStatus;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setTakeBuyfee(bool status) public onlyOwner{
        takeBuyFee = status;
    }

    function setTakeSellfee(bool status) public onlyOwner{
        takeSellFee = status;
    }

    function setTakeTransferfee(bool status) public onlyOwner{
        takeTransferFee = status;
    }

    function manualMarketingAndLiquidity() external onlyOwner {
        marketingAndLiquidity();
    }

    function setFees(uint256 newLiqFee, uint256 newMarketingFee, uint256 newTreasuryFee, uint256 newRewardsFee, uint256 extraSellFee) external onlyOwner {
        liquidityFee = newLiqFee;
        marketingFee = newMarketingFee;
        treasuryFee = newTreasuryFee;
        rewardsFee = newRewardsFee;

        totalFee = liquidityFee.add(marketingFee).add(treasuryFee).add(rewardsFee);
        totalFeeIfSelling = totalFee + extraSellFee;
        require (totalFeeIfSelling < 25);
    }

    function enable_blacklist(bool _status) public onlyOwner {
        blacklistMode = _status;
    }

        
    function manage_blacklist(address[] calldata addresses, bool status) public onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            isBlacklisted[addresses[i]] = status;
        }
    }

    function rescueToken(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        return IBEP20(tokenAddress).transfer(msg.sender, tokens);
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer(amountETH * amountPercentage / 100);
    }

    function multiTransfer_fixed( address[] calldata addresses, uint256 tokens) external onlyOwner {
        require(addresses.length < 2001,"GAS Error: max airdrop limit is 2000 addresses"); // to prevent overflow
        uint256 SCCC = tokens * addresses.length;
        require(balanceOf(msg.sender) >= SCCC, "Not enough tokens in wallet");
        for(uint i=0; i < addresses.length; i++){
            _basicTransfer(msg.sender, addresses[i], tokens);
        }
    }
    
}