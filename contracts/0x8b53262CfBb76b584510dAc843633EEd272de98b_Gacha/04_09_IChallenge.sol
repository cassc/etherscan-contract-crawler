// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IChallenge {
    //It returns the goal of the challenge.
    function goal() external view returns(uint256);

    //It returns the duration of the challenge.
    function duration() external view returns(uint256);

    //It returns the history of the challenge.
    function getChallengeHistory() external view returns(uint256[] memory date, uint256[] memory data);

    //It returns the number of days required to complete the challenge.
    function dayRequired() external view returns(uint256);

    //It returns the total balance of the base token.
    function totalReward() external view returns(uint256);

    //It returns the balance of the token.
    function getBalanceToken() external view returns(uint256[] memory);

    function allowGiveUp(uint256 _index) external view returns(bool);

    function donationWalletAddress() external view returns(address);

    function getAwardReceiversPercent() external view returns(uint256[] memory);

    function challenger() external view returns(address);

    function getAwardReceiversAtIndex(uint256 _index, bool _isAddressSuccess) external view returns(address);

    function isFinished() external view returns(bool);

    function erc721Address(uint256 _index) external view returns(address);

    function nextTokenIdToMint() external view returns(uint256);

    function ownerOf(uint256 _tokenIndex) external view returns(address);

    function safeMintNFT721Heper(address _tokenAddress, address _challengerAddress) external;

    function safeMintNFT1155Heper(
        address _tokenAddress, 
        address _challengerAddress,
        uint256 _indexToken,
        uint256 _rewardToken
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}