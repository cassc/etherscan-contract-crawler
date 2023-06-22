// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FMBClaim is Ownable, ReentrancyGuard, IERC721Receiver {
    
    uint256 period = 45 days;
    uint256 public unitToken = 2000 ether;
    address public GenesisBirdAddress = 0x679bDD1c961cE28E427BCC2a9BF982C92A99c73A;
    address public FMBAddress = 0x52284158E02425290f6B627Aeb5FFF65eDf058Ad;

    struct DepositNFT{
        address owner;
        uint256 depositTimestamp; 
    }
    mapping(uint256 => DepositNFT) public DepositInfo;
    mapping(address => uint256[]) private DepositList;
    mapping(uint256 => bool) public claimed;

    event Deposit(uint256 id, address owner);
    event Cancel(uint256 id, address owner);
    event Withdraw(uint256 id, address owner, uint256 tokenAmount);

    constructor() {}

    function _release( address holder, uint256 releasedAmount) internal {
        IERC20 token = IERC20(FMBAddress);
        token.transfer( holder, releasedAmount);
    }

    function _addElement(address _owner ,uint256 _element) internal {
        DepositList[_owner].push(_element);
    }

    function _removeDeposit(address _owner ,uint256 _element) internal {
        for (uint256 i = 0; i < DepositList[_owner].length; i++) {
            if (DepositList[_owner][i] == _element) {
                DepositList[_owner][i] = DepositList[_owner][DepositList[_owner].length - 1];
                DepositList[_owner].pop();
                break;
            }
        }
    }

    function getTokenStake(uint256 tokenId) public view returns (bool) {
        IERC721 nft = IERC721(GenesisBirdAddress); 
        if (nft.ownerOf(tokenId) == address(this)) {
            return block.timestamp >= DepositInfo[tokenId].depositTimestamp + period;
        } else {
            return false;
        }
    }

    function getOwnedTokenIdList(
        address owner,
        uint256 start,
        uint256 end
    ) external view returns (uint256[] memory tokenIdList) {
        require(start < end, "end must over start");
        IERC721 erc721 = IERC721(GenesisBirdAddress);
        uint256[] memory list = new uint256[](end - start);
        uint256 index;
        for (uint256 tokenId = start; tokenId < end; tokenId++) {
            if (erc721.ownerOf(tokenId) == owner) {
                list[index] = tokenId;
                index++;
            
            }
            
        }
        tokenIdList = new uint256[](index);
        for (uint256 i; i < index; i++) {
            tokenIdList[i] = list[i];
        }
    }

    function getStakeList(address _walletAddress) public view returns (uint256[] memory) {
        return DepositList[_walletAddress];
    }

    function getStakeListInfo(address _walletAddress) public view returns (DepositNFT[] memory) {
        uint256[] memory list = getStakeList(_walletAddress);
        DepositNFT[] memory depositList = new DepositNFT[](list.length);
        for (uint256 i = 0; i < list.length; i++) 
        {
            depositList[i] = DepositInfo[list[i]];
        }
        return depositList;
    }

    function batchStake(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) 
        {
            stakeBird(tokenIds[i]);
        }
    }

    function batchCancel(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) 
        {
            cancelStake(tokenIds[i]);
        }
    }

    function batchWithdraw(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) 
        {
            withdraw(tokenIds[i]);
        }
    }

    function stakeBird(uint256 tokenId) public {
        require(claimed[tokenId] == false, "Claimed");
        DepositNFT storage depositItem = DepositInfo[tokenId];
        depositItem.owner = msg.sender;
        depositItem.depositTimestamp = block.timestamp;
        _addElement(msg.sender, tokenId);
        IERC721 nft = IERC721(GenesisBirdAddress);
        nft.safeTransferFrom(msg.sender, address(this), tokenId);
        emit Deposit(tokenId, msg.sender);
    }

    function cancelStake(uint256 tokenId) public {
        require(DepositInfo[tokenId].owner == msg.sender, "Not deposited");
        IERC721 nft = IERC721(GenesisBirdAddress);
        require(nft.ownerOf(tokenId) == address(this), "Invalid Order"); 
        nft.safeTransferFrom(address(this), msg.sender, tokenId);
        emit Cancel(tokenId, msg.sender);
        _removeDeposit(msg.sender, tokenId);
        delete DepositInfo[tokenId];
    }

    function withdraw(uint256 tokenId) public nonReentrant {
        require(getTokenStake(tokenId), "Not withdraw");
        require(DepositInfo[tokenId].owner == msg.sender, "Not deposited");
        IERC721 nft = IERC721(GenesisBirdAddress);
        require(nft.ownerOf(tokenId) == address(this), "Invalid Order"); 
        nft.safeTransferFrom(address(this), msg.sender, tokenId);
        uint256 tokenAmount = unitToken;
        _release(msg.sender, tokenAmount);
        claimed[tokenId] = true;
        emit Withdraw(tokenId, msg.sender, tokenAmount);
        _removeDeposit(msg.sender, tokenId);
        delete DepositInfo[tokenId];
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function withdrawToken(uint256 _amount) external onlyOwner {
        _release(owner(), _amount);
    }

    function setGBAddress(address GB) external onlyOwner {
        GenesisBirdAddress = GB;
    }

    function setFMBAddress(address FMB) external onlyOwner {
        FMBAddress = FMB;
    }

    function setPeriod(uint256 _period) external onlyOwner {  
        period = _period;
    }

}