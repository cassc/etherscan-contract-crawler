// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./WhiteRabbitProducerPass.sol";

contract WhiteRabbitProducerPassDistribution is ERC1155Holder, Ownable {
    event ProducerPassBought(
        uint256 episodeId,
        address indexed account,
        uint256 amount
    );

    WhiteRabbitProducerPass public producerPassContract;
    address public treasury;

    mapping(uint256 => ProducerPass) private _episodeToProducerPass;

    mapping(address => mapping(uint256 => uint256))
        private _userPassesMintedPerTokenId;

    mapping(address => mapping(uint256 => uint256))
        private _userPassesMintedPerTokenIdOnEarlyMint;

    constructor(address producerPassContract_, address treasury_) {
        producerPassContract = WhiteRabbitProducerPass(producerPassContract_);
        treasury = treasury_;
    }

    function _merkleLeafForUserAndAllowedAmount(address user, uint256 amount)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(user, amount));
    }

    function earlyMintProducerPass(
        uint256 episodeId,
        uint256 amountAllowed,
        uint256 amountMinting,
        bytes32[] calldata merkleProof
    ) external payable noContract {
        ProducerPass memory pass = _episodeToProducerPass[episodeId];

        bytes32 merkleLeaf = _merkleLeafForUserAndAllowedAmount(
            msg.sender,
            amountAllowed
        );
        require(
            MerkleProof.verify(merkleProof, pass.merkleRoot, merkleLeaf),
            "Not authorized to mint"
        );
        require(amountMinting <= amountAllowed, "Exceeding allocation");
        // here we check against balance of this contract rather than max supply
        require(
            producerPassContract.balanceOf(address(this), episodeId) >=
                amountMinting,
            "Sold out"
        );
        uint256 totalMintedPasses = _userPassesMintedPerTokenIdOnEarlyMint[
            msg.sender
        ][episodeId];
        require(
            totalMintedPasses + amountMinting <= amountAllowed,
            "Exceeding total allocation"
        );
        require(msg.value == pass.price * amountMinting, "Not enough eth");

        _userPassesMintedPerTokenIdOnEarlyMint[msg.sender][episodeId] =
            totalMintedPasses +
            amountMinting;
        producerPassContract.safeTransferFrom(
            address(this),
            msg.sender,
            episodeId,
            amountMinting,
            ""
        );
        emit ProducerPassBought(episodeId, msg.sender, amountMinting);
    }

    function mintProducerPass(uint256 episodeId, uint256 amount)
        external
        payable
        noContract
    {
        ProducerPass memory pass = _episodeToProducerPass[episodeId];

        require(
            block.timestamp >= pass.openMintTimestamp,
            "Mint is not available"
        );
        require(
            producerPassContract.balanceOf(address(this), episodeId) >= amount,
            "Sold out"
        );

        uint256 totalMintedPasses = _userPassesMintedPerTokenId[msg.sender][
            episodeId
        ];
        require(
            totalMintedPasses + amount <= pass.maxPerWallet,
            "Exceeding maximum per wallet"
        );
        require(msg.value == pass.price * amount, "Not enough eth");

        _userPassesMintedPerTokenId[msg.sender][episodeId] =
            totalMintedPasses +
            amount;
        producerPassContract.safeTransferFrom(
            address(this),
            msg.sender,
            episodeId,
            amount,
            ""
        );
        emit ProducerPassBought(episodeId, msg.sender, amount);
    }

    function userPassesMintedByEpisodeId(uint256 episodeId)
        external
        view
        returns (uint256)
    {
        return _userPassesMintedPerTokenId[msg.sender][episodeId];
    }

    function userPassesEarlyMintedByEpisodeId(uint256 episodeId)
        external
        view
        returns (uint256)
    {
        return _userPassesMintedPerTokenIdOnEarlyMint[msg.sender][episodeId];
    }

    function getEpisodeToProducerPass(uint256 episodeId)
        external
        view
        returns (ProducerPass memory)
    {
        return _episodeToProducerPass[episodeId];
    }

    /**
     * Owner methods
     */

    function reserveProducerPassesForGifting(
        uint256 episodeId,
        uint256 amountEachAddress,
        address[] calldata addresses
    ) public onlyOwner {
        require(amountEachAddress > 0, "Amount cannot be 0");
        require(
            amountEachAddress * addresses.length <=
                producerPassContract.balanceOf(address(this), episodeId),
            "Cannot mint that many"
        );
        require(addresses.length > 0, "Need addresses");
        for (uint256 i = 0; i < addresses.length; i++) {
            address add = addresses[i];
            producerPassContract.safeTransferFrom(
                address(this),
                add,
                episodeId,
                amountEachAddress,
                ""
            );
        }
    }

    function setProducerPass(
        uint256 price,
        uint256 episodeId,
        uint256 maxSupply,
        uint256 maxPerWallet,
        uint256 openMintTimestamp,
        bytes32 merkleRoot
    ) external onlyOwner {
        _episodeToProducerPass[episodeId] = ProducerPass(
            price,
            episodeId,
            maxSupply,
            maxPerWallet,
            openMintTimestamp,
            merkleRoot
        );
    }

    function setMerkleRoot(uint256 episodeId, bytes32 merkleRoot)
        external
        onlyOwner
    {
        _episodeToProducerPass[episodeId].merkleRoot = merkleRoot;
    }

    function setTreasury(address treasuryAddress) external onlyOwner {
        treasury = treasuryAddress;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        bool success;
        // Transfer balance to treasury
        (success, ) = treasury.call{value: balance}("");
        require(success, "Withdraw unsuccessful");
    }

    modifier noContract() {
        require(tx.origin == msg.sender, "no contract");
        _;
    }
}