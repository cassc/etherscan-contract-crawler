/**
 *Submitted for verification at Etherscan.io on 2022-10-25
*/

// File: .deps/BalancerTripod.sol


pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;





// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

interface IBalancerVault {
    enum PoolSpecialization {GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN}
    enum JoinKind {INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT, ALL_TOKENS_IN_FOR_EXACT_BPT_OUT}
    enum ExitKind {EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, EXACT_BPT_IN_FOR_TOKENS_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT}
    enum SwapKind {GIVEN_IN, GIVEN_OUT}

    /**
     * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }
    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    // enconding formats https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/balancer-js/src/pool-weighted/encoder.ts
    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest calldata request
    ) external;

    function getPool(bytes32 poolId) external view returns (address poolAddress, PoolSpecialization);

    function getPoolTokenInfo(bytes32 poolId, IERC20 token) external view returns (
        uint256 cash,
        uint256 managed,
        uint256 lastChangeBlock,
        address assetManager
    );

    function getPoolTokens(bytes32 poolId) external view returns (
        IERC20[] calldata tokens,
        uint256[] calldata balances,
        uint256 lastChangeBlock
    );
    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external returns (uint256 amountCalculated);

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    function queryBatchSwap(
        SwapKind kind, 
        BatchSwapStep[] memory swaps, 
        IAsset[] memory assets, 
        FundManagement memory funds
    ) external view returns (int256[] memory assetDeltas);
}






interface IBalancerPool is IERC20 {
    enum SwapKind {GIVEN_IN, GIVEN_OUT}

    struct SwapRequest {
        SwapKind kind;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amount;
        // Misc data
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }

    // virtual price of bpt
    function getRate() external view returns (uint);

    function getPoolId() external view returns (bytes32 poolId);

    function symbol() external view returns (string memory s);

    function getMainToken() external view returns(address);

    function onSwap(
        SwapRequest memory swapRequest,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut
    ) external view returns (uint256 amount);
}




interface ICurveFi {

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy_underlying(
        int128 _fromIndex, 
        int128 _toIndex, 
        uint256 _from_amount
    ) external view returns (uint256);

    function balances(int128) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function coins(uint256) external view returns (address);

}





interface IFeedRegistry {
    function getFeed(address, address) external view returns (address);
    function latestRoundData(address, address) external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}






interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}







interface ITripod{
    function pool() external view returns(address);
    function tokenA() external view returns (address);
    function balanceOfA() external view returns(uint256);
    function tokenB() external view returns (address);
    function balanceOfB() external view returns(uint256);
    function tokenC() external view returns (address);
    function balanceOfC() external view returns(uint256);
    function invested(address) external view returns(uint256);
    function totalLpBalance() external view returns(uint256);
    function investedWeight(address)external view returns(uint256);
    function quote(address, address, uint256) external view returns(uint256);
    function usingReference() external view returns(bool);
    function referenceToken() external view returns(address);
    function balanceOfTokensInLP() external view returns(uint256, uint256, uint256);
    function getRewardTokens() external view returns(address[] memory);
    function pendingRewards() external view returns(uint256[] memory);
}

interface IBalancerTripod is ITripod{
    //Struct for each bb pool that makes up the main pool
    struct PoolInfo {
        address token;
        address bbPool;
        bytes32 poolId;
    }
    function poolInfo(uint256) external view returns(PoolInfo memory);
    function curveIndex(address) external view returns(int128);
    function poolId() external view returns(bytes32);
    function toSwapToIndex() external view returns(uint256); 
    function toSwapToPoolId() external view returns(bytes32);
}

library BalancerHelper {

    //The main Balancer vault
    IBalancerVault internal constant balancerVault = 
        IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    ICurveFi internal constant curvePool =
        ICurveFi(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    address internal constant balToken =
        0xba100000625a3754423978a60c9317c58a424e3D;
    uint256 internal constant RATIO_PRECISION = 1e18;

    /*
    * @notice
    *   This will return the expected balance of each token based on our lp balance
    *       This will not take into account the invested weight so it can be used to determine how in
            or out balance the pool currently is
    */
    function balanceOfTokensInLP()
        public
        view
        returns (uint256 _balanceA, uint256 _balanceB, uint256 _balanceC) 
    {
        IBalancerTripod tripod = IBalancerTripod(address(this));
        uint256 lpBalance = tripod.totalLpBalance();
     
        if(lpBalance == 0) return (0, 0, 0);

        //Get the total tokens in the lp and the relative portion for each provider token
        uint256 total;
        (IERC20[] memory tokens, uint256[] memory balances, ) = balancerVault.getPoolTokens(tripod.poolId());
        for(uint256 i; i < tokens.length; ++i) {
            address token = address(tokens[i]);
   
            if(token == tripod.pool()) continue;
            uint256 balance = balances[i];
     
            if(token == tripod.poolInfo(0).bbPool) {
                _balanceA = balance;
            } else if(token == tripod.poolInfo(1).bbPool) {
                _balanceB = balance;
            } else if(token == tripod.poolInfo(2).bbPool){
                _balanceC = balance;
            }

            total += balance;
        }

        unchecked {
            uint256 lpDollarValue = lpBalance * IBalancerPool(tripod.pool()).getRate() / 1e18;

            //Adjust for decimals and pool balance
            _balanceA = (lpDollarValue * _balanceA) / (total * (10 ** (18 - IERC20Extended(tripod.tokenA()).decimals())));
            _balanceB = (lpDollarValue * _balanceB) / (total * (10 ** (18 - IERC20Extended(tripod.tokenB()).decimals())));
            _balanceC = (lpDollarValue * _balanceC) / (total * (10 ** (18 - IERC20Extended(tripod.tokenC()).decimals())));
        }
    }

    function quote(
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountIn
    ) public view returns(uint256 amountOut) {
        if(_amountIn == 0) {
            return 0;
        }

        IBalancerTripod tripod = IBalancerTripod(address(this));

        require(_tokenTo == tripod.tokenA() || 
                    _tokenTo == tripod.tokenB() || 
                        _tokenTo == tripod.tokenC()); 

        if(_tokenFrom == balToken) {
            (, int256 balPrice,,,) = IFeedRegistry(0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf).latestRoundData(
                balToken,
                address(0x0000000000000000000000000000000000000348) // USD
            );

            //Get the latest oracle price for bal * amount of bal / (1e8 + (diff of token decimals to bal decimals)) to adjust oracle price that is 1e8
            amountOut = uint256(balPrice) * _amountIn / (10 ** (8 + (18 - IERC20Extended(_tokenTo).decimals())));
        } else if(_tokenFrom == tripod.tokenA() || _tokenFrom == tripod.tokenB() || _tokenFrom == tripod.tokenC()){

            // Call the quote function in CRV 3pool
            amountOut = curvePool.get_dy(
                tripod.curveIndex(_tokenFrom), 
                tripod.curveIndex(_tokenTo), 
                _amountIn
            );
        } else {
            amountOut = 0;
        }
    }

    function getCreateLPVariables()public view returns(IBalancerVault.BatchSwapStep[] memory swaps, IAsset[] memory assets, int[] memory limits) {
        IBalancerTripod tripod = IBalancerTripod(address(this));
        swaps = new IBalancerVault.BatchSwapStep[](6);
        assets = new IAsset[](7);
        limits = new int[](7);
        bytes32 poolId = tripod.poolId();

        //Need two trades for each provider token to create the LP
        //Each trade goes token -> bb-token -> mainPool
        IBalancerTripod.PoolInfo memory _poolInfo;
        for (uint256 i; i < 3; ++i) {
            _poolInfo = tripod.poolInfo(i);
            address token = _poolInfo.token;
            uint256 balance = IERC20(token).balanceOf(address(this));
            //Used to offset the array to the correct index
            uint256 j = i * 2;
            //Swap fromt token -> bb-token
            swaps[j] = IBalancerVault.BatchSwapStep(
                _poolInfo.poolId,
                j,  //index for token
                j + 1,  //index for bb-token
                balance,
                abi.encode(0)
            );

            //swap from bb-token -> main pool
            swaps[j+1] = IBalancerVault.BatchSwapStep(
                poolId,
                j + 1,  //index for bb-token
                6,  //index for main pool
                0,
                abi.encode(0)
            );

            //Match the index used with the correct address and balance
            assets[j] = IAsset(token);
            assets[j+1] = IAsset(_poolInfo.bbPool);
            limits[j] = int(balance);
        }
        //Set the main lp token as the last in the array
        assets[6] = IAsset(tripod.pool());
    }

    function getBurnLPVariables(
        uint256 _amount
    ) public view returns(IBalancerVault.BatchSwapStep[] memory swaps, IAsset[] memory assets, int[] memory limits) {
        IBalancerTripod tripod = IBalancerTripod(address(this));
        swaps = new IBalancerVault.BatchSwapStep[](6);
        assets = new IAsset[](7);
        limits = new int[](7);
        //Burn a third for each token
        uint256 burnt;
        bytes32 poolId = tripod.poolId();

        //Need seperate swaps for each provider token
        //Each swap goes mainPool -> bb-token -> token
        IBalancerTripod.PoolInfo memory _poolInfo;
        for (uint256 i; i < 3; ++i) {
            _poolInfo = tripod.poolInfo(i);
            uint256 weightedToBurn = _amount * tripod.investedWeight(_poolInfo.token) / RATIO_PRECISION;
            uint256 j = i * 2;
            //Swap from main pool -> bb-token
            swaps[j] = IBalancerVault.BatchSwapStep(
                poolId,
                6,  //Index used for main pool
                j,  //Index for bb-token pool
                i == 2 ? _amount - burnt : weightedToBurn, //To make sure we burn all of the LP
                abi.encode(0)
            );

            //swap from bb-token -> token
            swaps[j+1] = IBalancerVault.BatchSwapStep(
                _poolInfo.poolId,
                j,  //Index used for bb-token pool
                j + 1,  //Index used for token
                0,
                abi.encode(0)
            );

            //adjust the already burnt LP amount
            burnt += weightedToBurn;
            //Match the index used with the applicable address
            assets[j] = IAsset(_poolInfo.bbPool);
            assets[j+1] = IAsset(_poolInfo.token);
        }
        //Set the lp token as asset 6
        assets[6] = IAsset(tripod.pool());
        limits[6] = int(_amount);
    }


    function getRewardVariables(
        uint256 balBalance, 
        uint256 auraBalance
    ) public view returns (IBalancerVault.BatchSwapStep[] memory _swaps, IAsset[] memory assets, int[] memory limits) {
        IBalancerTripod tripod = IBalancerTripod(address(this));
        _swaps = new IBalancerVault.BatchSwapStep[](4);
        assets = new IAsset[](4);
        limits = new int[](4);
        
        bytes32 toSwapToPoolId = tripod.toSwapToPoolId();
        _swaps[0] = IBalancerVault.BatchSwapStep(
            0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014, //bal-eth pool id
            0,  //Index to use for Bal
            2,  //index to use for Weth
            balBalance,
            abi.encode(0)
        );
        
        //Sell WETH -> toSwapTo token set
        _swaps[1] = IBalancerVault.BatchSwapStep(
            toSwapToPoolId,
            2,  //index to use for Weth
            3,  //Index to use for toSwapTo
            0,
            abi.encode(0)
        );

        //Sell Aura -> Weth
        _swaps[2] = IBalancerVault.BatchSwapStep(
            0xc29562b045d80fd77c69bec09541f5c16fe20d9d000200000000000000000251, //aura eth pool id
            1,  //Index to use for Aura
            2,  //index to use for Weth
            auraBalance,
            abi.encode(0)
        );

        //Sell WETH -> toSwapTo
        _swaps[3] = IBalancerVault.BatchSwapStep(
            toSwapToPoolId,
            2,  //index to use for Weth
            3,  //index to use for toSwapTo
            0,
            abi.encode(0)
        );

        assets[0] = IAsset(0xba100000625a3754423978a60c9317c58a424e3D); //bal token
        assets[1] = IAsset(0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF); //Aura token
        assets[2] = IAsset(tripod.referenceToken()); //weth
        assets[3] = IAsset(tripod.poolInfo(tripod.toSwapToIndex()).token); //to Swap to token

        limits[0] = int(balBalance);
        limits[1] = int(auraBalance);
    }

    function getTendVariables(
        IBalancerTripod.PoolInfo memory _poolInfo,
        uint256 balance
    ) public view returns(IBalancerVault.BatchSwapStep[] memory swaps, IAsset[] memory assets, int[] memory limits) {
        IBalancerTripod tripod = IBalancerTripod(address(this));
        swaps = new IBalancerVault.BatchSwapStep[](2);
        assets = new IAsset[](3);
        limits = new int[](3);

        swaps[0] = IBalancerVault.BatchSwapStep(
            _poolInfo.poolId,
            0,  //Index to use for toSwapTo
            1,  //Index to use for bb-toSwapTo
            balance,
            abi.encode(0)
        );

        swaps[1] = IBalancerVault.BatchSwapStep(
            tripod.poolId(),
            1,  //Index to use for bb-toSwapTo
            2,  //Index to use for the main lp token
            0, 
            abi.encode(0)
        );

        assets[0] = IAsset(_poolInfo.token);
        assets[1] = IAsset(_poolInfo.bbPool);
        assets[2] = IAsset(tripod.pool());

        //Only need to set the toSwapTo balance goin in
        limits[0] = int(balance);
    }

}