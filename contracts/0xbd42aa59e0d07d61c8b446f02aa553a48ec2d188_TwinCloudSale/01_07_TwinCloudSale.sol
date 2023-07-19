// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interface/ITwinCloud.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


contract TwinCloudSale is Ownable, IERC721Receiver, ReentrancyGuard {

    address public twinCloud;

    uint256 public maxSalesPerAccount;

    uint256 public salePrice;

    uint256 public startTime;

    uint256 public whitelistSaleInterval;

    bytes32 public whiteListMerkleRoot;

    mapping(address => uint256) public userSales;

    constructor(address twinCloud_, 
        uint256 maxSalesPerAccount_,
        uint256 salePrice_,
        uint256 startTime_,
        uint256 whitelistSaleInterval_) {

        twinCloud = twinCloud_;
        maxSalesPerAccount = maxSalesPerAccount_;
        salePrice = salePrice_;
        startTime = startTime_;
        whitelistSaleInterval = whitelistSaleInterval_;
    }

    function whiteListSales(
        uint256 index,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external payable nonReentrant{
        require(block.timestamp >= startTime, "sale did not start");
        require(block.timestamp <= startTime + whitelistSaleInterval, "whitelist sales ended");
        uint256 salt = 0x0a;
        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, salt));
        require(
            MerkleProof.verify(merkleProof, whiteListMerkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );
        _sale(msg.sender, amount);
    }

    function isWhiteList(uint256 index, address account, bytes32[] calldata merkleProof) external view returns(bool){
        uint256 salt = 0x0a;
        bytes32 node = keccak256(abi.encodePacked(index, account, salt));
        return MerkleProof.verify(merkleProof, whiteListMerkleRoot, node);

    }

    function publicSales(uint256 amount) external payable nonReentrant{
        require((startTime + whitelistSaleInterval) <= block.timestamp, "public sale did not start");
        _sale(msg.sender, amount);
    }

    function _sale(address account, uint256 amount) internal{
        require(amount > 0, "sales:invalid sale amount");
        require(salePrice * amount <= msg.value, "sales: Insufficient Balance");
        require( (userSales[account] + amount) <= maxSalesPerAccount, "sales:exceed max sales");

        userSales[account] = userSales[account] + amount;
        ITwinCloud(twinCloud).safeMint(account, amount);
    }


    //===================admin function================

    function setTwinCloud(address twinCloud_) external onlyOwner{
        twinCloud = twinCloud_;
    }

    function setMaxSalesPerAccount(uint256 newMaxSales_) external onlyOwner{
        maxSalesPerAccount = newMaxSales_;
    }

    function setSalePrice(uint256 salePrice_) external onlyOwner{
        salePrice = salePrice_;
    }

    function setStartTime(uint256 startTime_) external onlyOwner {
        startTime = startTime_;
    }

    function setWhitelistSaleInterval(uint256 whitelistSaleInterval_) external onlyOwner{
        whitelistSaleInterval = whitelistSaleInterval_;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot_) external onlyOwner{
        whiteListMerkleRoot = merkleRoot_;
    }

    function withdraw() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }

    //===================view function ===================
    

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}