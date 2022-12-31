//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// ___________               ________   _____  _____.__       .__       .__      _________ __          __           
// \_   _____/ ____ _____    \_____  \_/ ____\/ ____\__| ____ |__|____  |  |    /   _____//  |______  |  | __ ____  
//  |    __)_ /    \\__  \    /   |   \   __\\   __\|  |/ ___\|  \__  \ |  |    \_____  \\   __\__  \ |  |/ // __ \ 
//  |        \   |  \/ __ \_ /    |    \  |   |  |  |  \  \___|  |/ __ \|  |__  /        \|  |  / __ \|    <\  ___/ 
// /_______  /___|  (____  / \_______  /__|   |__|  |__|\___  >__(____  /____/ /_______  /|__| (____  /__|_ \\___  >
//         \/     \/     \/          \/                     \/        \/               \/           \/     \/    \/ 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract EnaOfficialStake is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Locker {
        bool locked;
        uint256 tokenNumber;
        address lockerOwner;
    }

    IERC721 public nftTokenAddress;
    mapping(uint256 => Locker) public nftLocker;
    mapping(address => uint256) public nftLocked;
    mapping(address => uint256[]) internal nftLockedTokenIds;
    uint256 public stakingCounter = 0;

    function lock(uint256 _tokenId) public {
        require(
            nftTokenAddress.ownerOf(_tokenId) == msg.sender,
            "You are not Owner of the NFT"
        );
        Locker storage locker = nftLocker[_tokenId];

        nftTokenAddress.transferFrom(msg.sender, address(this), _tokenId);
        locker.lockerOwner = msg.sender;
        locker.locked = true;
        locker.tokenNumber = _tokenId;
        nftLockedTokenIds[msg.sender].push(_tokenId);

        nftLocked[msg.sender] += 1;
        stakingCounter += 1;
    }

    function multipleLock(uint256[] memory _tokenList) external nonReentrant {
        for (uint256 i = 0; i < _tokenList.length; i++) {
            lock(_tokenList[i]);
        }
    }

    function unlock(uint256 _tokenId) public {
        Locker storage locker = nftLocker[_tokenId];
        require(locker.locked, "This NFT is not Locked");
        require(
            locker.lockerOwner == msg.sender,
            "You are not owner of the NFT"
        );
        require(
            nftTokenAddress.ownerOf(_tokenId) == address(this),
            "NFT is not locked in this contract"
        );

        nftTokenAddress.transferFrom(
            address(this),
            locker.lockerOwner,
            _tokenId
        );
        locker.locked = false;
        locker.lockerOwner = address(0);

        for (uint256 i; i < nftLockedTokenIds[msg.sender].length; i++) {
            if (nftLockedTokenIds[msg.sender][i] == _tokenId) {
                nftLockedTokenIds[msg.sender][i] = nftLockedTokenIds[
                    msg.sender
                ][nftLockedTokenIds[msg.sender].length - 1];
                nftLockedTokenIds[msg.sender].pop();
                break;
            }
        }

        nftLocked[msg.sender] -= 1;
        stakingCounter -= 1;
    }

    function multipleUnlock(uint256[] memory _tokenList) external nonReentrant {
        for (uint256 i = 0; i < _tokenList.length; i++) {
            unlock(_tokenList[i]);
        }
    }

    function updateNftAddress(IERC721 _token) public onlyOwner {
        require(
            stakingCounter == 0,
            "NFTs are already staked, cannot change address"
        );
        nftTokenAddress = IERC721(_token);
    }

    function getLockedTokenIds(address _address)
        external
        view
        returns (uint256[] memory)
    {
        return nftLockedTokenIds[_address];
    }
}