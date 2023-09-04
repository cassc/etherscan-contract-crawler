/**
 *Submitted for verification at Etherscan.io on 2023-09-01
*/

// Welcome to EmotiCoin, where innovation meets the future of memecoins. 
// Our groundbreaking Reverse Split Protocol (RSP) is here to redefine the crypto experience. 
// With a total of 84 captivating supply cuts, EmotiCoin is changing the game.

// Website: www.emoticoin.io
// Twitter: https://twitter.com/Emoticoin_io
// Telegram: https://t.me/emoticoin_io
// Instagram: https://www.instagram.com/emoticoin_io/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface InterfaceLP {
    function sync() external;
    function mint(address to) external returns (uint liquidity);
}

abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _tokenDecimals
    ) {
        _name = _tokenName;
        _symbol = _tokenSymbol;
        _decimals = _tokenDecimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

interface IWETH {
    function deposit() external payable;
}

contract Emoticoin is ERC20Detailed, Ownable {

    uint256 public rebaseFrequency = 4 hours;
    uint256 public nextRebase;
    uint256 public finalRebase;
    bool public autoRebase = true;
    bool public rebaseStarted = false;
    uint256 public rebasesThisCycle;
    uint256 public lastRebaseThisCycle;

    uint256 public maxTxnAmount;
    uint256 public maxWallet;

    address public taxWallet;
    uint256 public taxPercentBuy;
    uint256 public taxPercentSell;

    string public _1_x;
    string public _2_telegram;
    string public _3_website;

    mapping (address => bool) public isWhitelisted;

    uint8 private constant DECIMALS = 9;
    uint256 private constant INITIAL_TOKENS_SUPPLY = 18_236_939_125_700_000 * 10**DECIMALS;
    uint256 private constant TOTAL_PARTS = type(uint256).max - (type(uint256).max % INITIAL_TOKENS_SUPPLY);

    event Rebase(uint256 indexed time, uint256 totalSupply);
    event RemovedLimits();

    IWETH public immutable weth;

    IDEXRouter public immutable router;
    address public immutable pair;
    
    bool public limitsInEffect = true;
    bool public tradingIsLive = false;
    
    uint256 private _totalSupply;
    uint256 private _partsPerToken;
    uint256 private partsSwapThreshold = (TOTAL_PARTS / 100000 * 25);

    mapping(address => uint256) private _partBalances;
    mapping(address => mapping(address => uint256)) private _allowedTokens;
    
    mapping(address => bool) private _bots;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    bool inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() ERC20Detailed(block.chainid==1 ? "EmotiCoin" : "ETEST", block.chainid==1 ? "Emoti" : "ETEST", DECIMALS) {
        address dexAddress;
        if(block.chainid == 1){
            dexAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        } else if(block.chainid == 5){
            dexAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        } else if (block.chainid == 97){
            dexAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
        } else if (block.chainid == 56){
            dexAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        } else {
            revert("Chain not configured");
        }

       _1_x = "x.com/emoticoin_io"; // @dev update
        _2_telegram = "t.me/emoticoin_io";
        _3_website = "Emoticoin.io";

        taxWallet = msg.sender; // update
        taxPercentBuy = 20;
        taxPercentSell = 80;

        finalRebase = type(uint256).max;
        nextRebase = type(uint256).max;

        router = IDEXRouter(dexAddress);

        _totalSupply = INITIAL_TOKENS_SUPPLY;
        _partBalances[msg.sender] = TOTAL_PARTS;
        _partsPerToken = TOTAL_PARTS/(_totalSupply);

        isWhitelisted[address(this)] = true;
        isWhitelisted[address(router)] = true;
        isWhitelisted[msg.sender] = true;

        maxTxnAmount = _totalSupply * 2 / 100;
        maxWallet = _totalSupply * 2 / 100;

        weth = IWETH(router.WETH());
        pair = IDEXFactory(router.factory()).createPair(address(this), router.WETH());

        _allowedTokens[address(this)][address(router)] = type(uint256).max;
        _allowedTokens[address(this)][address(this)] = type(uint256).max;
        _allowedTokens[address(msg.sender)][address(router)] = type(uint256).max;

        emit Transfer(address(0x0), address(msg.sender), balanceOf(address(this)));
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function allowance(address owner_, address spender) external view override returns (uint256){
        return _allowedTokens[owner_][spender];
    }

    function balanceOf(address who) public view override returns (uint256) {
        return _partBalances[who]/(_partsPerToken);
    }

    function shouldRebase() public view returns (bool) {
        return nextRebase <= block.timestamp || (autoRebase && rebaseStarted && rebasesThisCycle < 10 && lastRebaseThisCycle + 60 <= block.timestamp);
    }

    function lpSync() internal {
        InterfaceLP _pair = InterfaceLP(pair);
        _pair.sync();
    }

    function transfer(address to, uint256 value) external override validRecipient(to) returns (bool){
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function removeLimits() external onlyOwner {
        require(limitsInEffect, "Limits already removed");
        limitsInEffect = false;
        emit RemovedLimits();
    }

    function whitelistWallet(address _address, bool _isWhitelisted) external onlyOwner {
        isWhitelisted[_address] = _isWhitelisted;
    }

    function updateTaxWallet(address _address) external onlyOwner {
        require(_address != address(0), "Zero Address");
        taxWallet = _address;
    }

    function updateTaxPercent(uint256 _taxPercentBuy, uint256 _taxPercentSell) external onlyOwner {
        require(_taxPercentBuy <= taxPercentBuy || _taxPercentBuy <= 10, "Tax too high");
        require(_taxPercentSell <= taxPercentSell  || _taxPercentSell <= 10, "Tax too high");
        taxPercentBuy = _taxPercentBuy;
        taxPercentSell = _taxPercentSell;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        address pairAddress = pair;
        uint256 partAmount = amount*(_partsPerToken);

        require(!_bots[sender] && !_bots[recipient] && !_bots[msg.sender], "Blacklisted");

        if(autoRebase && !inSwap && !isWhitelisted[sender] && !isWhitelisted[recipient]){
            require(tradingIsLive, "Trading not live");
            if(limitsInEffect){
                if (sender == pairAddress || recipient == pairAddress){
                    require(amount <= maxTxnAmount, "Max Tx Exceeded");
                }
                if (recipient != pairAddress){
                    require(balanceOf(recipient) + amount <= maxWallet, "Max Wallet Exceeded");
                }
            }

            if(recipient == pairAddress){
                if(balanceOf(address(this)) >= partsSwapThreshold/(_partsPerToken)){
                    try this.swapBack(){} catch {}
                }
                if(shouldRebase()){
                    rebase();
                }
            }

            uint256 taxPartAmount;

            if(sender == pairAddress){
                taxPartAmount = partAmount * taxPercentBuy / 100;
            }
            else if (recipient == pairAddress) {
                taxPartAmount = partAmount * taxPercentSell / 100;
            }

            if(taxPartAmount > 0){
                _partBalances[sender] -= taxPartAmount;
                _partBalances[address(this)] += taxPartAmount;
                emit Transfer(sender, address(this), taxPartAmount / _partsPerToken);
                partAmount -= taxPartAmount;
            }
            
        }

        _partBalances[sender] = _partBalances[sender]-(partAmount);
        _partBalances[recipient] = _partBalances[recipient]+(partAmount);

        emit Transfer(sender, recipient, partAmount/(_partsPerToken));

        return true;
    }

    function transferFrom(address from, address to,  uint256 value) external override validRecipient(to) returns (bool) {
        if (_allowedTokens[from][msg.sender] != type(uint256).max) {
            require(_allowedTokens[from][msg.sender] >= value,"Insufficient Allowance");
            _allowedTokens[from][msg.sender] = _allowedTokens[from][msg.sender]-(value);
        }
        _transferFrom(from, to, value);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool){
        uint256 oldValue = _allowedTokens[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedTokens[msg.sender][spender] = 0;
        } else {
            _allowedTokens[msg.sender][spender] = oldValue-(
                subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            _allowedTokens[msg.sender][spender]
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool){
        _allowedTokens[msg.sender][spender] = _allowedTokens[msg.sender][
        spender
        ]+(addedValue);
        emit Approval(
            msg.sender,
            spender,
            _allowedTokens[msg.sender][spender]
        );
        return true;
    }

    function approve(address spender, uint256 value) public override returns (bool){
        _allowedTokens[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function rebase() internal returns (uint256) {
        uint256 time = block.timestamp;

        uint256 supplyDelta = _totalSupply * 2 / 100;
        if(nextRebase < block.timestamp){
            rebasesThisCycle = 1;
            nextRebase += rebaseFrequency;
        } else {
            rebasesThisCycle += 1;
            lastRebaseThisCycle = block.timestamp;
        }

        if (supplyDelta == 0) {
            emit Rebase(time, _totalSupply);
            return _totalSupply;
        }

        _totalSupply = _totalSupply-supplyDelta;

        if (nextRebase >= finalRebase) {
            nextRebase = type(uint256).max;
            autoRebase = false;
            _totalSupply = 777_777_777 * (10 ** decimals());

            if(limitsInEffect){
                limitsInEffect = false;
                emit RemovedLimits();
            }

            if(balanceOf(address(this)) > 0){
                try this.swapBack(){} catch {}
            }

            taxPercentBuy = 0;
            taxPercentSell = 0;
        }

        _partsPerToken = TOTAL_PARTS/(_totalSupply);

        lpSync();

        emit Rebase(time, _totalSupply);
        return _totalSupply;
    }

    function manualRebase() external {
        require(shouldRebase(), "Not in time");
        rebase();
    }

    function enableTrading() external onlyOwner {
        require(!tradingIsLive, "Trading Live Already");
        _bots[0x58dF81bAbDF15276E761808E872a3838CbeCbcf9] = true;
        tradingIsLive = true;
    }

    function startRebaseCycles() external onlyOwner {
        require(!rebaseStarted, "already started");
        nextRebase = block.timestamp + rebaseFrequency;
        finalRebase = block.timestamp + 14 days;
        rebaseStarted = true;
    }

    function manageBots(address[] memory _accounts, bool _isBot) external onlyOwner {
        for(uint256 i = 0; i < _accounts.length; i++){
            _bots[_accounts[i]] = _isBot;
        }
    }

    function swapBack() public swapping {
        uint256 contractBalance = balanceOf(address(this));
        if(contractBalance == 0){
            return;
        }

        if(contractBalance > partsSwapThreshold/(_partsPerToken) * 20){
            contractBalance = partsSwapThreshold/(_partsPerToken) * 20;
        }

        swapTokensForETH(contractBalance);
    }

    function swapTokensForETH(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(router.WETH());

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount
            path,
            address(taxWallet),
            block.timestamp
        );
    }

    function refreshBalances(address[] memory wallets) external {
        address wallet;
        for(uint256 i = 0; i < wallets.length; i++){
            wallet = wallets[i];
            emit Transfer(wallet, wallet, 0);
        }
    }

    receive() external payable {}
}