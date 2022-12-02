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
    uint256 episodeId;
    uint256 maxSupply;
    uint256 maxPerWallet;
    uint256 openMintTimestamp; // unix timestamp in seconds
    bytes32 merkleRoot;
}

contract WhiteRabbitProducerPass is ERC1155, ERC1155Supply, Ownable {
    using Strings for uint256;

    // The name of the token ("White Rabbit Producer Pass")
    string public name;
    // The token symbol ("WRPP")
    string public symbol;

    // The wallet addresses of the two artists creating the film
    address payable private artistAddress1;
    address payable private artistAddress2;
    // The wallet addresses of the three developers managing the film
    address payable private devAddress1;
    address payable private devAddress2;
    address payable private devAddress3;

    // The royalty percentages for the artists and developers
    uint256 private constant ARTIST_ROYALTY_PERCENTAGE = 60;
    uint256 private constant DEV_ROYALTY_PERCENTAGE = 40;

    // A mapping of the number of Producer Passes minted per episodeId per user
    // userPassesMintedPerTokenId[msg.sender][episodeId] => number of minted passes
    mapping(address => mapping(uint256 => uint256))
        private userPassesMintedPerTokenId;

    // A mapping from episodeId to its Producer Pass
    mapping(uint256 => ProducerPass) private episodeToProducerPass;

    // Event emitted when a Producer Pass is bought
    event ProducerPassBought(
        uint256 episodeId,
        address indexed account,
        uint256 amount
    );

    /**
     * @dev Initializes the contract by setting the name and the token symbol
     */
    constructor(string memory baseURI) ERC1155(baseURI) {
        name = "White Rabbit Producer Pass";
        symbol = "WRPP";
    }

    /**
     * @dev Checks if the provided Merkle Proof is valid for the given root hash.
     */
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

    /**
     * @dev Retrieves the Producer Pass for a given episode.
     */
    function getEpisodeToProducerPass(uint256 episodeId)
        external
        view
        returns (ProducerPass memory)
    {
        return episodeToProducerPass[episodeId];
    }

    /**
     * @dev Contracts the metadata URI for the Producer Pass of the given episodeId.
     *
     * Requirements:
     *
     * - The Producer Pass exists for the given episode
     */
    function uri(uint256 episodeId)
        public
        view
        override
        returns (string memory)
    {
        require(
            episodeToProducerPass[episodeId].episodeId != 0,
            "Invalid episode"
        );
        return
            string(
                abi.encodePacked(
                    super.uri(episodeId),
                    episodeId.toString(),
                    ".json"
                )
            );
    }

    /**
     * Owner-only methods
     */

    /**
     * @dev Sets the base URI for the Producer Pass metadata.
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }

    /**
     * @dev Sets the parameters on the Producer Pass struct for the given episode.
     */
    function setProducerPass(
        uint256 price,
        uint256 episodeId,
        uint256 maxSupply,
        uint256 maxPerWallet,
        uint256 openMintTimestamp,
        bytes32 merkleRoot
    ) external onlyOwner {
        episodeToProducerPass[episodeId] = ProducerPass(
            price,
            episodeId,
            maxSupply,
            maxPerWallet,
            openMintTimestamp,
            merkleRoot
        );
    }

    /**
     * @dev Withdraws the balance and distributes it to the artists and developers
     * based on the `ARTIST_ROYALTY_PERCENTAGE` and `DEV_ROYALTY_PERCENTAGE`.
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 artistBalance = (balance * ARTIST_ROYALTY_PERCENTAGE) / 100;
        uint256 balancePerArtist = artistBalance / 2;
        uint256 devBalance = (balance * DEV_ROYALTY_PERCENTAGE) / 100;
        uint256 balancePerDev = devBalance / 3;

        bool success;
        // Transfer artist balances
        (success, ) = artistAddress1.call{value: balancePerArtist}("");
        require(success, "Withdraw unsuccessful");

        (success, ) = artistAddress2.call{value: balancePerArtist}("");
        require(success, "Withdraw unsuccessful");

        // Transfer dev balances
        (success, ) = devAddress1.call{value: balancePerDev}("");
        require(success, "Withdraw unsuccessful");

        (success, ) = devAddress2.call{value: balancePerDev}("");
        require(success, "Withdraw unsuccessful");

        (success, ) = devAddress3.call{value: balancePerDev}("");
        require(success, "Withdraw unsuccessful");
    }

    /**
     * @dev Sets the royalty addresses for the two artists and three developers.
     */
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

    /**
     * @dev Creates a reserve of Producer Passes to set aside for gifting.
     *
     * Requirements:
     *
     * - There are enough Producer Passes to mint for the given episode
     * - The supply for the given episode does not exceed the maxSupply of the Producer Pass
     */
    function reserveProducerPassesForGifting(
        uint256 episodeId,
        uint256 amountEachAddress,
        address[] calldata addresses
    ) public onlyOwner {
        ProducerPass memory pass = episodeToProducerPass[episodeId];
        require(amountEachAddress > 0, "Amount cannot be 0");
        require(totalSupply(episodeId) < pass.maxSupply, "No passes to mint");
        require(
            totalSupply(episodeId) + amountEachAddress * addresses.length <=
                pass.maxSupply,
            "Cannot mint that many"
        );
        require(addresses.length > 0, "Need addresses");
        for (uint256 i = 0; i < addresses.length; i++) {
            address add = addresses[i];
            _mint(add, episodeId, amountEachAddress, "");
        }
    }

    /**
     * @dev Mints a set number of Producer Passes for a given episode.
     *
     * Emits a `ProducerPassBought` event indicating the Producer Pass was minted successfully.
     *
     * Requirements:
     *
     * - The current time is within the minting window for the given episode
     * - There are Producer Passes available to mint for the given episode
     * - The user is not trying to mint more than the maxSupply
     * - The user is not trying to mint more than the maxPerWallet
     * - The user has enough ETH for the transaction
     */
    function mintProducerPass(uint256 episodeId, uint256 amount)
        external
        payable
    {
        ProducerPass memory pass = episodeToProducerPass[episodeId];
        require(
            block.timestamp >= pass.openMintTimestamp,
            "Mint is not available"
        );
        require(totalSupply(episodeId) < pass.maxSupply, "Sold out");
        require(
            totalSupply(episodeId) + amount <= pass.maxSupply,
            "Cannot mint that many"
        );

        uint256 totalMintedPasses = userPassesMintedPerTokenId[msg.sender][
            episodeId
        ];
        require(
            totalMintedPasses + amount <= pass.maxPerWallet,
            "Exceeding maximum per wallet"
        );
        require(msg.value == pass.price * amount, "Not enough eth");

        userPassesMintedPerTokenId[msg.sender][episodeId] =
            totalMintedPasses +
            amount;
        _mint(msg.sender, episodeId, amount, "");

        emit ProducerPassBought(episodeId, msg.sender, amount);
    }

    /**
     * @dev For those on with early access (on the whitelist),
     * mints a set number of Producer Passes for a given episode.
     *
     * Emits a `ProducerPassBought` event indicating the Producer Pass was minted successfully.
     *
     * Requirements:
     *
     * - Provides a valid Merkle proof, indicating the user is on the whitelist
     * - There are Producer Passes available to mint for the given episode
     * - The user is not trying to mint more than the maxSupply
     * - The user is not trying to mint more than the maxPerWallet
     * - The user has enough ETH for the transaction
     */
    function earlyMintProducerPass(
        uint256 episodeId,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external payable {
        ProducerPass memory pass = episodeToProducerPass[episodeId];
        require(
            isValidMerkleProof(merkleProof, pass.merkleRoot),
            "Not authorized to mint"
        );
        require(totalSupply(episodeId) < pass.maxSupply, "Sold out");
        require(
            totalSupply(episodeId) + amount <= pass.maxSupply,
            "Cannot mint that many"
        );
        uint256 totalMintedPasses = userPassesMintedPerTokenId[msg.sender][
            episodeId
        ];
        require(
            totalMintedPasses + amount <= pass.maxPerWallet,
            "Exceeding maximum per wallet"
        );
        require(msg.value == pass.price * amount, "Not enough eth");

        userPassesMintedPerTokenId[msg.sender][episodeId] =
            totalMintedPasses +
            amount;
        _mint(msg.sender, episodeId, amount, "");
        emit ProducerPassBought(episodeId, msg.sender, amount);
    }

    /**
     * @dev Retrieves the number of Producer Passes a user has minted by episodeId.
     */
    function userPassesMintedByEpisodeId(uint256 episodeId)
        external
        view
        returns (uint256)
    {
        return userPassesMintedPerTokenId[msg.sender][episodeId];
    }

    /**
     * @dev Boilerplate override for `_beforeTokenTransfer`
     */
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