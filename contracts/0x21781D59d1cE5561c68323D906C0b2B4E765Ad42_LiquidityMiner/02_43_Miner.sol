// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IERC20Minimal.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV2V3Interface.sol";
import "@uniswap/v3-staker/contracts/interfaces/IUniswapV3Staker.sol";
import "@uniswap/v3-core/contracts/interfaces/IERC20Minimal.sol";
import "@uniswap/v3-staker/contracts/libraries/IncentiveId.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces/IOracle.sol";
import "./Mocks/aUSDmock.sol";
import "./Mocks/XFTmock.sol";

contract Miner is IERC721Receiver, Ownable {
    XFTMock public XFT;
    anonUSD public aUSD;
    IWETH9 public WETH;
    IUniswapV3Pool public xftPool;
    IUniswapV3Pool public tokenPool;
    INonfungiblePositionManager public immutable nonfungiblePositionManager;
    IUniswapV3Staker public immutable uniswapV3Staker;
    IOracle public oracle;
    AggregatorV2V3Interface public chainlinkFeed;
    uint256 public startTime;
    uint256 public endTime;
    address public refundee;
    IUniswapV3Staker.IncentiveKey public incentiveKey;

    //end of reward period
    uint256 public expiry;

    event NFT_LOCKED(uint256 tokenId, address indexed owner);
    event SimpleShift(uint256 amount, address indexed recipient, uint256 output);

    /// @notice Represents the deposit of an NFT
    struct Deposit {
        address owner;
        uint128 liquidity;
        address token0;
        address token1;
    }

    /// @dev deposits[tokenId] => Deposit
    mapping(uint256 => Deposit) public deposits;

    constructor(
        address _XFT,
        address _aUSD,
        address _WETH,
        IUniswapV3Pool _xftPool,
        IUniswapV3Pool _tokenPool,
        INonfungiblePositionManager _nonfungiblePositionManager,
        IOracle _oracle,
        IUniswapV3Staker _uniswapV3Staker,
        address _chainlinkFeed,
        uint256 _startTime,
        uint256 _endTime,
        address _refundee
    ) {
        XFT = XFTMock(_XFT);
        aUSD = anonUSD(_aUSD);
        WETH = IWETH9(_WETH);
        xftPool = _xftPool;
        tokenPool = _tokenPool;
        nonfungiblePositionManager = _nonfungiblePositionManager;
        uniswapV3Staker = _uniswapV3Staker;
        expiry = block.number + 21600; //Appx. 3 days from deployment
        oracle = _oracle;
        chainlinkFeed = AggregatorV2V3Interface(_chainlinkFeed);
        incentiveKey = IUniswapV3Staker.IncentiveKey({
            rewardToken:  IERC20Minimal(_XFT),
            pool: tokenPool,
            startTime: _startTime,
            endTime: _endTime,
            refundee: _refundee
        });
    }

    function incentiveId() public view returns (bytes32) {
        return IncentiveId.compute(incentiveKey);
    }

    // Simple shift XFT to anonUSD (limited time only)
    function _simpleShift(uint256 _amount) internal {
        require(block.number < expiry, "Simple shift launch period has ended");
        uint256 input = oracle.getCost(_amount, address(chainlinkFeed), address(xftPool));
        require(XFT.balanceOf(msg.sender) >= input, "Insufficient balance");
        XFT.burn(msg.sender, input);
        aUSD.mint(address(this), _amount);
        emit SimpleShift(input, msg.sender, _amount);
    }

    function _createDeposit(uint256 _tokenId, address _owner) internal {
        (, , address t_0, address t_1, , , , uint128 liquidity, , , , ) = nonfungiblePositionManager.positions(_tokenId);

        // set the owner and data for position
        // operator is msg.sender
        // Deposit NFT with _tokenId to UniswapV3Staker
        nonfungiblePositionManager.safeTransferFrom(address(this), address(uniswapV3Staker), _tokenId, "");
        uniswapV3Staker.stakeToken(incentiveKey, _tokenId);
        deposits[_tokenId] = Deposit({ owner: _owner, liquidity: liquidity, token0: t_0, token1: t_1 });
    }

    //Helper function to filter invalid Chainlink feeds ie 0 timestamp, invalid round IDs
    function chainlinkPrice() public view returns (uint256) {
        (uint80 roundID, int256 price, , uint256 timeStamp, uint80 answeredInRound) = chainlinkFeed.latestRoundData();
        require(answeredInRound >= roundID, "Answer given before round");
        require(timeStamp != 0, "Invalid timestamp");
        require(price > 0, "Price must be greater than 0");
        return uint256(price);
    }

    // Get approximate amount of ETH for given _amount in anonUSD
    function getETHAmount(uint256 _amount) public view returns (uint256 ethAmount) {
        uint8 decimals = chainlinkFeed.decimals();
        return FullMath.mulDivRoundingUp(_amount, 10**decimals, chainlinkPrice());
    }

    function shift(
        uint256 _amount
    )
        public
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        require(msg.value >= getETHAmount(_amount), "Insufficient ETH provided");
        uint256 etherAmount = msg.value;
        _simpleShift(_amount);
        // Approve the position manager
        aUSD.approve(address(nonfungiblePositionManager), _amount);
        //wrap the ether into WETH to make the process more flexible
        WETH.deposit{ value: etherAmount }();
        WETH.approve(address(nonfungiblePositionManager), etherAmount);

        uint256 amount0Desired;
        uint256 amount1Desired;

        if (tokenPool.token0() == address(WETH)) {
            amount0Desired = etherAmount;
            amount1Desired = _amount;
        } else {
            amount0Desired = _amount;
            amount1Desired = etherAmount;
        }

        // The values for tickLower and tickUpper may not work for all tick spacings.
        // Setting amount0Min and amount1Min to 0 is unsafe.
        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: tokenPool.token0(),
            token1: tokenPool.token1(),
            fee: tokenPool.fee(),
            tickLower: TickMath.MIN_TICK - (TickMath.MIN_TICK % tokenPool.tickSpacing()),
            tickUpper: TickMath.MAX_TICK - (TickMath.MAX_TICK % tokenPool.tickSpacing()),
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: amount0Desired * 9 / 10, //90% of desired amount
            amount1Min: amount1Desired * 9 / 10, //90% of desired amount
            recipient: address(this),
            deadline: block.timestamp + 300 //Five minutes from "now"
        });

        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(params);
        _createDeposit(tokenId, msg.sender);

        // Remove allowance and refund in both assets.
        if (tokenPool.token0() == address(WETH)) {
            if (amount0 < etherAmount) {
                WETH.approve(address(nonfungiblePositionManager), 0);
                uint256 refund0 = etherAmount - amount0;
                WETH.transfer(msg.sender, refund0);
            }

            if (amount1 < _amount) {
                aUSD.approve(address(nonfungiblePositionManager), 0);
                uint256 refund1 = _amount - amount1;
                aUSD.transfer(msg.sender, refund1);
            }
        } else {
            if (amount0 < _amount) {
                aUSD.approve(address(nonfungiblePositionManager), 0);
                uint256 refund0 = _amount - amount0;
                aUSD.transfer(msg.sender, refund0);
            }

            if (amount1 < etherAmount) {
                WETH.approve(address(nonfungiblePositionManager), 0);
                uint256 refund1 = etherAmount - amount1;
                WETH.transfer(msg.sender, refund1);
            }
        }
        emit NFT_LOCKED(tokenId, msg.sender);
    }

    function withdraw(uint256 tokenId) public virtual{
        require(block.number >= expiry, "Your token is still locked");
        Deposit memory deposit = deposits[tokenId];
        require(deposit.owner == msg.sender, "Not your token.");
        //retreive the accumulated reward amount
        (uint256 reward, ) = uniswapV3Staker.getRewardInfo(incentiveKey, tokenId);
        //unstake the token and calculate the rewards
        uniswapV3Staker.unstakeToken(incentiveKey, tokenId);
        //send the token to the beneficiary
        uniswapV3Staker.withdrawToken(tokenId, msg.sender, "");
        //send the rewards
        uniswapV3Staker.claimReward(IERC20Minimal(address(XFT)), msg.sender, reward);
        delete deposits[tokenId];
    }

    //force withdraw un-withdrawan tokens
    function ForceWithdraw(uint256 len, uint256[] memory ids) public onlyOwner virtual{
        require(block.number >= expiry, "Tokens are still locked");
        for (uint256 i = 0; i < len; i++) {
            uint256 tokenId = ids[i];
            Deposit memory deposit = deposits[tokenId];
            //retreive the accumulated reward amount
            (uint256 reward, ) = uniswapV3Staker.getRewardInfo(incentiveKey, tokenId);
            //unstake the token and calculate the rewards
            uniswapV3Staker.unstakeToken(incentiveKey, tokenId);
            //send the token to the beneficiary
            uniswapV3Staker.withdrawToken(tokenId, deposit.owner, "");
            //send the rewards
            uniswapV3Staker.claimReward(IERC20Minimal(address(XFT)), deposit.owner, reward);
            delete deposits[tokenId];
        }
    }


    // Implementing `onERC721Received` so this contract can receive custody of erc721 tokens
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}