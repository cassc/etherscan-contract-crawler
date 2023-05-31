// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./Mike.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";

contract MikePresale is Ownable {
    uint256 private _totalContribution;

    uint256 public constant MAX_INDIVIDUAL_CONTRIBUTION = 1 ether;
    uint256 public constant LIQUIDITY_ALLOCATION = 2_000_000_000 ether; // 20% of total supply
    uint256 public constant PRESALE_ALLOCATION = 3_500_000_000 ether; // 35% of total supply
    uint256 public constant PUBLIC_SALE_DURATION = 10; // 10 blocks

    Mike public mike;

    uint256 public finalizedOnBlock;

    bytes32 public whitelistMerkleRoot;
    bool public whitelistEnabled;
    uint256 public publicSaleEndBlock;

    mapping(address => uint256) public contributions;

    function updateMerkleRoot(bytes32 whitelistMerkleRoot_) external onlyOwner {
        whitelistMerkleRoot = whitelistMerkleRoot_;
    }

    function setMike(address mike_) external onlyOwner {
        mike = Mike(mike_);
    }

    function finalize() external payable onlyOwner {
        _totalContribution = address(this).balance;
        finalizedOnBlock = block.number;

        mike.approve(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
            type(uint256).max
        );

        (bool success, ) = owner().call{
            value: (_totalContribution * 250) / 1000
        }("");

        require(success, "Presale: failed to transfer funds");

        IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)
            .addLiquidityETH{value: address(this).balance}(
            address(mike),
            LIQUIDITY_ALLOCATION,
            0,
            0,
            msg.sender,
            block.timestamp + 30 minutes
        );
    }

    function setPublicPresale() external onlyOwner {
        publicSaleEndBlock = block.number + PUBLIC_SALE_DURATION;
    }

    function setWhitelistEnabled(bool state) external onlyOwner {
        whitelistEnabled = state;
    }

    function reserveMikesForPublicPresale() external payable {
        require(
            publicSaleEndBlock > 0,
            "Presale: public presale has not started"
        );
        require(
            block.number <= publicSaleEndBlock,
            "Presale: presale has ended"
        );
        _contribute(msg.sender, msg.value);
    }

    function reserveMikesForWhitelistPresale(
        bytes32[] calldata proof
    ) external payable {
        require(whitelistEnabled, "Presale: whitelist presale has not started");

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

        require(
            MerkleProof.verify(proof, whitelistMerkleRoot, leaf),
            "Presale: Invalid proof"
        );

        _contribute(msg.sender, msg.value);
    }

    function claim() external {
        require(finalizedOnBlock > 0, "Presale: presale has not finalized");
        uint256 claimable = contributions[msg.sender];
        require(claimable > 0, "Presale: you have no shares to claim");
        delete contributions[msg.sender];

        mike.transfer(
            msg.sender,
            (claimable * PRESALE_ALLOCATION) / getTotalContribution()
        );
    }

    function getTotalContribution() public view returns (uint256) {
        return
            finalizedOnBlock > 0 ? _totalContribution : address(this).balance;
    }

    function _contribute(address account, uint256 amount) internal {
        require(
            contributions[account] + amount <= MAX_INDIVIDUAL_CONTRIBUTION,
            "Presale: max contribution exceeded"
        );

        contributions[account] += amount;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Presale: failed to withdraw funds");
    }
}