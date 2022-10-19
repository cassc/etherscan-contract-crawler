// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


interface IIVO{

    function getReferralCount(address _address) external view returns (uint256);

    function getReferralReward(address _address) external view returns (uint256);

    function getLastReceiveIvoTime(address _address) external view returns (uint256);

    function isWzNftList(address _address) external view returns (bool);

    function isReceiveWzNft(address _address) external view returns (bool);

    function isMemberIvo(address _address) external  view returns (bool);

    function isShareholderIvo(address _address) external  view returns (bool);

    function canIvo(address _address, bool _isMember)
        external
        view
        returns (bool);

    function isIvo(address _account) external view returns (bool);

    function canReceiveReward(address _address) external view returns (bool);

    function canReceiveWzNft(address _address) external view returns (bool) ;

    function canReceiveIvo(address _address) external view returns (bool) ;

    function getIvoReceiveAmount(address _address)
        external
        view
        returns (uint256);

    function getIvoBalance(address _address) external view returns (uint256);

    function getIvoAmount(address _address) external view returns (uint256);

    function getIvoFee(bool _isMember) external view returns (uint256);

    function receiveReward() external;

    function receiveWzNft() external;

    function receiveIvo() external;
}