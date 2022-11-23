// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../amm_pool/IStableSwapPool.sol";
import "../../interfaces/ISynthesis.sol";
import "../../interfaces/ICurveBalancer.sol";
import "../../interfaces/ITreasury.sol";
import "../../interfaces/IWhitelist.sol";

abstract contract CurveProxyCore {

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    address public portal;
    address public synthesis;
    address public bridge;
    address public whitelist;
    address public curveBalancer;
    address public treasury;

    mapping(address => EnumerableSetUpgradeable.AddressSet) internal pool;
    mapping(address => address) internal lpToken;

    struct TokenInput {
        address token;
        uint256 amount;
        uint256 coinIndex;
    }

    event InconsistencyCallback(address pool, address token, address to, uint256 amount);

    function registerNewBalance(address token, uint256 expectedAmount) internal view {
        require(
            IERC20Upgradeable(token).balanceOf(address(this)) >= expectedAmount,
            "CurveProxy: insufficient balance"
        );
    }

    function _addLiquidityCrosschainPool(
        address _add,
        TokenInput calldata tokenParams,
        bytes32 _txId,
        uint256 _expectedMin,
        address _to
    ) internal returns (bool) {
        uint256 size = pool[_add].length();
        address representation = ISynthesis(synthesis).getRepresentation(bytes32(uint256(uint160(tokenParams.token))));
        ISynthesis(synthesis).mintSyntheticToken(_txId, tokenParams.token, tokenParams.amount, address(this));
        IERC20Upgradeable(representation).approve(curveBalancer, tokenParams.amount);

        bool inconsistencyResult = _addLiquidityInconsistency(
            _add,
            _expectedMin,
            _to,
            tokenParams.coinIndex,
            tokenParams.amount,
            representation
        );

        bool result = ICurveBalancer(curveBalancer).addLiqBalancedOut(
            _add,
            size,
            tokenParams.coinIndex,
            tokenParams.amount
        );

        if(!result && !inconsistencyResult) {
            if(tokenParams.amount > IWhitelist(whitelist).stableFee()){
                uint256 amountToReturn = tokenParams.amount - IWhitelist(whitelist).stableFee();
                IERC20Upgradeable(representation).safeTransfer(treasury, IWhitelist(whitelist).stableFee());
                IERC20Upgradeable(representation).safeTransfer(_to, amountToReturn);
                ITreasury(treasury).withdrawNative(IWhitelist(whitelist).nativeReturnAmount(), _to);
                emit InconsistencyCallback(_add, representation, _to, amountToReturn);
            } else {
                IERC20Upgradeable(representation).safeTransfer(_to, tokenParams.amount);
                emit InconsistencyCallback(_add, representation, _to, tokenParams.amount);
            }
        }
    }

    function _addLiquidityCrosschainPoolLocal(
        address _add,
        ICurveProxy.TokenInput memory tokenParams,
        uint256 _expectedMin,
        address _to
    ) internal returns (bool) {
        uint256 size = pool[_add].length();
        IERC20Upgradeable(tokenParams.token).approve(curveBalancer, tokenParams.amount);
        registerNewBalance(tokenParams.token, tokenParams.amount);

        bool inconsistencyResult = _addLiquidityInconsistencyLocal(
            _add,
            _expectedMin,
            _to,
            tokenParams.token,
            tokenParams.amount,
            tokenParams.coinIndex
        );
        
        bool result =  ICurveBalancer(curveBalancer).addLiqBalancedOut(
            _add,
            size,
            tokenParams.coinIndex,
            tokenParams.amount
        );

        if(!result && !inconsistencyResult) {
            if(tokenParams.amount > IWhitelist(whitelist).stableFee()){
                uint256 amountToReturn = tokenParams.amount - IWhitelist(whitelist).stableFee();
                IERC20Upgradeable(tokenParams.token).safeTransfer(treasury, IWhitelist(whitelist).stableFee());
                IERC20Upgradeable(tokenParams.token).safeTransfer(_to, amountToReturn);
                ITreasury(treasury).withdrawNative(IWhitelist(whitelist).nativeReturnAmount(), _to);
                emit InconsistencyCallback(_add, tokenParams.token, _to, amountToReturn);
            } else {
                IERC20Upgradeable(tokenParams.token).safeTransfer(_to, tokenParams.amount);
                emit InconsistencyCallback(_add, tokenParams.token, _to, tokenParams.amount);
            }
        }
    }

    function _addLiquidityHubPoolLocal(
        address _addAtCrosschainPool,
        uint256 _lpIndex,
        address _addAtHubPool,
        uint256 _expectedMinMintAmountH,
        address _to
    ) internal returns (uint256) {
       IERC20Upgradeable(lpToken[_addAtCrosschainPool]).approve(
            _addAtHubPool,
            IERC20Upgradeable(lpToken[_addAtCrosschainPool]).balanceOf(address(this))
        );
        uint256[4] memory amountH;
        amountH[_lpIndex] = IERC20Upgradeable(lpToken[_addAtCrosschainPool]).balanceOf(address(this));

        if (_addLiquidityHubInconsistencyLocal(
            _addAtHubPool,
            _expectedMinMintAmountH,
            _to,
            _lpIndex,
            amountH,
            _addAtCrosschainPool
        )) {
            return 0;
        }

        //add liquidity
        IStableSwapPool(_addAtHubPool).add_liquidity(amountH, 0); 

        return(IERC20Upgradeable(lpToken[_addAtHubPool]).balanceOf(address(this)));
    }

    function _addLiquidityHubPool(
        address _addAtCrosschainPool,
        address _addAtHubPool,
        uint256 _expectedMinMintAmountH,
        address _to,
        uint256 _lpIndex
    ) internal returns (uint256) {
         IERC20Upgradeable(lpToken[_addAtCrosschainPool]).approve(
            _addAtHubPool,
            IERC20Upgradeable(lpToken[_addAtCrosschainPool]).balanceOf(address(this))
        );
        uint256[4] memory amountH;
        amountH[_lpIndex] = IERC20Upgradeable(lpToken[_addAtCrosschainPool]).balanceOf(address(this));

        if (_addLiquidityHubInconsistencyLocal(
            _addAtHubPool,
            _expectedMinMintAmountH,
            _to,
            _lpIndex,
            amountH,
            _addAtCrosschainPool
        )) {
            return 0;
        }

        //add liquidity
        IStableSwapPool(_addAtHubPool).add_liquidity(amountH, 0);

        return IERC20Upgradeable(lpToken[_addAtHubPool]).balanceOf(address(this));
    }

    function _metaExchangeSwapStage(
        address _add,
        address _exchange,
        int128 _i,
        int128 _j,
        uint256 _expectedMinDy,
        address _to
    ) internal returns (bool) {
        address lpLocalPool = lpToken[_add];

        IERC20Upgradeable(lpLocalPool).approve(
            _exchange,
            IERC20Upgradeable(lpLocalPool).balanceOf(address(this))
        );

        (uint256 dx, uint256 min_dy) = _exchangeInconsistency(_exchange, _i, _j, _expectedMinDy, _to, lpLocalPool);

        if(dx == 0 && min_dy == 0) {
            return true;
        }

        //perform an exhange
        IStableSwapPool(_exchange).exchange(_i, _j, dx, min_dy);
    }

    function _metaExchangeOneType(
        int128 _i,
        int128 _j,
        address _exchange,
        uint256 _expectedMinDy,
        address _to,
        address _synthToken,
        uint256 _synthAmount,
        bytes32 _txId
    ) internal returns (bool) {
        address representation;
        //synthesize stage
        representation = ISynthesis(synthesis).getRepresentation(bytes32(uint256(uint160(_synthToken))));
        ISynthesis(synthesis).mintSyntheticToken(_txId, _synthToken, _synthAmount, address(this));
        IERC20Upgradeable(representation).approve(_exchange, _synthAmount);

        (uint256 dx, uint256 min_dy) = _exchangeOneTypeInconsistency(_exchange, _i, _j, _expectedMinDy, _to, representation);

        if(dx == 0 && min_dy == 0) {
            return true;
        }

        IStableSwapPool(_exchange).exchange(_i, _j, dx, min_dy);
    }

    function _metaExchangeOneTypeLocal(
        int128 _i,
        int128 _j,
        address _exchange,
        uint256 _expectedMinDy,
        address _to,
        address _token,
        uint256 _amount
    ) internal returns (bool) {
        //synthesize stage
        registerNewBalance(_token, _amount);
        IERC20Upgradeable(_token).approve(_exchange, _amount);

        (uint256 dx, uint256 min_dy) = _exchangeOneTypeInconsistency(_exchange, _i, _j, _expectedMinDy, _to, _token);

        if(dx == 0 && min_dy == 0) {
            return true;
        }

        IStableSwapPool(_exchange).exchange(_i, _j, dx, min_dy);
    }

    function _addLiquidityHubInconsistencyLocal(
        address _addAtHubPool,
        uint256 _expectedMinMintAmountH,
        address _to,
        uint256 _lpIndex,
        uint256[4] memory amountH,
        address _addAtCrosschainPool
    ) internal returns (bool) {
        uint256 minMintAmountH = IStableSwapPool(_addAtHubPool).calc_token_amount(amountH, true);
        if (_expectedMinMintAmountH > minMintAmountH) {
            if(amountH[_lpIndex] > IWhitelist(whitelist).stableFee()) {
                uint256 amountToSend = amountH[_lpIndex] - IWhitelist(whitelist).stableFee();
                IERC20Upgradeable(lpToken[_addAtCrosschainPool]).safeTransfer(treasury, IWhitelist(whitelist).stableFee());
                IERC20Upgradeable(lpToken[_addAtCrosschainPool]).safeTransfer(_to, amountToSend);
                ITreasury(treasury).withdrawNative(IWhitelist(whitelist).nativeReturnAmount(), _to);
                emit InconsistencyCallback(
                    _addAtHubPool,
                    lpToken[_addAtCrosschainPool],
                    _to,
                    amountToSend
                );
                return true;
            } else {
                IERC20Upgradeable(lpToken[_addAtCrosschainPool]).safeTransfer(_to, amountH[_lpIndex]);
                emit InconsistencyCallback(
                    _addAtHubPool,
                    lpToken[_addAtCrosschainPool],
                    _to,
                    amountH[_lpIndex]
                );
                return true;
            }
        } else {
            return false;
        }
    }

    function _exchangeInconsistency(
        address _exchange,
        int128 _i,
        int128 _j,
        uint256 _expectedMinDy,
        address _to,
        address _token
    ) internal returns (uint256 dx, uint256 min_dy) {

        dx = IERC20Upgradeable(_token).balanceOf(address(this)); //amount to swap
        min_dy = IStableSwapPool(_exchange).get_dy(_i, _j, dx);

        if (_expectedMinDy > min_dy) {
            if(IERC20Upgradeable(pool[_exchange].at(uint256(int256(_i)))).balanceOf(address(this)) > IWhitelist(whitelist).stableFee()){
                uint256 amountToSend = IERC20Upgradeable(pool[_exchange].at(uint256(int256(_i)))).balanceOf(address(this)) - IWhitelist(whitelist).stableFee();
                
                IERC20Upgradeable(pool[_exchange].at(uint256(int256(_i)))).safeTransfer(
                    treasury,
                    IWhitelist(whitelist).stableFee()
                );
                IERC20Upgradeable(pool[_exchange].at(uint256(int256(_i)))).safeTransfer(
                    _to,
                    amountToSend
                );
                ITreasury(treasury).withdrawNative(IWhitelist(whitelist).nativeReturnAmount(), _to);
                emit InconsistencyCallback(
                    _exchange,
                    pool[_exchange].at(uint256(int256(_i))),
                    _to,
                    amountToSend
                );
                return (0,0);
            } else {
                uint256 amountToSend = IERC20Upgradeable(pool[_exchange].at(uint256(int256(_i)))).balanceOf(address(this));
                IERC20Upgradeable(pool[_exchange].at(uint256(int256(_i)))).safeTransfer(
                    _to,
                    amountToSend
                );
                emit InconsistencyCallback(
                    _exchange,
                    pool[_exchange].at(uint256(int256(_i))),
                    _to,
                    amountToSend
                );
                return (0,0);
            }
        }
    }

    function _exchangeOneTypeInconsistency(
        address _exchange,
        int128 _i,
        int128 _j,
        uint256 _expectedMinDy,
        address _to,
        address _token
    ) internal returns (uint256 dx, uint256 min_dy) {

        dx = IERC20Upgradeable(_token).balanceOf(address(this)); //amount to swap
        min_dy = IStableSwapPool(_exchange).get_dy(_i, _j, dx);

        if (_expectedMinDy > min_dy) {
            if(IERC20Upgradeable(_token).balanceOf(address(this)) > IWhitelist(whitelist).stableFee()){
                uint256 amountToSend = IERC20Upgradeable(_token).balanceOf(address(this)) - IWhitelist(whitelist).stableFee();

                IERC20Upgradeable(_token).safeTransfer(
                    treasury,
                    IWhitelist(whitelist).stableFee()
                );
                
                IERC20Upgradeable(_token).safeTransfer(
                    _to,
                    amountToSend
                );
                ITreasury(treasury).withdrawNative(IWhitelist(whitelist).nativeReturnAmount(), _to);
                emit InconsistencyCallback(
                    _exchange,
                    pool[_exchange].at(uint256(int256(_i))),
                    _to,
                    amountToSend
                );
                return (0,0);
            } else {
                uint256 amountToSend = IERC20Upgradeable(_token).balanceOf(address(this));
                IERC20Upgradeable(_token).safeTransfer(
                    _to,
                    amountToSend
                );
                emit InconsistencyCallback(
                    _exchange,
                    pool[_exchange].at(uint256(int256(_i))),
                    _to,
                    amountToSend
                );
                return (0,0);
            }
        }
    }

    function _metaExchangeRemoveStage(
        address _remove,
        int128 _x,
        uint256 _expectedMinAmount,
        address _to
    ) internal returns (uint256) {
        address thisLpToken = lpToken[_remove];
        IERC20Upgradeable(thisLpToken).approve(
            _remove,
            IERC20Upgradeable(thisLpToken).balanceOf(address(this))
        );

        uint256 tokenAmount = IERC20Upgradeable(thisLpToken).balanceOf(address(this));
        uint256 minAmount = IStableSwapPool(_remove).calc_withdraw_one_coin(tokenAmount, _x);

        //inconsistency check
        if (_expectedMinAmount > minAmount) {
            if(tokenAmount > IWhitelist(whitelist).stableFee()) {
                uint256 amountToSend = tokenAmount - IWhitelist(whitelist).stableFee();
                IERC20Upgradeable(thisLpToken).safeTransfer(treasury, IWhitelist(whitelist).stableFee());
                IERC20Upgradeable(thisLpToken).safeTransfer(_to, amountToSend);
                ITreasury(treasury).withdrawNative(IWhitelist(whitelist).nativeReturnAmount(), _to);
                emit InconsistencyCallback(_remove, thisLpToken, _to, amountToSend);
                return 0;
            } else {
                IERC20Upgradeable(thisLpToken).safeTransfer(_to, tokenAmount);
                emit InconsistencyCallback(_remove, thisLpToken, _to, tokenAmount);
                return 0;
            }
        }

        //remove liquidity
        IStableSwapPool(_remove).remove_liquidity_one_coin(tokenAmount, _x, 0);

        //transfer asset to the recipient (unsynth if mentioned)
        return IERC20Upgradeable(pool[_remove].at(uint256(int256(_x)))).balanceOf(
            address(this)
        );
    }

    function _addLiquidityInconsistency(
        address _add,
        uint256 _expectedMinMintAmount,
        address _to,
        uint256 _coinIndex,
        uint256 _amount,
        address _representation
    ) internal returns (bool) {
        uint256 size = pool[_add].length();
        uint256 minMintAmount;
        if(size == 2){
            uint256[2] memory amount;
            amount[_coinIndex] = _amount;
            minMintAmount = IStableSwapPool(_add).calc_token_amount(amount, true);
        }
        if(size == 3){
            uint256[3] memory amount;
            amount[_coinIndex] = _amount;
            minMintAmount = IStableSwapPool(_add).calc_token_amount(amount, true);
        }
        if(size == 4){
            uint256[4] memory amount;
            amount[_coinIndex] = _amount;
            minMintAmount = IStableSwapPool(_add).calc_token_amount(amount, true);
        }
        if(size == 5){
            uint256[5] memory amount;
            amount[_coinIndex] = _amount;
            minMintAmount = IStableSwapPool(_add).calc_token_amount(amount, true);
        }
        if(size == 6){
            uint256[6] memory amount;
            amount[_coinIndex] = _amount;
            minMintAmount = IStableSwapPool(_add).calc_token_amount(amount, true);
        }
        if(size == 7){
            uint256[7] memory amount;
            amount[_coinIndex] = _amount;
            minMintAmount = IStableSwapPool(_add).calc_token_amount(amount, true);
        }
        if(size == 8){
            uint256[8] memory amount;
            amount[_coinIndex] = _amount;
            minMintAmount = IStableSwapPool(_add).calc_token_amount(amount, true);
        }

        //inconsistency check
        if (_expectedMinMintAmount > minMintAmount) {
            return false;
        } else {
            return true;
        }
    }

    function _addLiquidityInconsistencyLocal(
        address _addAtCrosschainPool,
        uint256 _expectedMinMintAmountC,
        address _to,
        address _token,
        uint256 _amount,
        uint256 _coinIndex
    ) internal returns (bool) {
        uint256 size = pool[_addAtCrosschainPool].length();
        uint256 minMintAmountC;
        if(size == 2){
            uint256[2] memory amount;
            amount[_coinIndex] = _amount;
            minMintAmountC = IStableSwapPool(_addAtCrosschainPool).calc_token_amount(amount, true);
        }
        if(size == 3){
            uint256[3] memory amount;
            amount[_coinIndex] = _amount;
            minMintAmountC = IStableSwapPool(_addAtCrosschainPool).calc_token_amount(amount, true);
        }
        if(size == 4){
            uint256[4] memory amount;
            amount[_coinIndex] = _amount;
            minMintAmountC = IStableSwapPool(_addAtCrosschainPool).calc_token_amount(amount, true);
        }
        if(size == 5){
            uint256[5] memory amount;
            amount[_coinIndex] = _amount;
            minMintAmountC = IStableSwapPool(_addAtCrosschainPool).calc_token_amount(amount, true);
        }
        if(size == 6){
            uint256[6] memory amount;
            amount[_coinIndex] = _amount;
            minMintAmountC = IStableSwapPool(_addAtCrosschainPool).calc_token_amount(amount, true);
        }
        if(size == 7){
            uint256[7] memory amount;
            amount[_coinIndex] = _amount;
            minMintAmountC = IStableSwapPool(_addAtCrosschainPool).calc_token_amount(amount, true);
        }
        if(size == 8){
            uint256[8] memory amount;
            amount[_coinIndex] = _amount;
            minMintAmountC = IStableSwapPool(_addAtCrosschainPool).calc_token_amount(amount, true);
        }

        //inconsistency check
        if (_expectedMinMintAmountC > minMintAmountC) {
            return false;
        } else {
            return true;
        }
    }


}