// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./Dealer.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IDealer.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(owner, spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[from] = fromBalance - amount;
        _balances[to] += amount;
    }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
    unchecked {
        _balances[account] += amount;
    }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
        unchecked {
            _approve(owner, spender, currentAllowance - amount);
        }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract MegaLotto is ERC20, Ownable, VRFConsumerBase {
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public immutable pairCurrency;
    address public wallet;
    address public dealer;
    address[] public excludeWallet;
    address[] public holder;
    mapping (address => uint256) public holderId;
    uint256 public winnerNumber;
    uint256 public feeSelling;
    uint256 public feeBuying;
    uint256 public feeToWallet;
    uint256 public startReward;
    bool public alreadyRandom;
    bool public alreadyDistributed;
    mapping (address => bool) public whitelist;
    bytes32 internal keyHash;
    uint256 internal feeChainlink;
    uint256 public randomSeed;
    bytes32 public chainlinkId;

    event RequestFulfilled(bytes32 requestId, uint256 randomness);
    event OnWhitelist(address _whitelist, bool _status);
    event OnSetFeeSelling(uint256 _fee);
    event OnSetFeeBuying(uint256 _fee);
    event OnSetFeeToWallet(uint256 _fee);
    event OnSetWallet(address _wallet);
    event OnRandomSeed(bytes32 _requestId);
    event OnSetExcludeLotto(address _adr);
    event OnDistributeReward(uint256 _amount);

    constructor(address _WBNB) ERC20("2023 Mega Lotto", "2023") VRFConsumerBase(
        0x747973a5A2a4Ae1D3a8fDF5479f1514F65Db9C31, // VRF Coordinator
        0x404460C6A5EdE2D891e8297795264fDe62ADBB75 // LINK Token
    ) {
        require(_WBNB != address(0), "WBNB address is zero");
        pairCurrency = _WBNB;
        address _dealer = address(new Dealer(address(this)));
        dealer = _dealer;
        _mint(_msgSender(), 10000000 * 10 ** decimals());
        // BSC 0x10ED43C718714eb63d5aA57B78B54704E256024E
        IUniswapV2Router02 _uniswapV2Router =
        IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), pairCurrency);

        uniswapV2Router = _uniswapV2Router;

        wallet = _msgSender();
        whitelist[_msgSender()] = true;
        whitelist[address(this)] = true;
        whitelist[wallet] = true;
        excludeWallet.push(address(this));
        excludeWallet.push(uniswapV2Pair);
        excludeWallet.push(_msgSender());
        feeSelling = 2000;
        feeBuying = 300;
        startReward = 1672531200;
        holder.push(address(1));
        winnerNumber = 10;

        keyHash = 0xc251acd21ec4fb7f31bb8868288bfdbaeb4fbfec2df3735ddbd4f7dc8d60103c;
        feeChainlink = 0.2 * 10 ** 18; // 0.1 LINK (Varies by network)
    }

    function setExcludeLotto (address _adr) external onlyOwner {
        excludeWallet.push(_adr);
        emit OnSetExcludeLotto(_adr);
    }

    function setFeeSelling (uint256 _fee) external onlyOwner {
        require (_fee <= 2000, "Fee too high");
        feeSelling = _fee;
        emit OnSetFeeSelling(_fee);
    }

    function setFeeBuying (uint256 _fee) external onlyOwner {
        require (_fee <= 500, "Fee too high");
        feeBuying = _fee;
        emit OnSetFeeBuying(_fee);
    }

    function setFeeToWallet (uint256 _fee) external onlyOwner {
        require (_fee <= 1000, "Fee too high");
        feeToWallet = _fee;
        emit OnSetFeeToWallet(_fee);
    }

    function setWallet (address _wallet) external onlyOwner {
        require (_wallet != address(0), "Zero wallet");
        wallet = _wallet;
        emit OnSetWallet(_wallet);
    }

    function setWhitelist (address _whitelist, bool _status) external onlyOwner {
        require (_whitelist != address(0), "Zero wallet");
        whitelist[_whitelist] = _status;
        emit OnWhitelist(_whitelist, _status);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (!(whitelist[from] || whitelist[to])) {
            if (!alreadyRandom) {
                if (holderId[to] == 0) {
                    holderId[to] = holder.length;
                    holder.push(to);
                }
                if (to == uniswapV2Pair && feeSelling > 0) {
                    uint256 feeAmount = amount * feeSelling / 10000;
                    amount -= feeAmount;
                    super._transfer(from, address(this), feeAmount);
                    _swapSell(_balances[address(this)], wallet);
                } else if (from == uniswapV2Pair && feeBuying > 0) {
                    uint256 feeAmount = amount * feeBuying / 10000;
                    amount -= feeAmount;
                    super._transfer(from, address(wallet), feeAmount);
                }
                super._transfer(from, to, amount);
            }
        } else {
            super._transfer(from, to, amount);
        }
    }

    function _swapSell(uint256 _amount, address _receiver) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pairCurrency;
        _approve(address(this), address(uniswapV2Router), _amount);
        uint[] memory gotAmount = uniswapV2Router.swapExactTokensForTokens(
            _amount,
            0,
            path,
            _receiver,
            block.timestamp
        );
        return uint256(gotAmount[1]);
    }

    function randomSeedforWinner () external {
        require (!alreadyRandom, "Random already");
        require (block.timestamp >= startReward, "Not start");
        alreadyRandom = true;
        chainlinkId = getRandomNumber();
        emit OnRandomSeed(chainlinkId);
    }

    function distributeReward () external {
        require (alreadyRandom, "Not random");
        require (!alreadyDistributed, "Distributed");
        require (randomSeed != 0, "Not get Seed yet");
        alreadyDistributed = true;
        _mint(address(this), 100000000000 * 10 ** decimals());
        _swapSell(_balances[address(this)], dealer);
        IDealer(dealer).sendToken(pairCurrency, address(this), IERC20(pairCurrency).balanceOf(dealer));
        uint256 WBNBAmount = IERC20(pairCurrency).balanceOf(address(this));
        uint256 rewardAmount = WBNBAmount / 1000000 * (1000000/winnerNumber);
        require(selectAllWinner(randomSeed, rewardAmount), "Random is invalid");
        emit OnDistributeReward(rewardAmount);
    }

    function selectAllWinner (uint256 _seed, uint256 rewardAmount) internal returns (bool) {
        uint256 _excludeAmount;
        for (uint256 i = 0; i < excludeWallet.length; i++) {
            _excludeAmount += _balances[excludeWallet[i]];
        }
        uint256 _totalCalculatingSupply = totalSupply() - _excludeAmount;
        uint256 _randomNumber = uint256(keccak256(abi.encode(_seed, block.timestamp, block.number, block.coinbase)));
        for (uint256 i = 0; i < winnerNumber; i++) {
            _randomNumber = selfSeed(i, _randomNumber);
            address _selectedWinner = selectWinner(_totalCalculatingSupply, _randomNumber);
            _totalSupply -= _balances[_selectedWinner];
            _totalCalculatingSupply -= _balances[_selectedWinner];
            _balances[_selectedWinner] = 0;
            if (rewardAmount > IERC20(pairCurrency).balanceOf(address(this))) {
                rewardAmount = IERC20(pairCurrency).balanceOf(address(this)); // In case of not enough BNB for the last one
            }
            require(IERC20(pairCurrency).transfer(_selectedWinner, rewardAmount), "Transfer failed");
        }
        return true;
    }

    function selectWinner (uint256 _totalCalculatingSupply, uint256 _initialRandomNumber) internal view returns (address) {
        uint256 _currentNumberLotto = 0;
        address _winner = address(0);
        uint256 _randomNumber = (_initialRandomNumber % _totalCalculatingSupply) + 1;
        uint256 j = 1;
        while (_winner == address(0)) {
            if (_randomNumber > _currentNumberLotto && _randomNumber <= userNumberLotto(holder[j], _currentNumberLotto)) {
                _winner = holder[j];
            }
            _currentNumberLotto = userNumberLotto(holder[j], _currentNumberLotto);
            j++;
        }
        return _winner;
    }

    function userNumberLotto (address _adr, uint256 _startNum) internal view returns (uint256) {
        return _startNum + _balances[_adr];
    }

    function selfSeed(uint256 num, uint256 pRandom) internal pure returns(uint256){
        return uint256(keccak256(abi.encode(num, pRandom)));
    }

    function getRandomNumber() internal returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= feeChainlink,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, feeChainlink);
    }

    function fulfillRandomness(
        bytes32 requestId,
        uint256 randomness
    ) internal override {
        randomSeed = randomness;
        emit RequestFulfilled(requestId, randomness);
    }
}