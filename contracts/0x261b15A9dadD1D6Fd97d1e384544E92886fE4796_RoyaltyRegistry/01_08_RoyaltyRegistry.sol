// SingleNFT Auction Contract
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IERC721NFT.sol";

contract RoyaltyRegistry is Ownable {
    uint256 public constant MAX_ROYALTY_PERCENT = 5000; // 50%

    mapping(address => uint256) public _collectionRoyalties;
    mapping(address => address) public _collectionCreators;

    event NFTRegistered(address collection);

    constructor() {
        _transferOwnership(msg.sender);
    }

    function emergencyWithdrawToken(
        address token_,
        address to_,
        uint256 amount_
    ) public onlyOwner {
        SafeERC20.safeTransfer(IERC20(token_), to_, amount_);
    }

    function emergencyWithdrawCoin(
        address payable to_,
        uint256 amount_
    ) public onlyOwner {
        (bool result, ) = to_.call{value: amount_}("");
        require(result, "withdraw failed");
    }

    function registerERC721(address _collectionAddr) external onlyOwner {
        emit NFTRegistered(_collectionAddr);
    }

    function setCollectionRoyalty(
        address _collectionAddr,
        address _creator,
        uint256 _royalty
    ) external onlyOwner {
        require(_royalty <= MAX_ROYALTY_PERCENT, "Invalid percent");
        _collectionCreators[_collectionAddr] = _creator;
        _collectionRoyalties[_collectionAddr] = _royalty;
    }

    function getRoyalty(
        address _collectionAddr,
        uint256 _tokenId
    ) public view returns (uint256) {
        address _creator = _collectionCreators[_collectionAddr];
        if (_creator != address(0))
            return _collectionRoyalties[_collectionAddr];
        return IERC721NFT(_collectionAddr).royalties(_tokenId);
    }

    function getCreator(
        address _collectionAddr,
        uint256 _tokenId
    ) public view returns (address) {
        address _creator = _collectionCreators[_collectionAddr];
        if (_creator != address(0)) return _creator;
        return IERC721NFT(_collectionAddr).creatorOf(_tokenId);
    }
}