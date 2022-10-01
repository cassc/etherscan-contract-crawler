// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseGatewayEthereum {

    function initNftData(address _nft, address _poolA, address _poolC, bool _increaseable, uint256 _delta) external;

    function deposit(uint256 _tokenId) external payable;

    function batchDeposit(uint256 _idFrom, uint256 _offset) external payable;

    function baseValue(address _nft, uint256 _tokenId) external view returns (uint256, uint256);

    function tokenReward(address _nft, uint256 _tokenId) external view returns (uint256);

    function redeem(address _nft, uint256 _tokenId, bool _isToken0) external;

    function withdraw(address _to) external;

    function withdrawWithERC20(address _token, address _to) external;

    function setPoolBalances(address pool, uint256 amount) external;

    function investWithERC20(address pool, bool isToken0, uint256 minReceivedTokenAmountSwap) external;

    function getReward(address pool) external;

    function setWeightPowerMaximum (uint256 _weight) external;

    function setVRFConsumer(address vrf) external;

    function setRandomPrizeWinners(address nft, uint256 totalWinner, uint256 prizePerWinner) external;

    function getWinnerBoard(uint256 requestId, address nft) external returns (uint256[] memory);

    function setWinnerBoard(uint256 requestId, address nft, uint256[] memory ids) external;

    function complementWinner(address nft, uint256 id, uint256 prizePerWinner) external;

    function complementAndSetWinner(address nft, uint256 id, uint256 prizePerWinner) external;

    function setHotpotPoolToCurvePool(address hotpotPoolAddress, address curvePoolAddress) external;

    function getHotpotPoolToCurvePool(address hotpotPoolAddress) external returns (address);
}