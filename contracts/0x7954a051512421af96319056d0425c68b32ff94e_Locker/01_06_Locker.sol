// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';


interface IPoolInitializer {
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

interface IERC721Permit is IERC721 {
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

interface IPeripheryPayments {
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;
    function refundETH() external payable;
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

interface IPeripheryImmutableState {
    function factory() external view returns (address);
    function WETH9() external view returns (address);
}

interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    function burn(uint256 tokenId) external payable;
}


contract Locker is IERC721Receiver {

    bool private entered;

    INonfungiblePositionManager public immutable nonfungiblePositionManager;

    struct Deposit {
        address owner;
        uint256 unlockTime;
    }
    mapping(uint256 => Deposit) public deposits;

    event Deposited(address indexed sender, uint256 indexed tokenId, uint256 unlockTime);
    event Withdrawn(address indexed sender, uint256 indexed tokenId);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner, uint256 tokenId);

    modifier nonReentrant() {
        require(!entered, "REENTRANT");
        entered = true;
        _;
        entered = false;
    }

    // NFT: 0xC36442b4a4522E871399CD717aBDD847Ab11FE88
    constructor(
        INonfungiblePositionManager _nonfungiblePositionManager
    ) {
        nonfungiblePositionManager = _nonfungiblePositionManager;
    }

    function deposit(uint256 tokenId, uint256 unlockTime) external nonReentrant {
        require(unlockTime > block.timestamp, "Invalid unlock time");
        require(nonfungiblePositionManager.ownerOf(tokenId) == msg.sender, "Not Authorized");
        require(nonfungiblePositionManager.getApproved(tokenId) == address(this), "Not approved");
        nonfungiblePositionManager.safeTransferFrom(msg.sender, address(this), tokenId);
        deposits[tokenId].owner = msg.sender;
        deposits[tokenId].unlockTime = unlockTime;
        emit Deposited(msg.sender, tokenId, unlockTime);
    }

    function withdraw(uint256 tokenId) external nonReentrant {
        require(deposits[tokenId].unlockTime < block.timestamp, "Not allow");
        nonfungiblePositionManager.safeTransferFrom(address(this), deposits[tokenId].owner, tokenId);
        emit Withdrawn(deposits[tokenId].owner, tokenId);
        delete deposits[tokenId];
    }

    function collect(uint256 tokenId) external nonReentrant {
        INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams({
            tokenId: tokenId,
            recipient: deposits[tokenId].owner,
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        });
        nonfungiblePositionManager.collect(params);
    }

    function transferOwnership(uint256 tokenId, address newOwner) external nonReentrant {
        require(deposits[tokenId].owner == msg.sender, "Caller is not the owner");
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(deposits[tokenId].owner, newOwner, tokenId);
        deposits[tokenId].owner = newOwner;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}