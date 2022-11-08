pragma solidity ^0.8.9;

// SPDX-License-Identifier: MIT

import "./Interfaces/IBEP20.sol";
import "./Interfaces/IPreSale.sol";
import "./Interfaces/IPancakeswapV2Factory.sol";


interface ImetaStarterDeployer{
    function getAdmin() external view returns(address);
}

contract preSaleBnb is ReentrancyGuard {
    using SafeMath for uint256;

    address payable public admin;
    address payable public tokenOwner;
    IBEP20 public pair;
    IBEP20 public nativetoken;
    uint256 public liquidityunLocktime;
    uint256 public liquiditylockduration;
    address public deployer;
    IBEP20 public token;
    IPancakeRouter02 public routerAddress;

    uint256 public adminFeePercent;
    uint256 public reffralPercent;
    uint256 public buybackPercent;
    uint256 public tokenPrice;
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public hardCap;
    uint256 public softCap;
    uint256 public listingPrice;
    uint256 public liquidityPercent;
    uint256 public soldTokens;
    uint256 public preSaleTokens;
    uint256 public totalUser;
    uint256 public amountRaised;
    uint256 public refamountRaised;

    bool public allow;
    bool public canClaim;

    mapping(address => uint256) public tokenBalance;
    mapping(address => uint256) public bnbBalance;
    mapping(address => uint256) public refBalance;

    modifier onlyAdmin() {
        require(msg.sender == admin, "MetaStarter: Not an admin");
        _;
    }

    modifier onlyTokenOwner() {
        require(msg.sender == tokenOwner, "MetaStarter: Not a token owner");
        _;
    }

    modifier allowed() {
        require(allow == true, "MetaStarter: Not allowed");
        _;
    }

    event tokenBought(
        address indexed user,
        uint256 indexed numberOfTokens,
        uint256 indexed amountBusd
    );

    event tokenClaimed(address indexed user, uint256 indexed numberOfTokens);

    event bnbClaimed(address indexed user, uint256 indexed balance);

    event tokenUnSold(address indexed user, uint256 indexed numberOfTokens);

    constructor(){
        deployer = msg.sender;
        allow = true;
    }

    // called once by the deployer contract at time of deployment
    function initialize(
        address _tokenOwner,
        IBEP20 _token,
        uint256[9] memory values,
        uint256 _adminfeePercent,
        uint256 _reffralPercent,
        uint256 _buybackPercent,
        address _routerAddress,
        uint256 _liquiditylockduration,
        IBEP20 _nativetoken
    ) external {
        require(msg.sender == deployer, "MetaStarter: FORBIDDEN"); // sufficient check
        admin = payable(ImetaStarterDeployer(deployer).getAdmin());
        tokenOwner = payable(_tokenOwner);
        token = _token;
        tokenPrice = values[0];
        preSaleStartTime = values[1];
        preSaleEndTime = values[2];
        minAmount = values[3];
        maxAmount = values[4];
        hardCap = values[5];
        softCap = values[6];
        listingPrice = values[7];
        liquidityPercent = values[8];
        adminFeePercent = _adminfeePercent;
        reffralPercent = _reffralPercent;
        buybackPercent = _buybackPercent;
        routerAddress = IPancakeRouter02(_routerAddress);
        preSaleTokens = bnbToToken(hardCap);
        liquiditylockduration = _liquiditylockduration;
        nativetoken = _nativetoken;
    }

    receive() external payable {}

    // to buy token during preSale time => for web3 use
    function buyToken(address payable reffral) public payable allowed isHuman {
        require(block.timestamp < preSaleEndTime, "MetaStarter: Time over"); // time check
        require(
            block.timestamp > preSaleStartTime,
            "MetaStarter: Time not Started"
        ); // time check
        require(
            getContractBnbBalance() <= hardCap,
            "MetaStarter: Hardcap reached"
        );
        uint256 numberOfTokens = bnbToToken(msg.value);
        uint256 maxBuy = bnbToToken(maxAmount);
        require(
            msg.value >= minAmount && msg.value <= maxAmount,
            "MetaStarter: Invalid Amount"
        );
        require(
            numberOfTokens.add(tokenBalance[msg.sender]) <= maxBuy,
            "MetaStarter: Amount exceeded"
        );
        if (tokenBalance[msg.sender] == 0) {
            totalUser++;
        }
        tokenBalance[msg.sender] = tokenBalance[msg.sender].add(numberOfTokens);
        bnbBalance[msg.sender] = bnbBalance[msg.sender].add(
            msg.value.sub(msg.value.mul(reffralPercent).div(100))
        );
        refBalance[reffral] = refBalance[reffral].add(
            msg.value.mul(reffralPercent).div(100)
        );
        refamountRaised = refamountRaised.add(
            msg.value.mul(reffralPercent).div(100)
        );
        soldTokens = soldTokens.add(numberOfTokens);
        amountRaised = amountRaised.add(msg.value);

        emit tokenBought(msg.sender, numberOfTokens, msg.value);
    }

    function claim() public allowed isHuman {
        require(
            block.timestamp > preSaleEndTime,
            "MetaStarter: Presale not over"
        );
        require(canClaim == true, "MetaStarter: pool not initialized yet");

        if (amountRaised < softCap) {
            uint256 Balance = bnbBalance[msg.sender];
            require(Balance > 0, "MetaStarter: Zero balance");

            payable(msg.sender).transfer(Balance);
            bnbBalance[msg.sender] = 0;
            if (refBalance[msg.sender] > 0) {
                payable(msg.sender).transfer(refBalance[msg.sender]);
                refBalance[msg.sender] = 0;
                emit bnbClaimed(msg.sender, refBalance[msg.sender]);
            }

            emit bnbClaimed(msg.sender, Balance);
        } else {
            uint256 numberOfTokens = tokenBalance[msg.sender];
            require(numberOfTokens > 0, "MetaStarter: Zero balance");

            token.transfer(msg.sender, numberOfTokens);
            tokenBalance[msg.sender] = 0;
            if (refBalance[msg.sender] > 0) {
                payable(msg.sender).transfer(refBalance[msg.sender]);
                emit bnbClaimed(msg.sender, refBalance[msg.sender]);
                refBalance[msg.sender] = 0;
            }

            emit tokenClaimed(msg.sender, numberOfTokens);
        }
    }

    function withdrawAndInitializePool() public onlyTokenOwner allowed isHuman {
        require(
            block.timestamp > preSaleEndTime,
            "MetaStarter: PreSale not over yet"
        );
        if (amountRaised > softCap) {
            canClaim = true;
            uint256 bnbAmountForLiquidity = amountRaised
                .mul(liquidityPercent)
                .div(100);
            uint256 tokenAmountForLiquidity = listingTokens(
                bnbAmountForLiquidity
            );
            token.approve(address(routerAddress), tokenAmountForLiquidity);
            addLiquidity(tokenAmountForLiquidity, bnbAmountForLiquidity);
            pair = IBEP20(
                IPancakeswapV2Factory(address(routerAddress.factory())).getPair(
                    address(token),
                    routerAddress.WETH()
                )
            );
            liquidityunLocktime = block.timestamp.add(liquiditylockduration);
            buyTokens(amountRaised.mul(buybackPercent).div(100), address(this));
            nativetoken.burn(nativetoken.balanceOf(address(this)));
            admin.transfer(amountRaised.mul(adminFeePercent).div(100));
            tokenOwner.transfer(getContractBnbBalance().sub(refamountRaised));
            uint256 refund = getContractTokenBalance().sub(soldTokens);
            if (refund > 0) {
                token.transfer(tokenOwner, refund);

                emit tokenUnSold(tokenOwner, refund);
            }
        } else {
            canClaim = true;
            token.transfer(tokenOwner, getContractTokenBalance());

            emit tokenUnSold(tokenOwner, getContractBnbBalance());
        }
    }

    function unlocklptokens() external onlyTokenOwner {
        
        require( block.timestamp > liquidityunLocktime, 
        "MetaStarter: Liquidity lock not over yet"
        );
        pair.transfer(tokenOwner, pair.balanceOf(address(this)));
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) internal {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value: bnbAmount}(
            address(token),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp + 360
        );
    }

    function buyTokens(uint256 amount, address to) internal {
        address[] memory path = new address[](2);
        path[0] = routerAddress.WETH();
        path[1] = address(nativetoken);

        routerAddress.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(0, path, to, block.timestamp);
    }

    // to check number of token for buying
    function bnbToToken(uint256 _amount) public view returns (uint256) {
        uint256 numberOfTokens = _amount.mul(tokenPrice).mul(1000).div(1 ether);
        return numberOfTokens.mul(10**(token.decimals())).div(1000);
    }

    // to calculate number of tokens for listing price
    function listingTokens(uint256 _amount) public view returns (uint256) {
        uint256 numberOfTokens = _amount.mul(listingPrice).mul(1000).div(
            1 ether
        );
        return numberOfTokens.mul(10**(token.decimals())).div(1000);
    }

    // to check contribution
    function userContribution(address _user) public view returns (uint256) {
        return bnbBalance[_user];
    }

    // to check contribution
    function refContribution(address _user) public view returns (uint256) {
        return refBalance[_user];
    }

    // to check token balance of user
    function userTokenBalance(address _user) public view returns (uint256) {
        return tokenBalance[_user];
    }

    // to Stop preSale in case of scam
    function setAllow(bool _enable) external onlyAdmin {
        allow = _enable;
    }

    function getContractBnbBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getContractTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
}