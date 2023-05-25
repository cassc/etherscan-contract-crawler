//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "erc721a/contracts/ERC721A.sol";

contract EvincoCellarAging is Ownable, ERC721Holder {
    ERC721A public nft;

    struct StakerWallet {
        mapping(uint256 => uint256) timeStaked;
        uint256[] tokenIDs;
    }

    mapping(uint256 => address) public tokenOwner;
    mapping(address => StakerWallet) Stakers;
    uint256 public totalStaked;

    constructor(address _nft) {
        nft = ERC721A(_nft);
    }

    //view functions
    function getStakedTokens(address user)
        public
        view
        returns (uint256[] memory tokens)
    {
        return Stakers[user].tokenIDs;
    }

    function getStakedTime(uint256 tokenId)
        public
        view
        returns (uint256 stakeTime)
    {
        return Stakers[tokenOwner[tokenId]].timeStaked[tokenId];
    }

    //stake
    function stake(uint256 tokenID) public {
        _stake(msg.sender, tokenID);
    }

    function batchStake(uint256[] memory tokenIDs) public {
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            _stake(msg.sender, tokenIDs[i]);
        }
    }

    function _stake(address _user, uint256 _tokenId) internal {
        require(
            nft.ownerOf(_tokenId) == _user,
            "cannot stake an NFT you don't own!"
        );
        require(
            nft.getApproved(_tokenId) == address(this) ||
                nft.isApprovedForAll(_user, address(this)),
            "Contract not approved to transfer ownership"
        );
        //get/create Staker Wallet
        StakerWallet storage _staker = Stakers[_user];

        //transfer ownership (assumes pre-approved before this is called)
        nft.safeTransferFrom(_user, address(this), _tokenId);

        //update Owner Wallet
        _staker.tokenIDs.push(_tokenId);
        _staker.timeStaked[_tokenId] = block.timestamp;

        //update tokenOwner mapping
        tokenOwner[_tokenId] = _user;

        //update total amount staked
        totalStaked++;
    }

    //unstake
    function unstake(uint256 tokenID) public {
        _unstake(msg.sender, tokenID);
    }

    function batchUnstake(uint256[] memory tokenIDs) public {
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            _unstake(msg.sender, tokenIDs[i]);
        }
    }

    function _unstake(address _user, uint256 _tokenId) internal {
        require(
            tokenOwner[_tokenId] == _user,
            "Cannot unstake an NFT you don't own!"
        );
        //get Staker Wallet
        StakerWallet storage _staker = Stakers[_user];

        //transfer ownership back to user
        nft.approve(_user, _tokenId);
        nft.safeTransferFrom(address(this), _user, _tokenId);

        //clear out staked info
        delete tokenOwner[_tokenId];
        delete _staker.timeStaked[_tokenId];
        totalStaked--;

        //replace the removed token id at its current index with the last value in the array
        //and then pop() off the last index.  We do not care about the order of this
        //array
        for (uint256 i = 0; i <= _staker.tokenIDs.length - 1; i++) {
            if (_staker.tokenIDs[i] == _tokenId) {
                _staker.tokenIDs[i] = _staker.tokenIDs[
                    _staker.tokenIDs.length - 1
                ];
                _staker.tokenIDs.pop();
                break;
            }
        }
    }
}