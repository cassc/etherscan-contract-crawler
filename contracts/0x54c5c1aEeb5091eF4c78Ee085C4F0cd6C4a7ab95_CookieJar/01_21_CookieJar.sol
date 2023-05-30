// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CHIP.sol";
import "./CookiesNKicks.sol";


// Maybe add in events for when staking occurs.
contract CookieJar is Ownable, IERC721Receiver {

    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }
    bool public emergencyWithdrawAllowed = false;

    mapping(uint256 => Stake) public jar; 
    mapping(address => uint256[]) public cnkOwnerIds;
    uint256 public totalStaked = 0;

    uint256 public constant REGULAR_REWARD_PER_DAY = 10000 ether;
    uint256 public constant TIER_ONE_REWARD_PER_DAY = 15000 ether;

    uint256 public maxTierOneId = 3000; // can change if less mint

    CHIP private immutable chip;
    CookiesNKicks private immutable cnk;

    constructor(address _chip, address _cnk) { 
        chip = CHIP(_chip);
        cnk = CookiesNKicks(_cnk);
    }

    function setMaxTierOneId(uint256 _maxTierOneId) external onlyOwner {
        maxTierOneId = _maxTierOneId;
    }

    // need to make when not paused.
    function stakeCookies(uint16[] calldata _tokenIds) external {
        
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(cnk.ownerOf(_tokenIds[i]) == _msgSender(), "You cannot stake this! Nice try.");
            cnk.transferFrom(_msgSender(), address(this), _tokenIds[i]);

            jar[_tokenIds[i]] = Stake({
                owner: _msgSender(),
                tokenId: uint16(_tokenIds[i]),
                value: uint80(block.timestamp)
            });
            cnkOwnerIds[_msgSender()].push(_tokenIds[i]);

            totalStaked += 1;
        }
    }

    function _calculateReward(Stake memory _stake) internal view returns(uint256){

        uint256 dailyReward = _stake.tokenId <= maxTierOneId ? 
            TIER_ONE_REWARD_PER_DAY : REGULAR_REWARD_PER_DAY;
        
        return (block.timestamp - _stake.value) * dailyReward / 1 days;
    }

    function claimCurrentReward(bool unstake) external returns(uint256){

        uint256 totalReward = 0;
        for (uint i = 0; i < cnkOwnerIds[_msgSender()].length; i++) {
            uint256 tokenId = cnkOwnerIds[_msgSender()][i];
            Stake memory stake = jar[tokenId];
            require(stake.owner == _msgSender(), "You cannot take this. It isn't yours.");
            totalReward += _calculateReward(stake);
            if(unstake){
                cnk.safeTransferFrom(address(this), _msgSender(), tokenId, "");
                delete jar[tokenId];
                totalStaked -= 1;
            } else {
                jar[tokenId] = Stake({
                    owner: _msgSender(),
                    tokenId: uint16(tokenId),
                    value: uint80(block.timestamp)
                });
            }
        }
        chip.mint(_msgSender(), totalReward);
        if(unstake){
            delete cnkOwnerIds[_msgSender()];
        }
        return totalReward;
    }

    function setEmergencyWithdraw(bool _value) external onlyOwner {
        emergencyWithdrawAllowed = _value;
    }

    function emergencyWithdraw() external {
        require(emergencyWithdrawAllowed, "You may not do this.");
         for (uint i = 0; i < cnkOwnerIds[_msgSender()].length; i++) {
            uint256 tokenId = cnkOwnerIds[_msgSender()][i];
            Stake memory stake = jar[tokenId];
            require(stake.owner == _msgSender(), "You cannot take this. It isn't yours.");

            cnk.safeTransferFrom(address(this), _msgSender(), tokenId, "");
            delete jar[tokenId];
            totalStaked -= 1;
           
        }
        delete cnkOwnerIds[_msgSender()];
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send tokens to here directly");
      return IERC721Receiver.onERC721Received.selector;
    }

}