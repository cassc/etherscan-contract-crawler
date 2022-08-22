// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../framework/erc721/ERC721APreApprovalUpgradeable.sol";

/// @title StreetlabERC721A
/// @notice NFT contracts dedicated to auctions for Streetlab OGs. Mint is restricted to owner
contract StreetlabRestrictedERC721AUpgradeable is ERC721APreApprovalUpgradeable, OwnableUpgradeable {

    /// @notice Revenues & Royalties recipient
    address public beneficiary;

    uint256 public maxSupply;

    /// @notice base URI for metadata
    string public baseURI;
    /// @dev Contract URI used by OpenSea to get contract details (owner, royalties...)
    string public contractURI;

    function initialize(
        address owner_,
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_
    )
        public
        initializerERC721A
    {
        __ERC721A_init(name_, symbol_);
        _transferOwnership(owner_);
        // contractURI = contractURI_;
        beneficiary = owner();

        maxSupply = maxSupply_;
    }

    modifier belowTotalSupply(uint256 quantity) {
        require(
            totalSupply() + quantity <= maxSupply,
            "not enough tokens left."
        );
        _;
    }

    /// @notice Mint your NFT(s) (public sale)
    /// @param quantity number of NFT to mint
    /// no gift allowed nor minting from other smartcontracts
    function mint(uint256 quantity)
        external
        onlyOwner
        belowTotalSupply(quantity)
    {
        _safeMint(msg.sender, quantity);
    }

    /// @notice Mint NFT(s) by Credit Card with Crossmint (public sale)
    /// @param to NFT recipient
    /// @param quantity number of NFT to mint
    /// no gift allowed nor minting from other smartcontracts
    function mintTo(address to, uint256 quantity)
        external
        onlyOwner
        belowTotalSupply(quantity)
    {
        _safeMint(to, quantity);
    }

    /// @inheritdoc ERC721AUpgradeable
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @inheritdoc ERC721AUpgradeable
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @inheritdoc ERC721AUpgradeable
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId == this.royaltyInfo.selector ||
            super.supportsInterface(interfaceId);
    }

    ////////////////////////////////////////////////////
    ///// Royalties                                   //
    ////////////////////////////////////////////////////

    /// @dev Royalties are the same for every token that's why we don't use OZ's impl.
    function royaltyInfo(uint256, uint256 amount)
        public
        view
        returns (address, uint256)
    {
        address recipient = beneficiary;
        if (recipient == address(0)) {
            recipient = owner();
        }

        // (royaltiesRecipient || owner), 7.5%
        return (recipient, (amount * 750) / 10000);
    }

    /// @notice Allow the owner to change the baseURI
    /// @param newBaseURI the new uri
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    /// @notice Allow owner to set the royalties recipient
    /// @param newBeneficiary the new contract uri
    function setBeneficiary(address newBeneficiary) external onlyOwner {
        beneficiary = newBeneficiary;
    }

    /// @notice Allow owner to set contract URI
    /// @param newContractURI the new contract URI
    function setContractURI(string calldata newContractURI)
        external
        onlyOwner
    {
        contractURI = newContractURI;
    }
}