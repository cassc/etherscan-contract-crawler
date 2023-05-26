/**
 *Submitted for verification at Etherscan.io on 2023-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

contract AsterFiStaking {
    
    struct Stake {
        address owner;
        uint256 tokenId;
        uint256 stakedAt;
        uint256 unstakeAvailableAt;
        bool active;
    }
    
    mapping(address => mapping(uint256 => Stake)) public stakes;
    mapping(address => uint256[]) public stakedNFTs;
    
    uint256 public stakingPeriod = 12 * 30 days;
    IERC721 public _AsterFiContract;

    constructor(address nftContract) {
        _AsterFiContract = IERC721(nftContract);
    }
    
    function stake(uint256 _tokenId) external {
        require(_AsterFiContract.ownerOf(_tokenId) == msg.sender, "You don't own this NFT");
        require(stakes[msg.sender][_tokenId].active == false, "NFT already staked");
        
        stakes[msg.sender][_tokenId] = Stake(msg.sender, _tokenId, block.timestamp, block.timestamp + stakingPeriod, true);
        
        stakedNFTs[msg.sender].push(_tokenId);
        
        _AsterFiContract.transferFrom(msg.sender, address(this), _tokenId);
    }
    
    function unstake(uint256 _tokenId) external {
        require(stakes[msg.sender][_tokenId].active == true, "NFT not staked");
        require(stakes[msg.sender][_tokenId].unstakeAvailableAt <= block.timestamp, "Cannot unstake yet");
        
    uint256[] storage userStakedNFTs = stakedNFTs[msg.sender];
    for (uint256 i = 0; i < userStakedNFTs.length; i++) {
        if (userStakedNFTs[i] == _tokenId) {
            userStakedNFTs[i] = userStakedNFTs[userStakedNFTs.length - 1];
            userStakedNFTs.pop();
            break;
        }
    }
    
    delete stakes[msg.sender][_tokenId];
        
        _AsterFiContract.transferFrom(address(this), msg.sender, _tokenId);
    }
    
    function getStakeInfo(address _owner, uint256 _tokenId) external view returns (Stake memory) {
        return stakes[_owner][_tokenId];
    }
    
    function getStakedNFTs(address _owner) external view returns (uint256[] memory) {
        return stakedNFTs[_owner];
    }
    
}