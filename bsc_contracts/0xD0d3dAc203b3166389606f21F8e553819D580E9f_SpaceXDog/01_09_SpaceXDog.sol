// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./SpaceXDogLib.sol";

contract SpaceXDog is Context, Ownable, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping(address => bool) private _isExcludedFromFee;

    mapping (address => mapping (address => uint256)) private _allowances;


    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    usdtReceiver public _usdtReceiver;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public USDT;

    address public foundAddress;
    address public spaceXDogNFT;

    uint256 public tokenId = 2;
    bool public transferNFTEnabled = true;
    bool public swapNFTEnabled = true;

    uint8 private _foundFee = 5;  // 5 / 100 =  5%
    uint8 private _liquidityFee = 5; // 5 / 100 =  5%

    uint256 public numTokensToSwapAndLiquify = 1000 * (1e18);

    bool public swapAndLiquifyEnabled = true;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 usdtReceived,
        uint256 tokensIntoLiqudity
    );

    constructor (
        string memory name_,
        string memory symbol_,
        uint8  decimals_,
        uint256 total_,
        address router_,
        address usdt_,
        address foundAddress_,
        address spaceXDogNFT_
    ) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        foundAddress = foundAddress_;
        spaceXDogNFT = spaceXDogNFT_;

        _usdtReceiver = new usdtReceiver(usdt_);
        uniswapV2Router = IUniswapV2Router02(router_);
        USDT = usdt_;
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(USDT, address(this));

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _mint(_msgSender(), total_);
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        if (!_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient]) {
            if (transferNFTEnabled && sender != uniswapV2Pair && recipient != uniswapV2Pair) {
                uint256 nftAmount = IERC1155(spaceXDogNFT).balanceOf(sender, tokenId);
                require(nftAmount > 0, "SpaceXDog: Transfer Have No SpaceXDog NFT");
            }

            if (swapNFTEnabled && (sender == uniswapV2Pair || recipient == uniswapV2Pair)) {
                address user = (sender == uniswapV2Pair) ? recipient : sender;
                uint256 nftAmount = IERC1155(spaceXDogNFT).balanceOf(user, tokenId);
                require(nftAmount > 0, "SpaceXDog: Swap Have No SpaceXDog NFT");
            }
        }

        uint256 realAmount = _addFee(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(realAmount);
        emit Transfer(sender, recipient, realAmount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }


    function _addFee(address _from, address _to, uint256 _amount) internal virtual returns (uint256){
        uint256 realAmount = _amount;
        if (!_isExcludedFromFee[_from] && !_isExcludedFromFee[_to]) {
            uint256 foundFeeAmount = _amount.mul(_foundFee).div(10**2);
            _balances[foundAddress] = _balances[foundAddress].add(foundFeeAmount);
            emit Transfer(_from, foundAddress, foundFeeAmount);

            uint256 liquidityFeeAmount = _amount.mul(_liquidityFee).div(10**2);
            _balances[address(this)] = _balances[address(this)].add(liquidityFeeAmount);
            emit Transfer(_from, address(this), liquidityFeeAmount);

            uint256 tokenBalance = balanceOf(address(this));
            if (tokenBalance >= numTokensToSwapAndLiquify && swapAndLiquifyEnabled && _from != uniswapV2Pair) {
                swapAndLiquify(numTokensToSwapAndLiquify);
            }

            realAmount = _amount.mul(10**2 - (_foundFee + _liquidityFee)).div(10**2);
        }
        return realAmount;
    }

    function swapAndLiquify(uint256 contractTokenBalance) private {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        uint256 initialBalance = IERC20(USDT).balanceOf(address(_usdtReceiver));

        // swap tokens for USDT
        swapTokensForTokens(half);

        // how much USDT did we just swap into?
        uint256 newBalance = IERC20(USDT).balanceOf(address(_usdtReceiver)).sub(initialBalance);

        IERC20(USDT).transferFrom(address(_usdtReceiver), address(this), newBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForTokens(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> token
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDT;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of USDT
            path,
            address(_usdtReceiver),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 usdtAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        IERC20(USDT).approve(address(uniswapV2Router), usdtAmount);

        // add the liquidity
        uniswapV2Router.addLiquidity(
            address(this),
            USDT,
            tokenAmount,
            usdtAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function setTokenId(uint256 _tokenId) public onlyOwner {
        tokenId = _tokenId;
    }

    function setWhiteList(address _user, bool _flag) public onlyOwner {
        _isExcludedFromFee[_user] = _flag;
    }

    function setSpaceXDogNFT(address _nft) public onlyOwner {
        spaceXDogNFT = _nft;
    }

    function setFoundAddress(address _fund) public onlyOwner {
        foundAddress = _fund;
    }

    function setFee(uint8 _found, uint8 _liquidity) public onlyOwner {
        require(_found >= 0 && _liquidity >= 0, "SpaceXDog: invalid fee!");
        require(_foundFee + _liquidityFee <= 100, "SpaceXDog: max fee reached!");
        _foundFee = _found;
        _liquidityFee = _liquidity;
    }

    function setTransferNFTEnabled(bool _flag) public onlyOwner {
        transferNFTEnabled = _flag;
    }

    function setSwapNFTEnabled(bool _flag) public onlyOwner {
        swapNFTEnabled = _flag;
    }

    function setSwapAndLiquifyEnabled(bool _flag) public onlyOwner {
        swapAndLiquifyEnabled = _flag;
    }

    function setNumTokensToSwapAndLiquify(uint256 _num) public onlyOwner {
        numTokensToSwapAndLiquify = _num;
    }

    function withdrawLeftUSDT() public onlyOwner {
        uint256 left = IERC20(USDT).balanceOf(address(_usdtReceiver));
        IERC20(USDT).transferFrom(address(_usdtReceiver), owner(), left);
    }

    function withdrawLeftToken(address _token) public onlyOwner {
        uint256 left = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_msgSender(), left);
    }

    function airdrop(address[] memory accounts, uint256 amount) public onlyOwner {
        require(accounts.length > 0, "SpaceXDog: no account");
        require(amount > 0, "SpaceXDog: no amount");
        address cur;
        uint256 totalAmount = (accounts.length).mul(amount);
        require(totalAmount > 0, "SpaceXDog: error amount");
        _balances[msg.sender] = _balances[msg.sender].sub(totalAmount);
        for(uint256 i = 0; i < accounts.length; i++) {
            cur = accounts[i];
            _balances[cur] = _balances[cur].add(amount);
            emit Transfer(msg.sender, cur, amount);
        }
    }
}

contract usdtReceiver {
    constructor(
        address usdt
    ) public {
        IERC20(usdt).approve(msg.sender, ~uint256(0));
    }
}