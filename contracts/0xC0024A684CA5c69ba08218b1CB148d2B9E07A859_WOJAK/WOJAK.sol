/**
 *Submitted for verification at Etherscan.io on 2023-08-31
*/

/**
 * SPDX-License-Identifier: UNLICENSED 
 *
 * Token: WOJAK
 * Web: https://www.wojakcommunity.com/
 * TG: t.me/wojaktokenportal
 * X: https://twitter.com/wojaktoken_erc
 *
 *                                        .:^~~~~~~~~~~~~~~:..                                        
 *                                    :!???7!!!!!!!~~~~~~!!7????7!^:                                  
 *                               .^~?J?!:                      .:~7?J7~.                              
 *                           ^!7J?7~^.                               ^7J?^                            
 *                         .5?~^.                                       ^?J?^                         
 *                        ~P7                                              ~JJ7.                      
 *                      ^5?:                                                 .!J?^                    
 *                      P7                                                      ^YJ.                  
 *                     ^G:                                                        7P:                 
 *                    !P^                                                          !G:                
 *                   .B^                      .^^^~~~~~~~~~~~~!~^^:..:..:::::.      7G                
 *                   !P                        :::..     ..... .:^^^^^^^^^^^^~!^     P?               
 *                   P7                          ..:^~~!~~~^~~~~~::..::...... .:.    ^G               
 *                  J5                    ^~~~~~~~~^:..        .:^^^^^^^~~~~~~       :B^              
 *                  P?                    .....     .:::::::.              .....      ~P!             
 *                  P7                        :^~~!~~^^^^^^~:            ~!~~~~~!~.    ^B:            
 *                 :G.                        ^^.           .~.          .       :~~    JJ            
 *                 :G                                        ~?.         !~             75            
 *                 ^B.                           :^^^^^:      .          !^             .G:           
 *                  P!                          ?Y~~P@@&GY!:                ^^~!??!.    !P            
 *                  J5                          JY~.B@@@@@JP!             :P?~?@@@@P    Y7            
 *                   YY                          :??J5YJYJ??:             ^P7!J#@&#P    5?            
 *                   .G!                                                    ....^!!^    .5J           
 *                    ~B.                                              .P.               .B^          
 *                     ?P.          Y!                                  G7                P7          
 *                      !P~        :#:                                  :5J:              P7          
 *                       :P?       :#.                                    ~Y?:            G!          
 *                        .P7       5J                     .77?!            Y5           YY           
 *                         ^B:       57                    ^#~.    ..      7P:          ?P            
 *                          #~       7P                     !Y7!. ~J7.  ~!?B.          YY             
 *                          B~        !P~                     ::        :~7:         .5J              
 *                          B~        ~^57.                                         .P?               
 *                          B~        ?^ ~J?:             ^~~:.                    !P~                
 *                          #^        7~   ~J?:          .7!!7???7777777??JY^     .B^                 
 *                        7P         ?~     ^JY!:              .......... ^:     !P                  
 *                        ~G:        :?.       .~JJ~                             !5!                  
 *                        YJ         .            :7Y7.                        7Y7.                   
 *                       ^G^                        .7Y7:                   .^5J                      
 *                      !B~          ::               .~?J?!^:.         .^!JJ?~                       
 *                     7G:        ^JJ?!                   :~!??77777YJ77?7~.                          
 *                   ^YY:        ?P^                       :!       JY                                
 *              .::JPY^       .^YY.                         7!^     .YJ!!~^^^^^^^^^:::                
 *         :~7???77?7~       .!7^                            .:       ::^~!!!!!!!!!7??J?77~~          
 *   ^7!!7?J!^:.                               ..                                      .:^~!.         
 *   :^^^^.                                   ^~~!~^    :!~~~                                         
 *                                                .!7^^~?:..                                          
 *                                                  ...:                                              
 *
*/

pragma solidity ^0.8.20;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

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

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract WOJAK is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "Wojak";
    string private constant _symbol = "WOJAK";
    uint8 private constant _decimals = 9;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1e12 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private minContractTokensToSwap = 1e9 * 10**9;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromMaxWallet;
    mapping (address => bool) private _bots;
    uint256 private _taxFee = 0;
    uint256 private _teamFee = 0;
    uint256 private _maxWalletSize = 1e10 * 10**9;
    uint256 private _buyFee = 12;
    uint256 private _sellFee = 12;
    uint256 private _previousTaxFee = _taxFee;
    uint256 private _previousteamFee = _teamFee;
    address payable private _developmentWallet;
    address payable private _marketingWallet;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen = false;
    bool private _swapAll = true;
    bool private inSwap = false;
    mapping(address => bool) private automatedMarketMakerPairs;

    event Response(bool dev, bool marketing);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
        constructor () {

        _developmentWallet = payable(0x6d1A94e077BDaC9e3519F611849352DB8f10d61e);
        _marketingWallet = payable(0xA85eEfB09e5Baf10667099CC94B80964D70c65c6);
        
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_developmentWallet] = true;
        _isExcludedFromFee[_marketingWallet] = true;
        _isExcludedFromMaxWallet[owner()] = true;
        _isExcludedFromMaxWallet[address(this)] = true;
        _isExcludedFromMaxWallet[_developmentWallet] = true;
        _isExcludedFromMaxWallet[_marketingWallet] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }
    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(from != owner() && to != owner()) {
            
            require(!_bots[from] && !_bots[to]);

            if(to != uniswapV2Pair && !_isExcludedFromMaxWallet[to] && _maxWalletSize != 0) {
                require(balanceOf(address(to)) + amount <= _maxWalletSize, "TOKEN: Balance exceeds wallet size!");
            }
            
            if(from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(tradingOpen, "Trading not yet enabled.");
                _teamFee = _buyFee;
            }
            uint256 contractTokenBalance = balanceOf(address(this));

            if(!inSwap && from != uniswapV2Pair && tradingOpen) {

                _teamFee = _sellFee;

                if (automatedMarketMakerPairs[to]) {
                    if(contractTokenBalance > minContractTokensToSwap) {
                        if(!_swapAll) {
                            contractTokenBalance = minContractTokensToSwap;
                        }
                        swapBack(contractTokenBalance);
                    }
                }

            }
        }
        bool takeFee = true;

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        if(!automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to]) {
            takeFee = false;
        }
        
        _tokenTransfer(from,to,amount,takeFee);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function swapBack(uint256 contractTokenBalance) private {
        
        swapTokensForEth(contractTokenBalance);

        uint256 contractETHBalance = address(this).balance;
        if(contractETHBalance > 0) {
            sendETHToFee(address(this).balance);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
        
    function sendETHToFee(uint256 amount) private {
        (bool development, ) = _developmentWallet.call{value: amount.div(2)}("");
        (bool marketing, ) = _marketingWallet.call{value: amount.div(2)}("");

        emit Response(development, marketing);
    }
    
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        _transferStandard(sender, recipient, amount);
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 

        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, _taxFee, _teamFee);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 taxFee, uint256 TeamFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(taxFee).div(100);
        uint256 tTeam = tAmount.mul(TeamFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if(rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate =  _getRate();
        uint256 rTeam = tTeam.mul(currentRate);

        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}
    
    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        tradingOpen = true;
        automatedMarketMakerPairs[uniswapV2Pair] = true;
    }

    function setDevelopmentWallet (address payable development) external onlyOwner() {
        _isExcludedFromFee[_developmentWallet] = false;
        _developmentWallet = development;
        _isExcludedFromFee[development] = true;
    }
    
    function setMarketingWallet (address payable marketing) external onlyOwner {
        _isExcludedFromFee[_marketingWallet] = false;
        _marketingWallet = marketing;
        _isExcludedFromFee[marketing] = true;
    }

    function excludeFromFee(address[] calldata ads, bool onoff) public onlyOwner {
        for (uint i = 0; i < ads.length; i++) {
            _isExcludedFromFee[ads[i]] = onoff;
        }
    }

    function isExcludedFromFee(address ad) public view returns (bool) {
        return _isExcludedFromFee[ad];
    }

    function excludeFromMaxWallet(address[] calldata ads, bool onoff) public onlyOwner {
        for (uint i = 0; i < ads.length; i++) {
            _isExcludedFromMaxWallet[ads[i]] = onoff;
        }
    }
    
    function isExcludedMaxWallet(address ad) public view returns (bool) {
        return _isExcludedFromMaxWallet[ad];
    }

    function setFee(uint256 buy, uint256 sell) external onlyOwner {
        _buyFee = buy;
        _sellFee = sell;
    }

    function setTaxFee(uint256 tax) external onlyOwner {
        _taxFee = tax;
    }
    
    function setMinContractTokensToSwap(uint256 numToken) external onlyOwner {
        minContractTokensToSwap = numToken * 10**9;
    }

    function setMaxWallet(uint256 amt) external onlyOwner {
        _maxWalletSize = amt * 10**9;
    }

    function setSwapAll(bool onoff) external onlyOwner {
        _swapAll = onoff;
    }

    function manualswap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function thisBalance() public view returns (uint) {
        return balanceOf(address(this));
    }

    function amountInPool() public view returns (uint) {
        return balanceOf(uniswapV2Pair);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function removeAllFee() private {
        if(_taxFee == 0 && _teamFee == 0) return;
        _previousTaxFee = _taxFee;
        _previousteamFee = _teamFee;
        _taxFee = 0;
        _teamFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _teamFee = _previousteamFee;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}