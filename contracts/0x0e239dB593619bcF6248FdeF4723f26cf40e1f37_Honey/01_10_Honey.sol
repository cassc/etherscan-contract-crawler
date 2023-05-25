// SPDX-License-Identifier: MIT
// Inspired by: $Loomi by Creepz
pragma solidity ^0.8.13;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./libraries/SimpleAccess.sol";

contract IEcoSystem {
    function getTotalProductionOfUser(address user, uint256[] memory flowersWithBees) external view returns (uint256) {}
}

contract ITaxManager {
    function getSpendTax(address user, uint256 amount, bytes memory data) external returns (uint128) {}
    function getBuyTax(address user, uint256 amount) external returns (uint256) {}
    function getSellTax(address user, uint256 amount) external returns (uint256) {}
}

contract Honey is ERC20, SimpleAccess {
    IEcoSystem public ecoSystem;
    ITaxManager public taxManager;
    address public mintPass;
    address public uniswapPair;


    struct EcoSystemBalance {
        uint128 deposit;
        uint256 spent;
    }
    mapping(address => EcoSystemBalance) public userEcoSystemBalance;

    mapping(address => bool) public liquidityPair;
    mapping(address => bool) public blacklisted;
    mapping(address => bool) public noFee;

    bool public whitelistActive;
    mapping(address => bool) public isWhiteListed;

    bool public buyLimitActive;
    uint256 public buyLimitTimePeriod = 1 days;
    uint256 public buyLimitAmount = 4000 ether;
    struct BuyLimit {
        uint128 bought;
        uint128 lastBuy;
    }
    mapping(address => BuyLimit) public userToBuyLimit;

    event SendToEcoSystem(address indexed user, uint256 indexed amount);
    event TakeFromEcoSytem(address indexed user, uint256 indexed amount);
    event TransferEcoSystemBalance(address indexed user, address indexed recipient, uint256 indexed amount);
    event SpendEcoSystemBalance(address indexed user, uint256 indexed amount, uint256 indexed tax);

    constructor(        
        address _router
    ) ERC20("HONEY COIN", "HONEYCOIN") {
        _mint(msg.sender, 1000000 ether);

        IUniswapV2Router02 router = IUniswapV2Router02(_router);
        uniswapPair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );

        whitelistActive = true;
        buyLimitActive = true;

        noFee[msg.sender] = true;
        noFee[uniswapPair] = true;
        isWhiteListed[msg.sender] = true;
        isWhiteListed[uniswapPair] = true;

        liquidityPair[uniswapPair] = true;
    }

    function getEcoSystemBalance(address user, uint256[] memory flowersWithBees) public view returns (uint256) {
        EcoSystemBalance memory ecoSystemBalance = userEcoSystemBalance[user];
        
        uint256 plusBalance = ecoSystem.getTotalProductionOfUser(user, flowersWithBees) + ecoSystemBalance.deposit;
        uint256 minBalance = ecoSystemBalance.spent;

        if (minBalance > plusBalance)
            return 0;

        return plusBalance - minBalance;
    }

    function sendToEcoSystem(uint128 amount) external {
        require(balanceOf(msg.sender) >= amount, "Not enough balance");
        
        _burn(msg.sender, amount);
        EcoSystemBalance storage ecoSystemBalance = userEcoSystemBalance[msg.sender];
        ecoSystemBalance.deposit += amount;

        emit SendToEcoSystem(msg.sender, amount);
    }

    function takeFromEcoSystem(uint128 amount, uint256[] memory flowersWithBees) external {
        require(getEcoSystemBalance(msg.sender, flowersWithBees) >= amount, "Eco system balance too low");

        _mint(msg.sender, amount);
        EcoSystemBalance storage ecoSystemBalance = userEcoSystemBalance[msg.sender];
        ecoSystemBalance.spent += amount;

        emit TakeFromEcoSytem(msg.sender, amount);
    }

    function transferEcoSystemBalance(address _to, uint128 amount, uint256[] memory flowersWithBees) external {
        require(getEcoSystemBalance(msg.sender, flowersWithBees) >= amount, "Eco system balance too low");

        EcoSystemBalance storage ecoSystemBalanceUser = userEcoSystemBalance[msg.sender];
        EcoSystemBalance storage ecoSystemBalanceReceiver = userEcoSystemBalance[_to];

        ecoSystemBalanceUser.spent += amount;
        ecoSystemBalanceReceiver.deposit += amount;

        emit TransferEcoSystemBalance(msg.sender, _to, amount);
    }

    function spendEcoSystemBalance(address user, uint128 amount, uint256[] memory flowersWithBees, bytes memory data) external onlyAuthorized {
        require(getEcoSystemBalance(user, flowersWithBees) >= amount, "Eco system balance too low");

        uint256 taxAmount = taxManager.getSpendTax(user, amount, data);

        if (taxAmount > 0)
            super._transfer(user, address(taxManager), taxAmount);

        EcoSystemBalance storage ecoSystemBalance = userEcoSystemBalance[user];
        ecoSystemBalance.spent += amount;

        emit SpendEcoSystemBalance(user, amount, taxAmount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal view override {
        require(!blacklisted[from] && !blacklisted[to], "SENDER / RECIPIENT BANNED");
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (whitelistActive)
            require(isWhiteListed[from] && isWhiteListed[to], "Sender not whitelisted");

        if (buyLimitActive && liquidityPair[from]) {
            BuyLimit storage limit = userToBuyLimit[to];
            uint256 boughtToday;
            uint256 diffSinceLastBuy = block.timestamp - limit.lastBuy;

            if (diffSinceLastBuy >= buyLimitTimePeriod) {
                boughtToday = amount;
            } else {
                uint256 nowModule = block.timestamp % buyLimitTimePeriod; // how far we are in the day now
                uint256 lastModulo = limit.lastBuy % buyLimitTimePeriod; // how far the last buy was in the day

                // if how far we are in the day now is less than how far we were in the day at last buy then its a new day
                if (nowModule <= lastModulo) {
                    boughtToday = amount;
                } else { // if how far we are in the day now is greater than how far we were in the day at last buy then its the same day
                    boughtToday = amount + limit.bought;
                }
            }

            require(boughtToday <= buyLimitAmount, "Buy exceeds buy limit");

            limit.lastBuy = uint128(block.timestamp);
            limit.bought = uint128(boughtToday);
        }

        uint256 transferAmount = amount;

        if (liquidityPair[from] && !noFee[to])
            transferAmount -= taxManager.getBuyTax(to, transferAmount);
        else if (liquidityPair[to] && !noFee[from])
            transferAmount -= taxManager.getSellTax(from, transferAmount);

        uint256 tax = amount - transferAmount;
        if (tax > 0) 
            super._transfer(from, address(taxManager), tax);
        
        super._transfer(from, to, transferAmount);
    }

    function burn(address user, uint256 amount) external {
        require(mintPass != address(0));
        require(msg.sender == mintPass, "Only mint pass can burn honey");
        _burn(user, amount);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setEcosystem(address eco) external onlyOwner {
        ecoSystem = IEcoSystem(eco);
    }

    function setTaxManager(address manager) external onlyOwner {
        taxManager = ITaxManager(manager);
    }

    function setMintPass(address _mintPass) external onlyOwner {
        mintPass = _mintPass;
    }

    function setLiqPair(address liqpair, bool isliq) external onlyOwner {
        liquidityPair[liqpair] = isliq;
    }

    function setBlackListed(address bl, bool isbl) external onlyOwner {
        blacklisted[bl] = isbl;
    }

    function setNoFee(address nf, bool isnf) external onlyOwner {
        noFee[nf] = isnf;
    }

    function setWhiteListed(address wl, bool iswl) external onlyOwner {
        isWhiteListed[wl] = iswl;
    }

    function setWlActive(bool _active) external onlyOwner {
        whitelistActive = _active;
    }

    function configureBuyLimit(bool _active, uint256 _period, uint256 _amount) external onlyOwner {
        buyLimitActive = _active;
        buyLimitTimePeriod = _period;
        buyLimitAmount = _amount;
    }

    receive() external payable {}
}