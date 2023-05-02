// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; 	// OZ: ReentrancyGuard 

contract NFTStaking is Ownable, ReentrancyGuard {

    struct StakeInfo {
        uint256 rewardAmount;
        uint256 rewardClaimed;
        uint256 updateTime;
        uint256 hashRate;
        uint256[] stakedIds;
        bool isUsed;
    }
    address public nftAddress;
    address public esgToken;
    uint256[5] public hashMap = [100, 130,175,330,450];

    mapping (address => StakeInfo) stakeInfo;
    mapping (uint256 => address) idToStaker;
    event NewStake(address indexed user, uint256 indexed tokenId, uint256 level, uint256 timestamp);
    event UnStake(address indexed user, uint256 indexed tokenId, uint256 level, uint256 timestamp);
    event Rewarded(address indexed user, uint256 amount, uint256 timestamp);

    constructor(address _nftAddress, address _esgToken) {
        nftAddress = _nftAddress;
        esgToken = _esgToken;
    }

    // TODO: staking algorithm needs to be fixed
    function reward(address account) public view returns (uint256) {
        StakeInfo memory info = stakeInfo[account];
        if(!info.isUsed)
            return 0;
        return info.rewardAmount + (block.timestamp - info.updateTime) * info.hashRate;
    }

    function _setHashRate(uint index, uint256 rate) public onlyOwner {
       require(index < 5, "invalid index");
       hashMap[index] = rate;
    }

    function getStakedIds(address account) external view returns (uint256[] memory){
        StakeInfo memory info = stakeInfo[account];
        require(info.isUsed, "no record");
        return info.stakedIds;
    }

    function stake(
        uint256[] calldata ids 
    ) external nonReentrant {
        require(ids.length > 0, "invalid ids");
        for(uint i = 0; i < ids.length; i++)
        {
          StakeInfo storage info = stakeInfo[msg.sender];
          if(info.isUsed)
          {
              uint256 tokenId = ids[i];
              IERC721(nftAddress).transferFrom(msg.sender, address(this), tokenId);

              uint256 level = ( tokenId - 1 ) / 1000;
              uint256 rate = hashMap[level];
              idToStaker[tokenId] = msg.sender;
              info.rewardAmount = reward(msg.sender);
              info.hashRate += rate;
              info.updateTime = block.timestamp;
              emit NewStake(msg.sender, tokenId, level+1, block.timestamp);
              info.stakedIds.push(tokenId);
          }else
          {
              uint256 tokenId = ids[i];
              IERC721(nftAddress).transferFrom(msg.sender, address(this), tokenId);

              uint256 level = ( tokenId - 1 ) / 1000;
              uint256 hashRate = hashMap[level];
              idToStaker[tokenId] = msg.sender;

              uint256[] memory newIds = new uint256[](1);
              newIds[0] = tokenId;
              stakeInfo[msg.sender] = StakeInfo(0, 0, block.timestamp, hashRate, newIds, true);
              emit NewStake(msg.sender, tokenId, level+1, block.timestamp);
          }
        }
    }

    function unstake(
        uint256[] calldata ids
    ) external nonReentrant {
        require(ids.length > 0, "invalid ids");
        StakeInfo storage info = stakeInfo[msg.sender];
        require(info.isUsed, "invalid caller");

        for(uint i = 0; i < ids.length; i++)
        {
            uint256 tokenId = ids[i];
            require(idToStaker[tokenId] == msg.sender, "invalid staker");
            delete idToStaker[tokenId];

            uint256 level = ( tokenId - 1 ) / 1000;
            uint256 rate = hashMap[level];
            info.rewardAmount = reward(msg.sender);
            info.hashRate -= rate;
            info.updateTime = block.timestamp;
            IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenId);
            emit UnStake(msg.sender, tokenId, level+1, block.timestamp);

            for(uint j = 0; j < info.stakedIds.length; j++)
            {
                if(tokenId == info.stakedIds[j])
                {
                    info.stakedIds[j] = info.stakedIds[info.stakedIds.length - 1];
                    info.stakedIds.pop();
                }
            }
        }
    }

    function claimReward(uint256 amount) external nonReentrant {
        require(amount > 0, "invalid amount");
        StakeInfo storage info = stakeInfo[msg.sender];
        require(info.isUsed, "invalid staker");

        info.rewardAmount = reward(msg.sender);
        require(info.rewardAmount >= amount, "insufficient rewards");
        info.updateTime = block.timestamp;
        info.rewardAmount -= amount;

        IERC20(esgToken).transfer(msg.sender, amount);
        emit Rewarded(msg.sender, amount, block.timestamp);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return 0x150b7a02;
    }

    // Used by ERC721BasicToken.sol
    function onERC721Received(
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return 0xf0b9e5ba;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        virtual
        view
        returns (bool)
    {
        return interfaceId == this.supportsInterface.selector;
    }

    receive() external payable {}

    function _checkCallResult(bool _success) internal pure {
        if (!_success) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    // Emergency function: In case any ETH get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueETH(address recipient) onlyOwner external {
        uint256 balance = address(this).balance;
        if(balance>0)
            payable(recipient).transfer(balance);
    }

    // Emergency function: In case any ERC20 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC20(address asset, address recipient) onlyOwner external { 
        (bool success, ) = asset.call(abi.encodeWithSelector(0xa9059cbb, recipient, IERC20(asset).balanceOf(address(this))));
        _checkCallResult(success);
    }

    // Emergency function: In case any ERC721 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC721(address asset, uint256[] calldata ids, address recipient) onlyOwner external {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC721(asset).transferFrom(address(this), recipient, ids[i]);
        }
    }

    // Emergency function: In case any ERC1155 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC1155(address asset, uint256[] calldata ids, uint256[] calldata amounts, address recipient) onlyOwner external {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC1155(asset).safeTransferFrom(address(this), recipient, ids[i], amounts[i], "");
        }
    }
}