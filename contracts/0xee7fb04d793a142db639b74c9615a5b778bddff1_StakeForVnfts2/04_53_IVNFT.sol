pragma solidity ^0.6.0;

interface IVNFT {
    // function ownerOf(uint256 _tokenId) external view returns (address _owner);

    function totalSupply() external view returns (uint256);

    function fatality(uint256 _deadId, uint256 _tokenId) external;

    function buyAccesory(uint256 nftId, uint256 itemId) external;

    function claimMiningRewards(uint256 nftId) external;

    function addCareTaker(uint256 _tokenId, address _careTaker) external;

    function careTaker(uint256 _tokenId, address _user)
        external
        view
        returns (address _careTaker);

    function ownerOf(uint256 _tokenId) external view returns (address _owner);

    function itemPrice(uint256 itemId) external view returns (uint256 _amount);

    function timeUntilStarving(uint256 _tokenId)
        external
        view
        returns (uint256 _time);

    function lastTimeMined(uint256 _tokenId)
        external
        view
        returns (uint256 _time);

    function vnftScore(uint256 _tokenId) external view returns (uint256 _score);

    function vnftScore(uint256 _tokenId, address)
        external
        view
        returns (uint256 _score);
}