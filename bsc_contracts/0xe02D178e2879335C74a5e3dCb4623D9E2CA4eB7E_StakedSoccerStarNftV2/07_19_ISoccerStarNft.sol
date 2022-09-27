// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface ISoccerStarNft {

     struct SoccerStar {
        string name;
        string country;
        string position;
        // range [1,4]
        uint256 starLevel;
        // range [1,4]
        uint256 gradient;
    }

    // roud->timeInfo
    struct TimeInfo {
        uint startTime;
        uint endTime;
        uint revealTime;
    }

    enum BlindBoxesType {
        presale,
        normal,
        supers,
        legend
    }

    enum PayMethod{
        PAY_BIB,
        PAY_BUSD
    }

    event Mint(
        address newAddress, 
        uint rount,
        BlindBoxesType blindBoxes, 
        uint256 tokenIdSt, 
        uint256 quantity, 
        PayMethod payMethod, 
        uint sales);
        
    function updateStarlevel(uint tokenId, uint starLevel) external;

    // whitelist functions
    function addUserQuotaPreRoundBatch(address[] memory users,uint[] memory quotas) external;
    function setUserQuotaPreRound(address user, uint quota) external;
    function getUserRemainningQuotaPreRound(address user) external view returns(uint);
    function getUserQuotaPreRound(address user) external view returns(uint);

    function getCardProperty(uint256 tokenId) external view returns(SoccerStar memory);

    // BUSD quota
    function setBUSDQuotaPerPubRound(uint round, uint quota) external;
    function getBUSDQuotaPerPubRound(uint round) external view returns(uint);
    function getBUSDUsedQuotaPerPubRound(uint round) external view returns(uint);

    // only allow protocol related contract to mint
    function protocolMint() external returns(uint tokenId);

    // only allow protocol related contract to mint to burn
    function protocolBurn(uint tokenId) external;

    // only allow protocol related contract to bind star property
    function protocolBind(uint tokenId, SoccerStar memory soccerStar) external;
}