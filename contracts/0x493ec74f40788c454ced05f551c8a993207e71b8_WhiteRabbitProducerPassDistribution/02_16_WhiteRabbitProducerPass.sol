// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

struct ProducerPass {
    uint256 price;
    uint256 episodeID;
    uint256 maxSupply;
    uint256 maxPerWallet;
    uint256 openMintTimestamp; // unix timestamp in seconds
    bytes32 merkleRoot;
}

contract WhiteRabbitProducerPass is ERC1155, ERC1155Supply, Ownable {
    using Strings for uint256;
    string public name;
    string public symbol;
    address payable private artistAddress1;
    address payable private artistAddress2;
    address payable private devAddress1;
    address payable private devAddress2;
    address payable private devAddress3;
    uint256 private ARTIST_ROYALTY_PERCENTAGE = 60;
    uint256 private DEV_ROYALTY_PERCENTAGE = 40;
    mapping(address => mapping(uint256 => uint256))
        private userPassesMintedPerTokenId;

    event ProducerPassBought(
        uint256 episodeID,
        address indexed account,
        uint256 amount
    );

    mapping(uint256 => ProducerPass) private episodeToProducerPass;

    constructor(string memory baseURI) ERC1155(baseURI) {
        name = "White Rabbit Producer Pass";
        symbol = "WRPP";
    }

    function isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root)
        internal
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            );
    }

    function getEpisodeToProducerPass(uint256 episodeID)
        external
        view
        returns (ProducerPass memory)
    {
        return episodeToProducerPass[episodeID];
    }

    function uri(uint256 episodeID)
        public
        view
        override
        returns (string memory)
    {
        require(
            episodeToProducerPass[episodeID].episodeID != 0,
            "URI requested for invalid episode"
        );
        return
            string(
                abi.encodePacked(super.uri(episodeID), episodeID.toString())
            );
    }

    // owner only methods
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }

    function setProducerPass(
        uint256 price,
        uint256 episodeID,
        uint256 maxSupply,
        uint256 maxPerWallet,
        uint256 openMintTimestamp,
        bytes32 merkleRoot
    ) external onlyOwner {
        episodeToProducerPass[episodeID] = ProducerPass(
            price,
            episodeID,
            maxSupply,
            maxPerWallet,
            openMintTimestamp,
            merkleRoot
        );
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 artistBalance = (balance * ARTIST_ROYALTY_PERCENTAGE) / 100;
        uint256 balancePerArtist = artistBalance / 2;
        uint256 devBalance = (balance * DEV_ROYALTY_PERCENTAGE) / 100;
        uint256 balancePerDev = devBalance / 3;

        bool success;
        // Transfer artist balances
        (success, ) = artistAddress1.call{value: balancePerArtist}("");
        require(success, "Withdraw Unsuccessful");

        (success, ) = artistAddress2.call{value: balancePerArtist}("");
        require(success, "Withdraw Unsuccessful");

        // Transfer dev balances
        (success, ) = devAddress1.call{value: balancePerDev}("");
        require(success, "Withdraw Unsuccessful");

        (success, ) = devAddress2.call{value: balancePerDev}("");
        require(success, "Withdraw Unsuccessful");

        (success, ) = devAddress3.call{value: balancePerDev}("");
        require(success, "Withdraw Unsuccessful");
    }

    function setRoyaltyAddresses(
        address _a1,
        address _a2,
        address _d1,
        address _d2,
        address _d3
    ) external onlyOwner {
        artistAddress1 = payable(_a1);
        artistAddress2 = payable(_a2);
        devAddress1 = payable(_d1);
        devAddress2 = payable(_d2);
        devAddress3 = payable(_d3);
    }

    function reserveProducerPassesForGifting(uint256 episodeID, uint256 amount)
        public
        onlyOwner
    {
        ProducerPass memory pass = episodeToProducerPass[episodeID];
        require(totalSupply(episodeID) < pass.maxSupply, "No passes to mint");

        _mint(msg.sender, episodeID, amount, "");
    }

    function mintProducerPass(uint256 episodeID, uint256 amount)
        external
        payable
    {
        ProducerPass memory pass = episodeToProducerPass[episodeID];
        require(
            block.timestamp >= pass.openMintTimestamp,
            "Mint is not available"
        );
        require(totalSupply(episodeID) < pass.maxSupply, "sold out");
        require(
            totalSupply(episodeID) + amount <= pass.maxSupply,
            "cannot mint that many"
        );

        uint256 totalMintedPasses = userPassesMintedPerTokenId[msg.sender][
            episodeID
        ];
        require(
            totalMintedPasses + amount <= pass.maxPerWallet,
            "Exceeding maximum passes per wallet"
        );
        require(msg.value == pass.price * amount, "Not enough eth");

        userPassesMintedPerTokenId[msg.sender][episodeID] =
            totalMintedPasses +
            amount;
        _mint(msg.sender, episodeID, amount, "");

        emit ProducerPassBought(episodeID, msg.sender, amount);
    }

    // Minting for those in the early access list
    function earlyMintProducerPass(
        uint256 episodeID,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external payable {
        ProducerPass memory pass = episodeToProducerPass[episodeID];
        require(
            isValidMerkleProof(merkleProof, pass.merkleRoot),
            "Not authorized to mint"
        );
        require(totalSupply(episodeID) < pass.maxSupply, "sold out");
        require(
            totalSupply(episodeID) + amount <= pass.maxSupply,
            "cannot mint that many"
        );
        require(msg.value == pass.price * amount, "Not enough eth");

        _mint(msg.sender, episodeID, amount, "");
        emit ProducerPassBought(episodeID, msg.sender, amount);
    }

    // boilerplate override
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override(ERC1155) {
        super._mint(account, id, amount, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155) {
        super._mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}