// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./GrimaceSplitter.sol";

contract GrimaceNftStaking is Ownable, GrimaceSplitter {
    IERC721 public grimaceNFT;

    mapping(address => uint256) public stakedCount;
    mapping(uint256 => address) public stakedNFTOwner;  

    constructor(
        address _grimaceNFT
    ) GrimaceSplitter() Ownable() {
        grimaceNFT = IERC721(_grimaceNFT);       
    }

    function claimBnb(uint256[] memory tokenIds) external {
        require(msg.sender != address(0));
        require(tokenIds.length > 0, "No tokenIds found");
        for (uint i = 0; i < tokenIds.length; i++) {
            require(stakedNFTOwner[tokenIds[i]] == msg.sender);
        }
        release(tokenIds);
    }

    function claimLpTokens(IERC20[] memory tokens, uint256[] memory tokenIds) external {
        require(msg.sender != address(0));
        require(tokens.length > 0, "No tokens supplied");
        require(tokenIds.length > 0, "No tokenIds found");
        for (uint i = 0; i < tokenIds.length; i++) {
            require(stakedNFTOwner[tokenIds[i]] == msg.sender);
        }
        release(tokens, tokenIds);
    }

    function stake(uint256 tokenId) external {
        require(msg.sender != address(0));     
        require(stakedNFTOwner[tokenId] == address(0), "NFT already staked");
        require(grimaceNFT.ownerOf(tokenId) == msg.sender, "Sender does not own NFT");

        stakedNFTOwner[tokenId] = msg.sender;

        grimaceNFT.transferFrom(msg.sender, address(this), tokenId);
        stakedCount[msg.sender]++;
    }

    function unstake(uint256 tokenId) external {
        require(msg.sender != address(0));       
        require(stakedNFTOwner[tokenId] == msg.sender, "Sender does not own NFT");
        require(grimaceNFT.ownerOf(tokenId) == address(this), "NFT not staked");

        delete stakedNFTOwner[tokenId];

        grimaceNFT.transferFrom(address(this), msg.sender, tokenId);
        stakedCount[msg.sender]--;      
    }

    function stakeMany(uint256[] calldata manyTokenIds) external {
        require(msg.sender != address(0));
        require(manyTokenIds.length > 0, "No NFTs supplied");

        for (uint i = 0; i < manyTokenIds.length; i++) {
            uint256 tokenId = manyTokenIds[i];
            require(stakedNFTOwner[tokenId] == address(0), "NFT already staked");
            require(grimaceNFT.ownerOf(tokenId) == msg.sender, "Sender does not own NFT");

            stakedNFTOwner[tokenId] = msg.sender;

            grimaceNFT.transferFrom(msg.sender, address(this), tokenId); 
        }
        stakedCount[msg.sender] += manyTokenIds.length;
    }

    function unstakeMany(uint256[] calldata manyTokenIds) external {
        require(msg.sender != address(0));
        require(manyTokenIds.length > 0, "No NFTs supplied");

        for (uint i = 0; i < manyTokenIds.length; i++) {
            uint256 tokenId = manyTokenIds[i];
            require(stakedNFTOwner[tokenId] == msg.sender, "Sender does not own NFT");
            require(grimaceNFT.ownerOf(tokenId) == address(this), "NFT not staked");

            delete stakedNFTOwner[tokenId];

            grimaceNFT.transferFrom(address(this), msg.sender, tokenId);   
        }
        stakedCount[msg.sender] -= manyTokenIds.length;
    }

    function getStakedNFTsOfUser(address user) external view returns (uint256[] memory) {      
        uint256 amountStaked = stakedCount[user];

        uint256[] memory ownedNFTs = new uint256[](amountStaked);
        uint256 counter;

        for (uint i = 0; i <= 2560; i++) {
            address nftOwner = stakedNFTOwner[i];

            if (nftOwner == user) {
                ownedNFTs[counter] = i;
                counter++;
            }        
        }
        return ownedNFTs;
    }

    function setContracts(address _grimaceNFT) external onlyOwner {
        grimaceNFT = IERC721(_grimaceNFT);
    }

    function setApprovalForAll(address operator, bool _approved) external onlyOwner {
        grimaceNFT.setApprovalForAll(operator, _approved);
    }

    function setShares(uint256 newShares) external onlyOwner {
        _setShares(newShares);
    }

    function setPayees(uint256 newPayees) external onlyOwner {
        _setPayees(newPayees);
    }

    function setTotalShares(uint256 newShares) external onlyOwner {
        _setTotalShares(newShares);
    }
}