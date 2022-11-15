// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

// Uncomment if needed.
// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "../multicall.sol";
import "../libraries/Math.sol";

import "../base/Base.sol";


/// @title iZiSwap Liquidity Mining Main Contract
contract FixRange is Base, IERC721Receiver {
    using Math for int24;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    /// @dev Contract of the uniV3 Nonfungible Position Manager.
    address iZiSwapLiquidityManager;

    /// @dev The reward range of this mining contract.
    int24 rewardUpperTick;
    int24 rewardLowerTick;

    /// @dev Record the status for a certain token for the last touched time.
    struct TokenStatus {
        uint256 vLiquidity;
        uint256 validVLiquidity;
        uint256 nIZI;
        uint256 lastTouchBlock;
        uint256 lastRemainTokenX;
        uint256 lastRemainTokenY;
        uint256[] lastTouchAccRewardPerShare;
    }

    mapping(uint256 => TokenStatus) public tokenStatus;

    function tokenStatusLastTouchAccRewardPerShare(uint256 tokenId) public view returns(uint256[] memory lastTouchAccRewardPerShare) {
        if (rewardInfosLen > 0) {
            lastTouchAccRewardPerShare = new uint256[](rewardInfosLen);
            TokenStatus memory ts = tokenStatus[tokenId];
            for (uint256 i = 0; i < rewardInfosLen; i ++) {
                lastTouchAccRewardPerShare[i] = ts.lastTouchAccRewardPerShare[i];
            }
        }
    }

    // override for mining base
    function getBaseTokenStatus(uint256 tokenId) internal override view returns(BaseTokenStatus memory t) {
        TokenStatus memory ts = tokenStatus[tokenId];
        t = BaseTokenStatus({
            vLiquidity: ts.vLiquidity,
            validVLiquidity: ts.validVLiquidity,
            nIZI: ts.nIZI,
            lastTouchAccRewardPerShare: ts.lastTouchAccRewardPerShare
        });
    }
    struct PoolParams {
        address iZiSwapLiquidityManager;
        address tokenX;
        address tokenY;
        uint24 fee;
    }

    receive() external payable {}

    constructor(
        PoolParams memory poolParams,
        RewardInfo[] memory _rewardInfos,
        address iziTokenAddr,
        int24 _rewardUpperTick,
        int24 _rewardLowerTick,
        uint256 _startBlock,
        uint256 _endBlock,
        uint24 _feeChargePercent,
        address _chargeReceiver
    ) Base (_feeChargePercent, poolParams.iZiSwapLiquidityManager, poolParams.tokenX, poolParams.tokenY, poolParams.fee, _chargeReceiver, "FixRange") {
        iZiSwapLiquidityManager = poolParams.iZiSwapLiquidityManager;

        require(_rewardLowerTick < _rewardUpperTick, "L<U");
        require(poolParams.tokenX < poolParams.tokenY, "TOKEN0 < TOKEN1 NOT MATCH");

        rewardInfosLen = _rewardInfos.length;
        require(rewardInfosLen > 0, "NO REWARD");
        require(rewardInfosLen < 3, "AT MOST 2 REWARDS");

        for (uint256 i = 0; i < rewardInfosLen; i++) {
            rewardInfos[i] = _rewardInfos[i];
            rewardInfos[i].accRewardPerShare = 0;
        }

        // iziTokenAddr == 0 means not boost
        iziToken = IERC20(iziTokenAddr);

        rewardUpperTick = _rewardUpperTick;
        rewardLowerTick = _rewardLowerTick;

        startBlock = _startBlock;
        endBlock = _endBlock;

        lastTouchBlock = startBlock;

        totalVLiquidity = 0;
        totalNIZI = 0;

    }

    /// @notice Used for ERC721 safeTransferFrom
    function onERC721Received(address, address, uint256, bytes memory) 
        public 
        virtual 
        override 
        returns (bytes4) 
    {
        return this.onERC721Received.selector;
    }

    /// @notice Get the overall info for the mining contract.
    function getMiningContractInfo()
        external
        view
        returns (
            address tokenX_,
            address tokenY_,
            uint24 fee_,
            RewardInfo[] memory rewardInfos_,
            address iziTokenAddr_,
            int24 rewardUpperTick_,
            int24 rewardLowerTick_,
            uint256 lastTouchBlock_,
            uint256 totalVLiquidity_,
            uint256 startBlock_,
            uint256 endBlock_
        )
    {
        rewardInfos_ = new RewardInfo[](rewardInfosLen);
        for (uint256 i = 0; i < rewardInfosLen; i++) {
            rewardInfos_[i] = rewardInfos[i];
        }
        return (
            rewardPool.tokenX,
            rewardPool.tokenY,
            rewardPool.fee,
            rewardInfos_,
            address(iziToken),
            rewardUpperTick,
            rewardLowerTick,
            lastTouchBlock,
            totalVLiquidity,
            startBlock,
            endBlock
        );
    }

    /// @notice Compute the virtual liquidity from a liquidity's parameters.
    /// @param tickLower The lower tick of a liquidity.
    /// @param tickUpper The upper tick of a liquidity.
    /// @param liquidity The liquidity of a a liquidity.
    /// @dev vLiquidity = liquidity * validRange^2 / 1e6, where the validRange is the tick amount of the
    /// intersection between the liquidity and the reward range.
    /// We divided it by 1e6 to keep vLiquidity smaller than Q128 in most cases. This is safe since liqudity is usually a large number.
    function _getVLiquidityForNFT(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) internal view returns (uint256 vLiquidity) {
        // liquidity is roughly equals to sqrt(amountX*amountY)
        require(liquidity >= 1e6, "LIQUIDITY TOO SMALL");
        uint256 validRange = uint24(
            Math.max(
                Math.min(rewardUpperTick, tickUpper) - Math.max(rewardLowerTick, tickLower),
                0
            )
        );
        vLiquidity = (validRange * validRange * uint256(liquidity)) / 1e6;
        return vLiquidity;
    }

    /// @notice new a token status when touched.
    function _newTokenStatus(
        uint256 tokenId,
        uint256 vLiquidity,
        uint256 validVLiquidity,
        uint256 nIZI,
        uint256 lastRemainTokenX,
        uint256 lastRemainTokenY
    ) internal {
        TokenStatus storage t = tokenStatus[tokenId];

        t.vLiquidity = vLiquidity;
        t.validVLiquidity = validVLiquidity;
        t.nIZI = nIZI;

        t.lastTouchBlock = lastTouchBlock;
        t.lastTouchAccRewardPerShare = new uint256[](rewardInfosLen);
        t.lastRemainTokenX = lastRemainTokenX;
        t.lastRemainTokenY = lastRemainTokenY;
        for (uint256 i = 0; i < rewardInfosLen; i++) {
            t.lastTouchAccRewardPerShare[i] = rewardInfos[i].accRewardPerShare;
        }
    }

    /// @notice update a token status when touched
    function _updateTokenStatus(
        uint256 tokenId,
        uint256 validVLiquidity,
        uint256 nIZI
    ) internal override {
        TokenStatus storage t = tokenStatus[tokenId];

        // when not boost, validVL == vL
        t.validVLiquidity = validVLiquidity;
        t.nIZI = nIZI;

        t.lastTouchBlock = lastTouchBlock;
        for (uint256 i = 0; i < rewardInfosLen; i++) {
            t.lastTouchAccRewardPerShare[i] = rewardInfos[i].accRewardPerShare;
        }
    }

    function _computeValidVLiquidity(uint256 vLiquidity, uint256 nIZI)
        internal override
        view
        returns (uint256)
    {
        if (totalNIZI == 0) {
            return vLiquidity;
        }
        uint256 iziVLiquidity = (vLiquidity * 4 + (totalVLiquidity * nIZI * 6) / totalNIZI) / 10;
        return Math.min(iziVLiquidity, vLiquidity);
    }

    /// @notice Deposit a single liquidity.
    /// @param tokenId The related liquidity id.
    /// @param nIZI the amount of izi to lock
    function deposit(uint256 tokenId, uint256 nIZI)
        external
        returns (uint256 vLiquidity)
    {
        address owner = IiZiSwapLiquidityManager(iZiSwapLiquidityManager).ownerOf(tokenId);
        require(owner == msg.sender, "NOT OWNER");
        IiZiSwapLiquidityManager.Liquidity memory liquidity;

        (
            liquidity.leftPt,
            liquidity.rightPt,
            liquidity.liquidity,
            liquidity.lastFeeScaleX_128,
            liquidity.lastFeeScaleY_128,
            liquidity.remainTokenX,
            liquidity.remainTokenY,
            liquidity.poolId
        ) = IiZiSwapLiquidityManager(iZiSwapLiquidityManager).liquidities(tokenId);

        IiZiSwapLiquidityManager.PoolMeta memory poolMeta;

        (
            poolMeta.tokenX,
            poolMeta.tokenY,
            poolMeta.fee
        ) = IiZiSwapLiquidityManager(iZiSwapLiquidityManager).poolMetas(liquidity.poolId);

        // alternatively we can compute the pool address with tokens and fee and compare the address directly
        require(poolMeta.tokenX == rewardPool.tokenX, "TOEKN0 NOT MATCH");
        require(poolMeta.tokenY == rewardPool.tokenY, "TOKEN1 NOT MATCH");
        require(poolMeta.fee == rewardPool.fee, "FEE NOT MATCH");

        // require the NFT token has interaction with [rewardLowerTick, rewardUpperTick]
        vLiquidity = _getVLiquidityForNFT(liquidity.leftPt, liquidity.rightPt, liquidity.liquidity);
        require(vLiquidity > 0, "INVALID TOKEN");

        IiZiSwapLiquidityManager(iZiSwapLiquidityManager).safeTransferFrom(msg.sender, address(this), tokenId);
        owners[tokenId] = msg.sender;
        bool res = tokenIds[msg.sender].add(tokenId);
        require(res);

        // the execution order for the next three lines is crutial
        _updateGlobalStatus();
        _updateVLiquidity(vLiquidity, true);
        if (address(iziToken) == address(0)) {
            // boost is not enabled
            nIZI = 0;
        }
        _updateNIZI(nIZI, true);
        uint256 validVLiquidity = _computeValidVLiquidity(vLiquidity, nIZI);
        require(nIZI < FixedPoints.Q128 / 6, "NIZI O");
        _newTokenStatus(tokenId, vLiquidity, validVLiquidity, nIZI, uint256(liquidity.remainTokenX), uint256(liquidity.remainTokenY));
        if (nIZI > 0) {
            // lock izi in this contract
            iziToken.safeTransferFrom(msg.sender, address(this), nIZI);
        }

        emit Deposit(msg.sender, tokenId, nIZI);
        return vLiquidity;
    }

    /// @notice withdraw a single liquidity.
    /// @param tokenId The related liquidity id.
    /// @param noReward true if donot collect reward
    function withdraw(uint256 tokenId, bool noReward) external nonReentrant {
        require(owners[tokenId] == msg.sender, "NOT OWNER OR NOT EXIST");

        if (noReward) {
            _updateGlobalStatus();
        } else {
            _collectReward(tokenId);
        }
        uint256 vLiquidity = tokenStatus[tokenId].vLiquidity;
        _updateVLiquidity(vLiquidity, false);
        uint256 nIZI = tokenStatus[tokenId].nIZI;
        if (nIZI > 0) {
            _updateNIZI(nIZI, false);
            // refund iZi to user
            iziToken.safeTransfer(msg.sender, nIZI);
        }

        // charge and refund remain fee to user

        uint256 amountX;
        uint256 amountY;

        try
            IiZiSwapLiquidityManager(
                iZiSwapLiquidityManager
            ).collect(
                address(this),
                tokenId,
                type(uint128).max,
                type(uint128).max
            ) returns(uint256 ax, uint256 ay)
        {
            amountX = ax;
            amountY = ay;
        } catch (bytes memory) {
            // if revert, 
            amountX = 0;
            amountY = 0;
        }

        uint256 lastRemainTokenX = Math.min(tokenStatus[tokenId].lastRemainTokenX, amountX);
        uint256 lastRemainTokenY = Math.min(tokenStatus[tokenId].lastRemainTokenY, amountY);

        uint256 refundAmountX = lastRemainTokenX + (amountX - lastRemainTokenX) * feeRemainPercent / 100;
        uint256 refundAmountY = lastRemainTokenY + (amountY - lastRemainTokenY) * feeRemainPercent / 100;
        _safeTransferToken(rewardPool.tokenX, msg.sender, refundAmountX);
        _safeTransferToken(rewardPool.tokenY, msg.sender, refundAmountY);
        totalFeeChargedX += amountX - refundAmountX;
        totalFeeChargedY += amountY - refundAmountY;

        IiZiSwapLiquidityManager(iZiSwapLiquidityManager).safeTransferFrom(address(this), msg.sender, tokenId);
        owners[tokenId] = address(0);
        bool res = tokenIds[msg.sender].remove(tokenId);
        require(res);

        emit Withdraw(msg.sender, tokenId);
    }

    /// @notice Collect pending reward for a single liquidity.
    /// @param tokenId The related liquidity id.
    function collectReward(uint256 tokenId) external nonReentrant {
        require(owners[tokenId] == msg.sender, "NOT OWNER OR NOT EXIST");
        _collectReward(tokenId);
    }

    /// @notice Collect all pending rewards.
    function collectRewards() external nonReentrant {
        EnumerableSet.UintSet storage ids = tokenIds[msg.sender];
        for (uint256 i = 0; i < ids.length(); i++) {
            require(owners[ids.at(i)] == msg.sender, "NOT OWNER");
            _collectReward(ids.at(i));
        }
    }

    // Control fuctions for the contract owner and operators.

    /// @notice If something goes wrong, we can send back user's nft and locked iZi
    /// @param tokenId The related liquidity id.
    function emergenceWithdraw(uint256 tokenId) external override onlyOwner {
        address owner = owners[tokenId];
        require(owner != address(0));
        IiZiSwapLiquidityManager(iZiSwapLiquidityManager).safeTransferFrom(
            address(this),
            owners[tokenId],
            tokenId
        );
        uint256 nIZI = tokenStatus[tokenId].nIZI;
        if (nIZI > 0) {
            // we should ensure nft refund to user
            // omit the case when transfer() returns false unexpectedly
            iziToken.transfer(owner, nIZI);
        }
        // make sure user cannot withdraw/depositIZI or collect reward on this nft
        owners[tokenId] = address(0);
    }

}