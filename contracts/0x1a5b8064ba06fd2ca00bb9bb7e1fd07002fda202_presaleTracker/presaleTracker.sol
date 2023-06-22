/**
 *Submitted for verification at Etherscan.io on 2023-06-21
*/

pragma solidity 0.8.18;

contract presaleTracker {

    mapping(address => uint256) private _balances;
    mapping(address => bool) public _whitelisted;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint public _ethCap;
    uint public _maxBuy;
    uint public _minBuy;
    address private _dev;
    address private _wallet;
    bool public _public;

    event Transfer(address indexed from, address indexed to, uint256 value);

    modifier onlyDev() {
        require(msg.sender == _dev, "Only the developer can call this function"); _;
    }

    constructor(string memory name_, string memory symbol_, uint ethCap_, uint minBuy_, uint maxBuy_, address wallet_) {
        _name = name_; _symbol = symbol_; _decimals = 18;
        _totalSupply = 0 * 10 ** _decimals;
        _ethCap = ethCap_; _minBuy = minBuy_; _maxBuy = maxBuy_;
        _dev = msg.sender; _wallet = wallet_;
    }

    function name() public view returns (string memory) {return _name;}
    function symbol() public view returns (string memory) {return _symbol;}
    function decimals() public view returns (uint8) {return _decimals;}
    function totalSupply() public view returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view returns (uint256) {return _balances[account];}

    function buyTokens() public payable {
        require(msg.value >= _minBuy, "You must purchase more than min amount!");
        require(_balances[msg.sender] + msg.value <= _maxBuy || _public, "You must purchase less than max amount!");
        require(_totalSupply + msg.value <= _ethCap, "Purchase would exceed total supply");
        require(_public || _whitelisted[msg.sender], "You are not whitelisted for the private sale!");
        payable(_wallet).transfer(msg.value);
        _balances[msg.sender] += msg.value; _totalSupply += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }

    function transfer(address from, address to, uint256 amount) public onlyDev {
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    receive() external payable {buyTokens();}

    function withdraw(address to_) public onlyDev {payable(to_).transfer(address(this).balance);}

    function updateWhitelist(address[] memory addresses, bool whitelisted_) public onlyDev {
        for (uint i = 0; i < addresses.length; i++) {
            _whitelisted[addresses[i]] = whitelisted_;
        }
    }

    function openToPublic(bool public_) public onlyDev {
        _public = public_;
    }

    function setLimits (uint ethCap_, uint maxBuy_) public onlyDev {
        _ethCap = ethCap_;
        _maxBuy = maxBuy_;
    }

    function changeDev (address dev_) public onlyDev {
        _dev = dev_;
    }

    function changeWallet (address wallet_) public onlyDev {
        _wallet = wallet_;
    }
    
}