// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract UsdcAirdrop is Ownable, Pausable {
    IERC20 public token; // Airdrop token
    bytes32 public root; // merkle tree root
    uint256 public startTime;
    uint256 public claimDuration = 7 days; // 604800
    address[] private whitelistClaimed;


    constructor(IERC20 _token) onlyOwner {
        token = _token;
        startTime = block.timestamp;
    }

    function getWhitelistClaimed() public view returns(address[] memory) {
        return whitelistClaimed;
    }

    function remainingDuration() public view returns (uint256) {
        if(block.timestamp < (startTime + claimDuration)) {
            uint256 duration;
            duration = claimDuration - (block.timestamp - startTime);
            return duration;
        }else {
            return 0;
        }
    }

    function canClaim(bytes32[] memory merkleProof, uint256 amount) external view returns (bool) {
        require(block.timestamp <= (startTime + claimDuration), "Claim is not allowed after claimDuration");
        bytes32 result = leaf(amount);
        require(MerkleProof.verify(merkleProof, root, result), "Proof is not valid");
        if(!claimed(merkleProof, amount)) {
            return true;
        } else {
            return false;
        }
    }

    function claimed(bytes32[] memory merkleProof, uint256 amount) public view returns (bool) {
        bool checkClaimed = false;
        bytes32 result = leaf(amount);
        require(MerkleProof.verify(merkleProof, root, result), "Proof is not valid");
        if(whitelistClaimed.length > 0) {
            for(uint i = 0; i < whitelistClaimed.length; i++) {
                if(whitelistClaimed[i] == msg.sender) {
                    checkClaimed = true;
                }
            }
        }
        return checkClaimed;
    }

    function claim(bytes32[] memory merkleProof, uint256 amount) public whenNotPaused {
        require(block.timestamp <= (startTime + claimDuration), "Claim is not allowed after claimDuration");
        require(token.balanceOf(address(this)) >= amount, "Contract doesnt have enough tokens");
        if(whitelistClaimed.length > 0) {
            for(uint i = 0; i < whitelistClaimed.length; i++) {
                if(whitelistClaimed[i] == msg.sender) {
                    revert("Already Claimed");
                }
            }
        }
        bytes32 result = leaf(amount);
        require(MerkleProof.verify(merkleProof, root, result), "Proof is not valid");
        require(!claimed(merkleProof, amount), "Address has already claimed.");
        uint claimAmount = amount;
        token.transfer(msg.sender, claimAmount);
        whitelistClaimed.push(msg.sender);
        emit Claim(msg.sender, claimAmount, block.timestamp);
    }

    function setClaimDuration(uint256 _newDuration) public onlyOwner {
        require(claimDuration != _newDuration, "Same duration");
        claimDuration = _newDuration;
    }

    function setRoot(bytes32 _root) public onlyOwner {
        require(root != _root, "Same root");
        require(block.timestamp > (startTime + claimDuration), "claimDuration must be exceeded in order to update root");
        address[] memory reset;
        root = _root;
        startTime = block.timestamp;
        whitelistClaimed = reset;
        claimDuration = 1 days;
    }

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        IERC20(_tokenAddress).transfer(msg.sender, _tokenAmount);
        emit RecoveredERC20(_tokenAddress, _tokenAmount);
    }

    function recoverERC721(address _tokenAddress, uint256 _tokenId) external onlyOwner {
        IERC721(_tokenAddress).safeTransferFrom(address(this), msg.sender, _tokenId);
        emit RecoveredERC721(_tokenAddress, _tokenId);
    }

    function leaf(uint256 amount) internal view returns(bytes32){
        string memory l_amount=Strings.toString(amount);
        string memory l_acc = Strings.toHexString(msg.sender);
        string memory result = string(abi.encodePacked(l_acc,',',l_amount));
        return(keccak256(abi.encodePacked(result)));
    }

    event Claim(address claimer, uint256 claimAmount, uint timestamp);
    event RecoveredERC20(address token, uint256 amount);
    event RecoveredERC721(address token, uint256 tokenId);
}