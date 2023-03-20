// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import "./interfaces/INonfungiblePositionManager.sol";
import "./libraries/Position.sol";

contract UniswapV3LiquidityLocker {
    using Position for Position.Info;

    mapping(uint256 => Position.Info) public lockedLiquidityPositions;

    INonfungiblePositionManager private _uniswapNFPositionManager;
    uint128 private constant MAX_UINT128 = type(uint128).max;

    event PositionUpdated(Position.Info position);
    event FeeClaimed(uint256 tokenId);
    event TokenUnlocked(uint256 tokenId);

    constructor() {
        _uniswapNFPositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    }

    function lockLPToken(Position.Info calldata params) external {
        _uniswapNFPositionManager.transferFrom(msg.sender, address(this), params.tokenId);

        params.isPositionValid();

        lockedLiquidityPositions[params.tokenId] = params;

        emit PositionUpdated(params);
    }

    function claimLPFee(uint256 tokenId) external returns (uint256 amount0, uint256 amount1) {
        Position.Info memory llPosition = lockedLiquidityPositions[tokenId];

        llPosition.isTokenIdValid(tokenId);
        llPosition.isFeeClaimAllowed();

        (amount0, amount1) = _uniswapNFPositionManager.collect(
            INonfungiblePositionManager.CollectParams(tokenId, llPosition.feeReciever, MAX_UINT128, MAX_UINT128)
        );

        emit FeeClaimed(tokenId);
    }

    function updateOwner(uint256 tokenId, address owner) external {
        Position.Info storage llPosition = lockedLiquidityPositions[tokenId];

        llPosition.isTokenIdValid(tokenId);
        llPosition.isOwner();

        llPosition.owner = owner;

        emit PositionUpdated(llPosition);
    }

    function updateFeeReciever(uint256 tokenId, address feeReciever) external {
        Position.Info storage llPosition = lockedLiquidityPositions[tokenId];

        llPosition.isTokenIdValid(tokenId);
        llPosition.isOwner();

        llPosition.feeReciever = feeReciever;

        emit PositionUpdated(llPosition);
    }

    function renounceBeneficiaryUpdate(uint256 tokenId) external {
        Position.Info storage llPosition = lockedLiquidityPositions[tokenId];

        llPosition.isTokenIdValid(tokenId);
        llPosition.isOwner();

        llPosition.allowBeneficiaryUpdate = false;

        emit PositionUpdated(llPosition);
    }

    function unlockToken(uint256 tokenId) external {
        Position.Info memory llPosition = lockedLiquidityPositions[tokenId];

        llPosition.isTokenIdValid(tokenId);
        llPosition.isTokenUnlocked();

        _uniswapNFPositionManager.transferFrom(address(this), llPosition.owner, tokenId);

        delete lockedLiquidityPositions[tokenId];

        emit TokenUnlocked(tokenId);
    }
}