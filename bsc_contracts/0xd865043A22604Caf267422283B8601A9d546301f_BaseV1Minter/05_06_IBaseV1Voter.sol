// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IBaseV1Voter {

    function attachTokenToGauge(uint tokenId, address account) external;
    function detachTokenFromGauge(uint tokenId, address account) external;
    function emitDeposit(uint tokenId, address account, uint amount) external;
    function emitWithdraw(uint tokenId, address account, uint amount) external;
    function notifyRewardAmount(uint amount) external;
    function _ve() external view returns (address);
    function createGauge(address _pair) external returns (address);
    function factory() external view returns (address);
    function listing_fee() external view returns (uint);
    function whitelist(address _token) external;
    function isWhitelisted(address _token) external view returns (bool);
    function delist(address _token) external;
    function bribeFactory() external view returns (address);
    function bribes(address gauge) external view returns (address);
    function gauges(address pair) external view returns (address);
    function isGauge(address gauge) external view returns (bool);
    function allGauges(uint index) external view returns (address);
    function vote(uint tokenId, address[] calldata gaugeVote, uint[] calldata weights) external;
    function gaugeVote(uint tokenId) external view returns (address[] memory);
    function votes(uint tokenId, address gauge) external view returns (uint);
    function weights(address gauge) external view returns (uint);
    function usedWeights(uint tokenId) external view returns (uint);
    function claimable(address gauge) external view returns (uint);
    function totalWeight() external view returns (uint);
    function reset(uint _tokenId) external;
    function claimFees(address[] memory _fees, address[][] memory _tokens, uint _tokenId) external;
    function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint _tokenId) external;
    function distributeFees(address[] memory _gauges) external;
    function updateGauge(address _gauge) external;
    function poke(uint _tokenId) external;
    function initialize(address[] memory _tokens, address _minter) external;
    function minter() external view returns (address);
    function admin() external view returns (address);
    function claimRewards(address[] memory _gauges, address[][] memory _tokens) external;
    function isReward(address gauge, address token) external view returns (bool);
    function isBribe(address bribe, address token) external view returns (bool);
    function isLive(address gauge) external view returns (bool);
    function setBribe(address _bribe, address _token, bool _status) external;
    function setReward(address _gauge, address _token, bool _status) external;
    function killGauge(address _gauge) external;
    function reviveGauge(address _gauge) external;
    function distroFees() external;
    function distro() external;
    function distribute() external;
    function distribute(address _gauge) external;
    function distribute(uint start, uint finish) external;
    function distribute(address[] memory _gauges) external;
}