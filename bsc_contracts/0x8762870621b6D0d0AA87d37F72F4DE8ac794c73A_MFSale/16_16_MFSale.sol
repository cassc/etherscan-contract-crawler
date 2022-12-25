// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../common/BaseDAOProxy.sol";

contract MFSale is BaseDAOProxy {
    struct PackData {
        address investor;
        uint256[] quantity;
    }

    struct Seller {
        uint256 amount;
        uint256 startIndex;
    }

    struct Pack {
        uint256 MFAmount;
        uint256 price;
    }

    uint256 public totalOnSale;
    uint256 public totalSold;
    uint256 public buybackPrice;
    uint256 public totalWithdrawnByInvestors;

    enum PhaseEnum {
        ONLY_SELL,
        ONLY_BUY,
        ONLY_WITHDRAW
    }

    PhaseEnum public phase;

    mapping(address => uint256) public saleAmount;
    mapping(address => Seller) public sellers;

    Pack[] public packs;

    IERC20 public cbt;
    IERC20 public usdt;
    IMFSwap public mfSwap;

    function initialize(
        address _cbt,
        address _usdt,
        address _mfSwap,
        uint256 _buybackPrice,
        Pack[] memory _packs
    ) public initializer {
        cbt = IERC20(_cbt);
        usdt = IERC20(_usdt);
        mfSwap = IMFSwap(_mfSwap);
        buybackPrice = _buybackPrice;
        for (uint256 i; i < _packs.length; i++) {
            packs.push(Pack(_packs[i].MFAmount, _packs[i].price));
        }

        __Ownable_init();
    }

    function sell(uint256 amount) external {
        require(phase == PhaseEnum.ONLY_SELL, "Only sell phase");

        cbt.transferFrom(msg.sender, address(this), amount);
        saleAmount[msg.sender] += amount;
    }

    function _buy(
        uint256[] memory quantity,
        address _investor,
        address _payer
    ) private {
        require(phase == PhaseEnum.ONLY_BUY, "Only buy phase");
        Pack[] memory _packs = packs;
        require(quantity.length == _packs.length, "Wrong packs length");

        uint256 usdtAmount;
        uint256 buyingAmount;

        for (uint256 i; i < quantity.length; i++) {
            Pack memory pack = _packs[i];

            usdtAmount += quantity[i] * pack.price;
            buyingAmount += quantity[i] * pack.MFAmount;
        }

        usdt.transferFrom(_payer, address(this), usdtAmount);

        if (buyingAmount + totalSold <= totalOnSale) {
            totalSold += buyingAmount;

            cbt.approve(address(mfSwap), buyingAmount);
            mfSwap.swap(buyingAmount, _investor);
        }
    }

    function buy(uint256[] memory quantity) external {
        _buy(quantity, msg.sender, msg.sender);
    }

    function buyForOwner(
        uint256[] memory quantity,
        address _investor,
        address _payer
    ) external onlyOwner {
        _buy(quantity, _investor, _payer);
    }

    function buyForOwner(
        PackData[] memory packData,
        address _payer
    ) external onlyOwner {
        for (uint256 i; i < packData.length; i++) {
            PackData memory data = packData[i];

            _buy(data.quantity, data.investor, _payer);
        }
    }

    function recieveProfit() external {
        require(phase == PhaseEnum.ONLY_WITHDRAW, "Only withdraw phase");

        address seller = msg.sender;

        uint256 investorPart = (saleAmount[msg.sender] * precision) /
            totalOnSale;
        uint256 investorSold = (totalSold * investorPart) / precision;
        uint256 usdtProfit = investorSold * buybackPrice;
        uint256 investorNotSold = saleAmount[seller] - investorSold;

        saleAmount[seller] = 0;
        usdt.transfer(msg.sender, usdtProfit);

        totalWithdrawnByInvestors += usdtProfit;

        cbt.approve(address(mfSwap), investorNotSold);
        mfSwap.swap(investorNotSold, msg.sender);
    }

    function sendProfitToTreasury(address _treasury) external {
        require(phase == PhaseEnum.ONLY_WITHDRAW, "Only withdraw phase");

        uint256 balance = usdt.balanceOf(address(this));
        uint256 amount = balance -
            (totalSold * buybackPrice - totalWithdrawnByInvestors);
        usdt.transfer(_treasury, amount);
    }

    function setBuyPhase() external onlyOwner {
        require(phase == PhaseEnum.ONLY_SELL, "Only sell phase");

        totalOnSale = cbt.balanceOf(address(this));
        phase = PhaseEnum.ONLY_BUY;
    }

    function setWithdrawPhase() external onlyOwner {
        require(phase == PhaseEnum.ONLY_BUY, "Only buy phase");

        phase = PhaseEnum.ONLY_WITHDRAW;
    }

    function setPack(Pack[] memory _packs) external onlyOwner {
        delete packs;

        for (uint256 i; i < _packs.length; i++) {
            packs.push(Pack(_packs[i].MFAmount, _packs[i].price));
        }
    }

    function setBuybackPrice(uint256 _buybackPrice) external onlyOwner {
        buybackPrice = _buybackPrice;
    }

    function setMFSwap(address _mfSwap) external onlyOwner {
        mfSwap = IMFSwap(_mfSwap);
    }

    function getPacks() external view returns (Pack[] memory) {
        return packs;
    }

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}
}