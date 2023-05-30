// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.7;

// Author: @gizmolab_
// Audited by @ViperwareLabs



import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract NFTStaking is Ownable {

    address[] public VaultContracts;

    address public caveAddress = 0x6058224af88C344c919325720a7784c69202B815;

    struct Stake {
        address owner; // 32bits
        uint128 timestamp;  // 32bits
    }

    bool public stakingEnabled = false;
    uint256 public totalStaked;

    mapping(address => mapping(uint256 => Stake)) public vault; 
    mapping(address => mapping(address => uint256[])) public userStakeTokens;
    mapping(address => uint256[]) public userStakeCaves;

    event NFTStaked(address owner, address tokenAddress, uint256 tokenId, uint256 value);
    event NFTUnstaked(address owner, address tokenAddress, uint256 tokenId, uint256 value);
    event Claimed(address owner);

    function setCaveAddress(address _contract) public onlyOwner {
        caveAddress = _contract;
    }

    function addVault(address _contract) public onlyOwner {
        VaultContracts.push(_contract);
    }
    
    function stakeNfts(uint256 _pid, uint256[] calldata tokenIds) external {

        require(stakingEnabled == true, "Staking is not enabled yet.");
        require(userStakeCaves[msg.sender].length > 0, "You cannot stake without having a Cave staked.");

        IERC721 nftContract = IERC721(VaultContracts[_pid]);

        for (uint i; i < tokenIds.length; i++) {
            require(nftContract.ownerOf(tokenIds[i]) == msg.sender, "You do not own this token");
            nftContract.transferFrom(msg.sender, address(this), tokenIds[i]);
            vault[VaultContracts[_pid]][tokenIds[i]] = Stake({owner: msg.sender, timestamp: uint128(block.timestamp)});
            userStakeTokens[msg.sender][VaultContracts[_pid]].push(tokenIds[i]);
            emit NFTStaked(msg.sender, VaultContracts[_pid], tokenIds[i], block.timestamp);
            totalStaked++;
        }

    }

    function stakeCave(uint256[] memory tokenIds) external {
        require(stakingEnabled == true, "Staking is not enabled yet.");

        IERC721 Cave = IERC721(caveAddress);

        for (uint i; i < tokenIds.length; i++) {
            Cave.transferFrom(msg.sender, address(this), tokenIds[i]);
            userStakeCaves[msg.sender].push(tokenIds[i]);
        }
    }

    function unstakeNfts(uint256 _pid, uint256[] calldata tokenIds) external {
        IERC721 nftContract = IERC721(VaultContracts[_pid]);
        
        for (uint i; i < tokenIds.length; i++) {
            // Replaced this function with: require(isTokenOwner == true, "You do not own this Token"); 
            // require(vault[VaultContracts[_pid]][tokenIds[i]].owner == msg.sender, "You do not own this NFT");

            bool isTokenOwner = false;
            uint tokenIndex = 0;
        
            for (uint j = 0; j < userStakeTokens[msg.sender][VaultContracts[_pid]].length; j++) {
                if (tokenIds[i] == userStakeTokens[msg.sender][VaultContracts[_pid]][j]) {
                    isTokenOwner = true;
                    tokenIndex = j;
                    break;
                }
            }

            require(isTokenOwner == true, "You do not own this Token");

            nftContract.transferFrom(address(this), msg.sender, tokenIds[i]);

            delete vault[VaultContracts[_pid]][tokenIds[i]];
            totalStaked--;

            //delete userStakeTokens[msg.sender][VaultContracts[_pid]][tokenIndex];
            userStakeTokens[msg.sender][VaultContracts[_pid]][tokenIndex] = userStakeTokens[msg.sender][VaultContracts[_pid]][userStakeTokens[msg.sender][VaultContracts[_pid]].length - 1];
            userStakeTokens[msg.sender][VaultContracts[_pid]].pop();

            emit NFTUnstaked(msg.sender, VaultContracts[_pid], tokenIds[i], block.timestamp);
        }
    } 

    function unstakeCave(uint256[] memory tokenIds) external {
        require(stakingEnabled == true, "Staking is not enabled yet.");
        require(getUserStaked(msg.sender) == 0, "You cannot unstake your Cave until you unstake all your NFTs");

        IERC721 Cave = IERC721(caveAddress);

        for (uint i; i < tokenIds.length; i++) {
            
            bool isCaveOwner = false;
            uint caveIndex = 0;
        
            for (uint j = 0; j < userStakeCaves[msg.sender].length; j++) {
                if (tokenIds[i] == userStakeCaves[msg.sender][j]) {
                    isCaveOwner = true;
                    caveIndex = j;
                    break;
                }
            }

            require(isCaveOwner == true, "You do not own this Cave");

            Cave.transferFrom(address(this), msg.sender, tokenIds[i]);
            
            //delete userStakeCaves[msg.sender][caveIndex];
            userStakeCaves[msg.sender][caveIndex] = userStakeCaves[msg.sender][userStakeCaves[msg.sender].length - 1];
            userStakeCaves[msg.sender].pop();

        }
    }

    function setStakingEnabled(bool _enabled) external  onlyOwner {
        stakingEnabled = _enabled;
    }

    function getStakedCaves(address _user) external view returns (uint256[] memory) {
        return userStakeCaves[_user];
    } 

    function getStakedTokens(address _user, address _contract) external view returns (uint256[] memory) {
        return userStakeTokens[_user][_contract];
    } 

    function getVaultContracts() external view returns (address[] memory) {
        return VaultContracts;
    }

    function getStake(address _contract, uint256 _tokenId) external view returns (Stake memory) {
        return vault[_contract][_tokenId];
    }
    
    // get the total staked NFTs
    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    } 
    
    function getUserStaked(address _user) public view returns (uint256) {
        uint256 total;
        for (uint i; i < VaultContracts.length; i++) {
            total += userStakeTokens[_user][VaultContracts[i]].length;
        }
        return total;
    }

}