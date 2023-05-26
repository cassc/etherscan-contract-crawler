//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*
░█████╗░██╗░░░░░██████╗░██╗░░██╗░█████╗░  ██╗░░░░░░█████╗░░█████╗░██╗░░██╗███████╗██████╗░
██╔══██╗██║░░░░░██╔══██╗██║░░██║██╔══██╗  ██║░░░░░██╔══██╗██╔══██╗██║░██╔╝██╔════╝██╔══██╗
███████║██║░░░░░██████╔╝███████║███████║  ██║░░░░░██║░░██║██║░░╚═╝█████═╝░█████╗░░██████╔╝
██╔══██║██║░░░░░██╔═══╝░██╔══██║██╔══██║  ██║░░░░░██║░░██║██║░░██╗██╔═██╗░██╔══╝░░██╔══██╗
██║░░██║███████╗██║░░░░░██║░░██║██║░░██║  ███████╗╚█████╔╝╚█████╔╝██║░╚██╗███████╗██║░░██║
╚═╝░░╚═╝╚══════╝╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚═╝  ╚══════╝░╚════╝░░╚════╝░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝
*/

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract AlphaLocker is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    //Declare Events
    event Locked(address indexed _owner, uint256 _tokenId, uint256 _timeStamp);
    event Unlocked(address indexed _owner, uint256 _tokenId, uint256 _timeStamp);

    struct Locker {
        bool locked;  // 0 -> Unlocked, 1 -> Locked
        uint256 tokenNumber;
        address lockerOwner;
    }

    // Mapping NFT to locker
    mapping (uint256 => Locker) public nftLocker;

    IERC721 public nftTokenAddress;

    mapping(address => uint256) public nftLocked;

    uint256 public stakingCounter = 0;

    function updateNftAddress(IERC721 _token) public onlyOwner {
        require(stakingCounter==0, "NFT's Already staked, cannot change address");
        nftTokenAddress = IERC721(_token);
    }
    
    function lock(uint256 _tokenId) public {
        require(nftTokenAddress.ownerOf(_tokenId)==msg.sender, "You are not Owner of the NFT");
        Locker storage locker = nftLocker[_tokenId];

        nftTokenAddress.transferFrom(msg.sender, address(this), _tokenId);
        locker.lockerOwner = msg.sender;
        locker.locked = true;
        locker.tokenNumber = _tokenId;

        nftLocked[msg.sender] += 1;
        stakingCounter += 1;
        
        // Emit Locked!
        emit Locked(msg.sender, _tokenId, block.timestamp); 
    }

    function multipleLock(uint256[] memory _tokenList) external nonReentrant {
        for(uint256 i=0; i<_tokenList.length;i++)
        {
            lock(_tokenList[i]);
        }
    }

    function unLockNFT(uint256 _tokenId) external nonReentrant  {
        Locker storage locker = nftLocker[_tokenId];
        require(locker.locked, "This NFT is not Locked");
        require(locker.lockerOwner==msg.sender, "You are not owner of the Token");
        require(nftTokenAddress.ownerOf(_tokenId)==address(this), "NFT is not locked in this contract");
        
        nftTokenAddress.transferFrom(address(this), locker.lockerOwner, _tokenId);
        locker.locked = false;
        locker.lockerOwner = address(0);

        nftLocked[msg.sender] -= 1;
        stakingCounter -=1;
        
        // Emit Unlocked!
        emit Unlocked(locker.lockerOwner, _tokenId, block.timestamp); 
    }

}