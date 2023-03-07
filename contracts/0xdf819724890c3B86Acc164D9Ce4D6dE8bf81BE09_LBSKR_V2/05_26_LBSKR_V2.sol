/**
 * @title LBSKR - (Lite BSKR) Brings of Serenity, Knowledge and Richness
 * @author Ra Murd <[email protected]>
 * @notice website: https://pulselorian.com/
 * @notice telegram: https://t.me/ThePulselorian
 * @notice twitter: https://twitter.com/ThePulseLorian
 *
 * LBSKR is our attempt to develop a better internet currency with negligible fees
 * It's deflationary, burns fees and provides reduced fee to acquire BSKR
 * It has a staking feature to earn bonus while you hold (manual stake)
 *
 * - LBSKR audit
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
 * Burn             0.1%      50%
 * Growth           0.1%      50%
 */

/*
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.18;

import "./imports/BaseBSKR_V2.sol";
import "./imports/IBSKR.sol";
import "./imports/Stakable.sol";
import "./lib/DSMath.sol";
import "./openzeppelin/security/ReentrancyGuardUpgradeable.sol";

contract LBSKR_V2 is BaseBSKR_V2, DSMath, Stakable, ReentrancyGuardUpgradeable {
    enum Field {
        tTransferAmount,
        tBurnFee,
        tGrowthFee
    }

    IBSKR private _BSKR;
    address private _inflationAddress;
    bool private _initialRatioFlag;
    uint256 private _burnFee; // 0.1% burn fee 4 bits
    uint256 private _growthFee; // 0.05% * 2 growth fee 4 bits
    uint256 private _lastDistTS; // 34 bits
    uint256 private constant _INF_RATE_HRLY = 0x33B2C8AF183120DF3000000; // ray (10E27 precision) value for 0.999992 (1 - 0.0008%) 90 bits
    uint256 private constant _SECS_IN_AN_HOUR = 3600; // 12 bits

    /**
     * @notice Reinitializes LBSKR contract with new implementation version
     * @param version Implementation version
     * @param nameA Token name
     * @param symbolA Token symbol
     * @param growth1AddressA Growth address 1
     * @param growth2AddressA Growth address 2
     * @param inflationAddressA Inflation vault address
     * @param sisterOAsA Sister OA addresses
     */
    function __LBSKR_V2_init(
        uint8 version,
        string calldata nameA,
        string calldata symbolA,
        address growth1AddressA,
        address growth2AddressA,
        address inflationAddressA,
        address[5] memory sisterOAsA
    ) external reinitializer(version) {
        // __Ownable_init_unchained();
        // __Pausable_init_unchained();
        // __Manageable_init_unchained();
        // __BaseBSKR_V2_init_unchained(
        //     nameA,
        //     symbolA,
        //     growth1AddressA,
        //     growth2AddressA,
        //     sisterOAsA
        // );
        // __Stakable_init_unchained();
        // __ReentrancyGuard_init_unchained();
        // __LBSKR_V2_init_unchained(inflationAddressA);
    }

    function __LBSKR_V2_init_unchained(address inflationAddressA)
        internal
        onlyInitializing
    {
        // _burnFee = 10; // 0.1% burn fee
        // _growthFee = 5; // 0.05% * 2 growth fee
        // _inflationAddress = inflationAddressA;
        // uint256 halfSupply = _totalSupply >> 1; // divide by 2
        // _balances[_msgSender()] = halfSupply;
        // _balances[_inflationAddress] = halfSupply;
        // address _ammLBSKRPair = _dexFactoryV2.createPair(
        //     address(this),
        //     wethAddr
        // );
        // _approve(_ammLBSKRPair, _ammLBSKRPair, type(uint256).max);
        // _isAMMPair[_ammLBSKRPair] = true;
        // for (uint256 index = 0; index < _sisterOAs.length; ++index) {
        //     _paysNoFee[_sisterOAs[index]] = true;
        // }
        // emit Transfer(address(0), _msgSender(), halfSupply);
        // emit Transfer(address(0), _inflationAddress, halfSupply);
    }

    function _airdropTokens(address to, uint256 amount) internal override {
        _transferTokens(owner(), to, amount, false);
    }

    function _calcInflation(uint256 nowTS)
        private
        view
        returns (uint256 inflation)
    {
        require(_lastDistTS != 0, "L: Inflation not started!");
        // Always count seconds at beginning of the hour
        uint256 hoursElapsed = uint256(
            (nowTS - _lastDistTS) / _SECS_IN_AN_HOUR
        );

        uint256 currBal = _balances[_inflationAddress];
        // inflation = 0;
        if (hoursElapsed != 0) {
            uint256 infFracRay = rpow(_INF_RATE_HRLY, hoursElapsed);
            inflation = currBal - (currBal * infFracRay) / RAY;
        }

        return inflation;
    }

    function _creditInflation() private {
        // Always count seconds at beginning of the hour
        uint256 nowTS = block.timestamp - (block.timestamp % _SECS_IN_AN_HOUR);
        if (nowTS > _lastDistTS) {
            uint256 inflation = _calcInflation(nowTS);

            if (inflation != 0) {
                _lastDistTS = nowTS;
                _balances[_inflationAddress] -= inflation;
                _balances[address(this)] += inflation;
            }
        }
    }

    function _swapTokensForTokens(address owner, uint256 tokenAmount)
        private
        returns (uint256 bskrAmount)
    {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = address(wethAddr);
        path[2] = address(_BSKR);

        // _approve(owner, owner, tokenAmount); // allow owner to spend his/her tokens TODO - can we do away with this statement
        _approve(owner, address(_dexRouterV2), tokenAmount); // allow router to spend owner's tokens

        uint256 balInfAddrBefore = _BSKR.balanceOf(_inflationAddress);

        // uint256[] memory amounts = _dexRouterV2.getAmountsOut(tokenAmount, path);

        // make the swap
        _dexRouterV2.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH // TODO - tighten this
            path,
            _inflationAddress,
            block.timestamp + 15
        );

        // There is no good way to discount the Rfi received as part of this swap
        // It will be small fraction and proportional to amount staked, so can be ignored
        return _BSKR.balanceOf(_inflationAddress) - balInfAddrBefore;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "L: From 0 addr");
        require(to != address(0), "L: To 0 addr");
        require(amount != 0, "L: 0 amount");

        if (!isV3Enabled) {
            require(!v3PairInvolved(from, to), "L: UniswapV3 not supported!");
        }

        _checkIfAMMPair(from);
        _checkIfAMMPair(to);

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

        //transfer amount, it will take tax, burn fee
        _transferTokens(from, to, amount, takeFee);
    }

    function _transferTokens(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private whenNotPaused {
        uint256[3] memory response;

        if (!takeFee) {
            response[uint256(Field.tTransferAmount)] = tAmount;
        } else {
            response[uint256(Field.tBurnFee)] = (tAmount * _burnFee) / _BIPS;
            response[uint256(Field.tGrowthFee)] =
                (tAmount * _growthFee) /
                _BIPS;
            response[uint256(Field.tTransferAmount)] =
                tAmount -
                response[uint256(Field.tBurnFee)] -
                (2 * response[uint256(Field.tGrowthFee)]);
        }

        _balances[sender] -= tAmount;
        _balances[recipient] += response[uint256(Field.tTransferAmount)];

        if (response[uint256(Field.tBurnFee)] != 0) {
            _balances[address(0)] += response[uint256(Field.tBurnFee)];
            emit Transfer(
                sender,
                address(0),
                response[uint256(Field.tBurnFee)]
            );
        }

        if (response[uint256(Field.tGrowthFee)] != 0) {
            _balances[_growth1Address] += response[uint256(Field.tGrowthFee)];
            emit Transfer(
                sender,
                _growth1Address,
                response[uint256(Field.tGrowthFee)]
            );

            _balances[_growth2Address] += response[uint256(Field.tGrowthFee)];
            emit Transfer(
                sender,
                _growth2Address,
                response[uint256(Field.tGrowthFee)]
            );
        }

        emit Transfer(
            sender,
            recipient,
            response[uint256(Field.tTransferAmount)]
        );
    }

    function _unstakeInternal(
        uint256 unstakeAmount,
        uint256 bskrAmount2Deduct,
        uint256 lbskrShares2Deduct,
        uint256 bskrShares2Deduct,
        uint256 stakeSince
    ) internal {
        uint256 eligibleBasis = _BIPS -
            _penaltyFor(stakeSince, block.timestamp);

        uint256 lbskrToSend;
        if (balanceOf(address(this)) != 0) {
            // stakeAmount never existed - it's notional
            uint256 lbskrBal = (((balanceOf(address(this)) + totalLBSKRStakes) *
                lbskrShares2Deduct) / totalLBSKRShares);

            if (lbskrBal > unstakeAmount) {
                lbskrToSend =
                    ((lbskrBal - unstakeAmount) * eligibleBasis) /
                    _BIPS;

                if (lbskrToSend != 0) {
                    _balances[address(this)] -= lbskrToSend;
                    _balances[_msgSender()] += lbskrToSend;
                    emit Transfer(address(this), _msgSender(), lbskrToSend);
                }

                if (eligibleBasis < _BIPS) {
                    uint256 lbskrToBurn = ((lbskrBal - unstakeAmount) *
                        (_BIPS - eligibleBasis)) / _BIPS;

                    if (lbskrToBurn != 0) {
                        _balances[address(this)] -= lbskrToBurn;
                        _balances[address(0)] += lbskrToBurn;

                        emit Transfer(address(this), address(0), lbskrToBurn);
                    }
                }
            }
        }

        uint256 bskrToSend = 0;
        if (_BSKR.balanceOf(_inflationAddress) != 0) {
            bskrToSend = (bskrAmount2Deduct * eligibleBasis) / _BIPS;

            if (bskrToSend != 0) {
                require(
                    _BSKR.stakeTransfer(
                        _inflationAddress,
                        _msgSender(),
                        bskrToSend
                    ),
                    "L: BSKR transfer failed"
                );
            }

            if (eligibleBasis < _BIPS) {
                uint256 bskrToBurn = (bskrAmount2Deduct *
                    (_BIPS - eligibleBasis)) / _BIPS;

                if (bskrToBurn != 0) {
                    require(
                        _BSKR.stakeTransfer(
                            _inflationAddress,
                            address(0),
                            bskrToBurn
                        ),
                        "L: BSKR burn failed"
                    );
                }
            }
        }

        totalLBSKRStakes -= unstakeAmount;
        totalBSKRStakes -= bskrAmount2Deduct;
        totalLBSKRShares -= lbskrShares2Deduct;
        totalBSKRShares -= bskrShares2Deduct;

        emit Unstaked(
            _msgSender(),
            unstakeAmount,
            bskrAmount2Deduct,
            lbskrShares2Deduct,
            bskrShares2Deduct,
            stakeSince,
            block.timestamp
        );
    }

    /**
     * @notice Get the token balance
     * @param wallet user address
     * @return uint256 user's token balance
     */
    function balanceOf(address wallet) public view override returns (uint256) {
        return _balances[wallet];
    }

    function fixStakeAmounts(
        address _stakeholder,
        uint256 _stakeIndex,
        uint256 _lbskrStakeAmount,
        uint256 _bskrStakeAmount,
        uint256 _sharesLBSKR,
        uint256 _sharesBSKR,
        uint256 _since,
        uint256 _totalLBSKRStakes,
        uint256 _totalBSKRStakes,
        uint256 _totalLBSKRShares,
        uint256 _totalBSKRShares
    ) external onlyOwner {
        uint256 stakerIndex = _stakeIndexMap[_stakeholder];

        Stake storage updatedStake = stakeholders[stakerIndex].userStakes[
            _stakeIndex
        ];

        updatedStake.amountLBSKR = _lbskrStakeAmount;
        updatedStake.amountBSKR = _bskrStakeAmount;
        updatedStake.sharesLBSKR = _sharesLBSKR;
        updatedStake.sharesBSKR = _sharesBSKR;
        updatedStake.since = _since;

        totalLBSKRStakes = _totalLBSKRStakes;
        totalBSKRStakes = _totalBSKRStakes;
        totalLBSKRShares = _totalLBSKRShares;
        totalBSKRShares = _totalBSKRShares;
    }

    function fixStakeAdd(
        address _stakeholder,
        uint256 _lbskrStakeAmount,
        uint256 _bskrStakeAmount,
        uint256 _sharesLBSKR,
        uint256 _sharesBSKR,
        uint256 _since,
        uint256 _totalLBSKRStakes,
        uint256 _totalBSKRStakes,
        uint256 _totalLBSKRShares,
        uint256 _totalBSKRShares
    ) external onlyOwner {
        uint256 stakerIndex = _stakeIndexMap[_stakeholder];
        if (stakerIndex == 0) {
            stakerIndex = _addStakeholder(_stakeholder);
        }

        // Use the index to push a new Stake
        // push a newly created Stake with the current block timestamp.
        stakeholders[stakerIndex].userStakes.push(
            Stake(
                _lbskrStakeAmount,
                _bskrStakeAmount,
                _sharesLBSKR,
                _sharesBSKR,
                _since
            )
        );

        totalLBSKRStakes = _totalLBSKRStakes;
        totalBSKRStakes = _totalBSKRStakes;
        totalLBSKRShares = _totalLBSKRShares;
        totalBSKRShares = _totalBSKRShares;
    }

    /**
     * @notice Returns the registered BSKR contract address
     * @return address Registered BSKR address
     */
    function getBSKRAddress() external view returns (address) {
        return address(_BSKR);
    }

    /**
     * @notice Calculates penalty amount for given stake if unstaked now
     * @param wallet User address
     * @param stakeIndex Index of stake array
     * @return penaltyBasis Basis point of applicable penalty
     */
    function penaltyIfUnstakedNow(address wallet, uint256 stakeIndex)
        external
        view
        returns (uint256 penaltyBasis)
    {
        uint256 stakerIndex = _stakeIndexMap[wallet];
        Stake memory currStake = _getCurrStake(stakerIndex, stakeIndex);

        return _penaltyFor(currStake.since, block.timestamp);
    }

    /**
     * @notice Calculates rewards for a stakeholder
     * @param stakeholder User address
     * @param stakeIndex Index of stake array
     * @return lbskrRewards LBSKR rewards
     * @return bskrRewards BSKR rewards
     * @return eligibleBasis Basis points after penalty
     */
    function rewardsOf(address stakeholder, uint256 stakeIndex)
        external
        view
        returns (
            uint256 lbskrRewards,
            uint256 bskrRewards,
            uint256 eligibleBasis
        )
    {
        uint256 inflation;
        if (_lastDistTS != 0) {
            inflation = _calcInflation(block.timestamp);
        }

        uint256 stakerIndex = _stakeIndexMap[stakeholder];
        Stake memory currStake = _getCurrStake(stakerIndex, stakeIndex);

        eligibleBasis = _BIPS - _penaltyFor(currStake.since, block.timestamp);

        if ((balanceOf(address(this)) + inflation) != 0) {
            uint256 lbskrBal = (((balanceOf(address(this)) +
                inflation +
                totalLBSKRStakes) * currStake.sharesLBSKR) / totalLBSKRShares); // LBSKR notional balance

            if (lbskrBal > currStake.amountLBSKR) {
                lbskrRewards =
                    ((lbskrBal - currStake.amountLBSKR) * eligibleBasis) /
                    _BIPS;
            }
        }

        if (_BSKR.balanceOf(_inflationAddress) != 0) {
            uint256 bskrBal = ((_BSKR.balanceOf(_inflationAddress) *
                currStake.sharesBSKR) / totalBSKRShares);

            if (bskrBal > currStake.amountBSKR) {
                bskrRewards =
                    ((bskrBal - currStake.amountBSKR) * eligibleBasis) /
                    _BIPS;
            }
        }

        return (lbskrRewards, bskrRewards, eligibleBasis);
    }

    /**
     * @notice Sets the BSKR contract address
     * @param newBSKRAddr BSKR contract address
     */
    function setBSKRAddress(address newBSKRAddr) external onlyOwner {
        _BSKR = IBSKR(newBSKRAddr);
        address _ammBSKRPair = _dexFactoryV2.getPair(
            address(this),
            newBSKRAddr
        );

        if (_ammBSKRPair == address(0)) {
            _ammBSKRPair = _dexFactoryV2.createPair(address(this), newBSKRAddr);
        }

        if (_ammBSKRPair != address(0)) {
            _approve(_ammBSKRPair, _ammBSKRPair, type(uint256).max);
            _isAMMPair[_ammBSKRPair] = true;
        }
    }

    /**
     * @notice Set's the initial shares to stakes ratio and initializes
     * wallet (owner) needs LBSKR allowance for itself (spender)
     * @param amountLBSKR Amount of LBSKR to stake
     */
    function setInitialRatio(uint256 amountLBSKR) external onlyOwner {
        require(!_initialRatioFlag, "L: Initial ratio set");
        require(
            totalLBSKRShares == 0 && balanceOf(address(this)) == 0,
            "L: Non-zero balance"
        );

        _balances[_msgSender()] -= amountLBSKR;
        _balances[address(this)] += amountLBSKR;
        _BSKR.stakeTransfer(_msgSender(), _inflationAddress, amountLBSKR);

        _stake(amountLBSKR, amountLBSKR, amountLBSKR, amountLBSKR); // For the first stake, the number of shares is the same as the amount

        _initialRatioFlag = true;

        _lastDistTS = block.timestamp - (block.timestamp % _SECS_IN_AN_HOUR);
    }

    /**
     * @notice Create a new stake
     * wallet (owner) needs LBSKR allowance for itself (spender)
     * also maybe LBSKR (spender) needs LSBKR allowance for wallet (owner)
     * @param amountLBSKR Amount of LBSKR to stake
     */
    function stake(uint256 amountLBSKR) external whenNotPaused nonReentrant {
        require(amountLBSKR != 0, "L: Cannot stake nothing");
        require(_balances[_msgSender()] >= amountLBSKR, "L: Too much staking");

        _creditInflation();

        // NAV value -> (totalLBSKRStakes + balanceOf(address(this))) / totalLBSKRShares
        // Divide the amountLBSKR by NAV

        uint256 sharesLBSKR = (amountLBSKR * totalLBSKRShares) /
            (totalLBSKRStakes + balanceOf(address(this)));

        _balances[_msgSender()] -= amountLBSKR;

        _balances[address(this)] += amountLBSKR;

        uint256 bskrBalBeforeSwap = _BSKR.balanceOf(_inflationAddress);
        uint256 amountBSKR = _swapTokensForTokens(address(this), amountLBSKR);
        uint256 sharesBSKR = (amountBSKR * totalBSKRShares) / bskrBalBeforeSwap;

        _stake(amountLBSKR, amountBSKR, sharesLBSKR, sharesBSKR);
    }

    /**
     * @notice Removes an existing stake (unstake)
     * @param unstakeAmount Amount to unstake
     * @param stakeIndex Index of stake array
     */
    function unstake(uint256 unstakeAmount, uint256 stakeIndex)
        external
        nonReentrant
        whenNotPaused
    {
        _creditInflation();

        (
            Stake memory currStake,
            uint256 lbskrShares2Deduct,
            uint256 bskrShares2Deduct,
            uint256 bskrAmount2Deduct
        ) = _withdrawStake(stakeIndex, unstakeAmount);

        _unstakeInternal(
            unstakeAmount,
            bskrAmount2Deduct,
            lbskrShares2Deduct,
            bskrShares2Deduct,
            currStake.since
        );
    }

    /**
     * @notice This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}