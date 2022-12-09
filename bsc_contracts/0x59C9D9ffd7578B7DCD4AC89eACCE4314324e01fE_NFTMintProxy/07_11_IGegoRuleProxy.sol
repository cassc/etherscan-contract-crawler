// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.4;

pragma experimental ABIEncoderV2;

import "./INFTSignature.sol";


interface IGegoRuleProxy  {

    struct Cost721Asset{
        uint256 costErc721Id1;
        uint256 costErc721Id2;
        uint256 costErc721Id3;

        address costErc721Origin;
    }

    struct MintParams{
        address user;
        uint256 amount;
        uint256 ruleId;
        bool fromAdmin;
    }

    function takeFee(
        INFTSignature.Gego calldata gego,
        uint256 feeAmount,
        address receipt
    ) external returns (address);

    function cost( MintParams calldata params) external returns (
        uint256 mintAmount,
        address mintErc20
    );

    function costMultiple(MintParams calldata params, uint256 quantity) external returns (
        address mintErc20
    );

    function inject( MintParams calldata params, uint256 currentAmount) external returns (
        uint256 injectedAmount,
        address mintErc20,
        uint256 expiringDuration
    );

    function generate( address user,uint256 ruleId, uint256 randomNonce ) external view returns ( INFTSignature.Gego memory gego );

}