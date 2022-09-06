// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721AV4.sol";

contract Nanobits is ERC20Burnable, Ownable {
    uint256 public _maxSupply = 100000000 * 10**18;
    uint256 public _initialSupply = 51000000 * 10**18;
    bool public isStakingLive = false;

    uint256 public constant legendaryRatePerDay = 69444444444444; // 6 $NANOBITS per day for 1/1s
    uint256 public constant commonRatePerDay = 34722222222222; // 3 $NANOBITS per day for common

    struct StakingData {
        uint256 timeStaked;
        address owner;
        uint256 rarity;
    }

    struct StakingParams {
        uint256 tokenId;
        uint256 rarity;
    }

    mapping(uint256 => StakingData) stakedData;
    mapping(address => uint256[]) internal tokenIds;

    mapping(address => uint256) addressBlockBought;
    address signer;

    address public constant PROJECT_ADDRESS = 0xf3a823bf459b00702904C9bA90BFA19e04787261; 

    ERC721A private yagiContract;
    constructor(address _signer, address _yagiContract) ERC20("Nanobits", "NANOB") {
        signer = _signer;
        yagiContract = ERC721A(_yagiContract);
        _mint(PROJECT_ADDRESS, _initialSupply);
    }

    function getStaked(address _owner) public view returns (uint256[] memory) {
        return tokenIds[_owner];
    }

    function getOwner(uint256 tokenId) public view returns (address) {
        return stakedData[tokenId].owner;
    }
    
    function toggleStaking() external onlyOwner {
        isStakingLive = !isStakingLive;
    }

    function removeTokenIdFromArray(uint256[] storage array, uint256 tokenId) internal {
        uint256 length = array.length;
        for (uint256 i = 0; i < length; i++) {
            if (array[i] == tokenId) {
                length--;
                if (i < length) {
                    array[i] = array[length];
                }
                array.pop();
                break;
            }
        }
    }

    // STAKING FUNCTIONS
    function stake(uint256[] memory _tokenIds, uint64 expireTime, bytes memory sig, uint256[] calldata rarity) external {
        require(totalSupply() <= _maxSupply, "NO_MORE_MINTABLE_SUPPLY");
        require(addressBlockBought[msg.sender] < block.timestamp, "CANNOT_TRANSACT_THE_SAME_BLOCK");
        require(tx.origin == msg.sender,"CONTRACTS_NOT_ALLOWED_TO_MINT");
        require(isStakingLive, "STAKING_IS_NOT_YET_ACTIVE");
        bytes32 digest = keccak256(abi.encodePacked(msg.sender, expireTime));
        require(isAuthorized(sig,digest),"CONTRACT_MINT_NOT_ALLOWED");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 id = _tokenIds[i];
            require(yagiContract.ownerOf(id) == msg.sender && stakedData[id].owner == address(0), "TOKEN_IS_NOT_YOURS");
            yagiContract.transferFrom(msg.sender, address(this), id);

            tokenIds[msg.sender].push(id);
            stakedData[id].timeStaked = block.timestamp;
            stakedData[id].owner = msg.sender;
            stakedData[id].rarity = rarity[i];
            addressBlockBought[msg.sender] = block.timestamp;
        }
    }

    // UNSTAKE FUNCTIONS
    function unstake(uint256[] memory _tokenIds) public {
        require(tokenIds[msg.sender].length > 0, "NO_STAKED_YAGI");
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 id = _tokenIds[i];
            require(stakedData[id].owner == msg.sender, "Not Owner");

            yagiContract.transferFrom(address(this), msg.sender, id);
            uint256 rewards = claim(id);
            totalRewards += rewards;

            removeTokenIdFromArray(tokenIds[msg.sender], id);
            stakedData[id].owner = address(0);
        }
        if(totalSupply() <= _maxSupply) {
            _mint(msg.sender, totalRewards);
        }
    }

    // CLAIM FUNCTIONS
    function claimAll() public {
        require(totalSupply() <= _maxSupply, "NO_MORE_MINTABLE_SUPPLY");
        require(tokenIds[msg.sender].length > 0, "NO_STAKED_YAGI");
        uint256 totalRewards = 0;

        uint256[] memory _tokensIds = tokenIds[msg.sender];
        for (uint256 i = 0; i < _tokensIds.length; i++) {
            uint256 id = _tokensIds[i];
            require(stakedData[id].owner == msg.sender, "Not Owner");

            uint256 rewards = claim(id);
            stakedData[id].timeStaked = block.timestamp;
            totalRewards += rewards;
        }

        _mint(msg.sender, totalRewards);
    }

    function claim(uint256 id) internal view returns(uint256) {
        uint256 totalRewards = 0;
        uint256 ratePerday = 0;

        if(stakedData[id].rarity == 1) {
            ratePerday = legendaryRatePerDay;
        } else {
            ratePerday = commonRatePerDay;
        }
        uint256 numOfDays = ((block.timestamp - stakedData[id].timeStaked) / 1 days) * 1e18;
        if(numOfDays > 14) {
            uint256 reward = ((block.timestamp - stakedData[id].timeStaked) * ratePerday);
            uint256 multiplier = 1e18 + (numOfDays * 14 / 1000000);
            totalRewards = (reward * multiplier) / 1e18;
        }

        if(numOfDays > 30) {
            uint256 reward = ((block.timestamp - stakedData[id].timeStaked) * ratePerday);
            uint256 multiplier = 1e18 + (numOfDays * 28 / 1000000);
            totalRewards = (reward * multiplier) / 1e18;
        }

        if(numOfDays > 90) {
            uint256 reward = ((block.timestamp - stakedData[id].timeStaked) * ratePerday); // days reward
            uint256 multiplier = 1e18 + (numOfDays * 98 / 1000000);
            totalRewards = (reward * multiplier) / 1e18;
        }

        if(numOfDays < 14) {
            totalRewards += ((block.timestamp - stakedData[id].timeStaked) * ratePerday);
        }

        return totalRewards;
    }


    // CHECKERS
    function checkRewardsByIds(uint256 tokenId) external view returns (uint256) {
        require(stakedData[tokenId].owner != address(0), "TOKEN_NOT_BURIED");

        uint256 rewards = claim(tokenId);
        return rewards;
    }

    function checkAllRewards(address _owner) external view returns (uint256) {
        uint256 totalRewards = 0;
        uint256[] memory _tokensIds = tokenIds[_owner];

        for (uint256 i = 0; i < _tokensIds.length; i++) {
            uint256 id = _tokensIds[i];

            uint256 rewards = claim(id);
            totalRewards += rewards;
        }

        return totalRewards;
    }
    // SETTERS

    function setSigner(address _signer) external onlyOwner{
        signer = _signer;
    }

    function setYagiContract(address yagiContractAddress) external onlyOwner{
        yagiContract = ERC721A(yagiContractAddress);
    }

    function isAuthorized(bytes memory sig, bytes32 digest) private view returns (bool) {
        return ECDSA.recover(digest, sig) == signer;
    }
}