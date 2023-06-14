pragma solidity 0.7.5;
pragma abicoder v2;

import "./IRouter.sol";
import "../lib/UtilsNFT.sol";

interface IRouterNFT is IRouter {
    event BoughtNFTV3(
        bytes16 uuid,
        address partner,
        uint256 feePercent,
        address initiator,
        address indexed beneficiary,
        address indexed srcToken,
        UtilsNFT.ToTokenNFTDetails[] destTokenDetails,
        uint256 srcAmount,
        uint256 expectedAmount
    );
}