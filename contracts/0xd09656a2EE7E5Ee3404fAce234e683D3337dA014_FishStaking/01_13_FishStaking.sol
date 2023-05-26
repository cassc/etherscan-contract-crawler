// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/utils/math/Math.sol';
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract FishStaking is Ownable, IERC721Receiver, ReentrancyGuard, Pausable {
    using EnumerableSet for EnumerableSet.UintSet; 
    
    //addresses 
    address nullAddress = 0x0000000000000000000000000000000000000000;
    address public stakingDestinationAddress;
    address public erc20Address;

    //uint256's 
    uint256 public expiration; 
    //rate governs how often you receive your token
    uint256 public rate; 
  
    // mappings 
    mapping(address => EnumerableSet.UintSet) private _deposits;
    mapping(address => mapping(uint256 => uint256)) public _depositBlocks;

    constructor(
      address _stakingDestinationAddress,
      uint256 _rate,
      uint256 _expiration,
      address _erc20Address
    ) {
        stakingDestinationAddress = _stakingDestinationAddress;
        rate = _rate;
        expiration = block.number + _expiration;
        erc20Address = _erc20Address;
        _pause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

/* STAKING MECHANICS */

    // Set a multiplier for how many tokens to earn each time a block passes.
    function setRate(uint256 _rate) public onlyOwner() {
      rate = _rate;
    }

    // Set this to a block to disable the ability to continue accruing tokens past that block number.
    function setExpiration(uint256 _expiration) public onlyOwner() {
      expiration = block.number + _expiration;
    }

    //check deposit amount. 
    function depositsOf(address account)
      external 
      view 
      returns (uint256[] memory)
    {
      EnumerableSet.UintSet storage depositSet = _deposits[account];
      uint256[] memory tokenIds = new uint256[] (depositSet.length());

      for (uint256 i; i < depositSet.length(); i++) {
        tokenIds[i] = depositSet.at(i);
      }

      return tokenIds;
    }

    function calculateRewards(address account, uint256[] memory tokenIds) 
      public 
      view 
      returns (uint256[] memory rewards) 
    {
      rewards = new uint256[](tokenIds.length);

      for (uint256 i; i < tokenIds.length; i++) {
        uint256 tokenId = tokenIds[i];

        rewards[i] = 
          rate * 
          (_deposits[account].contains(tokenId) ? 1 : 0) * 
          (Math.min(block.number, expiration) - 
            _depositBlocks[account][tokenId]);
      }

      return rewards;
    }

    //reward amount by address/tokenIds[]
    function calculateReward(address account, uint256 tokenId) 
      public 
      view 
      returns (uint256) 
    {
      require(Math.min(block.number, expiration) > _depositBlocks[account][tokenId], "Invalid blocks");
      return rate * 
          (_deposits[account].contains(tokenId) ? 1 : 0) * 
          (Math.min(block.number, expiration) - 
            _depositBlocks[account][tokenId]);
    }

    //reward claim function 
    function claimRewards(uint256[] calldata tokenIds) public whenNotPaused {
      uint256 reward; 
      uint256 blockCur = Math.min(block.number, expiration);

      for (uint256 i; i < tokenIds.length; i++) {
        reward += calculateReward(msg.sender, tokenIds[i]);
        _depositBlocks[msg.sender][tokenIds[i]] = blockCur;
      }

      if (reward > 0) {
        IERC20(erc20Address).transfer(msg.sender, reward);
      }
    }

    //deposit function. 
    function deposit(uint256[] calldata tokenIds) external whenNotPaused {
        require(msg.sender != stakingDestinationAddress, "Invalid address");
        claimRewards(tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            IERC721(stakingDestinationAddress).safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i],
                ""
            );

            _deposits[msg.sender].add(tokenIds[i]);
        }
    }

    //withdrawal function.
    function withdraw(uint256[] calldata tokenIds) external whenNotPaused nonReentrant() {
        claimRewards(tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                _deposits[msg.sender].contains(tokenIds[i]),
                "Staking: token not deposited"
            );

            _deposits[msg.sender].remove(tokenIds[i]);

            IERC721(stakingDestinationAddress).safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i],
                ""
            );
        }
    }

    //withdrawal function.
    function withdrawTokens() external onlyOwner {
        uint256 tokenSupply = IERC20(erc20Address).balanceOf(address(this));
        IERC20(erc20Address).transfer(msg.sender, tokenSupply);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}