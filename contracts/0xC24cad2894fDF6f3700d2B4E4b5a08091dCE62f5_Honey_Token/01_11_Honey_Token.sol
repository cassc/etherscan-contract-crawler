// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

    error OnlyUserCanUse();
    error NotNftOwner();
    error HasClaimed();
    error NoHarvesToken();
    error NoEnoughHarvesToken();

contract Honey_Token is ERC20, Ownable, ReentrancyGuard,Pausable {
    using SafeMath for uint256;

    struct UserBag {
        uint256 UserWaitingReleased;
        uint256 UserWaitingReleasedRatio;
        uint256 UserLastRewardNumber;
        uint256 UserHasGetClaimToken;
    }

    address public BEARnft = 0xa166fDB6Ba158677b89E24F33453951929590809;  //BearComing Token
    uint256 public hcPerBlock = 77160000000000000000000; // Honey_Token tokens created per block.
    mapping(address => UserBag) public UserInfo;
    mapping(uint => bool) public IsBearClaimed;

    constructor()
    ERC20("Honey Coin", "HC"){
        _mint(msg.sender, 200000000000000 ether);
        _pause();
    }


    function Claim(uint256[] calldata _tokenids) external nonReentrant whenNotPaused {
        if (tx.origin != msg.sender) revert OnlyUserCanUse();
        for (uint256 i = 0 ;i < _tokenids.length ; i++ ){
            if (IERC721(BEARnft).ownerOf(_tokenids[i]) != msg.sender) revert NotNftOwner();
            if (IsBearClaimed[_tokenids[i]]) revert HasClaimed();

            IsBearClaimed[_tokenids[i]]=true;

            //update userbag
            UserInfo[msg.sender].UserHasGetClaimToken = (block.number - UserInfo[msg.sender].UserLastRewardNumber) * hcPerBlock * UserInfo[msg.sender].UserWaitingReleasedRatio;
            UserInfo[msg.sender].UserWaitingReleased=UserInfo[msg.sender].UserWaitingReleased + 80000000000 ether;
            UserInfo[msg.sender].UserWaitingReleasedRatio=UserInfo[msg.sender].UserWaitingReleasedRatio + 1;
            UserInfo[msg.sender].UserLastRewardNumber=block.number;
        }
    }


    function HarvesToken() external nonReentrant whenNotPaused {
        if (tx.origin != msg.sender) revert OnlyUserCanUse();

        uint256 mfcReward = (block.number - UserInfo[msg.sender].UserLastRewardNumber) * hcPerBlock * UserInfo[msg.sender].UserWaitingReleasedRatio;

        UserInfo[msg.sender].UserHasGetClaimToken=UserInfo[msg.sender].UserHasGetClaimToken+ mfcReward;

        if (UserInfo[msg.sender].UserHasGetClaimToken <= 0) revert NoHarvesToken();

        if (UserInfo[msg.sender].UserHasGetClaimToken > UserInfo[msg.sender].UserWaitingReleased) revert NoEnoughHarvesToken();

        if (UserInfo[msg.sender].UserWaitingReleased >= mfcReward){
            UserInfo[msg.sender].UserWaitingReleased = UserInfo[msg.sender].UserWaitingReleased - mfcReward;
        }else{
            UserInfo[msg.sender].UserWaitingReleased = 0;
        }

        UserInfo[msg.sender].UserHasGetClaimToken=0;

        _mint(msg.sender, mfcReward);
    }

    function QueryWaitClaimToken(address owner) public view returns(uint256) {

        uint256 mfcReward = (block.number - UserInfo[owner].UserLastRewardNumber) * hcPerBlock * UserInfo[owner].UserWaitingReleasedRatio;

        uint256 userallReward = mfcReward + UserInfo[owner].UserHasGetClaimToken;

        return userallReward;
    }


    function _mint(address to, uint256 amount) internal override(ERC20) {
        super._mint(to, amount);
    }
}