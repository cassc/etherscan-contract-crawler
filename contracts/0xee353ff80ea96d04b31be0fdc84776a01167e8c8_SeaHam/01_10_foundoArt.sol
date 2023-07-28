// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract SeaHam is ERC721A, DefaultOperatorFilterer, Ownable {
    using SafeMath for uint256;
    string public baseUri;
    uint256 public maxCount = 69;
    mapping(uint256 => uint256) internal stakeMap;
    bool stakeAvailable = false;
    bool unstakeAvailable = false;

    constructor() ERC721A("Sea Ham - Fashion Voyage by Che-Yu Wu", "SEA HAM") {}

    event MintSuccess(address indexed operatorAddress, uint256 startId, uint256 quantity, uint256 price, string nonce, uint256 blockHeight);

    event MetadataUpdate(uint256 _tokenId);

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    event TokenLocked(uint256 indexed tokenId, address indexed approvedContract);

    event Stake(uint256 indexed tokenId);

    event TokenUnlocked(uint256 indexed tokenId, address indexed approvedContract);

    event Unstake(uint256 indexed tokenId, uint256 stakedAtTimestamp, uint256 removedFromStakeAtTimestamp);

    //******Settings******
    function setBaseURI(string memory _newURI) external onlyOwner {
        baseUri = _newURI;
    }

    function setMaxCount(uint256 _maxCount) external onlyOwner {
        maxCount = _maxCount;
    }

    function setStakeAvailable(bool _stakeAvailable) external onlyOwner {
        stakeAvailable = _stakeAvailable;
    }

    function setUnstakeAvailable(bool _unstakeAvailable) external onlyOwner {
        unstakeAvailable = _unstakeAvailable;
    }

    function airdrop(address to, uint256 quantity) external onlyOwner {
        require(
            _nextTokenId() + quantity <= maxCount,
            "The quantity exceeds the stock!"
        );
        _safeMint(to, quantity);
    }

    function batchAirdrop(
        address[] memory _address,
        uint256[] memory _quantities
    ) external onlyOwner {
        uint256 total;
        for (uint i = 0; i < _quantities.length; i++) {
            total += _quantities[i];
        }
        require(
            _nextTokenId() + total <= maxCount,
            "The quantity exceeds the stock!"
        );
        for (uint i = 0; i < _address.length; i++) {
            _safeMint(_address[i], _quantities[i]);
        }
    }

    function withdrawAll() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdraw(uint256 amount) external payable onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function adminStake(uint256[] memory tokenIds) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (stakeMap[tokenId] == 0) {
                stakeMap[tokenId] = block.timestamp;
                emit Stake(tokenId);
            }
        }
    }

    function adminUnstake(uint256[] memory tokenIds) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (stakeMap[tokenId] > 0) {
                uint256 stakedTime = stakeMap[tokenId];
                stakeMap[tokenId] = 0;
                emit Unstake(tokenId, stakedTime, block.timestamp);
            }
        }
    }

    function adminMetadataUpdate(uint256 _tokenId) external onlyOwner {
        emit MetadataUpdate(_tokenId);
    }

    function adminBatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId) external onlyOwner {
        emit BatchMetadataUpdate(_fromTokenId, _toTokenId);
    }

    function adminTokenLocked(uint256 tokenId, address approvedContract) external onlyOwner {
        emit TokenLocked(tokenId, approvedContract);
    }

    function adminTokenUnlocked(uint256 tokenId, address approvedContract) external onlyOwner {
        emit TokenUnlocked(tokenId, approvedContract);
    }

    //******Functions******
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }

    function checkStakeStatus(uint256 tokenId) external view returns (uint256)  {
        return stakeMap[tokenId];
    }

    function stake(uint256[] memory tokenIds) external {
        require(stakeAvailable, "local stake not available!");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender, "Caller is not owner!");

            if (stakeMap[tokenId] == 0) {
                stakeMap[tokenId] = block.timestamp;
                emit Stake(tokenId);
            }
        }
    }

    function unstake(uint256[] memory tokenIds) external {
        require(unstakeAvailable, "local redeem not available!");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender, "Caller is not owner!");

            if (stakeMap[tokenId] > 0) {
                uint256 stakedTime = stakeMap[tokenId];
                stakeMap[tokenId] = 0;
                emit Unstake(tokenId, stakedTime, block.timestamp);
            }
        }
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override
    {
        require(stakeMap[startTokenId] == 0, "This token is staking!");
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    //******OperatorFilterer******
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}