/**
 *Submitted for verification at BscScan.com on 2023-02-20
*/

// SPDX-License-Identifier: MIT

/*

    WOR pre-sales contract

    World of Rewards (WOR) is a rewards platform
    based on blockchains that aims to create an ecosystem
    decentralized, transparent, and
    fair reward system for users.
    The project is based on the BSC blockchain and uses
    smart contracts to automate the distribution of rewards.

    https://worldofrewards.finance/
    https://twitter.com/WorldofRewards
    https://t.me/WorldofRewards


*/


pragma solidity 0.8.0;


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
*/
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Is impossible to renounce the ownership of the contract");
        require(newOwner != address(0xdead), "Is impossible to renounce the ownership of the contract");

        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface IERC20 {

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

}


interface IERC20Metadata {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

}


interface IUniswapV2Router02 {

    function getAmountsOut(
        uint amountIn, 
        address[] calldata path) 
        external view returns (uint[] memory amounts);

}


contract ERC20 is Context, IERC20Metadata {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;

    event Transfer(address indexed from, address indexed to, uint256 value);

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
        return 0;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function _mint(address account, uint256 amount) internal virtual {
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

}

contract WORPrivateSale is ERC20, Ownable, ReentrancyGuard {

    uint256 public timeDeployContract;

    uint256 public percent;
    uint256 public priceBNB;
    uint256 public priceUSD;
    uint256 public denominatorUSD;

    //1% bonus, which equals 1/40 of the buyer's tokens 
    uint256 public denominatorBonus;

    //As the sale is in more than one cryptocurrency
    //so there will be a difference due to BNB or to BNB conversion spreeds
    uint256 public errorMarginPercent;

    //Private sale limit
    uint256 public hardCapPrivate;

    uint256 public minBNBBuy;
    uint256 public maxBNBbuy;

    //Stats here
    //Number of purchases in private
    uint256 public count;
    //All BNB purchases are added to this variable
    uint256 public totalBNBpaid;
    //All USD purchases are added to this variable
    uint256 public totalUSDpaid;

    //All tokens sold in private
    //Tokens sold without adding the private sale bonus
    uint256 public totalTokensWOR;

    //Total amount sold equivalent in BNB
    uint256 public totalSoldInBNB;
    //Total sold amount equivalent in USD
    uint256 public totalSoldInUSD;

    bool public isOpenPrivate;


    address public uniswapV2Router  = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public addressBUSD      = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public addressUSDT      = 0x55d398326f99059fF775485246999027B3197955;
    address public addressWBNB      = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public addressWOR       = 0x1980f4Dd2A2DE4450Da2057dFbe76E91CfDaeAE8;

    address public privateSaleWallet    = payable(0x7665024aC52435E8506331d674c51Fa027d88FbC);
    address public privateSaleWalletBonus   = 0xFd8db97121A000572D4689c1af40Fd23Bd582893;
    address public projectWallet    = payable(0xd8D65AE7b47e4F6DF5864BcbAce9fb2DEC322c4D);

    struct structBuy {
        //All tokens that a uer bought
        uint256 amountTokenPurchased;
        //Only the amounts in BNB that the user has paid
        uint256 amountBNBpaid;
        //Only the values in BUSD that the user paid
        uint256 amountBUSDpaid;
        //Only the amounts in USDT that the user paid
        uint256 amountUSDTpaid;
        //Conversion of USD to BNB added to the BNB paid in this private
        uint256 amountBNBPaidConverted;
        //Conversion of BNB to USD added to the USD paid in this private
        uint256 amountUSDPaidConverted;
    }

    mapping (address => structBuy) mappingStructBuy;

    receive() external payable 
    {}

    constructor() ERC20("World Of Rewards - Private Sale", "WOR Private Sale") {
        timeDeployContract = block.timestamp;

        priceBNB = 168000;
        priceUSD = 1785714;
        denominatorUSD = 1000000000;
        percent = 10;

        denominatorBonus = 40;

        errorMarginPercent = 110;

        hardCapPrivate = 505 * 10 ** 18 / 10; // 50,5 BNB

        minBNBBuy = 35 * 10 ** 18 / 1000;
        maxBNBbuy = 1 * 10 ** 18;

        _mint(address(0), 1);
    }

    function maxUSDbuy() public view returns (uint256) {
        return convert(addressWBNB, addressBUSD, maxBNBbuy);
    }

    function minUSDbuy() public view returns (uint256) {
        return convert(addressWBNB, addressBUSD, minBNBBuy);
    }

    function getTokensOut_BNB(uint256 amountIn) public view returns (uint256) {
        return amountIn * priceBNB;
    }

    function getTokensOut_USD(uint256 amountIn) public view returns (uint256) {
        return (amountIn / priceUSD) * denominatorUSD;
    }

    function getMappingStructBuy(address buyer) public view returns (structBuy memory) {
        return mappingStructBuy[buyer];
    }

    function getLimitToBuy_BNB(address buyer) public view returns (uint256 limit) {

        //It is redundant and unnecessary to check, but we do these rechecks
        if (maxBNBbuy >= mappingStructBuy[buyer].amountBNBPaidConverted) {
            limit = maxBNBbuy - mappingStructBuy[buyer].amountBNBPaidConverted;

        } else {
            limit = 0;
        }

        if (limit > hardCapPrivate - totalSoldInBNB) limit = hardCapPrivate - totalSoldInBNB;

        if (limit > address(buyer).balance - 10 ** 18 / 1000) 
            limit = address(buyer).balance - 10 ** 18 / 1000;

        return limit;

    }

    function getLimitToBuy_USD(address buyer) public view returns (uint256 limit) {

        uint256 maxBNBbuyConverted = convert(addressWBNB, addressBUSD, maxBNBbuy);
        uint256 hardCapPrivateConverted = convert(addressWBNB, addressBUSD, hardCapPrivate);
        uint256 totalSoldInBNBConverted = convert(addressWBNB, addressBUSD, totalSoldInBNB);
        //It is redundant and unnecessary to check, but we do these rechecks
        if (maxBNBbuyConverted >= mappingStructBuy[buyer].amountUSDPaidConverted) {
            limit = maxBNBbuyConverted - mappingStructBuy[buyer].amountUSDPaidConverted;

        } else {
            limit = 0;
        }

        if (limit > hardCapPrivateConverted - totalSoldInBNBConverted) 
        limit = hardCapPrivateConverted - totalSoldInBNBConverted;

        return limit;

    }

    function convert(address addressIn, address addressOut, uint256 amount) public view returns (uint256) {
        
        address[] memory path = new address[](2);
        path[0] = addressIn;
        path[1] = addressOut;

        uint256[] memory amountOutMins = 
        IUniswapV2Router02(uniswapV2Router).getAmountsOut(amount, path);

        return amountOutMins[path.length -1];
    } 


    function buyNumberByBNB() 
        external payable nonReentrant() {
        
        require(isOpenPrivate, "Private not opened yet");
        require(totalSoldInBNB <= hardCapPrivate, "Sales limit reached");

        uint256 amountBNB = msg.value;
        uint256 amountUSDconverted = convert(addressWBNB, addressBUSD, amountBNB);

        unchecked {
            require(minBNBBuy <= amountBNB, "Minimum purchase");
            require(mappingStructBuy[_msgSender()].amountBNBPaidConverted + amountBNB 
                    <= maxBNBbuy * errorMarginPercent / 100);
        
            uint256 amountBuy = amountBNB * priceBNB;

            IERC20(addressWOR).transferFrom(privateSaleWallet, msg.sender, amountBuy);
            IERC20(addressWOR).transferFrom(
                privateSaleWalletBonus, msg.sender, amountBuy * 1 / denominatorBonus
                );

            //amountBNB is in wei
            //The calculation of the number of tokens is offset by the 10 ** 18 decimals of the token itself        
            mappingStructBuy[_msgSender()].amountTokenPurchased += amountBuy;
            mappingStructBuy[_msgSender()].amountBNBpaid += amountBNB;
            mappingStructBuy[_msgSender()].amountBNBPaidConverted += amountBNB;
            mappingStructBuy[_msgSender()].amountUSDPaidConverted += amountUSDconverted;

            count ++;
            totalBNBpaid += amountBNB;
            totalTokensWOR += amountBuy;
            
            totalSoldInBNB += amountBNB;
            totalSoldInUSD += amountUSDconverted;

            (bool success1,) = privateSaleWallet.call{value: amountBNB * (100 - percent) /100}("");
            require(success1, "Failed to send BNB");

            (bool success2,) = projectWallet.call{value: address(this).balance}("");
            require(success2, "Failed to send BNB");
        }
    }

    //You have to approve the token first
    function buyNumberByBUSD(uint256 amountBUSD)
        external nonReentrant() {
        require(isOpenPrivate, "Private not opened yet");
        require(totalSoldInBNB <= hardCapPrivate, "Sales limit reached");

        uint256 amountBNBconverted = convert(addressBUSD, addressWBNB, amountBUSD);

        unchecked {
            require(minBNBBuy <= amountBNBconverted, "Minimum purchase");
            require(mappingStructBuy[_msgSender()].amountBNBPaidConverted + 
            amountBNBconverted <= maxBNBbuy * errorMarginPercent / 100);

            uint256 amountBuy = (amountBUSD / priceUSD) * denominatorUSD;

            IERC20(addressBUSD).transferFrom(msg.sender, privateSaleWallet, amountBUSD * (100 - percent) /100);
            IERC20(addressBUSD).transferFrom(msg.sender, projectWallet, amountBUSD * (percent) / 100);

            //amountBUSD is in wei
            //The calculation of the number of tokens is offset by the 10 ** 18 decimals of the token itself
            IERC20(addressWOR).transferFrom(privateSaleWallet, msg.sender, amountBuy);
            IERC20(addressWOR).transferFrom(
                privateSaleWalletBonus, msg.sender, amountBuy * 1 / denominatorBonus
                );

            mappingStructBuy[_msgSender()].amountTokenPurchased += amountBuy;
            mappingStructBuy[_msgSender()].amountBUSDpaid += amountBUSD;
            mappingStructBuy[_msgSender()].amountBNBPaidConverted += amountBNBconverted;
            mappingStructBuy[_msgSender()].amountUSDPaidConverted += amountBUSD;

            count ++;
            totalUSDpaid += amountBUSD;
            totalTokensWOR += amountBuy;

            totalSoldInBNB += amountBNBconverted;
            totalSoldInUSD += amountBUSD;
        }
    }

    function buyNumberByUSDT(uint256 amountUSDT)
        external nonReentrant() {
        require(isOpenPrivate, "Private not opened yet");
        require(totalSoldInBNB <= hardCapPrivate, "Sales limit reached");

        uint256 amountBNBconverted = convert(addressUSDT, addressWBNB, amountUSDT);

        unchecked {
            require(minBNBBuy <= amountBNBconverted, "Minimum purchase");
            require(mappingStructBuy[_msgSender()].amountBNBPaidConverted + 
            amountBNBconverted <= maxBNBbuy * errorMarginPercent / 100);

            uint256 amountBuy = (amountUSDT / priceUSD) * denominatorUSD;

            IERC20(addressUSDT).transferFrom(msg.sender, privateSaleWallet, amountUSDT * (100 - percent) /100);
            IERC20(addressUSDT).transferFrom(msg.sender, projectWallet, amountUSDT * (percent) / 100);

            //addressUSDT is in wei
            //The calculation of the number of tokens is offset by the 10 ** 18 decimals of the token itself
            IERC20(addressWOR).transferFrom(privateSaleWallet, msg.sender, amountBuy);
            IERC20(addressWOR).transferFrom(
                privateSaleWalletBonus, msg.sender, amountBuy * 1 / denominatorBonus
                );

            mappingStructBuy[_msgSender()].amountTokenPurchased += amountBuy;
            mappingStructBuy[_msgSender()].amountUSDTpaid += amountUSDT;
            mappingStructBuy[_msgSender()].amountBNBPaidConverted += amountBNBconverted;
            mappingStructBuy[_msgSender()].amountUSDPaidConverted += amountUSDT;

            count ++;
            totalUSDpaid += amountUSDT;
            totalTokensWOR += amountBuy;

            totalSoldInBNB += amountBNBconverted;
            totalSoldInUSD += amountUSDT;

        }

    }

    function managerBNB () external onlyOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }

    function managerERC20 (address token) external onlyOwner {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function setPercent (uint256 _percent) external onlyOwner {
        percent = _percent;
    }

    function setLimits(uint256 _minBNBBuy, uint256 _maxBNBbuy) external onlyOwner {
        minBNBBuy = _minBNBBuy;
        maxBNBbuy = _maxBNBbuy;
    }

    function setIsOpenPrivate (bool _isOpenPrivate) external onlyOwner {
        isOpenPrivate = _isOpenPrivate;
    }

    function setHardCapPrivate (uint256 _hardCapPrivate) external onlyOwner {
        hardCapPrivate = _hardCapPrivate;
    }

    function setErrorMarginPercent (uint256 _errorMarginPercent) external onlyOwner {
        errorMarginPercent = _errorMarginPercent;
    }

}