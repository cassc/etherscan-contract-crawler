// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./AbstractApeStakingStrategy.sol";

contract MAYCApeStakingStrategy is AbstractApeStakingStrategy {
    
    function _depositSelector() internal override pure returns (bytes4) {
        return IApeStaking.depositMAYC.selector;
    }

    function _withdrawSelector() internal override pure returns (bytes4) {
        return IApeStaking.withdrawMAYC.selector;
    }

    function _claimSelector() internal override pure returns (bytes4) {
        return IApeStaking.claimMAYC.selector;
    }

    function _depositBAKCCalldata(
        IApeStaking.PairNftDepositWithAmount[] calldata _nfts
    ) internal pure override returns (bytes memory) {
        return
            abi.encodeWithSelector(
                IApeStaking.depositBAKC.selector,
                new IApeStaking.PairNftDepositWithAmount[](0),
                _nfts
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
                new IApeStaking.PairNftWithdrawWithAmount[](0),
                _nfts
            );
    }

    function _claimBAKCCalldata(
        IApeStaking.PairNft[] memory _nfts,
        address _recipient
    ) internal pure override returns (bytes memory) {
        return
            abi.encodeWithSelector(
                IApeStaking.claimBAKC.selector,
                new IApeStaking.PairNft[](0),
                _nfts,
                _recipient
            );
    }
}