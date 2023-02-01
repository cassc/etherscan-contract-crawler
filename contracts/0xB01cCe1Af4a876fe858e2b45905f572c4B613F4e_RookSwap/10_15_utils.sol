// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library LibSignatures
{
    /**
     * @dev Enumeration of supported signing schemes
     */
    enum Scheme
    {
        Eip712,
        EthSign,
        Eip1271,
        PreSign
    }
}

library LibData
{
    /**
     * @dev Data specific to this contract.
     */
    struct ContractData
    {
        uint256 surplusTokenBalance_before;
        uint256 surplusTokenBalance_after;
        uint256 otherTokenBalance_before;
    }

    /**
     * @dev Data specific to a maker.
     */
    struct MakerData
    {
        // Params we calculate
        bytes32 orderHash;
        uint256 takerTokenBalance_before;
        uint256 takerTokenBalance_after;
        // Params extracted from order.data
        uint256 begin;
        uint256 expiry;
        bool partiallyFillable;
        LibSignatures.Scheme signingScheme;
    }
}

library LibSwap
{
    /**
     * @dev DexAgg swap calldata.
     */
    struct DexAggSwap
    {
        address router;
        bytes callData;
        address approveToken;
        uint256 approvalAmount;
    }

    /**
     * @dev Metadata regarding the swap and how to handle surplus
     */
    struct MetaData
    {
        address surplusToken;
        uint256 surplusAmountWithheld;
        address otherToken;
        bool surplusTokenIsSwapTakerToken;
        TakerTokenDistributionType takerTokenDistributionType;
        uint256 surplusProtectionThreshold;
    }

    /**
     * @dev How to handle swap takerToken distribution
     */
    enum TakerTokenDistributionType
    {
        Even,
        Custom
    }
}

library LibBytes
{
    /**
     * @dev Convert bytes to uint256
     */
    function toUint256(
        bytes memory bytesToConvert,
        uint256 start
    )
        internal
        pure
        returns (uint256 convertedInt)
    {
        require(
            bytesToConvert.length >= start + 32,
            "RS:E11"
        );
        assembly
        {
            convertedInt := mload(add(add(bytesToConvert, 0x20), start))
        }
    }
}