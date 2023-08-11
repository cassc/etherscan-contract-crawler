// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "./interfaces/ISwapContract.sol";
import "./interfaces/ISwapRewards.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/lib/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

//import "hardhat/console.sol"; //console.log()

contract SwapContract is ISwapContract, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IBurnableToken public immutable lpToken;
    ISwapRewards public immutable sw;

    /** Skybridge */
    mapping(address => bool) public whitelist;
    address public immutable BTCT_ADDR;
    uint256 private immutable convertScale;
    uint256 private immutable lpDivisor;
    address public buybackAddress;
    address public sbBTCPool;
    uint256 public withdrawalFeeBPS;
    uint256 public nodeRewardsRatio;
    uint256 public buybackRewardsRatio;

    mapping(address => uint256) private floatAmountOf;
    mapping(bytes32 => bool) private used; //used TX

    /** TSS */
    // Node lists state { 0 => not exist, 1 => exist, 2 => removed }
    mapping(address => uint8) private nodes;
    address[] private nodeAddrs;
    uint8 public activeNodeCount;
    uint8 public churnedInCount;
    uint8 public tssThreshold;

    /**
     * Events
     */
    event Swap(address from, address to, uint256 amount);

    event RewardsCollection(
        address feesToken,
        uint256 rewards,
        uint256 rewardsLPTTotal,
        uint256 currentPriceLP
    );

    event IssueLPTokensForFloat(
        address to,
        uint256 amountOfFloat,
        uint256 amountOfLP,
        uint256 currentPriceLP,
        uint256 depositFees,
        bytes32 txid
    );

    event BurnLPTokensForFloat(
        address token,
        uint256 amountOfLP,
        uint256 amountOfFloat,
        uint256 currentPriceLP,
        uint256 withdrawal,
        bytes32 txid
    );

    modifier priceCheck() {
        uint256 beforePrice = getCurrentPriceLP();
        _;
        require(getCurrentPriceLP() >= beforePrice, "Invalid LPT price");
    }

    constructor(
        address _lpToken,
        address _btct,
        address _sbBTCPool,
        address _swapRewards,
        address _buybackAddress,
        uint256 _initBTCFloat,
        uint256 _initWBTCFloat
    ) {
        //set address for sbBTCpool
        sbBTCPool = _sbBTCPool;
        //set ISwapRewards
        sw = ISwapRewards(_swapRewards);
        // Set lpToken address
        lpToken = IBurnableToken(_lpToken);
        // Set initial lpDivisor of LP token
        lpDivisor = 10 ** IERC20(_lpToken).decimals();
        // Set BTCT address
        BTCT_ADDR = _btct;
        // Set convertScale
        convertScale = 10 ** (IERC20(_btct).decimals() - 8);
        // Set whitelist addresses
        whitelist[_btct] = true;
        whitelist[_lpToken] = true;
        whitelist[address(0)] = true;
        floatAmountOf[address(0)] = _initBTCFloat;
        floatAmountOf[BTCT_ADDR] = _initWBTCFloat;
        buybackAddress = _buybackAddress;
        withdrawalFeeBPS = 20;
        nodeRewardsRatio = 66;
        buybackRewardsRatio = 25;
    }

    /**
     * Transfer part
     */
    /// @dev singleTransferERC20 sends tokens from contract.
    /// @param _destToken The address of target token.
    /// @param _to The address of recipient.
    /// @param _amount The amount of tokens.
    /// @param _totalSwapped The amount of swap.
    /// @param _rewardsAmount The fees that should be paid.
    /// @param _redeemedFloatTxIds The txids which is for recording.
    function singleTransferERC20(
        address _destToken,
        address _to,
        uint256 _amount,
        uint256 _totalSwapped,
        uint256 _rewardsAmount,
        bytes32[] memory _redeemedFloatTxIds
    ) external override onlyOwner returns (bool) {
        require(whitelist[_destToken], "14"); //_destToken is not whitelisted
        require(
            _destToken != address(0),
            "15" //_destToken should not be address(0)
        );
        address _feesToken = address(0);
        if (_totalSwapped > 0) {
            sw.pullRewards(_destToken, _to, _totalSwapped);
            _swap(address(0), BTCT_ADDR, _totalSwapped);
        } else {
            _feesToken = (_destToken == address(lpToken))
                ? address(lpToken)
                : BTCT_ADDR;
        }
        _rewardsCollection(_feesToken, _rewardsAmount);
        _addUsedTxs(_redeemedFloatTxIds);
        _safeTransfer(_destToken, _to, _amount);
        return true;
    }

    /// @dev multiTransferERC20TightlyPacked sends tokens from contract.
    /// @param _destToken The address of target token.
    /// @param _addressesAndAmounts The address of recipient and amount.
    /// @param _totalSwapped The amount of swap.
    /// @param _rewardsAmount The fees that should be paid.
    /// @param _redeemedFloatTxIds The txids which is for recording.
    function multiTransferERC20TightlyPacked(
        address _destToken,
        bytes32[] memory _addressesAndAmounts,
        uint256 _totalSwapped,
        uint256 _rewardsAmount,
        bytes32[] memory _redeemedFloatTxIds
    ) external override onlyOwner returns (bool) {
        require(whitelist[_destToken], "_destToken is not whitelisted");
        require(
            _destToken != address(0),
            "_destToken should not be address(0)"
        );
        address _feesToken = address(0);
        if (_totalSwapped > 0) {
            _swap(address(0), BTCT_ADDR, _totalSwapped);
        } else {
            _feesToken = (_destToken == address(lpToken))
                ? address(lpToken)
                : BTCT_ADDR;
        }
        _rewardsCollection(_feesToken, _rewardsAmount);
        _addUsedTxs(_redeemedFloatTxIds);
        for (uint256 i = 0; i < _addressesAndAmounts.length; i++) {
            _safeTransfer(
                _destToken,
                address(uint160(uint256(_addressesAndAmounts[i]))),
                uint256(uint96(bytes12(_addressesAndAmounts[i])))
            );
        }
        return true;
    }

    /// @dev collectSwapFeesForBTC collects fees in the case of swap BTCT to BTC.
    /// @param _incomingAmount The spent amount. (BTCT)
    /// @param _minerFee The miner fees of BTC transaction.
    /// @param _rewardsAmount The fees that should be paid.
    function collectSwapFeesForBTC(
        uint256 _incomingAmount,
        uint256 _minerFee,
        uint256 _rewardsAmount,
        address[] memory _spenders,
        uint256[] memory _swapAmounts
    ) external override onlyOwner returns (bool) {
        address _feesToken = BTCT_ADDR;
        if (_incomingAmount > 0) {
            uint256 swapAmount = _incomingAmount.sub(_rewardsAmount);
            sw.pullRewardsMulti(address(0), _spenders, _swapAmounts);
            _swap(BTCT_ADDR, address(0), swapAmount);
        } else if (_incomingAmount == 0) {
            _feesToken = address(0);
        }
        _rewardsCollection(_feesToken, _rewardsAmount);
        return true;
    }

    /**
     * Float part
     */
    /// @dev recordIncomingFloat mints LP token.
    /// @param _token The address of target token.
    /// @param _addressesAndAmountOfFloat The address of recipient and amount.
    /// @param _txid The txids which is for recording.
    function recordIncomingFloat(
        address _token,
        bytes32 _addressesAndAmountOfFloat,
        bytes32 _txid
    ) external override onlyOwner priceCheck returns (bool) {
        require(whitelist[_token], "16"); //_token is invalid
        require(
            _issueLPTokensForFloat(_token, _addressesAndAmountOfFloat, _txid)
        );
        return true;
    }

    /// @dev recordOutcomingFloat burns LP token.
    /// @param _token The address of target token.
    /// @param _addressesAndAmountOfLPtoken The address of recipient and amount.
    /// @param _minerFee The miner fees of BTC transaction.
    /// @param _txid The txid which is for recording.
    function recordOutcomingFloat(
        address _token,
        bytes32 _addressesAndAmountOfLPtoken,
        uint256 _minerFee,
        bytes32 _txid
    ) external override onlyOwner priceCheck returns (bool) {
        require(whitelist[_token], "16"); //_token is invalid
        require(
            _burnLPTokensForFloat(
                _token,
                _addressesAndAmountOfLPtoken,
                _minerFee,
                _txid
            )
        );
        return true;
    }

    fallback() external {
        revert(); // reject all ETH
    }

    /**
     * Life cycle part
     */

    /// @dev recordUTXOSweepMinerFee reduces float amount by collected miner fees.
    /// @param _minerFee The miner fees of BTC transaction.
    /// @param _txid The txid which is for recording.
    function recordUTXOSweepMinerFee(
        uint256 _minerFee,
        bytes32 _txid
    ) public override onlyOwner returns (bool) {
        require(!isTxUsed(_txid), "The txid is already used");
        floatAmountOf[address(0)] = floatAmountOf[address(0)].sub(
            _minerFee,
            "12" //"BTC float amount insufficient"
        );
        _addUsedTx(_txid);
        return true;
    }

    /// @dev churn transfers contract ownership and set variables of the next TSS validator set.
    /// @param _newOwner The address of new Owner.
    /// @param _nodes The reward addresses.
    /// @param _isRemoved The flags to remove node.
    /// @param _churnedInCount The number of next party size of TSS group.
    /// @param _tssThreshold The number of next threshold.
    function churn(
        address _newOwner,
        address[] memory _nodes,
        bool[] memory _isRemoved,
        uint8 _churnedInCount,
        uint8 _tssThreshold
    ) external override onlyOwner returns (bool) {
        require(
            _tssThreshold >= tssThreshold && _tssThreshold <= 2 ** 8 - 1,
            "01" //"_tssThreshold should be >= tssThreshold"
        );
        require(
            _churnedInCount >= _tssThreshold + uint8(1),
            "02" //"n should be >= t+1"
        );
        require(
            _nodes.length == _isRemoved.length,
            "05" //"_nodes and _isRemoved length is not match"
        );

        transferOwnership(_newOwner);
        // Update active node list
        for (uint256 i = 0; i < _nodes.length; i++) {
            if (!_isRemoved[i]) {
                if (nodes[_nodes[i]] == uint8(0)) {
                    nodeAddrs.push(_nodes[i]);
                }
                if (nodes[_nodes[i]] != uint8(1)) {
                    activeNodeCount++;
                }
                nodes[_nodes[i]] = uint8(1);
            } else {
                activeNodeCount--;
                nodes[_nodes[i]] = uint8(2);
            }
        }
        require(activeNodeCount <= 100, "Stored node size should be <= 100");
        churnedInCount = _churnedInCount;
        tssThreshold = _tssThreshold;
        return true;
    }

    /// @dev updateParams changes contract params.
    /// @param _sbBTCPool The address of new sbBTCPool.
    /// @param _buybackAddress The address of new buyback.
    /// @param _withdrawalFeeBPS The number of next withdarw fees.
    /// @param _nodeRewardsRatio The number of next node rewards ratio.
    /// @param _buybackRewardsRatio The number of next buyback rewards ratio.
    function updateParams(
        address _sbBTCPool,
        address _buybackAddress,
        uint256 _withdrawalFeeBPS,
        uint256 _nodeRewardsRatio,
        uint256 _buybackRewardsRatio
    ) external override onlyOwner returns (bool) {
        sbBTCPool = _sbBTCPool;
        buybackAddress = _buybackAddress;
        withdrawalFeeBPS = _withdrawalFeeBPS;
        nodeRewardsRatio = _nodeRewardsRatio;
        buybackRewardsRatio = _buybackRewardsRatio;
        return true;
    }

    /// @dev isTxUsed sends rewards for Nodes.
    /// @param _txid The txid which is for recording.
    function isTxUsed(bytes32 _txid) public view override returns (bool) {
        return used[_txid];
    }

    /// @dev getCurrentPriceLP returns the current exchange rate of LP token.
    function getCurrentPriceLP()
        public
        view
        override
        returns (uint256 nowPrice)
    {
        (uint256 reserveA, uint256 reserveB) = getFloatReserve(
            address(0),
            BTCT_ADDR
        );
        uint256 totalLPs = lpToken.totalSupply();
        // decimals of totalReserved == 8, lpDivisor == 8, decimals of rate == 8
        nowPrice = totalLPs == 0
            ? lpDivisor
            : (reserveA.add(reserveB)).mul(lpDivisor).div(totalLPs);
        return nowPrice;
    }

    /// @dev getFloatReserve returns float reserves
    /// @param _tokenA The address of target tokenA.
    /// @param _tokenB The address of target tokenB.
    function getFloatReserve(
        address _tokenA,
        address _tokenB
    ) public view override returns (uint256 reserveA, uint256 reserveB) {
        (reserveA, reserveB) = (floatAmountOf[_tokenA], floatAmountOf[_tokenB]);
    }

    /// @dev getActiveNodes returns active nodes list
    function getActiveNodes() public view override returns (address[] memory) {
        uint256 count = 0;
        address[] memory _nodes = new address[](activeNodeCount);
        for (uint256 i = 0; i < nodeAddrs.length; i++) {
            if (nodes[nodeAddrs[i]] == uint8(1)) {
                _nodes[count] = nodeAddrs[i];
                count++;
            }
        }
        return _nodes;
    }

    /// @dev isNodeSake returns true if the node is churned in
    function isNodeStake(address _user) public view override returns (bool) {
        if (nodes[_user] == uint8(1)) {
            return true;
        }
        return false;
    }

    /// @dev _issueLPTokensForFloat
    /// @param _token The address of target token.
    /// @param _transaction The recevier address and amount.
    /// @param _txid The txid which is for recording.
    function _issueLPTokensForFloat(
        address _token,
        bytes32 _transaction,
        bytes32 _txid
    ) internal returns (bool) {
        require(!isTxUsed(_txid), "06"); //"The txid is already used");
        require(_transaction != 0x0, "07"); //"The transaction is not valid");
        // Define target address which is recorded on the tx data (20 bytes)
        // Define amountOfFloat which is recorded top on tx data (12 bytes)
        (address to, uint256 amountOfFloat) = _splitToValues(_transaction);
        // Calculate the amount of LP token
        uint256 nowPrice = getCurrentPriceLP();
        uint256 amountOfLP = amountOfFloat.mul(lpDivisor).div(nowPrice);
        // Send LP tokens to LP
        lpToken.mint(to, amountOfLP);
        // Add float amount
        _addFloat(_token, amountOfFloat);
        _addUsedTx(_txid);

        emit IssueLPTokensForFloat(
            to,
            amountOfFloat,
            amountOfLP,
            nowPrice,
            0,
            _txid
        );
        return true;
    }

    /// @dev _burnLPTokensForFloat
    /// @param _token The address of target token.
    /// @param _transaction The address of sender and amount.
    /// @param _minerFee The miner fees of BTC transaction.
    /// @param _txid The txid which is for recording.
    function _burnLPTokensForFloat(
        address _token,
        bytes32 _transaction,
        uint256 _minerFee,
        bytes32 _txid
    ) internal returns (bool) {
        require(!isTxUsed(_txid), "06"); //"The txid is already used");
        require(_transaction != 0x0, "07"); //"The transaction is not valid");
        // Define target address which is recorded on the tx data (20bytes)
        // Define amountLP which is recorded top on tx data (12bytes)
        (address to, uint256 amountOfLP) = _splitToValues(_transaction);
        // Calculate the amount of LP token
        uint256 nowPrice = getCurrentPriceLP();
        // Calculate the amountOfFloat
        uint256 amountOfFloat = amountOfLP.mul(nowPrice).div(lpDivisor);
        uint256 withdrawalFees = amountOfFloat.mul(withdrawalFeeBPS).div(10000);
        require(
            amountOfFloat.sub(withdrawalFees) >= _minerFee,
            "09" //"Error: amountOfFloat.sub(withdrawalFees) < _minerFee"
        );
        uint256 withdrawal = amountOfFloat.sub(withdrawalFees).sub(_minerFee);
        (uint256 reserveA, uint256 reserveB) = getFloatReserve(
            address(0),
            BTCT_ADDR
        );
        if (_token == address(0)) {
            require(
                reserveA >= amountOfFloat.sub(withdrawalFees),
                "08" //"The float balance insufficient."
            );
        } else if (_token == BTCT_ADDR) {
            require(
                reserveB >= amountOfFloat.sub(withdrawalFees),
                "12" //"BTC float amount insufficient"
            );
        }
        // Collect fees before remove float
        _rewardsCollection(_token, withdrawalFees);
        // Remove float amount
        _removeFloat(_token, amountOfFloat);
        // Add txid for recording.
        _addUsedTx(_txid);
        // BTCT transfer if token address is BTCT_ADDR
        if (_token == BTCT_ADDR) {
            // _minerFee should be zero
            _safeTransfer(_token, to, withdrawal);
        }
        // Burn LP tokens
        require(lpToken.burn(amountOfLP));
        emit BurnLPTokensForFloat(
            to,
            amountOfLP,
            amountOfFloat,
            nowPrice,
            withdrawal,
            _txid
        );
        return true;
    }

    /// @dev _addFloat updates one side of the float.
    /// @param _token The address of target token.
    /// @param _amount The amount of float.
    function _addFloat(address _token, uint256 _amount) internal {
        floatAmountOf[_token] = floatAmountOf[_token].add(_amount);
    }

    /// @dev _removeFloat remove one side of the float - redone for skypools using tokens mapping
    /// @param _token The address of target token.
    /// @param _amount The amount of float.
    function _removeFloat(address _token, uint256 _amount) internal {
        floatAmountOf[_token] = floatAmountOf[_token].sub(
            _amount,
            "10" //"_removeFloat: float amount insufficient"
        );
    }

    /// @dev _swap collects swap amount to change float.
    /// @param _sourceToken The address of source token
    /// @param _destToken The address of target token.
    /// @param _swapAmount The amount of swap.
    function _swap(
        address _sourceToken,
        address _destToken,
        uint256 _swapAmount
    ) internal {
        floatAmountOf[_destToken] = floatAmountOf[_destToken].sub(
            _swapAmount,
            "11" //"_swap: float amount insufficient"
        );
        floatAmountOf[_sourceToken] = floatAmountOf[_sourceToken].add(
            _swapAmount
        );

        emit Swap(_sourceToken, _destToken, _swapAmount);
    }

    /// @dev _safeTransfer executes tranfer erc20 tokens
    /// @param _token The address of target token
    /// @param _to The address of receiver.
    /// @param _amount The amount of transfer.
    function _safeTransfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        if (_token == BTCT_ADDR) {
            _amount = _amount.mul(convertScale);
        }
        IERC20(_token).safeTransfer(_to, _amount);
    }

    /// @dev _rewardsCollection collects tx rewards.
    /// @param _feesToken The token address for collection fees.
    /// @param _rewardsAmount The amount of rewards.
    function _rewardsCollection(
        address _feesToken,
        uint256 _rewardsAmount
    ) internal {
        if (_rewardsAmount == 0) return;
        // if (_feesToken == lpToken) {
        //     IBurnableToken(lpToken).transfer(sbBTCPool, _rewardsAmount);
        //     emit RewardsCollection(_feesToken, 0, _rewardsAmount, 0);
        //     return;
        // }

        // Get current LP token price.
        uint256 nowPrice = getCurrentPriceLP();
        // Add all fees into pool
        floatAmountOf[_feesToken] = floatAmountOf[_feesToken].add(
            _rewardsAmount
        );
        uint256 feesTotal = _rewardsAmount.mul(nodeRewardsRatio).div(100);
        // Alloc LP tokens for nodes as fees
        uint256 feesLPTTotal = feesTotal.mul(lpDivisor).div(nowPrice);
        // Alloc Buyback tokens for nodes as fees
        uint256 feesBuyback = feesLPTTotal.mul(buybackRewardsRatio).div(100);
        // Mints LP tokens for Nodes
        lpToken.mint(sbBTCPool, feesLPTTotal.sub(feesBuyback));
        lpToken.mint(buybackAddress, feesBuyback);

        emit RewardsCollection(
            _feesToken,
            _rewardsAmount,
            feesLPTTotal,
            nowPrice
        );
    }

    /// @dev _addUsedTx updates txid list which is spent. (single hash)
    /// @param _txid The array of txid.
    function _addUsedTx(bytes32 _txid) internal {
        used[_txid] = true;
    }

    /// @dev _addUsedTxs updates txid list which is spent. (multiple hashes)
    /// @param _txids The array of txid.
    function _addUsedTxs(bytes32[] memory _txids) internal {
        for (uint256 i = 0; i < _txids.length; i++) {
            used[_txids[i]] = true;
        }
    }

    /// @dev _splitToValues returns address and amount of staked SWINGBYs
    /// @param _data The info of a staker.
    function _splitToValues(
        bytes32 _data
    ) internal pure returns (address, uint256) {
        return (
            address(uint160(uint256(_data))),
            uint256(uint96(bytes12(_data)))
        );
    }
}