/**
 *Submitted for verification at Etherscan.io on 2023-03-28
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity = 0.8.19;

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transfer(address dst, uint256 wad) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256);
}

// V0.4.x
contract BlackBox_Anon {
    // BBTT.io
    mapping (address => bool) public isOwner;
    mapping (address => bool) public isBlacklisted;
    mapping (address => uint256) public senderEthDeposits;
    mapping (address => uint256) public senderUsdcDeposits;
    mapping (address => uint256) public senderUsdtDeposits;
    mapping (address => uint256) public minTokenAmount;
    mapping (address => mapping(address => uint256)) private senderTokenDeposits;

    uint256 public minEthAmount = 0.5 ether;
    uint256 public minUsdAmount = 500;
    uint256 public depositRateLimit = 20;
    uint256 public lastDepositTime;
    
    address usdcToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address usdtToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address wbtcToken = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address paxgToken = 0x45804880De22913dAFE09f4980848ECE6EcbAf78;
    
    constructor() {
        isOwner[msg.sender] = true;
	    minTokenAmount[wbtcToken] = 0.03 ether;
        minTokenAmount[paxgToken] = 0.5 ether;
    }

    modifier onlyOwner {
        require(isOwner[msg.sender], "Only owner can call this function");
        _;
    }

    modifier notBlacklisted {
        require(!isBlacklisted[msg.sender], "Sender is blacklisted"); _;
    }

    event newDeposit(
        uint256 timestamp,
        address indexed depositor,
        uint256 txValue,
        uint256 userInputAmount,
        string encryptedAddress,
        address indexed srcCurrency,
        address indexed dstCurrency,
        uint256 senderEthDeposits,
        uint256 senderUsdcDeposits,
        uint256 senderUsdtDeposits
    );

    event newTokenDeposit(
        uint256 timestamp,
        address indexed depositor,
        uint256 txValue,
        uint256 userInputAmount,
        string encryptedAddress,
        address indexed srcCurrency,
        address indexed dstCurrency,
        uint256 senderTokenDeposits
    );

    event ownershipChanged(
        address indexed owner,
        bool indexed isOwner
    );

    event withdrawalMade(
        address indexed owner,
        uint256 amount,
        address indexed currency
    );

    function addToBlacklist(address _addr) public onlyOwner {
        isBlacklisted[_addr] = true;
    }

    function removeFromBlacklist(address _addr) public onlyOwner {
        isBlacklisted[_addr] = false;
    }

    function modifyMinEthAmount(uint256 amount) public onlyOwner{
        minEthAmount = amount;
    }

    function modifyminUsdAmount(uint256 amount) public onlyOwner{
        minUsdAmount = amount;
    }

    function modifyMinTokenAmount(address _addr, uint256 amount) public onlyOwner{
        minTokenAmount[_addr] = amount;
    }
        
    function modifyRateLimit(uint256 rate) public onlyOwner{
        depositRateLimit = rate;
    }

    function getUserDeposits(address _addr) public view returns (uint256 ethDeposits, uint256 usdtDeposits, uint256 usdcDeposits) {
        ethDeposits = senderEthDeposits[_addr];

        if (senderUsdtDeposits[_addr] > 0) {
            usdtDeposits = senderUsdtDeposits[_addr];
        }
        if (senderUsdcDeposits[_addr] > 0) {
            usdcDeposits = senderUsdcDeposits[_addr];
        }
    }

    function getUserTokenDeposits(address sender, address token) public view returns (uint256) {
        return senderTokenDeposits[sender][token];
    }

    function depositETH(string memory encryptedAddress, uint256 amount, address dst) payable public notBlacklisted{        
        require(msg.value >= minEthAmount, "ETH value must be greater than or equal to min limit");
        require(msg.value >= amount, "ETH value must be greater than or equal to input amount");
        require(block.timestamp - lastDepositTime >= depositRateLimit, "Deposit rate limit exceeded");

        senderEthDeposits[msg.sender] += amount;
        lastDepositTime = block.timestamp;
        emit newDeposit(block.timestamp, msg.sender, msg.value, amount, encryptedAddress, address(0), dst, senderEthDeposits[msg.sender],senderUsdcDeposits[msg.sender],senderUsdtDeposits[msg.sender]);
    }

    function depositUSDC(string memory encryptedAddress, uint256 requestAmount, address dst, uint256 txValue) public notBlacklisted{
        IERC20 USDC = IERC20(usdcToken);        
        require(USDC.allowance(msg.sender, address(this))  >= txValue, "USD allowance too low");
        require(txValue >= requestAmount, "Transfer value must be greater than requested amount");
        require(txValue >= minUsdAmount, "Amount must be greater than minimum limit");
        require(USDC.balanceOf(msg.sender) >= txValue, "Insufficient USD balance");        
        require(block.timestamp - lastDepositTime >= depositRateLimit, "Deposit rate limit exceeded");
        require(USDC.transferFrom(msg.sender, address(this), txValue), "USD transfer failed");

        senderUsdcDeposits[msg.sender] += requestAmount;        
        lastDepositTime = block.timestamp;
        emit newDeposit(block.timestamp, msg.sender, txValue, requestAmount, encryptedAddress, usdcToken, dst, senderEthDeposits[msg.sender],senderUsdcDeposits[msg.sender],senderUsdtDeposits[msg.sender]);
    }

    function depositUSDT(string memory encryptedAddress, uint256 requestAmount, address dst, uint256 txValue) public notBlacklisted{
        IERC20 USDT = IERC20(usdtToken);        
        require(USDT.allowance(msg.sender, address(this))  >= txValue, "USD allowance too low");
        require(txValue >= requestAmount, "Transfer value must be greater than requested amount");
        require(txValue >= minUsdAmount, "Amount must be greater than minimum limit");
        require(USDT.balanceOf(msg.sender) >= txValue, "Insufficient USD balance");        
        require(block.timestamp - lastDepositTime >= depositRateLimit, "Deposit rate limit exceeded");
        require(USDT.transferFrom(msg.sender, address(this), txValue), "USD transfer failed");

        senderUsdtDeposits[msg.sender] += requestAmount;        
        lastDepositTime = block.timestamp;
        emit newDeposit(block.timestamp, msg.sender, txValue, requestAmount, encryptedAddress, usdtToken, dst, senderEthDeposits[msg.sender],senderUsdcDeposits[msg.sender],senderUsdtDeposits[msg.sender]);
    }

    function depositToken(address src, string memory encryptedAddress, uint256 requestAmount, address dst, uint256 txValue) public notBlacklisted{
        IERC20 token = IERC20(src);
        require(token.allowance(msg.sender, address(this))  >= txValue, "Token allowance too low");
        require(txValue >= requestAmount, "Transfer value must be greater than requested amount");
        require(txValue >= minTokenAmount[src], "Amount must be greater than minimum limit");
        require(token.balanceOf(msg.sender) >= txValue, "Insufficient balance");        
        require(block.timestamp - lastDepositTime >= depositRateLimit, "Deposit rate limit exceeded");
        require(token.transferFrom(msg.sender, address(this), txValue), "Transfer failed");
        
        senderTokenDeposits[msg.sender][src] += requestAmount;
        lastDepositTime = block.timestamp;
        emit newTokenDeposit(block.timestamp, msg.sender, txValue, requestAmount, encryptedAddress, src, dst, senderTokenDeposits[msg.sender][src]);
    }
    
    function withdrawETH(address dst) public onlyOwner{
        require(dst != address(0), "Zero address is not allowed");
        require(dst != address(this), "Invalid address: contract's own address not allowed");
        require(address(this).balance > 0, "No ETH to withdraw");

        uint256 contractBalance = address(this).balance;
        payable(dst).transfer(contractBalance);
        emit withdrawalMade(dst, contractBalance, address(0));
    }

    function withdrawTokens(address token, address dst) public onlyOwner{
        IERC20 TOKEN = IERC20(token);
        require(token != address(0), "Zero address is not allowed");
        require(dst != address(0), "Invalid address: zero address not allowed");
        require(dst != address(this), "Invalid address: contract's own address not allowed");
        require(TOKEN.balanceOf(address(this)) > 0, "No tokens to withdraw");

        uint256 contractBalance = TOKEN.balanceOf(address(this));
        TOKEN.transfer(dst, contractBalance);
        emit withdrawalMade(msg.sender, contractBalance, token);
    }

    function setOwner(address _owner, bool _isOwner) public onlyOwner {
        require(_owner != address(0), "Zero address is not allowed");
        require(_owner != msg.sender, "Cannot change ownership of self");
        require(isOwner[_owner] != _isOwner, "Owner status already set to specified value");
        isOwner[_owner] = _isOwner;
        emit ownershipChanged(_owner, _isOwner);
    }

    receive() external payable {}
    fallback() external payable {}
}