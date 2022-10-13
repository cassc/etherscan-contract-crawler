//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/INovationRouter02.sol";
import "./interfaces/INovationPair.sol";
import "./interfaces/INovationFactory.sol";

struct PoolParam {
    uint hardCap;
    uint softCap;
    uint minInvest;
    uint maxInvest;
    uint startTime;
    uint endTime;
    uint salePrice;
    uint listPrice;
    uint liquidityAlloc;
    bool isBurnForUnsold;
}

interface IPool {
    function token() external view returns (address);
    function hardcap() external view returns (uint);
    function softcap() external view returns (uint);
    function maxInvestable() external view returns (uint);
    function minInvestable() external view returns(uint);
    function startTime() external view returns (uint);
    function endTime() external view returns (uint);
    function salePrice() external view returns(uint);
    function publicMode() external view returns (bool);
    function tokenOwner() external view returns (address);
}

contract PresalePool is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    bool public publicMode;
    mapping(address => bool) public whitelist;
    mapping(address => uint) public invests;
    address[] public investors;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    INovationRouter02 public immutable router;

    uint public maxInvestable = 100 ether;
    uint public minInvestable;
    uint public hardcap = 10000 ether;
    uint public softcap;
    bool public canceled;
    bool public enabled = true;
    // bool public ended;
    bool public finalized;
    uint public startTime;
    uint public endTime;

    uint public raised;

    uint public salePrice;
    uint public listPrice;
    uint public liquidityAlloc;
    bool public isBurnForUnsold;

    bool public enabledClaim;
    mapping(address => bool) public claimed;
    uint public totalClaimed;
    bool public enabledRefund;
    mapping(address => bool) public refunded;

    address public tokenOwner;

    address public bnbFeeWallet = 0xe327c0F351eC6809c0339EF75e7DF1A225e90Fae;
    address public tokenFeeWallet = 0xe327c0F351eC6809c0339EF75e7DF1A225e90Fae;
    uint public bnbFee = 400; // 4%
    uint public tokenFee;
    uint public constant feeDenominator = 10000;

    uint public minBnbAllocToLiquidity = 5000; // 50%
    uint public minTokenAllocToLiquidity = 1000; // 10%

    modifier onlyTokenOwner {
        require (msg.sender == tokenOwner, "!token owner");
        _;
    }

    modifier beforeStarted {
        require (!(enabled && block.timestamp >= startTime), "sale already started");
        _;
    }

    modifier onlyStarted {
        require (enabled && block.timestamp >= startTime, "sale isn't started");
        _;
    }

    constructor(
        address _token, 
        address _router,
        address _owner
    ) {
        token = IERC20(_token);
        tokenOwner = _owner;
        router = INovationRouter02(_router);
    }

    function initialize(
        PoolParam calldata _args, 
        address[] calldata _whitelist
    ) external onlyOwner {
        require (_args.hardCap > 0, "!hardcap");
        require (_args.softCap <= _args.hardCap, "!softcap");
        hardcap = _args.hardCap;
        if (_args.softCap > 0) softcap = _args.softCap;
        
        minInvestable = _args.minInvest == 0 ? 0.01 ether : _args.minInvest;
        maxInvestable = _args.maxInvest == 0 ? hardcap : _args.maxInvest;
        require (minInvestable <= maxInvestable, "!min investable");
        
        startTime = _args.startTime == 0 ? (block.timestamp + 1 hours) : _args.startTime;
        endTime = _args.endTime == 0 ? (block.timestamp + 2 days) : _args.endTime;
        require (startTime > block.timestamp, "!start time");
        require (startTime < endTime, "!end time");

        require (_args.salePrice > 0, "!sale price");
        salePrice = _args.salePrice;
        listPrice = _args.listPrice;
        require (_args.liquidityAlloc < feeDenominator, "!lp alloc");
        liquidityAlloc = _args.liquidityAlloc;
        isBurnForUnsold = _args.isBurnForUnsold;

        if (_whitelist.length > 0) {
            for (uint i = 0; i < _whitelist.length; i++) whitelist[_whitelist[i]] = true;
        } else {
            publicMode = true;
        }
    }

    function setPublicMode(bool _flag) external beforeStarted onlyTokenOwner {
        publicMode = _flag;
    }

    function setWhilteList(address[] memory _accounts, bool _flag) external beforeStarted onlyTokenOwner {
        for (uint i = 0; i < _accounts.length; i++) {
            if (whitelist[_accounts[i]] != _flag) whitelist[_accounts[i]] = _flag;
        }
    }

    function setInvestable(uint _min, uint _max) external beforeStarted onlyTokenOwner {
        require (_min <= _max, "invalid amount");
        minInvestable = _min;
        maxInvestable = _max;
    }

    function setCap(uint _soft, uint _hard) external beforeStarted onlyTokenOwner {
        require (_soft <= _hard, "invalid cap");
        softcap = _soft;
        hardcap = _hard;
    }

    function updateStartTime(uint _start) external beforeStarted onlyTokenOwner {
        require (block.timestamp <= _start, "invalid start time");
        startTime = _start;
    }

    function updateEndTime(uint _end) external beforeStarted onlyTokenOwner {
        if (_end > 0) { 
            require (_end > startTime, "!end time");
            endTime = _end;
        } else endTime = type(uint).max;
    }

    function setSalePrice(uint _price) external beforeStarted onlyTokenOwner {
        require (!enabledClaim, "already in claiming");
        salePrice = _price;
    }

    function setListingPrice(uint _price) external onlyTokenOwner {
        require (!finalized, "already listed");
        listPrice = _price;
    }

    function setLiquidityAlloc(uint _alloc) external onlyTokenOwner {
        require (!finalized, "already listed");
        require (_alloc <= feeDenominator - bnbFee, "!percent");
        liquidityAlloc = _alloc;
    }

    function toggleBurnForUnsold() external onlyTokenOwner {
        isBurnForUnsold = !isBurnForUnsold;
    }

    function cancelSale() external onlyTokenOwner {
        require (block.timestamp < startTime, "sale started");

        uint deposit = token.balanceOf(address(this));
        if (deposit > 0) token.safeTransfer(tokenOwner, deposit);

        canceled = true;
        enabled = false;
    }

    function enableSale() external onlyTokenOwner {
        require (!canceled, "canceled pool");
        require (token.balanceOf(address(this)) >= salePrice*hardcap/1e18, "!enough tokens");
        enabled = true;
    }

    function endSale() external onlyStarted onlyTokenOwner {
        // ended = true;
        endTime = block.timestamp;
    }

    // function enableClaim() external onlyTokenOwner {
    //     require (block.timestamp >= endTime, "!available");
    //     require (finalized, "!finalized");
    //     enabledClaim = true;
    // }

    function enableRefund() external onlyTokenOwner {
        require (block.timestamp >= endTime, "still in sale");
        require (!finalized, "already finalized");

        uint deposit = token.balanceOf(address(this));
        if (deposit > 0) token.safeTransfer(tokenOwner, deposit);

        enabledRefund = true;
    }

    function invest() external payable {
        require (msg.value > 0, "!invest");
        _invest();
    }

    function _invest() internal nonReentrant {
        require (enabled, "!enabld sale");
        require (block.timestamp >= startTime, "!started");
        require (block.timestamp < endTime, "ended");
        if (publicMode == false) require (whitelist[msg.sender] == true, "!whitelisted");
        require (raised + msg.value <= hardcap, "filled hardcap");
        require (invests[msg.sender] + msg.value <= maxInvestable, "exceeded invest");
        if (invests[msg.sender] == 0) {
            require (msg.value >= minInvestable, "too small invest");
        }

        if (invests[msg.sender] == 0) investors.push(msg.sender);
        
        invests[msg.sender] += msg.value;
        raised += msg.value;
    }

    function claim() external nonReentrant {
        require (invests[msg.sender] > 0, "!investor");
        require (enabledClaim == true, "!available");
        require (claimed[msg.sender] == false, "already claimed");

        uint claimAmount = salePrice * invests[msg.sender] / 1e18;

        require (claimAmount <= token.balanceOf(address(this)), "no balance");
        
        token.safeTransfer(msg.sender, claimAmount);

        claimed[msg.sender] = true;
        totalClaimed += claimAmount;
    }

    function multiSend() external onlyTokenOwner {
        require (enabledClaim == true, "!available");

        for (uint i = 0; i < investors.length; i++) {
            address investor = investors[i];
            if (claimed[investor] == true) continue;

            uint claimAmount = salePrice * invests[investor] / 1e18;

            require (claimAmount <= token.balanceOf(address(this)), "no balance");
            
            token.safeTransfer(investor, claimAmount);

            claimed[investor] = true;
            totalClaimed += claimAmount;
        }
    }

    function finalize() external onlyTokenOwner {
        require (enabledRefund == false, "enabled refund");
        require (block.timestamp >= endTime, "!end");
        require (raised >= softcap, "failed");
        
        if (liquidityAlloc == 0) {
            withdraw();
            return;
        }

        require (liquidityAlloc >= minBnbAllocToLiquidity, "!bnb percent");
        uint _bnbAmount = liquidityAlloc * raised / feeDenominator;
        uint _tokenAmount = _bnbAmount * listPrice / 1e18;
        require (_tokenAmount >= minTokenAllocToLiquidity * token.totalSupply() / feeDenominator, "!token percent");

        
        INovationFactory factory = INovationFactory(router.factory());
        INovationPair pair = INovationPair(factory.getPair(address(token), router.WETH()));
        if (address(pair) == address(0)) {
            pair = INovationPair(INovationFactory(router.factory()).createPair(
                address(token),
                router.WETH()
            ));
        }

        require (pair.totalSupply() == 0, "liquidity exsits");

        uint _before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _tokenAmount);
        uint _after = token.balanceOf(address(this));
        require (_after - _before >= _tokenAmount, "!liquidity tokens");

        token.approve(address(router), _tokenAmount);
        router.addLiquidityETH{value: _bnbAmount}(
            address(token),
            _tokenAmount,
            0,
            0,
            tokenOwner,
            block.timestamp
        );

        uint feeAmount = raised * bnbFee / feeDenominator;
        if (feeAmount > 0) {
            address(bnbFeeWallet).call{value: feeAmount}("");
        }
        address(tokenOwner).call{value: raised - _bnbAmount - feeAmount}("");

        if (tokenFee > 0) {
            feeAmount = (salePrice * hardcap / 1e18) * tokenFee / feeDenominator;
            token.safeTransferFrom(msg.sender, tokenFeeWallet, feeAmount);
        }

        finalized = true;
        enabledClaim = true;
    }

    function withdraw() internal {
        uint feeAmount = raised * bnbFee / feeDenominator;
        if (feeAmount > 0) {
            address(bnbFeeWallet).call{value: feeAmount}("");
        }
        address(tokenOwner).call{value: raised - feeAmount}("");

        if (tokenFee > 0) {
            feeAmount = (salePrice * hardcap / 1e18) * tokenFee / feeDenominator;
            token.safeTransferFrom(msg.sender, tokenFeeWallet, feeAmount);
        }

        finalized = true;
        enabledClaim = true;
    }

    function transferUnsold() external {
        require (msg.sender == owner() || msg.sender == tokenOwner, "!owner");
        require (finalized, "!available");
        require (hardcap > raised, "filled");
        uint unsold = salePrice * (hardcap - raised) / 1e18;
        if (isBurnForUnsold) token.safeTransfer(DEAD, unsold);
        else token.safeTransfer(tokenOwner, unsold);
    }

    function getRefund() external nonReentrant {
        require (enabledRefund == true, "!available");
        require (invests[msg.sender] > 0, "!investor");
        require (refunded[msg.sender] == false, "already returned");
        address(msg.sender).call{value: invests[msg.sender]}("");
        refunded[msg.sender] = true;
    }

    function claimable(address _user) external view returns(uint) {
        return salePrice * invests[_user] / 1e18;
    }

    function getInvestors() external view returns (address[] memory, uint[] memory) {
        uint[] memory amountList = new uint[](investors.length);
        for (uint i = 0; i < investors.length; i++) {
            amountList[i] = invests[investors[i]];
        }

        return (investors, amountList);
    }

    function count() external view returns (uint) {
        return investors.length;
    }

    function saleAmount() external view returns (uint amount) {
        amount = salePrice * raised / 1e18;
    }

    function started() external view returns (bool) {
        return (block.timestamp >= startTime) && enabled;
    }

    function ended() public view returns (bool) {
        return (block.timestamp >= endTime);
    }

    function setFee(uint _bnbFee, uint _tokenFee) external onlyOwner {
        bnbFee = _bnbFee;
        tokenFee = _tokenFee;
    }

    function setFeeWallets(address _bnbWallet, address _tokenWallet) external onlyOwner {
        bnbFeeWallet = _bnbWallet;
        tokenFeeWallet = _tokenWallet;
    }

    function setLimitForLiquidity(uint _bnb, uint _token) external onlyOwner {
        require (_bnb > 0 && _bnb <= feeDenominator, "invalid");
        require (_token > 0 && _token <= feeDenominator, "invalid");
        minBnbAllocToLiquidity = _bnb;
        minTokenAllocToLiquidity = _token;
    }

    // function getTokensInStuck() external onlyTokenOwner {
    //     uint256 _bal = token.balanceOf(address(this));
    //     if (_bal > 0) token.safeTransfer(msg.sender, _bal);
    // }

    receive() external payable {
        // _invest();
        revert ("!available to send BNB directly");
    }
}