//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {ERC721HolderUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import {IStakingPass} from "./IStakingPass.sol";
import "hardhat/console.sol";
contract StakingContract is OwnableUpgradeable, ERC721HolderUpgradeable {

    error IllegalClaimOfToken(address _user, address _owner,uint256 _illegalTokenId);

    mapping (address => bool) public isWhitelisted;
    mapping (address => address) public nftToStakingPass;

    function initialize() public initializer {
        __Ownable_init();
        __ERC721Holder_init();
    }

    function stakeKitties(address _collectionAddress, uint256[] memory kitties) external {
        uint256[] memory localKitties = kitties;
        uint256 arrayLength = localKitties.length;
        for (uint256 i =0; i<arrayLength;) {
            require(IStakingPass(_collectionAddress).ownerOf(localKitties[i]) == msg.sender, "You do not own this kitty");
            IStakingPass(_collectionAddress).safeTransferFrom(msg.sender, address(this), localKitties[i]);
            if(IStakingPass(nftToStakingPass[_collectionAddress]).checkExistence(localKitties[i])) {
                IStakingPass(nftToStakingPass[_collectionAddress]).transferFrom( address(this), msg.sender, localKitties[i]);
            } else {
                IStakingPass(nftToStakingPass[_collectionAddress]).mint(msg.sender, localKitties[i]);
            }
        unchecked {
            i++;
        }
        }
    }

    function unstakeKitties(address _collectionAddress, uint256[] memory kitties) external{
        uint256[] memory localKitties = kitties;
        uint256 arrayLength = localKitties.length;
        for (uint256 j = 0; j <arrayLength;) {
            require (IStakingPass(nftToStakingPass[_collectionAddress]).ownerOf(localKitties[j]) == msg.sender, "You do not own this staking pass");
            IStakingPass(nftToStakingPass[_collectionAddress]).safeTransferFrom( msg.sender, address(this), localKitties[j]);
            IStakingPass(_collectionAddress).transferFrom(address(this), msg.sender, localKitties[j]);
        unchecked {
            j++;
        }
        }
    }

    function whitelistNFTAddress (address[] memory _nftAddress) external onlyOwner {
        for (uint256 i = 0; i < _nftAddress.length;i++) {
            isWhitelisted[_nftAddress[i]] = true;
        }
    }

    function addNftToStakingPass (address[] memory _nftAddress, address[] memory _stakingPassAddress) external onlyOwner {
        for (uint256 i = 0; i < _nftAddress.length;i++) {
            nftToStakingPass[_nftAddress[i]] = _stakingPassAddress[i];
        }
    }

    function blackListNFTAddress (address[] memory _nftAddress) external onlyOwner {
        for (uint256 i = 0; i < _nftAddress.length;i++) {
            isWhitelisted[_nftAddress[i]] = false;
        }
    }

    function removeNftFromStakingPass (address[] memory _nftAddress) external onlyOwner {
        for (uint256 i = 0; i < _nftAddress.length;i++) {
            delete nftToStakingPass[_nftAddress[i]];
        }
    }
}