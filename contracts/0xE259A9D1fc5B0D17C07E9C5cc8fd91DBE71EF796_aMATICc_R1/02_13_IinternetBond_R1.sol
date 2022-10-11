// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

interface IinternetBond_R1 {

    event CertTokenChanged(address oldCertToken, address newCertToken);

    event SwapFeeOperatorChanged(address oldSwapFeeOperator, address newSwapFeeOperator);

    event SwapFeeRatioUpdate(uint256 newSwapFeeRatio);

    function balanceToShares(uint256 bonds) external view returns (uint256);

    function burn(address account, uint256 amount) external;

    function changeCertToken(address newCertToken) external;

    function changeSwapFeeOperator(address newSwapFeeOperator) external;

    function commitDelayedBurn(address account, uint256 amount) external;

    function getSwapFeeInBonds(uint256 bonds) external view returns(uint256);

    function getSwapFeeInShares(uint256 shares) external view returns(uint256);

    function lockForDelayedBurn(address account, uint256 amount) external;

    function lockShares(uint256 shares) external;

    function lockSharesFor(address account, uint256 shares) external;

    function mintBonds(address account, uint256 amount) external;

    function pendingBurn(address account) external view returns (uint256);

    function ratio() external view returns (uint256);

    function sharesOf(address account) external view returns (uint256);

    function sharesToBalance(uint256 shares) external view returns (uint256);

    function totalSharesSupply() external view returns (uint256);

    function unlockShares(uint256 shares) external;

    function unlockSharesFor(address account, uint256 bonds) external;

    function updateSwapFeeRatio(uint256 newSwapFeeRatio) external;
}