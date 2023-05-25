// SPDX-License-Identifier: UNLICENCED

pragma solidity 0.8.10;

import "./ERC721Common.sol";
import "./SimejiSeller.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SimejiNFT is ERC721Common, SimejiSeller {
    using Strings for uint256;

    struct OperateConfig {
        uint256 whiteListSaleBegin;
        uint256 whiteListSaleEnd;
        bytes32 merkleRoot;
        uint256 publicSaleBegin;
    }

    OperateConfig public operateConfig;

    constructor(string memory name, string memory symbol)
        ERC721Common(name, symbol)
        SimejiSeller(
            SimejiSeller.SellerConfig({
                totalInventory: 10000,
                airdropQuota: 300,
                reserveQuota: 0,
                lockTotalInventory: true,
                lockFreeQuota: true,
                reserveFreeQuota: true,
                maxPerAddress: 1,
                maxPerTx: 1
            })
        )
    {
        operateConfig = OperateConfig({
            whiteListSaleBegin: 1661738400,
            whiteListSaleEnd: 1661997599,
            merkleRoot: '',
            publicSaleBegin: 1661997600
        });
    }

    function airdrop(address to, uint256 requested) external onlyOwner {
        SimejiSeller._airdrop(to, requested);
    }

    function publicBuy(uint256 requested) external {
        require(block.timestamp >= operateConfig.publicSaleBegin, "SimejiNFT: Public sale not start!");

        SimejiSeller._purchase(msg.sender, requested);
    }
    
    function whitelistBuy(uint256 requested, bytes32[] calldata signature) external {
        require(block.timestamp >= operateConfig.whiteListSaleBegin
                && block.timestamp <= operateConfig.whiteListSaleEnd,
                "SimejiNFT: White list sale not start!");
        require(verify(_msgSender(), signature), "caller is not in whitelist");

        SimejiSeller._purchase(msg.sender, requested);
    }

    function _handlePurchase(
        address to,
        uint256 num
    ) internal override {
        for (uint256 i = 0; i < num; i++) {
            _safeMint(to, totalSold() + i);
        }
    }

    string public baseTokenURI;

    function setBaseTokenURI(string memory baseTokenURI_) external onlyOwner {
        baseTokenURI = baseTokenURI_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        tokenExists(tokenId)
        returns (string memory)
    {
        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }

    function totalSupply() external view returns (uint256) {
        return totalSold();
    }

    function setOperateConfig(OperateConfig memory config) external onlyOwner {
        operateConfig = config;
    }

    function verify(address to, bytes32[] calldata merkleProof) public view returns(bool) {
        if (operateConfig.merkleRoot == "") {
            return false;
        }

        bytes32 leaf = keccak256(abi.encodePacked(to));
        return MerkleProof.verify(merkleProof, operateConfig.merkleRoot, leaf);
    }

    function hadBought(address addr) external view returns(bool) {
        return SimejiSeller._hadBought(addr);
    }
}