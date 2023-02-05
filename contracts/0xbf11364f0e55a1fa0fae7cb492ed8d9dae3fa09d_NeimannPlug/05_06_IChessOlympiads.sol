// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IChessOlympiads {
    function mintPlayerBadge(uint256 _tokenId) external payable returns (uint256 _badgeId);
    function mintButtPlugBadge(address _buttPlug) external returns (uint256 _badgeId);
    function mintMedal(uint256[] memory _badgeIds) external returns (uint256 _badgeId);
    function withdrawRewards(uint256 _badgeId) external;
    function withdrawStakedNft(uint256 _badgeId) external;
    function startEvent() external;
    function pushLiquidity() external;
    function unbondLiquidity() external;
    function withdrawLiquidity() external;
    function updateSpotPrice() external;
    function workable() external view returns (bool _workable);
    function executeMove() external;
    function voteButtPlug(address _buttPlug, uint256 _badgeId) external;
    function voteButtPlug(address _buttPlug, uint256[] memory _badgeIds) external;
    function isWhitelistedToken(uint256 _id) external view returns (bool _isWhitelisted);
}