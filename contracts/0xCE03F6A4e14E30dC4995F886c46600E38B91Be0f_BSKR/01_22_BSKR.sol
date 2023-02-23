/**
 *
 * @title BSKR - Brings Serenity, Knowledge and Richness
 * @author Ra Murd <[email protected]>
 * @notice website: https://pulselorian.com/
 * @notice telegram: https://t.me/ThePulselorian
 * @notice twitter: https://twitter.com/ThePulseLorian
 *
 * BSKR is our attempt to develop a better internet currency
 * It's deflationary, burns some fees, reflects some fees and adds some fees to liquidity pool
 * It may also pay quarterly bonus to net buyers
 *
 * - BSKR audit
 *      <TODO Audit report link to be added here>
 *
 *
 *    (   (  (  (     (   (( (   .  (   (    (( (   ((
 *    )\  )\ )\ )\    )\ (\())\   . )\  )\   ))\)\  ))\
 *   ((_)((_)(_)(_)  ((_))(_)(_)   ((_)((_)(((_)_()((_)))
 *   | _ \ | | | |  / __| __| |   / _ \| _ \_ _|   \ \| |
 *   |  _/ |_| | |__\__ \ _|| |__| (_) |   /| || - | .  |
 *   |_|  \___/|____|___/___|____|\___/|_|_\___|_|_|_|\_|
 *
 * Tokenomics:
 *
 * Reflection       2.0%      36.36%
 * Burn             1.5%      27.27%
 * Growth           1.0%      18.18%
 * Liquidity        0.5%       9.09%
 * Payday           0.5%       9.09%
 */

/*
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.18;

import "./imports/BaseBSKR.sol";

contract BSKR is BaseBSKR {
    enum Field {
        tTransferAmount,
        rAmount,
        rTransferAmount,
        tRfiFee,
        tBurnFee,
        tOtherFees, // Growth1, Growth2, Payday & LP fees are all 0.5%
        rRfiFee,
        rBurnFee,
        rOtherFees
    }

    enum Fees {
        RfiFee, // 200 or 2.0%
        BurnFee, // 150 or 1.5%
        OtherFees, // 50 * 4 or 0.5% * 4
        GrossFees // 550 or 5.5%
    }

    address private _LBSKRAddr; // needs this address to provide discounts
    address private _ammBSKRPair; // BSKR-ETH pair address
    address private _paydayAddress;
    address[] private _noRfi;
    bool private _addLPEnabled;
    bool private _addingLiquidity;
    mapping(address => bool) private _getsNoRfi;
    mapping(address => bool) private _isMyTokensPair;
    mapping(address => uint256) private _rBalances;
    uint256 private _rTotal; // 40 bits
    uint256 private _max_tx_amount; // 40 million - 4% of the total supply // 40 bits
    uint256 private _num_tokens_for_lp; // 1 million - 0.1% of the total supply // 40 bits
    uint256 private totalReflection; // 40 bits
    uint32[4] private _currFees; // 16x6 bits

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event AddLPEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    /**
     * @notice Initializes BSKR contract with first implementation version
     * @param nameA Token name
     * @param symbolA Token symbol
     * @param growth1AddressA Growth address 1
     * @param growth2AddressA Growth address 2
     * @param paydayAddressA Payday address
     * @param lbskrAddrA LBSKR address
     * @param sisterOAsA Sister OA addresses
     */
    function __BSKR_init(
        string calldata nameA,
        string calldata symbolA,
        address growth1AddressA,
        address growth2AddressA,
        address paydayAddressA,
        address lbskrAddrA,
        address[5] memory sisterOAsA
    ) external initializer {
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __Manageable_init_unchained();
        __BaseBSKR_init_unchained(
            nameA,
            symbolA,
            growth1AddressA,
            growth2AddressA,
            sisterOAsA
        );
        __BSKR_init_unchained(paydayAddressA, lbskrAddrA);
    }

    function __BSKR_init_unchained(address paydayAddressA, address lbskrAddrA)
        internal
        onlyInitializing
    {
        _max_tx_amount = 0x2116545850052128000000; // 40 million
        _num_tokens_for_lp = 0xD3C21BCECCEDA1000000; // 1 million

        _addLPEnabled = true;
        _rTotal = (type(uint256).max - (type(uint256).max % _totalSupply));
        _currFees = [200, 150, 50, 550];
        _paydayAddress = paydayAddressA;
        _LBSKRAddr = lbskrAddrA;

        _rBalances[_msgSender()] = _rTotal;
        _balances[_msgSender()] = _totalSupply;

        _ammBSKRPair = _dexFactoryV2.createPair(address(this), wethAddr);
        _approve(_ammBSKRPair, _ammBSKRPair, type(uint256).max);
        _isAMMPair[_ammBSKRPair] = true;
        _setNoRfi(_ammBSKRPair);

        address _ammLBSKRPair = _dexFactoryV2.createPair(
            address(this),
            _LBSKRAddr
        );
        _approve(_ammLBSKRPair, _ammLBSKRPair, type(uint256).max);
        _isAMMPair[_ammLBSKRPair] = true;
        _setNoRfi(_ammLBSKRPair);

        for (uint256 index = 0; index < _sisterOAs.length; ++index) {
            _paysNoFee[_sisterOAs[index]] = true;
            _setNoRfi(_sisterOAs[index]);
        }

        _setNoRfi(_msgSender());
        _setNoRfi(address(this));
        _setNoRfi(_paydayAddress);
        _setNoRfi(_ammBSKRPair);
        _setNoRfi(_ammLBSKRPair);
        _setNoRfi(address(0));

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function _airdropTokens(address to, uint256 amount) internal override {
        _transferTokens(
            owner(),
            to,
            amount,
            false,
            true, // owner does not get Rfi
            _getsNoRfi[to]
        );
    }

    function _getRate() private view returns (uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _totalSupply;
        for (uint256 index = 0; index < _noRfi.length; ++index) {
            if (
                _rBalances[_noRfi[index]] > rSupply ||
                _balances[_noRfi[index]] > tSupply
            ) return (_rTotal / _totalSupply);
            rSupply -= _rBalances[_noRfi[index]];
            tSupply -= _balances[_noRfi[index]];
        }
        if (rSupply < _rTotal / _totalSupply) return (_rTotal / _totalSupply);
        return rSupply / tSupply;
    }

    function _getValues(uint256 tAmount, uint256 feeMultiplier)
        private
        view
        returns (uint256[9] memory response)
    {
        uint256 currentRate = _getRate();
        response[uint256(Field.rAmount)] = (tAmount * currentRate);

        if (feeMultiplier == 0) {
            response[uint256(Field.tTransferAmount)] = tAmount;
            response[uint256(Field.rTransferAmount)] = tAmount * currentRate;
        } else {
            response[uint256(Field.tRfiFee)] =
                (((tAmount * _currFees[uint256(Fees.RfiFee)]) / _BIPS) *
                    feeMultiplier) /
                10;
            response[uint256(Field.tBurnFee)] =
                (((tAmount * _currFees[uint256(Fees.BurnFee)]) / _BIPS) *
                    feeMultiplier) /
                10;
            response[uint256(Field.tOtherFees)] =
                (((tAmount * _currFees[uint256(Fees.OtherFees)]) / _BIPS) *
                    feeMultiplier) /
                10;
            response[uint256(Field.tTransferAmount)] =
                tAmount -
                ((((tAmount * _currFees[uint256(Fees.GrossFees)]) / _BIPS) *
                    feeMultiplier) / 10);

            response[uint256(Field.rRfiFee)] = (response[
                uint256(Field.tRfiFee)
            ] * currentRate);
            response[uint256(Field.rBurnFee)] = (response[
                uint256(Field.tBurnFee)
            ] * currentRate);
            response[uint256(Field.rOtherFees)] = (response[
                uint256(Field.tOtherFees)
            ] * currentRate);
            response[uint256(Field.rTransferAmount)] = (response[
                uint256(Field.tTransferAmount)
            ] * currentRate);
        }

        return (response);
    }

    function _isLBSKRPair(address target) internal returns (bool) {
        if (_isAMMPair[target]) {
            if (_isMyTokensPair[target]) {
                return true;
            }
            address token0 = _getToken0(target);

            if (token0 == _LBSKRAddr) {
                _isMyTokensPair[target] = true;
                return true;
            }
            address token1 = _getToken1(target);

            if (token1 == _LBSKRAddr) {
                _isMyTokensPair[target] = true;
                return true;
            }
        }

        return false;
    }

    function _setNoRfi(address wallet) private {
        if (!_getsNoRfi[wallet]) {
            _getsNoRfi[wallet] = true;
            _noRfi.push(wallet);
        }
    }

    function _takeFee(
        address target,
        uint256 tFee,
        uint256 rFee
    ) private {
        _rBalances[target] += rFee;
        if (_getsNoRfi[target]) _balances[target] += tFee;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        require(from != address(0), "B: From 0 addr");
        require(to != address(0), "B: To 0 addr");
        require(amount != 0, "B: 0 amount");

        if (from != owner() && to != owner()) {
            require(amount <= _max_tx_amount, "B: Exceeds max tx");
        }

        if (!isV3Enabled) {
            require(!v3PairInvolved(from, to), "B: UniV3 not supported!");
        }

        _checkIfAMMPair(from);
        if (_isAMMPair[from]) {
            _setNoRfi(from);
        }
        _checkIfAMMPair(to);
        if (_isAMMPair[to]) {
            _setNoRfi(to);
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        /* is the token balance of this contract address over the min number of
         * tokens that we need to initiate a swap + liquidity lock?
         * also, don't get caught in a circular liquidity event.
         * also, don't swap & liquify if sender is uniswap pair (Buy transaction).
         */
        if (
            (contractTokenBalance >= _num_tokens_for_lp) &&
            !_addingLiquidity &&
            from != _ammBSKRPair &&
            _addLPEnabled
        ) {
            _addingLiquidity = true;

            /* split the contract balance into halves */
            uint256 amount2Eth = _num_tokens_for_lp >> 1; // divide by 2
            uint256 tokenAmount = _num_tokens_for_lp - amount2Eth;

            /* Check balance before swap */
            uint256 initialBalance = address(this).balance;

            /* swap tokens for ETH */
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = wethAddr;

            _approve(address(this), address(this), amount2Eth); // allow address(this) to spend its tokens
            _approve(address(this), address(_dexRouterV2), amount2Eth);

            _dexRouterV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount2Eth,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp + 15
            );

            /* Determine ETH from the swap */
            uint256 ethAmount = address(this).balance - initialBalance;

            /* add liquidity to uniswap */
            _approve(address(this), address(_dexRouterV2), tokenAmount);

            _dexRouterV2.addLiquidityETH{value: ethAmount}(
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                _getOriginAddress(),
                block.timestamp + 15
            );

            // Prevent ETH dust from getting locked in the contract forever
            (bool success, ) = owner().call{value: address(this).balance}("");
            if (success) {
                // do nothing - it's not a must that transfer succeeds
            }

            emit SwapAndLiquify(amount2Eth, ethAmount, tokenAmount);
            _addingLiquidity = false;
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any wallet belongs to _paysNoFee wallet then remove the fee
        if (_paysNoFee[from] || _paysNoFee[to]) {
            takeFee = false;
        }

        if (!_isAMMPair[from] && !_isAMMPair[to]) {
            // simple transfer not buy/sell, take no fees
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _transferTokens(
            from,
            to,
            amount,
            takeFee,
            _getsNoRfi[from],
            _getsNoRfi[to]
        );
    }

    function _transferTokens(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        bool senderExcluded,
        bool recipientExcluded
    ) private {
        uint256 reducedFees = 10;

        if (!takeFee) {
            reducedFees = 0;
        } else if (_isLBSKRPair(sender) || _isLBSKRPair(recipient)) {
            reducedFees = 5;
        }

        uint256[9] memory response = _getValues(tAmount, reducedFees);

        if (senderExcluded) {
            _balances[sender] -= tAmount;
        }
        _rBalances[sender] -= response[uint256(Field.rAmount)];

        if (recipientExcluded) {
            _balances[recipient] += response[uint256(Field.tTransferAmount)];
        }
        _rBalances[recipient] += response[uint256(Field.rTransferAmount)];

        if (response[uint256(Field.tRfiFee)] != 0) {
            _rTotal -= response[uint256(Field.rRfiFee)];
            totalReflection += response[uint256(Field.tRfiFee)];
            // cannot emit transfer event
        }

        uint256 _tBurnFee_ = response[uint256(Field.tBurnFee)];
        if (_tBurnFee_ != 0) {
            _takeFee(address(0), _tBurnFee_, response[uint256(Field.rBurnFee)]);
            emit Transfer(sender, address(0), _tBurnFee_);
        }

        uint256 _tOtherFees_ = response[uint256(Field.tOtherFees)];
        if (_tOtherFees_ != 0) {
            uint256 _rOtherFees_ = response[uint256(Field.rOtherFees)];
            _takeFee(_growth1Address, _tOtherFees_, _rOtherFees_); // Half Growth Fee
            emit Transfer(sender, _growth1Address, _tOtherFees_);

            _takeFee(_growth2Address, _tOtherFees_, _rOtherFees_); // Half Growth Fee
            emit Transfer(sender, _growth2Address, _tOtherFees_);

            _takeFee(_paydayAddress, _tOtherFees_, _rOtherFees_); // Payday Fee
            emit Transfer(sender, _paydayAddress, _tOtherFees_);

            _takeFee(address(this), _tOtherFees_, _rOtherFees_); // LP Fee
            emit Transfer(sender, address(this), _tOtherFees_);
        }

        emit Transfer(
            sender,
            recipient,
            response[uint256(Field.tTransferAmount)]
        );
    }

    /**
     * Calculates the wallet balance taking into wallet Rfi received
     * @param wallet user address
     * @return uint256 user's token balance
     */
    function balanceOf(address wallet) public view override returns (uint256) {
        if (_getsNoRfi[wallet]) return _balances[wallet];

        require(_rBalances[wallet] <= _rTotal, "B: Amount too large");
        uint256 currentRate = _getRate();
        return _rBalances[wallet] / currentRate;
    }

    /**
     * @notice Gift reflection to the BSKR community
     * @param tAmount amount to gift
     */
    function giftReflection(uint256 tAmount) external whenNotPaused {
        require(tAmount != 0, "B: Zero gift amount");
        address sender = _msgSender();
        require(!_getsNoRfi[sender], "B: Excluded wallet");
        uint256[9] memory response = _getValues(tAmount, 10);
        require(
            _rBalances[sender] > response[uint256(Field.rAmount)],
            "B: Gift too large"
        );
        _rBalances[sender] -= response[uint256(Field.rAmount)];
        _rTotal -= response[uint256(Field.rAmount)];
        totalReflection += tAmount;
    }

    /**
     * @notice Enable or disable auto liquidity feature - for manager only in case of issues
     * @param _enabled true/false to enable or disable swap and liquify
     */
    function setSwapAndLiquifyEnabled(bool _enabled) external onlyManager {
        _addLPEnabled = _enabled;
        emit AddLPEnabledUpdated(_enabled);
    }

    /**
     * @notice Transfer the unstaked token while unstaking.
     * @param from Sender address
     * @param to Receiver address
     * @param amount Amount to transfer
     * @return bool flag indicating that transfer completed
     * Only LBSKR contract may call this function
     */
    function stakeTransfer(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(msg.sender == _LBSKRAddr);
        _transferTokens(
            from,
            to,
            amount,
            false,
            _getsNoRfi[from],
            _getsNoRfi[to]
        );
        return true;
    }

    /**
     * @notice This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}