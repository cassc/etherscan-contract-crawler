// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./AbstractApeStakingStrategy.sol";

contract BAYCApeStakingStrategy is AbstractApeStakingStrategy {
    function _depositSelector() internal pure override returns (bytes4) {
        return IApeStaking.depositBAYC.selector;
    }

    function _withdrawSelector() internal pure override returns (bytes4) {
        return IApeStaking.withdrawBAYC.selector;
    }

    function _claimSelector() internal pure override returns (bytes4) {
        return IApeStaking.claimBAYC.selector;
    }

    function _depositBAKCCalldata(
        IApeStaking.PairNftDepositWithAmount[] calldata _nfts
    ) internal pure override returns (bytes memory) {
        return
            abi.encodeWithSelector(
                IApeStaking.depositBAKC.selector,
                _nfts,
                new IApeStaking.PairNftDepositWithAmount[](0)
            );
    }

    function _withdrawBAKCCalldata(IApeStaking.PairNftWithdrawWithAmount[] memory _nfts)
        internal
        pure
        override
        returns (bytes memory)
    {
        return
            abi.encodeWithSelector(
                IApeStaking.withdrawBAKC.selector,
                _nfts,
                new IApeStaking.PairNftWithdrawWithAmount[](0)
            );
    }

    function _claimBAKCCalldata(
        IApeStaking.PairNft[] memory _nfts,
        address _recipient
    ) internal pure override returns (bytes memory) {
        return
            abi.encodeWithSelector(
                IApeStaking.claimBAKC.selector,
                _nfts,
                new IApeStaking.PairNft[](0),
                _recipient
            );
    }
}