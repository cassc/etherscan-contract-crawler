// SPDX-License-Identifier: Apache-2.0

/*
    Copyright 2022 0xPlasma Alliance
*/

/***
 *      ______             _______   __                                             
 *     /      \           |       \ |  \                                            
 *    |  $$$$$$\ __    __ | $$$$$$$\| $$  ______    _______  ______ ____    ______  
 *    | $$$\| $$|  \  /  \| $$__/ $$| $$ |      \  /       \|      \    \  |      \ 
 *    | $$$$\ $$ \$$\/  $$| $$    $$| $$  \$$$$$$\|  $$$$$$$| $$$$$$\$$$$\  \$$$$$$\
 *    | $$\$$\$$  >$$  $$ | $$$$$$$ | $$ /      $$ \$$    \ | $$ | $$ | $$ /      $$
 *    | $$_\$$$$ /  $$$$\ | $$      | $$|  $$$$$$$ _\$$$$$$\| $$ | $$ | $$|  $$$$$$$
 *     \$$  \$$$|  $$ \$$\| $$      | $$ \$$    $$|       $$| $$ | $$ | $$ \$$    $$
 *      \$$$$$$  \$$   \$$ \$$       \$$  \$$$$$$$ \$$$$$$$  \$$  \$$  \$$  \$$$$$$$
 *                                                                                  
 *                                                                                  
 *                                                                                  
 */
 

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0xPlasma/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";
import "../vendor/v3/IStaking.sol";
import "./FeeCollector.sol";
import "./LibFeeCollector.sol";


/// @dev A contract that manages `FeeCollector` contracts.
contract FeeCollectorController {

    /// @dev Hash of the fee collector init code.
    bytes32 public immutable FEE_COLLECTOR_INIT_CODE_HASH;
    /// @dev The WETH contract.
    IEtherTokenV06 private immutable WETH;
    /// @dev The staking contract.
    IStaking private immutable STAKING;

    constructor(
        IEtherTokenV06 weth,
        IStaking staking
    )
        public
    {
        FEE_COLLECTOR_INIT_CODE_HASH = keccak256(type(FeeCollector).creationCode);
        WETH = weth;
        STAKING = staking;
    }

    /// @dev Deploy (if needed) a `FeeCollector` contract for `poolId`
    ///      and wrap its ETH into WETH. Anyone may call this.
    /// @param poolId The pool ID associated with the staking pool.
    /// @return feeCollector The `FeeCollector` contract instance.
    function prepareFeeCollectorToPayFees(bytes32 poolId)
        external
        returns (FeeCollector feeCollector)
    {
        feeCollector = getFeeCollector(poolId);
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(feeCollector)
        }

        if (codeSize == 0) {
            // Create and initialize the contract if necessary.
            new FeeCollector{salt: bytes32(poolId)}();
            feeCollector.initialize(WETH, STAKING, poolId);
        }

        if (address(feeCollector).balance > 1) {
            feeCollector.convertToWeth(WETH);
        }

        return feeCollector;
    }

    /// @dev Get the `FeeCollector` contract for a given pool ID. The contract
    ///      will not actually exist until `prepareFeeCollectorToPayFees()`
    ///      has been called once.
    /// @param poolId The pool ID associated with the staking pool.
    /// @return feeCollector The `FeeCollector` contract instance.
    function getFeeCollector(bytes32 poolId)
        public
        view
        returns (FeeCollector feeCollector)
    {
        return FeeCollector(LibFeeCollector.getFeeCollectorAddress(
            address(this),
            FEE_COLLECTOR_INIT_CODE_HASH,
            poolId
        ));
    }
}