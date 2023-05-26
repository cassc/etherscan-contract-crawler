// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IMintableERC20 is IERC20  {
  function mint(address _to, uint256 _amount) external;
  function burn(address _from, uint256 _amount) external;
}

interface IStakingSystem {
    function getStakedTokens(address _owner) external view returns (uint16[] memory);
}

contract BOBLCarePackage is Ownable {

    IERC721 public erc721Token;
    IMintableERC20 public erc20Token;
    IStakingSystem public stakingSystem;

    // the number of weeks to claim tokens for
    uint256 public epochsToClaim = 16;

    // yield rate per week for each rarity
    uint256 public rowdyEpochYield = 1 ether;
    uint256 public ragingEpochYield = 3 ether;
    uint256 public royalEpochYield = 6 ether;

    // signer addresses
    address private rowdySigner;
    address private ragingSigner;
    address private royalSigner;

    // mapping points the token ID to claim boolean
    mapping(uint16 => uint8) claimed;

    // events
    event CarePackageClaimed(uint16 tokenId, address owner, uint256 reward);

    // constructor
    constructor(address _erc721Address, address _erc20Address, address _stakingAddress) {    
        erc721Token = IERC721(_erc721Address);
        erc20Token = IMintableERC20(_erc20Address);
        stakingSystem = IStakingSystem(_stakingAddress);
    }

    // sets the genesis ERC721 contract address
    function setERC721Contract(address _erc721Address) external onlyOwner {
        erc721Token = IERC721(_erc721Address);
    }

    // sets the rewards token contract address
    function setERC20Contract(address _erc20Address) external onlyOwner {
        erc20Token = IMintableERC20(_erc20Address);
    }

    // sets the staking token contract address
    function setStakingContract(address _stakingAddress) external onlyOwner {
        stakingSystem = IStakingSystem(_stakingAddress);
    }

    // sets the signer addresses for rarity verification
    function setSigners(address[] calldata signers) public onlyOwner{
        rowdySigner = signers[0];
        ragingSigner = signers[1];
        royalSigner = signers[2];
    }

    // claims the care package for all ids
    function claimCarePackage(address _owner, uint16[] calldata _tokenIds, bytes32[] memory _hashes, bytes[] memory _signatures) external {
        require((_owner == msg.sender), "only owners approved");

        uint256 reward;
        uint16[] memory stakedIds = stakingSystem.getStakedTokens(msg.sender);
        
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            if(erc721Token.ownerOf(_tokenIds[i]) == msg.sender) {
                reward += _claimCarePackage(_owner, _tokenIds[i], _hashes[i], _signatures[i]);
            } else {
                require(_isStakedOwner(_tokenIds[i], stakedIds),"only owners approved");
                reward += _claimCarePackage(_owner, _tokenIds[i], _hashes[i], _signatures[i]);
            }
        }
        if (reward != 0) {
            erc20Token.mint(msg.sender, reward);
        }
    }

    // verifies ownership of a staked token
    function _isStakedOwner(uint16 _tokenId, uint16[] memory _stakedIds) internal pure returns (bool){
        for(uint16 i; i<_stakedIds.length; i++) {
            if(_stakedIds[i] == _tokenId) {
                return true;
            }
        }
        return false;
    }

    // stake the token
    function _claimCarePackage(address _owner, uint16 _tokenId, bytes32 _hash, bytes memory _signature) internal returns (uint256 reward) {
        require((isClaimed(_tokenId) == false), "care package has already been claimed for this token");
        address signer = recoverSigner(_hash, _signature);
        uint8 rarity = 0;

        if(signer == rowdySigner){
            rarity = 0;
        } else if(signer == ragingSigner){
            rarity = 1;
        } else if(signer == royalSigner){
            rarity = 2;
        }

        reward = epochsToClaim;

        if(rarity == 0) {
            reward *= rowdyEpochYield;
        } else if(rarity == 1) {
            reward *= ragingEpochYield;
        } else if(rarity == 2) {
            reward *= royalEpochYield;
        }
        
        claimed[_tokenId] = 1;
        emit CarePackageClaimed(_tokenId, _owner, reward);
        return reward;
    }

    // checks if the care package has been claimed for this token id
    function isClaimed(uint16 _tokenId) public view returns (bool){
        if(claimed[_tokenId] == 1) {
            return true;
        } else {
            return false;
        }
    }

    // recovers the signer's address
    function recoverSigner(bytes32 _hash, bytes memory _signature) public pure returns (address) {
        bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
        return ECDSA.recover(messageDigest, _signature);
    }
}