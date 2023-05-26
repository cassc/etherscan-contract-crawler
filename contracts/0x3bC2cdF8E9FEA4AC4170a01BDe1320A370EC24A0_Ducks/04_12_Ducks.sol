// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/// @title Ducks
/// @notice Ducks NFT contract
/// @dev This contract uses OpenZeppelin's library and includes OpenSea's on-chain enforcement tool for royalties
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Ducks is
    ERC721A("Ducks", "DUCKS"),
    ERC721AQueryable,
    Ownable,
    DefaultOperatorFilterer
{
    struct Config {
        uint256 maxWlMintPerWallet;
        uint256 wlMintPrice;
        uint256 maxPublicMintPerWallet;
        uint256 publicMintPrice;
        uint256 maxSupply;
        bytes32 wlRoot;
    }

    /// @notice The minting configuration
    Config public config;

    /// @notice The base uri of the project
    string public baseURI;

    ///@notice Sets a new base uri
    ///@dev Only callable by owner
    ///@param newBaseURI The new base uri
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    /// @notice Sets a new minting configuration
    /// @dev Only callable by owner
    /// @param newConfig The new minting configuration
    function setMintConfiguration(
        Config calldata newConfig
    ) external onlyOwner {
        config = newConfig;
    }

    enum SaleState {
        PAUSED,
        WHITELIST,
        PUBLIC
    }
    /// @notice The sale state
    SaleState public saleState;

    ///@dev Only callable by owner
    ///@param newSaleState new state
    function setSaleState(SaleState newSaleState) external onlyOwner {
        saleState = newSaleState;
    }

    ///@notice Airdrops a token to users
    ///@dev Only callable by owner
    ///@param recipient address to receive airdrop
    ///@param amount amounts to airdrop
    function airdrop(address recipient, uint256 amount) external onlyOwner {
        /// Check balance of supply
        require(
            totalSupply() + amount <= config.maxSupply,
            "Ducks: Airdrop amount exceeds maximum supply"
        );

        /// Mint the token
        _safeMint(recipient, amount);
    }

    ///@notice Public quack function
    ///@param quacks QUACK QUACK QUACK. Get with the QUACKING program
    function quackQuackMfer(uint256 quacks) external payable {
        /// Check if the sale is paused
        require(saleState == SaleState.PUBLIC, "Ducks: Public Sale paused");

        uint256 previous = _numberMinted(_msgSender());

        // Check if user has not exceeded the max mint per wallet
        require(
            previous + quacks <= config.maxPublicMintPerWallet,
            "Ducks: Exceeds public mint limit"
        );

        /// Check if the max supply has been reached
        require(
            totalSupply() + quacks <= config.maxSupply,
            "Ducks: Max supply minted"
        );

        /// Check if the correct amount of ETH was sent
        require(
            msg.value >= config.publicMintPrice * quacks,
            "Ducks: Incorrect amount sent"
        );

        /// Mint the token
        _safeMint(_msgSender(), quacks);
    }

    ///@notice quacklist mint function
    ///@param eggs The number of eggs to hatch
    ///@param proof The Merkle tree proof of the quacklisted address
    function layADuckling(
        uint256 eggs,
        bytes32[] calldata proof
    ) external payable {
        /// Check if the sale is paused
        require(saleState == SaleState.WHITELIST, "Ducks: Sale paused");

        /// Check if user is on the allow list
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

        require(
            MerkleProof.verify(proof, config.wlRoot, leaf),
            "Ducks: Invalid wl proof"
        );

        uint256 previous = _getAux(_msgSender());

        /// Check if user has minted
        require(
            previous + eggs <= config.maxWlMintPerWallet,
            "Ducks: Exceeds wl mint limit"
        );

        _setAux(_msgSender(), uint64(previous + eggs));

        /// Check balance of supply
        require(
            totalSupply() + eggs <= config.maxSupply,
            "Ducks: Max supply minted"
        );

        require(
            msg.value >= config.wlMintPrice * eggs,
            "Ducks: Incorrect amount sent"
        );

        /// Mint the token
        _safeMint(_msgSender(), eggs);
    }

    function whitelistMinted(address user) external view returns (uint256) {
        return _getAux(user);
    }

    function minted(address user) external view returns (uint256) {
        return _numberMinted(user);
    }

    ///@dev Overrides for DefaultOperatorRegistry
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /// @dev internal overrides
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Ducks: Withdraw failed");
    }
}