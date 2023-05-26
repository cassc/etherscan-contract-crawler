pragma solidity ^0.8.15;

import './BasicType.sol';

interface BigBroOracle is BBTy {
    function riskRequest (
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _quantity
    ) external;

    function bigBroGuardState(
        address erc721
    ) external view returns(bool);

    function queryBlackList(
        address _operator
    ) external view returns(SAFEIDX);
}