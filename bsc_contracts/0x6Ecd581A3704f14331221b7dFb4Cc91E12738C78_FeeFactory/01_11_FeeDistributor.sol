//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/INovationRouter02.sol";
import "./interfaces/IFeeDistributor.sol";

interface IReflection {
    function deliver(uint) external;
}

contract FeeDistributor is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    IERC20 public token;
    address public tokenOwner;
    address public tefiSwapper;
    INovationRouter02 public immutable router;

    uint public collectedBuyFees;
    uint public collectedSellFees;
    uint public minForAutoDistribution = 0.1 ether;
    bool public isManual;

    uint public liquidityBuyFee;
    uint public dividendBuyFee;
    uint public reflectBuyFee;
    uint public burnBuyFee;
    uint public marketingBuyFee;
    uint[] public reservedBuyFees;

    uint public liquiditySellFee;
    uint public dividendSellFee;
    uint public reflectSellFee;
    uint public burnSellFee;
    uint public marketingSellFee;
    uint[] public reservedSellFees;

    address public liquidityReceiver;
    address public marketingWallet;
    address[] public reservedWallets;

    uint public maxSellAmount;

    address public dividendTracker;
    string public dividendMethod;

    uint256 public constant feeDenominator = 10000;

    mapping(address => bool) public isFeeExempt;

    modifier onlyTokenOwner {
        require (msg.sender == tokenOwner, "!permission");
        _;
    }

    modifier onlySwapper {
        require (msg.sender == tefiSwapper, "!permission");
        _;
    }

    modifier checkMaxFee {
        _;
        require (totalBuyFee() <= 3000, "exceeded tobal buy fee");
        require (totalSellFee() <= 3000, "exceeded tobal sell fee");
    }

    constructor(address _token, address _router, address _swapper, address _owner) {
        token = IERC20(_token);
        router = INovationRouter02(_router);
        tefiSwapper = _swapper;
        tokenOwner = _owner;
        liquidityReceiver = _owner;
        marketingWallet = _owner;
    }

    function reservedFeeCount() external view returns (uint) {
        return reservedBuyFees.length;
    }

    function totalBuyFee() public view returns (uint) {
        uint other = 0;
        for (uint i = 0; i < reservedBuyFees.length; i++) {
            other += reservedBuyFees[i];
        }
        return (
            liquidityBuyFee.
            add(dividendBuyFee).
            add(reflectBuyFee).
            add(burnBuyFee).
            add(marketingBuyFee).
            add(other)
        );
    }

    function totalSellFee() public view returns (uint) {
        uint other = 0;
        for (uint i = 0; i < reservedSellFees.length; i++) {
            other += reservedSellFees[i];
        }
        return (
            liquiditySellFee.
            add(dividendSellFee).
            add(reflectSellFee).
            add(burnSellFee).
            add(marketingSellFee).
            add(other)
        );
    }

    function buyFees() public view returns (uint, uint, uint) {
        return (
            liquidityBuyFee,
            burnBuyFee,
            totalBuyFee().sub(liquidityBuyFee).sub(burnBuyFee)
        );
    }

    function sellFees() public view returns (uint, uint, uint) {
        return (
            liquiditySellFee,
            burnSellFee,
            totalSellFee().sub(liquiditySellFee).sub(burnSellFee)
        );
    }

    function getFeeSet() external view returns (uint[] memory, uint[] memory) {
        uint[] memory buyFeeSet = new uint[](reservedBuyFees.length + 5);
        buyFeeSet[0] = liquidityBuyFee;
        buyFeeSet[1] = dividendBuyFee;
        buyFeeSet[2] = reflectBuyFee;
        buyFeeSet[3] = burnBuyFee;
        buyFeeSet[4] = marketingBuyFee;
        for (uint i = 5; i < reservedBuyFees.length + 5; i++) {
            buyFeeSet[i] = reservedBuyFees[i-5];
        }

        uint[] memory sellFeeSet = new uint[](reservedSellFees.length + 5);
        sellFeeSet[0] = liquiditySellFee;
        sellFeeSet[1] = dividendSellFee;
        sellFeeSet[2] = reflectSellFee;
        sellFeeSet[3] = burnSellFee;
        sellFeeSet[4] = marketingSellFee;
        for (uint i = 5; i < reservedSellFees.length + 5; i++) {
            sellFeeSet[i] = reservedSellFees[i-5];
        }

        return (buyFeeSet, sellFeeSet);
    }

    function setBuyFees(uint[] memory _fees) external onlyTokenOwner checkMaxFee {
        require (_fees.length == reservedBuyFees.length + 5, "invalid fee set");
        liquidityBuyFee = _fees[0];
        dividendBuyFee = _fees[1];
        reflectBuyFee = _fees[2];
        burnBuyFee = _fees[3];
        marketingBuyFee = _fees[4];
        for (uint i = 0; i < reservedBuyFees.length; i++) {
            reservedBuyFees[i] = _fees[i+5];
        }
    }

    function setSellFees(uint[] memory _fees) external onlyTokenOwner checkMaxFee {
        require (_fees.length == reservedSellFees.length + 5, "invalid fee set");
        liquiditySellFee = _fees[0];
        dividendSellFee = _fees[1];
        reflectSellFee = _fees[2];
        burnSellFee = _fees[3];
        marketingSellFee = _fees[4];
        for (uint i = 0; i < reservedSellFees.length; i++) {
            reservedSellFees[i] = _fees[i+5];
        }
    }

    function transferFee(bool _sell) external payable onlySwapper {
        if (_sell) {
            collectedSellFees += msg.value;
        } else {
            collectedBuyFees += msg.value;
        }

        if (!isManual && address(this).balance >= minForAutoDistribution) {
            _distribute();
        }
    }

    function distribute() external onlyTokenOwner {
        _distribute();
    }

    function _distribute() internal {
        (,,uint _totalBuyFee) = buyFees();
        (,,uint _totalSellFee) = sellFees();
        uint dividendFee = 0;
        uint reflectFee = 0;
        uint marketingFee = 0;

        if (_totalBuyFee > 0) {
            dividendFee += collectedBuyFees.mul(dividendBuyFee).div(_totalBuyFee);
            reflectFee += collectedBuyFees.mul(reflectBuyFee).div(_totalBuyFee);
            marketingFee += collectedBuyFees.mul(marketingBuyFee).div(_totalBuyFee);
        }

        if (_totalSellFee > 0) {
            dividendFee += collectedSellFees.mul(dividendSellFee).div(_totalSellFee);
            reflectFee += collectedSellFees.mul(reflectSellFee).div(_totalSellFee);
            marketingFee += collectedSellFees.mul(marketingSellFee).div(_totalSellFee);
        }

        uint[] memory reservedFees = new uint[](reservedBuyFees.length);
        for (uint i = 0; i < reservedBuyFees.length; i++) {
            if (_totalBuyFee > 0) {
                reservedFees[i] += collectedBuyFees.mul(reservedBuyFees[i]).div(_totalBuyFee);
            }
            if (_totalSellFee > 0) {
                reservedFees[i] += collectedSellFees.mul(reservedSellFees[i]).div(_totalSellFee);
            }
        }

        if (dividendFee > 0 && dividendTracker != address(0)) {
            bool ret = _dividend(dividendFee);
            // require (ret == true, "failed sending to dividend tracker");
        } else {
            marketingFee += dividendFee;
        }
        
        if (reflectFee > 0) {
            _reflect(reflectFee);
        }

        if (marketingFee > 0) {
            (bool success, ) = payable(marketingWallet).call{
                value: marketingFee,
                gas: 30000
            }("");
        }

        for (uint i = 0; i < reservedFees.length; i++) {
            if (reservedFees[i] > 0) {
                (bool success, ) = payable(reservedWallets[i]).call{
                    value: reservedFees[i],
                    gas: 30000
                }("");
            }
        }
        
        collectedBuyFees = 0;
        collectedSellFees = 0;
    }

    function _dividend(uint _amount) internal returns (bool) {
        bool success;
        if (bytes(dividendMethod).length > 0 && 
        keccak256(abi.encodePacked(dividendMethod)) != keccak256(abi.encodePacked("null"))) {
            (success, ) = address(dividendTracker).call{
                value: _amount}(abi.encodeWithSignature(dividendMethod));
            return success;
        }

        (success, ) = payable(dividendTracker).call{
            value: _amount
        }("");
        
        return success;
    }

    function _reflect(uint _amount) internal returns (uint) {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(token);

        router.swapExactETHForTokens{value:_amount}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint bal = token.balanceOf(address(this));
        if (bal > 0) {
            IReflection(address(token)).deliver(bal);
        }

        return bal;
    }

    function updateTokenOwner(address _owner) external onlySwapper {
        require (_owner != address(0), "invalid owner");
        tokenOwner = _owner;
    }

    function setIsManual(bool _flag) external onlyTokenOwner {
        isManual = _flag;
    }

    function setMinForAutoDistribution(uint _amount) external onlyTokenOwner {
        minForAutoDistribution = _amount;
    }

    function setLiquidityReceiver(address _wallet) external onlyTokenOwner {
        liquidityReceiver = _wallet;
    }

    function setMarketingWallet(address _wallet) external onlyTokenOwner {
        marketingWallet = _wallet;
    }

    function setDividendTracker(address _tracker) external onlyTokenOwner {
        dividendTracker = _tracker;
    }

    function setDividendMethod(string memory _method) external onlyTokenOwner {
        dividendMethod = _method;
    }

    function setReservedWallet(uint index, address _wallet) external onlyTokenOwner {
        require (index < reservedBuyFees.length, "invalid index");
        reservedWallets[index] = _wallet;
    }

    function addReservedFee(uint _buyFee, uint _sellFee, address _wallet) external onlyTokenOwner checkMaxFee {
        reservedBuyFees.push(_buyFee);
        reservedSellFees.push(_sellFee);
        reservedWallets.push(_wallet);
    }

    function setMaxSellAmount(uint _amount) external onlyTokenOwner {
        maxSellAmount = _amount;
    }

    function excludeFee(address _addr, bool _flag) external onlyTokenOwner {
        isFeeExempt[_addr] = _flag;
    }

    function updateTefiSwapper(address _swapper) external onlyOwner {
        tefiSwapper = _swapper;
    }

    function getInStuck() external onlyTokenOwner {
        require (address(this).balance > collectedBuyFees.add(collectedSellFees), "no stucked");
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance.sub(collectedBuyFees).sub(collectedSellFees),
            gas: 30000
        }("");
    }

    receive() external payable {
        if (msg.sender != address(router)) {
            require (false, "!allowed direct sending BNB");
        }
    }
}

contract FeeFactory is Ownable {

    address[] public distributors;
    mapping (address => uint) public indexMap;
    mapping (address => address) public ownerMap;
    mapping (address => address) public distMap;

    address public immutable router;
    address public swapper;

    constructor(address _router, address _swapper) {
        router = _router;
        swapper = _swapper;
    }

    function deploy(address _token, address _owner) external onlyOwner {
        FeeDistributor dist = new FeeDistributor(_token, router, swapper, _owner);

        distributors.push(address(dist));
        indexMap[address(dist)] = distributors.length - 1;
        ownerMap[address(dist)] = _owner;
        distMap[_token] = address(dist);

        dist.transferOwnership(msg.sender);
    }

    function count() external view returns (uint) {
        return distributors.length;
    }
}