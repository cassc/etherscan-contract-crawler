// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";
import "@uniswap/v3-periphery/contracts/libraries/PositionValue.sol";

import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

interface LPStakingEngine {
    function deposit(uint256 amount, address userAddr, address _referrer) external;
    function withdraw(uint256 amount, address userAddr)  external;
}
interface RevenueDistributor
{
    function distributeFee(uint256 _amount) external;
}
contract UniswapV3LP is IERC721Receiver, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint128;
    using PositionValue for INonfungiblePositionManager;

    INonfungiblePositionManager public immutable _posMgr;
    IUniswapV3Factory public immutable _univ3Factory;

    // @notice Represents the deposit of an NFT
    struct Deposit {
        address owner;
        uint128 liquidity;
        address token0;
        address token1;
    }

    // @dev deposits[tokenId] => Deposit
    mapping(uint256 => Deposit) public deposits;
    mapping(address => mapping(uint256 => uint256)) public balances;
    mapping(uint256 => address) public nftIdToStakingEngine;
    mapping(uint256 => uint256) public totalLPSupply;
    mapping(uint256 => uint256) public totalLPSupplyFromOwner;
    address public distributor;
    //posMgr 0xc36442b4a4522e871399cd717abdd847ab11fe88
    // v3 factory 0x1f98431c8ad98523631ae4a59f267346ea31f984
    constructor(address posMgr, address univ3Factory) {
        _posMgr = INonfungiblePositionManager(posMgr);
        _univ3Factory = IUniswapV3Factory(univ3Factory);
    }

    function updateDistributor(address _distributor) external onlyOwner
    {
        distributor = _distributor;
    }
    function updateStakingEngine(address stakingEngine, uint256 tokenId) external onlyOwner
    {
        nftIdToStakingEngine[tokenId] = stakingEngine;
    }

    // Implementing `onERC721Received` so this contract can receive custody of erc721 tokens
    // Note that the operator is recorded as the owner of the deposited NFT
    function onERC721Received(address operator, address, uint256 tokenId, bytes calldata)
        external
        override
        returns (bytes4)
    {
        require(msg.sender == address(_posMgr), "not a univ3 nft");
        _createDeposit(operator, tokenId);
        return this.onERC721Received.selector;
    }

    function _createDeposit(address owner, uint256 tokenId) internal {
        (,, address token0, address token1,,,, uint128 liquidity,,,,) = _posMgr.positions(tokenId);
        // set the owner and data for position
        deposits[tokenId] = Deposit({owner: owner, liquidity: liquidity, token0: token0, token1: token1});
    }

    function slippagify(uint256 amount, uint256 slippage) internal pure returns (uint256) {
        require(slippage >= 0 && slippage <= 1e5, "not in range");
        return amount.mul(1e5 - slippage).div(1e5);
    }

    /**
     * @notice Calls the mint function defined in periphery, mints the same amount of each token.
     *  For this example we are providing 1000 DAI and 1000 USDC in liquidity
     *  @param params The values for tickLower and tickUpper may not work for all tick spacings.
     *  Setting amount0Min and amount1Min to 0 is unsafe.
     *  @return tokenId The id of the newly minted ERC721
     *  @return liquidity The amount of liquidity for the position
     *  @return amount0 The amount of token0
     *  @return amount1 The amount of token1
     */
    function mintNewPosition(INonfungiblePositionManager.MintParams memory params, uint256 slippage)
        external
        onlyOwner //TODO remove onlyOwner?
        returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1)
    {
        // transfer tokens to contract
        TransferHelper.safeTransferFrom(params.token0, msg.sender, address(this), params.amount0Desired);
        TransferHelper.safeTransferFrom(params.token1, msg.sender, address(this), params.amount1Desired);

        // Approve the position manager
        TransferHelper.safeApprove(params.token0, address(_posMgr), params.amount0Desired);
        TransferHelper.safeApprove(params.token1, address(_posMgr), params.amount1Desired);

        // Note that the pool must already be created and initialized in order to mint
        params.amount0Min = slippagify(params.amount0Desired, slippage);
        params.amount1Min = slippagify(params.amount1Desired, slippage);

        (tokenId, liquidity, amount0, amount1) = _posMgr.mint(params);

        // Create a deposit
        _createDeposit(msg.sender, tokenId);
        //record lp token
        // Remove allowance and refund in both assets.
        if (amount0 < params.amount0Desired) {
            TransferHelper.safeApprove(params.token0, address(_posMgr), 0);
            uint256 refund0 = params.amount0Desired - amount0;
            TransferHelper.safeTransfer(params.token0, msg.sender, refund0);
        }

        if (amount1 < params.amount1Desired) {
            TransferHelper.safeApprove(params.token1, address(_posMgr), 0);
            uint256 refund1 = params.amount1Desired - amount1;
            TransferHelper.safeTransfer(params.token1, msg.sender, refund1);
        }
        balances[msg.sender][tokenId] = balances[msg.sender][tokenId].add(liquidity);
        totalLPSupply[tokenId] =  liquidity;
        if(msg.sender == owner())
        {
            totalLPSupplyFromOwner[tokenId] = liquidity;
        }
    }

    function rescuseNFT(uint256 tokenId, address to) external onlyOwner {
        _posMgr.safeTransferFrom(address(this), to, tokenId);
    }
    /**
     * @notice Collects the fees associated with provided liquidity
     * @dev The contract must hold the erc721 token before it can collect fees
     * @param tokenId The id of the erc721 token
     * @return amount0 The amount of fees collected in token0
     * @return amount1 The amount of fees collected in token1
     */
    function collectFees(uint256 tokenId) external returns (uint256 amount0, uint256 amount1) {
        // Caller must own the ERC721 position, meaning it must be a deposit
        // set amount0Max and amount1Max to type(uint128).max to collect all fees
        // alternatively can set recipient to msg.sender and avoid another transaction in `sendToOwner`
        INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams({
            tokenId: tokenId,
            recipient: address(this),
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        });

        (amount0, amount1) = _posMgr.collect(params);

        address token0 = deposits[tokenId].token0;
        address token1 = deposits[tokenId].token1;
        // send collected fees back to owner
        _sendToOwner(tokenId, IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)));
    }

    function balanceOf(address _user, uint256 tokenId) external view returns (uint256) {
        return balances[_user][tokenId];
    }
    function totalSupply(uint256 tokenId) external view returns (uint256) {
        return totalLPSupply[tokenId] - totalLPSupplyFromOwner[tokenId];
    }
    /**
     * @notice A function that decreases the current liquidity by half. An example to show how to call the `decreaseLiquidity` function defined in periphery.
     * @param tokenId The id of the erc721 token
     * @return amount0 The amount received back in token0
     * @return amount1 The amount returned back in token1
     */
    function decreaseLiquidity(uint256 tokenId, uint128 liquidity, uint256 slippage)
        external
        returns (uint256 amount0, uint256 amount1)
    {
        // caller must be the owner of the NFT
        require(balances[msg.sender][tokenId] >= liquidity, "balance too low");

        // amount0Min and amount1Min are price slippage checks
        // if the amount received after burning is not greater than these minimums, transaction will fail
        (uint256 amount0Min, uint256 amount1Min) = calcExpectedMin(tokenId, liquidity, slippage);
        INonfungiblePositionManager.DecreaseLiquidityParams memory params = INonfungiblePositionManager
            .DecreaseLiquidityParams({
            tokenId: tokenId,
            liquidity: liquidity,
            amount0Min: amount0Min,
            amount1Min: amount1Min,
            deadline: block.timestamp
        });

        INonfungiblePositionManager.CollectParams memory params2 = INonfungiblePositionManager.CollectParams({
            tokenId: tokenId,
            recipient: address(this),
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        });

        (amount0, amount1) = _posMgr.decreaseLiquidity(params);
        
        _posMgr.collect(params2);

        // send liquidity back to user
        _sendToUser(tokenId, msg.sender, amount0, amount1);

        //burn lp
        if(msg.sender == owner())
        {
            totalLPSupplyFromOwner[tokenId] = totalLPSupplyFromOwner[tokenId] - liquidity;
        }
        else
        {
            LPStakingEngine(nftIdToStakingEngine[tokenId]).withdraw(liquidity,msg.sender);
        }
        balances[msg.sender][tokenId] = balances[msg.sender][tokenId].sub(liquidity);
        totalLPSupply[tokenId] = totalLPSupply[tokenId] - liquidity;
    }

    function calcExpectedMin(uint256 tokenId, uint128 liquidity, uint256 slippage)
        internal
        view
        returns (uint256 amount0, uint256 amount1)
    {
        (,, address token0, address token1, uint24 fee,,,,,,,) = _posMgr.positions(tokenId);

        IUniswapV3Pool pool = IUniswapV3Pool(
            PoolAddress.computeAddress(
                _posMgr.factory(), PoolAddress.PoolKey({token0: token0, token1: token1, fee: fee})
            )
        );

        (uint160 sqrtRatioX96,,,,,,) = pool.slot0();
        (uint256 posValue0, uint256 posValue1) = _posMgr.total(tokenId, sqrtRatioX96); //Calls PositionValue::total() see https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/PositionValue.sol#L22

        amount0 = slippagify(posValue0.mul(liquidity).div(totalLPSupply[tokenId]), slippage);
        amount1 = slippagify(posValue1.mul(liquidity).div(totalLPSupply[tokenId]), slippage);
    }

    function withdrawReward(uint256 tokenId) external
    {
        LPStakingEngine(nftIdToStakingEngine[tokenId]).deposit(0, msg.sender, 0x0000000000000000000000000000000000000000);
    }

    /**
     * TODO test against https://arbiscan.io/tx/0xc4df8766ba80841f20210c067a27fa853567696495bc438b63001f9ef8c5ee64
     *
     * @notice Increases liquidity in the current range
     * @dev Pool must be initialized already to add liquidity
     * @param tokenId The id of the erc721 token
     * @param amount0 The amount to add of token0
     * @param amount1 The amount to add of token1
     */
    function increaseLiquidityCurrentRange(uint256 tokenId, uint256 amountAdd0, uint256 amountAdd1, uint256 slippage, address referrer)
        external
        returns (uint128 liquidity, uint256 amount0, uint256 amount1)
    {
        address token0 = deposits[tokenId].token0;
        address token1 = deposits[tokenId].token1;
        TransferHelper.safeTransferFrom(token0, msg.sender, address(this), amountAdd0);
        TransferHelper.safeTransferFrom(token1, msg.sender, address(this), amountAdd1);

        TransferHelper.safeApprove(token0, address(_posMgr), amountAdd0);
        TransferHelper.safeApprove(token1, address(_posMgr), amountAdd1);

        INonfungiblePositionManager.IncreaseLiquidityParams memory params = INonfungiblePositionManager
            .IncreaseLiquidityParams({
            tokenId: tokenId,
            amount0Desired: amountAdd0,
            amount1Desired: amountAdd1,
            amount0Min: slippagify(amountAdd0, slippage),
            amount1Min: slippagify(amountAdd1, slippage),
            deadline: block.timestamp
        });

        (liquidity, amount0, amount1) = _posMgr.increaseLiquidity(params);

        // Remove allowance and refund in both assets.
        if (amount0 < amountAdd0) {
            TransferHelper.safeApprove(token0, address(_posMgr), 0);
            uint256 refund0 = amountAdd0 - amount0;
            TransferHelper.safeTransfer(token0, msg.sender, refund0);
        }

        if (amount1 < amountAdd1) {
            TransferHelper.safeApprove(token1, address(_posMgr), 0);
            uint256 refund1 = amountAdd1 - amount1;
            TransferHelper.safeTransfer(token1, msg.sender, refund1);
        }
        //this is correct, because the distributor WILL add LP once aday
        if(msg.sender == distributor || msg.sender == owner())
        {
            totalLPSupplyFromOwner[tokenId] = totalLPSupplyFromOwner[tokenId] + liquidity;
            balances[owner()][tokenId] = balances[owner()][tokenId].add(liquidity);
        }
        else
        {
            LPStakingEngine(nftIdToStakingEngine[tokenId]).deposit(liquidity,msg.sender,referrer);
            balances[msg.sender][tokenId] = balances[msg.sender][tokenId].add(liquidity);
        }
        totalLPSupply[tokenId] = totalLPSupply[tokenId] + liquidity;

    }

    /**
     * @notice Transfers funds to owner of NFT
     * @param tokenId The id of the erc721
     * @param amount0 The amount of token0
     * @param amount1 The amount of token1
     */
    function _sendToOwner(uint256 tokenId, uint256 amount0, uint256 amount1) private {
        // get owner of contract
        address token0 = deposits[tokenId].token0;
        address token1 = deposits[tokenId].token1;
        // send collected fees to owner
        // TransferHelper.safeTransfer(token0, owner, amount0);
        // TransferHelper.safeTransfer(token1, owner, amount1);
        
        TransferHelper.safeTransfer(token0, distributor, amount0);
        TransferHelper.safeTransfer(token1, distributor, amount1);
    }
    /**
     * @notice Transfers funds to owner of lptokens
     * @param tokenId The id of the erc721
     * @param amount0 The amount of token0
     * @param amount1 The amount of token1
     */
    function _sendToUser(uint256 tokenId, address user, uint256 amount0, uint256 amount1) private {
        // get owner of contract
        address owner = deposits[tokenId].owner;

        address token0 = deposits[tokenId].token0;
        address token1 = deposits[tokenId].token1;
        // send back to users
        TransferHelper.safeTransfer(token0, user, amount0 * 997 / 1000);
        TransferHelper.safeTransfer(token1, user, amount1 * 997 / 1000);
        //0.3% fees collected when remove liquidity
        TransferHelper.safeTransfer(token0, owner, amount0 * 3 / 1000);
        TransferHelper.safeTransfer(token1, owner, amount1 * 3 / 1000);
    }
}