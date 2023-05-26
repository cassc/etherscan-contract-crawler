// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "./IMigration.sol";


contract SuperNormalHarvesterV2 is OwnableUpgradeable{

    bool public stakingOn;

    IERC721Enumerable public SNContractOLD;
    IMigration public SNContractNEW;

    mapping (uint256 => uint256) public tokenLastStakedAt;
    mapping (address => uint256[]) public stakedTokensOfWallet;

    address public burnAddress;
    

    function initialize(address oldSNContract, address newSNContract) initializer public {
        __Ownable_init();
    
        SNContractOLD = IERC721Enumerable(oldSNContract);
        SNContractNEW = IMigration(newSNContract);
    }

    event Staked(address indexed wallet, uint256 indexed tokenID, uint256 indexed stakeTime);
    event Unstaked(address indexed wallet, uint256 indexed tokenID, uint256 indexed unstakeTime);

    function stakeSwitch() public onlyOwner{
        stakingOn = !stakingOn;
    }

    function removeFromStaking (address wallet, uint256 tokenID) internal {
        uint256[] storage array = stakedTokensOfWallet[wallet];
        bool success;

        for(uint index = 0; index < array.length; ++index){
            if(array[index] == tokenID){
                array[index] = array[array.length - 1];
                array.pop();
                stakedTokensOfWallet[wallet] = array;
                success = true;
                break;
            }
        }

        if(!success){
            revert("You dont own at least one of the tokens");
        }
        
    }

    function stakeToken(uint256[] calldata tokenIDs) external {
        require(stakingOn,"Staking is not on");

        for(uint i; i < tokenIDs.length; ){
            uint currentToken = tokenIDs[i];

            if(SNContractOLD.ownerOf(currentToken) == msg.sender){
                SNContractOLD.transferFrom(msg.sender, burnAddress, currentToken);
            }else if(SNContractNEW.ownerOf(currentToken) == msg.sender){
                SNContractNEW.transferFrom(msg.sender, address(this), currentToken);
            }else{
                revert("You dont own at least one of the tokens");
            }
            
            stakedTokensOfWallet[msg.sender].push(currentToken);
            tokenLastStakedAt[currentToken] = block.timestamp;
            emit Staked(msg.sender, currentToken, block.timestamp);

            unchecked{
                ++i;
            }
        }
        
    }

    function unstakeToken(uint256[] calldata tokenIDs) external{
        require(stakingOn,"Staking is not on");

        for(uint i; i < tokenIDs.length;){
            uint currentToken = tokenIDs[i];
            removeFromStaking(msg.sender, currentToken);
            if(SNContractNEW.isClaimed(currentToken)){
                SNContractNEW.transferFrom(address(this), msg.sender, currentToken);
            }else{
                SNContractNEW.mint(msg.sender, currentToken);
            }
            
            tokenLastStakedAt[currentToken] = 0;
            emit Unstaked(msg.sender, currentToken, block.timestamp);
            unchecked{
                ++i;
            }
        }
    }

    function setBurnAddress(address newBurnAddress) external onlyOwner {
        burnAddress = newBurnAddress;
    }

    function migrateTokens(uint[] memory tokenIDs) external{
        for(uint i = 0; i < tokenIDs.length;++i){
            uint256 currentToken = tokenIDs[i];
            require(SNContractOLD.ownerOf(currentToken) == msg.sender,"You dont own this token");
            require(!(SNContractNEW.isClaimed(currentToken)),"This token is already claimed");
            SNContractOLD.transferFrom(msg.sender, burnAddress, currentToken);
            SNContractNEW.mint(msg.sender, currentToken);

        }        
    } 
}