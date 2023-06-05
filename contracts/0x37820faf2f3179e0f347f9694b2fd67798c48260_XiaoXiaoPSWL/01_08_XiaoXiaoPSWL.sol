// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Ownable.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (
        uint amountToken,
        uint amountETH,
        uint liquidity
    );
}

contract XiaoXiaoPSWL is Ownable, EIP712 {
    using SafeMath for uint256;

    bool public isInit;
    bool public isDeposit;
    bool public isRefund;
    bool public isFinish;
    bool public isWhitelist = true;
    bool public burnTokens = true;
    address public creatorWallet;
    address public weth;
    uint8 public tokenDecimals = 18;
    uint256 public ethRaised;
    uint256 public percentageRaised;
    uint256 public tokensSold;
    address public signerPublicAddress = 0xEF8f8C2A8383F48d8413f2d0bacB8e69ed1A101D;

    struct Pool {
        uint64 startTime;
        uint64 endTime;
        uint256 tokenDeposit;
        uint256 tokensForSale;
        uint256 tokensForLiquidity;
        uint8 liquidityPortion;
        uint256 hardCap;
        uint256 softCap;
        uint256 maxBuy;
        uint256 minBuy;
    }

    IERC20 public tokenInstance;
    IUniswapV2Factory public UniswapV2Factory;
    IUniswapV2Router02 public UniswapV2Router02;
    Pool public pool;

    mapping(address => uint256) public ethContribution;

    modifier onlyActive {
        require(block.timestamp >= pool.startTime, "Sale must be active.");
        require(block.timestamp <= pool.endTime, "Sale must be active.");
        _;
    }

    modifier onlyInactive {
        require(
            block.timestamp < pool.startTime ||
            block.timestamp > pool.endTime ||
            ethRaised >= pool.softCap, "Sale must be inactive."
            );
        _;
    }

    modifier onlyRefund {
        require(
            isRefund == true ||
            (block.timestamp > pool.endTime && ethRaised < pool.softCap), "Refund unavailable."
            );
        _;
    }

    constructor(
        IERC20 _tokenInstance,
        address _uniswapv2Router,
        address _uniswapv2Factory,
        address _weth
    ) EIP712("XiaoXiaoPSWL", "1.0.0") {
        require(_uniswapv2Router != address(0), "Invalid router address");
        require(_uniswapv2Factory != address(0), "Invalid factory address");

        isInit = false;
        isDeposit = false;
        isFinish = false;
        isRefund = false;
        ethRaised = 0;

        weth = _weth;
        tokenInstance = _tokenInstance;
        creatorWallet = address(payable(msg.sender));
        UniswapV2Router02 = IUniswapV2Router02(_uniswapv2Router);
        UniswapV2Factory = IUniswapV2Factory(_uniswapv2Factory);

        require(UniswapV2Factory.getPair(address(tokenInstance), weth) == address(0), "IUniswap: Pool exists.");

        tokenInstance.approve(_uniswapv2Router, tokenInstance.totalSupply());
    }

    event Liquified(
        address indexed _token,
        address indexed _router,
        address indexed _pair
        );

    event Canceled(
        address indexed _inititator,
        address indexed _token,
        address indexed _presale
        );

    event Bought(address indexed _buyer, uint256 _tokenAmount);

    event Refunded(address indexed _refunder, uint256 _tokenAmount);

    event Deposited(address indexed _initiator, uint256 _totalDeposit);

    event Claimed(address indexed _participent, uint256 _tokenAmount);

    event RefundedRemainder(address indexed _initiator, uint256 _amount);

    event BurntRemainder(address indexed _initiator, uint256 _amount);

    event Withdraw(address indexed _creator, uint256 _amount);

    /*
    * Reverts ethers sent to this address whenever requirements are not met
    */
    receive() external payable {
        if (!isWhitelist) {
            if(block.timestamp >= pool.startTime && block.timestamp <= pool.endTime){
                buyTokens(_msgSender());
            } else {
                revert("Presale is closed");
            }
        } else {
            revert("Transfer not allowed");
        }
    }

    /*
    * Initiates the arguments of the sale
    @dev arguments must be pa   ssed in wei (amount*10**18)
    */
    function initSale(
        uint64 _startTime,
        uint64 _endTime,
        uint256 _tokenDeposit,
        uint256 _tokensForSale,
        uint256 _tokensForLiquidity,
        uint8 _liquidityPortion,
        uint256 _hardCap,
        uint256 _softCap,
        uint256 _maxBuy,
        uint256 _minBuy
        ) external onlyOwner onlyInactive {

        require(isInit == false, "Sale no initialized");
        require(_startTime >= block.timestamp, "Invalid start time.");
        require(_endTime > block.timestamp, "Invalid end time.");
        require(_tokenDeposit > 0, "Invalid token deposit.");
        require(_tokensForSale < _tokenDeposit, "Invalid tokens for sale.");
        require(_tokensForLiquidity < _tokenDeposit, "Invalid tokens for liquidity.");
        require(_softCap >= _hardCap / 2, "SC must be >= HC/2.");
        require(_liquidityPortion >= 50, "Liquidity must be >=50.");
        require(_liquidityPortion <= 100, "Invalid liquidity.");
        require(_minBuy < _maxBuy, "Min buy must greater than max.");
        require(_minBuy > 0, "Min buy must exceed 0.");

        Pool memory newPool = Pool(
            _startTime,
            _endTime,
            _tokenDeposit,
            _tokensForSale,
            _tokensForLiquidity,
            _liquidityPortion,
            _hardCap,
            _softCap,
            _maxBuy,
            _minBuy
        );

        pool = newPool;

        isInit = true;
    }

    /*
    * Once called the owner deposits tokens into pool
    */
    function deposit() external onlyOwner {
        require(!isDeposit, "Tokens already deposited.");
        require(isInit, "Not initialized yet.");

        uint256 totalDeposit = _getTokenDeposit();

        isDeposit = true;

        require(tokenInstance.transferFrom(msg.sender, address(this), totalDeposit), "Deposit failed.");

        emit Deposited(msg.sender, totalDeposit);
    }

    /*
    * Finish the sale - Create Uniswap v2 pair, add liquidity, take fees, withrdawal funds, burn/refund unused tokens
    */
    function finishSale() external onlyOwner onlyInactive {
        require(ethRaised >= pool.softCap, "Soft Cap is not met.");
        require(block.timestamp > pool.startTime, "Can not finish before start");
        require(!isFinish, "Sale already launched.");
        require(!isRefund, "Refund process.");

        percentageRaised = _getPercentageFromValue(ethRaised, pool.hardCap);
        tokensSold = _getValueFromPercentage(percentageRaised, pool.tokensForSale);
        uint256 tokensForLiquidity = _getValueFromPercentage(percentageRaised, pool.tokensForLiquidity);
        isFinish = true;

        //add liquidity
        (uint amountToken, uint amountETH, ) = UniswapV2Router02.addLiquidityETH{value : _getLiquidityEth()}(
            address(tokenInstance),
            tokensForLiquidity,
            tokensForLiquidity,
            _getLiquidityEth(),
            owner(),
            block.timestamp + 600
        );

        require(amountToken == tokensForLiquidity && amountETH == _getLiquidityEth(), "Providing liquidity failed.");

        emit Liquified(
            address(tokenInstance),
            address(UniswapV2Router02),
            UniswapV2Factory.getPair(address(tokenInstance), weth)
        );

        //withrawal eth
        uint256 ownerShareEth = _getOwnerEth();

        if (ownerShareEth > 0) {
            payable(creatorWallet).transfer(ownerShareEth);
        }

        //If HC is not reached, burn or refund the remainder
        if (ethRaised < pool.hardCap) {
            uint256 remainder = _getUserTokens(pool.hardCap - ethRaised) + (pool.tokensForLiquidity - tokensForLiquidity);
            if(burnTokens == true){
                require(tokenInstance.transfer(
                    0x000000000000000000000000000000000000dEaD,
                    remainder), "Unable to burn."
                );
                emit BurntRemainder(msg.sender, remainder);
            } else {
                require(tokenInstance.transfer(creatorWallet, remainder), "Refund failed.");
                emit RefundedRemainder(msg.sender, remainder);
            }
        }
    }

    /*
    * The owner can decide to close the sale if it is still active
    NOTE: Creator may call this function even if the Hard Cap is reached, to prevent it use:
     require(ethRaised < pool.hardCap)
    */
    function cancelSale() external onlyOwner onlyActive {
        require(!isFinish, "Sale finished.");
        pool.endTime = 0;
        isRefund = true;

        if (tokenInstance.balanceOf(address(this)) > 0) {
            uint256 tokenDeposit = _getTokenDeposit();
            tokenInstance.transfer(msg.sender, tokenDeposit);
            emit Withdraw(msg.sender, tokenDeposit);
        }
        emit Canceled(msg.sender, address(tokenInstance), address(this));
    }

    /*
    * Allows participents to claim the tokens they purchased
    */
    function claimTokens() external onlyInactive {
        require(isFinish, "Sale is still active.");
        require(!isRefund, "Refund process.");
        require(ethContribution[msg.sender] > 0, "No tokens to be claimed.");

        uint256 tokensAmount = _getUserTokens(ethContribution[msg.sender]);
        ethContribution[msg.sender] = 0;
        require(tokenInstance.transfer(msg.sender, tokensAmount), "Claim failed.");
        emit Claimed(msg.sender, tokensAmount);
    }

    /*
    * Refunds the Eth to participents
    */
    function refund() external onlyInactive onlyRefund {
        uint256 refundAmount = ethContribution[msg.sender];

        require(refundAmount > 0, "No refund amount");
        require(address(this).balance >= refundAmount, "No amount available");

        ethContribution[msg.sender] = 0;
        address payable refunder = payable(msg.sender);
        refunder.transfer(refundAmount);
        emit Refunded(refunder, refundAmount);
    }

    /*
    * Withdrawal tokens on refund
    */
    function withrawTokens() external onlyOwner onlyInactive onlyRefund {
        if (tokenInstance.balanceOf(address(this)) > 0) {
            uint256 tokenDeposit = _getTokenDeposit();
            require(tokenInstance.transfer(msg.sender, tokenDeposit), "Withdraw failed.");
            emit Withdraw(msg.sender, tokenDeposit);
        }
    }

    /*
    * TODO: Add description.
    */
    function buyTokens(address _contributor) public payable onlyActive {
        require(!isWhitelist, "Whitelist is active.");
        _buyTokens(_contributor);
    }

    /*
    * TODO: Add description.
    */
    function buyTokens(address _contributor, bytes calldata signature) public payable onlyActive {
        require(isWhitelist, "Whitelist is not active.");
        require(_recoverAddress(_contributor, signature) == signerPublicAddress, "Account is not whitelisted.");
        _buyTokens(_contributor);
    }

    /*
    * TODO: Add description.
    */
    function setWhitelist(bool isWhitelist_) public onlyOwner {
        isWhitelist = isWhitelist_;
    }

    /*
    * TODO: Add description.
    */
    function setSignerPublicAddress(address signerPublicAddress_) public onlyOwner {
        signerPublicAddress = signerPublicAddress_;
    }

    /*
    * If requirements are passed, updates user"s token balance based on their eth contribution
    */
    function _buyTokens(address _contributor) internal {
        require(!isFinish, "Sale finished.");
        require(isDeposit, "Tokens not deposited.");
        require(_contributor != address(0), "Transfer to 0 address.");
        require(msg.value != 0, "Wei Amount is 0");

        if (ethRaised > pool.hardCap - pool.minBuy) {
            require(msg.value == pool.hardCap - ethRaised, "Value must be the remainder.");
        } else {
            require(msg.value >= pool.minBuy, "Min buy is not met.");
        }

        require(msg.value + ethContribution[_contributor] <= pool.maxBuy, "Max buy limit exceeded.");
        require(ethRaised + msg.value <= pool.hardCap, "HC Reached.");

        ethRaised += msg.value;
        ethContribution[msg.sender] += msg.value;
    }

    /*
    * Internal functions, called when calculating balances
    */
    function _getUserTokens(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(tokensSold).div(ethRaised);
    }

    /*
    * TODO: Add description.
    */
    function _getLiquidityEth() internal view returns (uint256) {
        return _getValueFromPercentage(pool.liquidityPortion, ethRaised);
    }

    /*
    * TODO: Add description.
    */
    function _getOwnerEth() internal view returns (uint256) {
        uint256 liquidityEthFee = _getLiquidityEth();
        return ethRaised - liquidityEthFee;
    }

    /*
    * TODO: Add description.
    */
    function _getTokenDeposit() internal view returns (uint256){
        return pool.tokenDeposit;
    }

    /*
    * TODO: Add description.
    */
    function _getPercentageFromValue(uint256 currentValue, uint256 maxValue) internal pure returns (uint256) {
        require(currentValue <= maxValue, "Number too high");

        return currentValue.mul(100).div(maxValue);
    }

    /*
    * TODO: Add description.
    */
    function _getValueFromPercentage(uint256 currentPercentage, uint256 maxValue) internal pure returns (uint256) {
        require(currentPercentage <= 100, "Number too high");

        return maxValue.mul(currentPercentage).div(100);
    }

    /*
    * TODO: Add description.
    */
    function _hash(address account) internal view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("XiaoXiaoPSWL(address account)"),
                    account
                )
            )
        );
    }

    /*
    * TODO: Add description.
    */
    function _recoverAddress(address account, bytes calldata signature) internal view returns (address) {
        return ECDSA.recover(_hash(account), signature);
    }
}