// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;


interface IMintingoCollection {

function reveal(uint256[] memory  _winners, uint256[] memory  tiers, string memory  revealed_uri) external ;
function mint(uint256 _mintAmount, address coin, address user, address payable _referrer) external;

function setVariables(uint256 _start_block, uint256 _expiration, uint256 _supply,
        string memory _initNotRevealedUri) external;

function set_referral(uint _decimals,
    uint _referralBonus,
    uint _secondsUntilInactive,
    bool _onlyRewardActiveReferrers,
    uint256[] memory _levelRate,
    uint256[] memory _refereeBonusRateMap) external;

}