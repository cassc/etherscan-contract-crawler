// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IAdapter.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IBrewlabsNFTDiscountManager.sol";
import "./libraries/BytesManipulation.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/SafeMath.sol";
import "./libraries/Ownable.sol";

contract BrewlabsAggregationRouter is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    address public immutable WNATIVE;
    address public constant NATIVE = address(0);
    string public constant NAME = "BrewlabsAggregationRouter";
    uint256 public constant FEE_DENOMINATOR = 1e4;
    uint256 public MIN_FEE = 0;
    uint256 public BREWS_FEE = 0;
    address public FEE_CLAIMER;
    address[] public TRUSTED_TOKENS;
    address[] public ADAPTERS;
    address private NFT_DISCOUNT_MGR;

    event Recovered(address indexed _asset, uint256 amount);
    event UpdatedTrustedTokens(address[] _newTrustedTokens);
    event UpdatedAdapters(address[] _newAdapters);
    event UpdatedMinFee(uint256 _oldMinFee, uint256 _newMinFee);
    event UpdatedFeeClaimer(address _oldFeeClaimer, address _newFeeClaimer);
    event BrewlabsSwap(address indexed _tokenIn, address indexed _tokenOut, uint256 _amountIn, uint256 _amountOut);
    event SetNFTDiscountManager(address prevMgr, address newMgr);

    struct Query {
        address adapter;
        address tokenIn;
        address tokenOut;
        uint256 amountOut;
    }

    struct Offer {
        bytes amounts;
        bytes adapters;
        bytes path;
        uint256 gasEstimate;
    }

    struct FormattedOffer {
        uint256[] amounts;
        address[] adapters;
        address[] path;
        uint256 gasEstimate;
    }

    struct Trade {
        uint256 amountIn;
        uint256 amountOut;
        address[] path;
        address[] adapters;
    }

    constructor(
        address[] memory _adapters,
        address[] memory _trustedTokens,
        address _feeClaimer,
        address _wrapped_native
    ) {
        _setAllowanceForWrapping(_wrapped_native);
        setTrustedTokens(_trustedTokens);
        setFeeClaimer(_feeClaimer);
        setAdapters(_adapters);
        WNATIVE = _wrapped_native;
    }

    // -- SETTERS --

    function _setAllowanceForWrapping(address _wnative) internal {
        IERC20(_wnative).safeApprove(_wnative, type(uint256).max);
    }

    function setTrustedTokens(address[] memory _trustedTokens) public onlyOwner {
        emit UpdatedTrustedTokens(_trustedTokens);
        TRUSTED_TOKENS = _trustedTokens;
    }

    function setAdapters(address[] memory _adapters) public onlyOwner {
        emit UpdatedAdapters(_adapters);
        ADAPTERS = _adapters;
    }

    function setBrewsFee(uint256 _fee) external onlyOwner {
        BREWS_FEE = _fee;
    }

    function setMinFee(uint256 _fee) external onlyOwner {
        emit UpdatedMinFee(MIN_FEE, _fee);
        MIN_FEE = _fee;
    }

    function setFeeClaimer(address _claimer) public onlyOwner {
        emit UpdatedFeeClaimer(FEE_CLAIMER, _claimer);
        FEE_CLAIMER = _claimer;
    }

    function setNFTDiscountManager(address _discountMgr) external onlyOwner {
        require(NFT_DISCOUNT_MGR != _discountMgr, "BrewlabsAggregationRouter: same address can't be set");
        emit SetNFTDiscountManager(NFT_DISCOUNT_MGR, _discountMgr);
        NFT_DISCOUNT_MGR = _discountMgr;
    }

    //  -- GENERAL --

    function trustedTokensCount() external view returns (uint256) {
        return TRUSTED_TOKENS.length;
    }

    function adaptersCount() external view returns (uint256) {
        return ADAPTERS.length;
    }

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAmount > 0, "BrewlabsAggregationRouter: Nothing to recover");
        IERC20(_tokenAddress).safeTransfer(msg.sender, _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    function recoverETH(uint256 _amount) external onlyOwner {
        require(_amount > 0, "BrewlabsAggregationRouter: Nothing to recover");
        payable(msg.sender).transfer(_amount);
        emit Recovered(address(0), _amount);
    }

    // Fallback
    receive() external payable {}

    // -- HELPERS --

    function _applyFee(uint256 _amountIn, uint256 _fee, uint256 _discount) internal view returns (uint256) {
        require(_fee >= MIN_FEE, "BrewlabsAggregationRouter: Insufficient fee");
        return _amountIn.mul(_fee).mul(FEE_DENOMINATOR - _discount) / (FEE_DENOMINATOR ** 2);
    }

    function _wrap(uint256 _amount) internal {
        IWETH(WNATIVE).deposit{ value: _amount }();
    }

    function _unwrap(uint256 _amount) internal {
        IWETH(WNATIVE).withdraw(_amount);
    }

    /**
     * @notice Return tokens to user
     * @dev Pass address(0) for ETH
     * @param _token address
     * @param _amount tokens to return
     * @param _to address where funds should be sent to
     */
    function _returnTokensTo(
        address _token,
        uint256 _amount,
        address _to
    ) internal {
        if (address(this) != _to) {
            if (_token == NATIVE) {
                payable(_to).transfer(_amount);
            } else {
                IERC20(_token).safeTransfer(_to, _amount);
            }
        }
    }

    /**
     * Makes a deep copy of Offer struct
     */
    function _cloneOffer(Offer memory _queries) internal pure returns (Offer memory) {
        return Offer(_queries.amounts, _queries.adapters, _queries.path, _queries.gasEstimate);
    }

    /**
     * Appends Query elements to Offer struct
     */
    function _addQuery(
        Offer memory _queries,
        uint256 _amount,
        address _adapter,
        address _tokenOut,
        uint256 _gasEstimate
    ) internal pure {
        _queries.path = BytesManipulation.mergeBytes(_queries.path, BytesManipulation.toBytes(_tokenOut));
        _queries.amounts = BytesManipulation.mergeBytes(_queries.amounts, BytesManipulation.toBytes(_amount));
        _queries.adapters = BytesManipulation.mergeBytes(_queries.adapters, BytesManipulation.toBytes(_adapter));
        _queries.gasEstimate += _gasEstimate;
    }

    /**
     * Converts byte-arrays to an array of integers
     */
    function _formatAmounts(bytes memory _amounts) internal pure returns (uint256[] memory) {
        // Format amounts
        uint256 chunks = _amounts.length / 32;
        uint256[] memory amountsFormatted = new uint256[](chunks);
        for (uint256 i = 0; i < chunks; i++) {
            amountsFormatted[i] = BytesManipulation.bytesToUint256(i * 32 + 32, _amounts);
        }
        return amountsFormatted;
    }

    /**
     * Converts byte-array to an array of addresses
     */
    function _formatAddresses(bytes memory _addresses) internal pure returns (address[] memory) {
        uint256 chunks = _addresses.length / 32;
        address[] memory addressesFormatted = new address[](chunks);
        for (uint256 i = 0; i < chunks; i++) {
            addressesFormatted[i] = BytesManipulation.bytesToAddress(i * 32 + 32, _addresses);
        }
        return addressesFormatted;
    }

    /**
     * Formats elements in the Offer object from byte-arrays to integers and addresses
     */
    function _formatOffer(Offer memory _queries) internal pure returns (FormattedOffer memory) {
        return
            FormattedOffer(
                _formatAmounts(_queries.amounts),
                _formatAddresses(_queries.adapters),
                _formatAddresses(_queries.path),
                _queries.gasEstimate
            );
    }

    // -- QUERIES --

    /**
     * Query single adapter
     */
    function queryAdapter(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint8 _index
    ) external view returns (uint256) {
        IAdapter _adapter = IAdapter(ADAPTERS[_index]);
        uint256 amountOut = _adapter.query(_amountIn, _tokenIn, _tokenOut);
        return amountOut;
    }

    /**
     * Query specified adapters
     */
    function queryNoSplit(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint8[] calldata _options
    ) public view returns (Query memory) {
        Query memory bestQuery;
        for (uint8 i; i < _options.length; i++) {
            address _adapter = ADAPTERS[_options[i]];
            uint256 amountOut = IAdapter(_adapter).query(_amountIn, _tokenIn, _tokenOut);
            if (i == 0 || amountOut > bestQuery.amountOut) {
                bestQuery = Query(_adapter, _tokenIn, _tokenOut, amountOut);
            }
        }
        return bestQuery;
    }

    /**
     * Query all adapters
     */
    function queryNoSplit(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) public view returns (Query memory) {
        Query memory bestQuery;
        for (uint8 i; i < ADAPTERS.length; i++) {
            address _adapter = ADAPTERS[i];
            uint256 amountOut = IAdapter(_adapter).query(_amountIn, _tokenIn, _tokenOut);
            if (i == 0 || amountOut > bestQuery.amountOut) {
                bestQuery = Query(_adapter, _tokenIn, _tokenOut, amountOut);
            }
        }
        return bestQuery;
    }

    /**
     * Return path with best returns between two tokens
     * Takes gas-cost into account
     */
    function findBestPathWithGas(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint256 _maxSteps,
        uint256 _gasPrice
    ) external view returns (FormattedOffer memory) {
        require(_maxSteps > 0 && _maxSteps < 5, "BrewlabsAggregationRouter: Invalid max-steps");
        Offer memory queries;
        queries.amounts = BytesManipulation.toBytes(_amountIn);
        queries.path = BytesManipulation.toBytes(_tokenIn);
        uint256 gasPriceInExitTkn = _gasPrice > 0 ? getGasPriceInExitTkn(_gasPrice, _tokenOut) : 0;
        queries = _findBestPath(_amountIn, _tokenIn, _tokenOut, _maxSteps, queries, gasPriceInExitTkn);
        if (queries.adapters.length == 0) {
            queries.amounts = "";
            queries.path = "";
        }
        return _formatOffer(queries);
    }

    // Find the market price between gas-asset(native) and token-out and express gas price in token-out
    function getGasPriceInExitTkn(uint256 _gasPrice, address _tokenOut) internal view returns (uint256 price) {
        FormattedOffer memory gasQuery = findBestPath(1e18, WNATIVE, _tokenOut, 2);
        if (gasQuery.path.length != 0) {
            // Leave result in nWei to preserve precision for assets with low decimal places
            price = (gasQuery.amounts[gasQuery.amounts.length - 1] * _gasPrice) / 1e9;
        }
    }

    /**
     * Return path with best returns between two tokens
     */
    function findBestPath(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint256 _maxSteps
    ) public view returns (FormattedOffer memory) {
        require(_maxSteps > 0 && _maxSteps < 5, "BrewlabsAggregationRouter: Invalid max-steps");
        Offer memory queries;
        queries.amounts = BytesManipulation.toBytes(_amountIn);
        queries.path = BytesManipulation.toBytes(_tokenIn);
        queries = _findBestPath(_amountIn, _tokenIn, _tokenOut, _maxSteps, queries, 0);
        // If no paths are found return empty struct
        if (queries.adapters.length == 0) {
            queries.amounts = "";
            queries.path = "";
        }
        return _formatOffer(queries);
    }

    function _findBestPath(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint256 _maxSteps,
        Offer memory _queries,
        uint256 _tknOutPriceNwei
    ) internal view returns (Offer memory) {
        Offer memory bestOption = _cloneOffer(_queries);
        uint256 bestAmountOut;
        uint256 gasEstimate;
        bool withGas = _tknOutPriceNwei != 0;

        // First check if there is a path directly from tokenIn to tokenOut
        Query memory queryDirect = queryNoSplit(_amountIn, _tokenIn, _tokenOut);

        if (queryDirect.amountOut != 0) {
            if (withGas) {
                gasEstimate = IAdapter(queryDirect.adapter).swapGasEstimate();
            }
            _addQuery(bestOption, queryDirect.amountOut, queryDirect.adapter, queryDirect.tokenOut, gasEstimate);
            bestAmountOut = queryDirect.amountOut;
        }
        // Only check the rest if they would go beyond step limit (Need at least 2 more steps)
        if (_maxSteps > 1 && _queries.adapters.length / 32 <= _maxSteps - 2) {
            // Check for paths that pass through trusted tokens
            for (uint256 i = 0; i < TRUSTED_TOKENS.length; i++) {
                if (_tokenIn == TRUSTED_TOKENS[i]) {
                    continue;
                }
                // Loop through all adapters to find the best one for swapping tokenIn for one of the trusted tokens
                Query memory bestSwap = queryNoSplit(_amountIn, _tokenIn, TRUSTED_TOKENS[i]);
                if (bestSwap.amountOut == 0) {
                    continue;
                }
                // Explore options that connect the current path to the tokenOut
                Offer memory newOffer = _cloneOffer(_queries);
                if (withGas) {
                    gasEstimate = IAdapter(bestSwap.adapter).swapGasEstimate();
                }
                _addQuery(newOffer, bestSwap.amountOut, bestSwap.adapter, bestSwap.tokenOut, gasEstimate);
                newOffer = _findBestPath(
                    bestSwap.amountOut,
                    TRUSTED_TOKENS[i],
                    _tokenOut,
                    _maxSteps,
                    newOffer,
                    _tknOutPriceNwei
                ); // Recursive step
                address tokenOut = BytesManipulation.bytesToAddress(newOffer.path.length, newOffer.path);
                uint256 amountOut = BytesManipulation.bytesToUint256(newOffer.amounts.length, newOffer.amounts);
                // Check that the last token in the path is the tokenOut and update the new best option if neccesary
                if (_tokenOut == tokenOut && amountOut > bestAmountOut) {
                    if (newOffer.gasEstimate > bestOption.gasEstimate) {
                        uint256 gasCostDiff = (_tknOutPriceNwei * (newOffer.gasEstimate - bestOption.gasEstimate)) /
                            1e9;
                        uint256 priceDiff = amountOut - bestAmountOut;
                        if (gasCostDiff > priceDiff) {
                            continue;
                        }
                    }
                    bestAmountOut = amountOut;
                    bestOption = newOffer;
                }
            }
        }
        return bestOption;
    }

    // -- SWAPPERS --

    function _swapNoSplit(
        Trade memory _trade,
        address _from,
        address _to
    ) internal returns (uint256) {
        uint256[] memory amounts = new uint256[](_trade.path.length);
        amounts[0] = _trade.amountIn;
        uint256 beforeBal = IERC20(_trade.path[0]).balanceOf(_trade.adapters[0]);
        if (_from == address(this)) {
            IERC20(_trade.path[0]).safeTransfer(_trade.adapters[0], amounts[0]);
        } else {
            IERC20(_trade.path[0]).safeTransferFrom(_from, _trade.adapters[0], amounts[0]);
        }
        amounts[0] = IERC20(_trade.path[0]).balanceOf(_trade.adapters[0]).sub(beforeBal);

        bool feeOn = BREWS_FEE > 0 || MIN_FEE > 0;
        for (uint256 i = 0; i < _trade.adapters.length; i++) {
            // All adapters should transfer output token to the following target
            // All targets are the adapters, expect for the last swap where tokens are sent out
            address targetAddress = i < _trade.adapters.length - 1 ? _trade.adapters[i + 1] : feeOn ? address(this) : _to;
            beforeBal = IERC20(_trade.path[i + 1]).balanceOf(targetAddress);
            IAdapter(_trade.adapters[i]).swap(
                amounts[i],
                _trade.path[i],
                _trade.path[i + 1],
                targetAddress
            );
            amounts[i + 1] = IERC20(_trade.path[i + 1]).balanceOf(targetAddress).sub(beforeBal);
        }
        if (feeOn) {
            uint256 discount = NFT_DISCOUNT_MGR != address(0) ? IBrewlabsNFTDiscountManager(NFT_DISCOUNT_MGR).discountOf(msg.sender) : 0;
            uint256 feeAmount = _applyFee(amounts[amounts.length - 1], BREWS_FEE, discount);
            if (_trade.path[_trade.path.length - 1] == WNATIVE) {
                _unwrap(feeAmount);
                _returnTokensTo(NATIVE, feeAmount, FEE_CLAIMER);
            } else {
                IERC20(_trade.path[_trade.path.length - 1]).safeTransfer(_to, amounts[amounts.length - 1].sub(feeAmount));
                IERC20(_trade.path[_trade.path.length - 1]).safeTransfer(FEE_CLAIMER, feeAmount);
            }
            amounts[amounts.length - 1] = amounts[amounts.length - 1].sub(feeAmount);
        }
        emit BrewlabsSwap(_trade.path[0], _trade.path[_trade.path.length - 1], _trade.amountIn, amounts[amounts.length - 1]);
        return amounts[amounts.length - 1];
    }

    function swapNoSplit(
        Trade memory _trade,
        address _to
    ) public {
        _swapNoSplit(_trade, msg.sender, _to);
    }

    function swapNoSplitFromETH(
        Trade memory _trade,
        address _to
    ) public payable {
        require(_trade.path[0] == WNATIVE, "BrewlabsAggregationRouter: Path needs to begin with WETH");
        _wrap(_trade.amountIn);
        _swapNoSplit(_trade, address(this), _to);
    }

    function swapNoSplitToETH(
        Trade memory _trade,
        address _to
    ) public {
        require(_trade.path[_trade.path.length - 1] == WNATIVE, "BrewlabsAggregationRouter: Path needs to end with WETH");
        uint256 returnAmount = _swapNoSplit(_trade, msg.sender, address(this));
        _unwrap(returnAmount);
        _returnTokensTo(NATIVE, returnAmount, _to);
    }

    /**
     * Swap token to token without the need to approve the first token
     */
    function swapNoSplitWithPermit(
        Trade memory _trade,
        address _to,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        IERC20(_trade.path[0]).permit(msg.sender, address(this), _trade.amountIn, _deadline, _v, _r, _s);
        swapNoSplit(_trade, _to);
    }

    /**
     * Swap token to ETH without the need to approve the first token
     */
    function swapNoSplitToETHWithPermit(
        Trade memory _trade,
        address _to,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        IERC20(_trade.path[0]).permit(msg.sender, address(this), _trade.amountIn, _deadline, _v, _r, _s);
        swapNoSplitToETH(_trade, _to);
    }
        
    /**
     * Aggregate swap calls between token to token, token to ETH, ETH to token.
     */
    function swapAggregationCall(uint256 amountIn, address tokenIn, address tokenOut, uint256 maxSteps, address to) external payable returns (uint256) {
        FormattedOffer memory offer = findBestPath(amountIn, tokenIn, tokenOut, maxSteps);
        uint256 amountOut = offer.amounts[offer.amounts.length - 1];
        Trade memory trade = Trade(amountIn, amountOut, offer.path, offer.adapters);
        if (offer.path[0] == WNATIVE) {
            swapNoSplitFromETH(trade, to);
        } else if (offer.path[offer.path.length - 1] == WNATIVE) {
            swapNoSplitToETH(trade, to);
        } else {
            swapNoSplit(trade, to);
        }
        return amountOut;
    }
}