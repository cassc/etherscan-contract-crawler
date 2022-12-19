pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IRouter.sol";
import "./interface/IFactory.sol";
import "./interface/IPair.sol";

// TODO write social networks here (or better to do it in storage vars)

contract RabBitcoin is ERC20, Ownable {
    uint256 public constant hundredPercent = 100;
    uint256 public transferTax;
    uint256 public sellPercent;

    address public developerWallet;
    address public marketingWallet;
    address public donationWallet;
    address public presaleContract;
    address public stakeBnbRabbitCoinContract;
    address public stakeRabbitCoinContract;

    mapping(address => bool) public whitelist;

    IRouter public router;
    IPair public pair;
    bool public addLiquidityOperation;
    bool public removeLiquidityOperationFirstTik;
    bool public removeLiquidityOperationSecondTik;

    struct User {
        uint256 availableSell;
        uint256 alreadySold; 
    }
    mapping(address => User) public usersSellInfo;

    constructor(string memory _name, string memory _symbol, uint256 _transferTax, uint256 _sellPercent, address _presaleContract,
                address _stakeBnbRabbitCoinContract, address _stakeRabbitCoinContract,
                address _developerWallet, address _marketingWallet, address _donationWallet, uint256 _totalSupply) ERC20(_name, _symbol) {
        whitelist[_developerWallet] = true;
        whitelist[_marketingWallet] = true;
        whitelist[_donationWallet] = true;

        sellPercent = _sellPercent;
        transferTax = _transferTax;

        developerWallet = _developerWallet;
        marketingWallet = _marketingWallet;
        donationWallet = _donationWallet;
        presaleContract = _presaleContract;
        stakeBnbRabbitCoinContract = _stakeBnbRabbitCoinContract;
        stakeRabbitCoinContract = _stakeRabbitCoinContract;

        ERC20._mint(_developerWallet, _totalSupply * 90 / 100);
        ERC20._mint(_presaleContract, _totalSupply * 10 / 100);

        router = IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IPair(IFactory(router.factory()).createPair(address(this), router.WETH()));
    }

    receive() external payable { }

    function setWhitelist(address _user, bool _value) onlyOwner external {
        whitelist[_user] = _value;
    }

    function changeTransferTax(uint256 _transferTax) onlyOwner external {
        transferTax = _transferTax;
    }

    function changeSellPercent(uint256 _sellPercent) onlyOwner external {
        sellPercent = _sellPercent;
    }

    function addLiquidity(uint256 _tokenAmount) external payable {
        addLiquidityOperation = true;
        ERC20._approve(msg.sender, address(this), _tokenAmount);
        this.transferFrom(msg.sender, address(this), _tokenAmount);
        ERC20._approve(address(this), address(router), _tokenAmount);


        addLiquidityOperation = true;
        (, uint256 amountETH,) = router.addLiquidityETH{value: msg.value}(
            address(this),
            _tokenAmount,
            0,
            0,
            msg.sender,
            block.timestamp
        );
        addLiquidityOperation = false;

        //send back if any
        if (msg.value > amountETH) {
            payable(msg.sender).transfer(msg.value - amountETH);
        }
    }

    function removeLiquidity(uint256 _liquidity) external {
        pair.transferFrom(msg.sender, address(this), _liquidity);
        pair.approve(address(router), _liquidity);

        removeLiquidityOperationFirstTik = true;
        removeLiquidityOperationSecondTik = true;
        router.removeLiquidityETH(
            address(this),
            _liquidity,
            0,
            0,
            msg.sender,
            block.timestamp
        );
        removeLiquidityOperationFirstTik = false;
        removeLiquidityOperationSecondTik = false;
    }

    function burn(uint256 _amount) external {
        ERC20._burn(msg.sender, _amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override virtual {
        // presale flow
        if (from == presaleContract) {
            usersSellInfo[to].availableSell += amount - amount * transferTax / hundredPercent;
            return;
        }

        // stake and unstake flow
        if (from == stakeBnbRabbitCoinContract || from == stakeRabbitCoinContract ||
            to == stakeBnbRabbitCoinContract || to == stakeRabbitCoinContract) {
            return;
        }

        // liquidity flow*
        if (addLiquidityOperation) {
            addLiquidityOperation = false;
            return;
        }

        if (removeLiquidityOperationFirstTik) {
            removeLiquidityOperationFirstTik = false;
            return;
        }

        if (removeLiquidityOperationSecondTik) {
            removeLiquidityOperationSecondTik = false;
            return;
        }
        // *liquidity flow

        // whitelist, mint and burn flow
        if (whitelist[from] || to == address(0) || from == address(0)) {
            return;
        }

        // sell flow
        if (to == address(pair)) {
            require(amount <= availableSellAmount(from), "exceedSellLimit");

            usersSellInfo[from].alreadySold += amount;
            
            ERC20._burn(to, amount * transferTax / hundredPercent);
            return;
        }

        // buy and transfer flow
        uint256 toBurn = amount * transferTax / hundredPercent;
        usersSellInfo[to].availableSell += amount - toBurn;
        ERC20._burn(to, toBurn);
    }

    function availableSellAmount(address _user) public view returns(uint256) {
        User memory user = usersSellInfo[_user];
        return user.availableSell * sellPercent / hundredPercent - user.alreadySold;
    }
}