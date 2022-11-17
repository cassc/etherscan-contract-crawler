// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721AQueryableUpgradeable, ERC721AUpgradeable, IERC721AUpgradeable} from "@erc721a-upgradable/extensions/ERC721AQueryableUpgradeable.sol";
import {Ownable} from "@solidstate-solidity/access/ownable/Ownable.sol";
import {ECDSA} from "@solady/utils/ECDSA.sol";
import {DeadLinkzStorage} from "./DeadLinkzStorage.sol";
import {IDeadLinkz} from "./IDeadLinkz.sol";

contract DeadLinkz is IDeadLinkz, ERC721AQueryableUpgradeable, Ownable {
    using ECDSA for bytes32;

    /// @notice Maximum supply of the mint passes
    uint256 public constant MAX_SUPPLY = 4004;

    /**
     * @notice Initialize the implementation
     */
    function initialize(string memory baseUri_, address signer_)
        public
        initializerERC721A
    {
        __ERC721A_init("D3ADLINKZ", "D3AD");
        __ERC721AQueryable_init();
        DeadLinkzStorage.layout().signer = signer_;
        DeadLinkzStorage.layout().maxMintQuantity = 1;
        setBaseUri(baseUri_);
    }

    /**
     * @notice Mint an NFT
     */
    function mint(uint256 quantity, bytes calldata signature)
        public
        payable
        insideTotalSupply(quantity)
        onlyEoa
    {
        if (!DeadLinkzStorage.layout().publicSale) {
            require(
                DeadLinkzStorage.layout().whitelistSale,
                "Whitelist not open"
            );
            bytes32 data = keccak256(abi.encodePacked(msg.sender, quantity));
            address signer_ = data.toEthSignedMessageHash().recover(signature);
            require(DeadLinkzStorage.layout().signer == signer_, "Not allowed");
        }
        require(
            DeadLinkzStorage.layout().addressNumMints[msg.sender] + quantity <=
                DeadLinkzStorage.layout().maxMintQuantity,
            "Minting above wallet limit"
        );
        DeadLinkzStorage.layout().addressNumMints[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    modifier onlyEoa() {
        require(tx.origin == msg.sender, "Not EOA");
        _;
    }

    /**
     * @notice Mint as an admin
     * @param recipient Mint recipient
     * @param quantity Mint quantity
     */
    function mintAsAdmin(address recipient, uint256 quantity)
        public
        onlyOwner
        insideTotalSupply(quantity)
    {
        _mint(recipient, quantity);
    }

    modifier insideTotalSupply(uint256 _quantity) {
        require(_totalMinted() + _quantity <= MAX_SUPPLY, "Above total supply");
        _;
    }

    /**
     * @notice Set the base token URI
     */
    function setBaseUri(string memory baseURI_) public onlyOwner {
        DeadLinkzStorage.layout().baseURI = baseURI_;
    }

    /**
     * @dev Base token URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return DeadLinkzStorage.layout().baseURI;
    }

    /**
     * @notice Return the token URI for an NFT
     * @param tokenId Token ID
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        string memory result = string(
            abi.encodePacked(baseURI, _toString(tokenId), ".json")
        );
        return bytes(baseURI).length != 0 ? result : "";
    }

    /**
     * @notice Toggle the public sale
     */
    function toggleSale() public onlyOwner {
        bool lastState = DeadLinkzStorage.layout().publicSale;
        DeadLinkzStorage.layout().publicSale = !lastState;
    }

    function getPublicSale() public view returns (bool) {
        return DeadLinkzStorage.layout().publicSale;
    }

    /**
     * @notice Toggle the whitelist sale
     */
    function toggleWhitelistSale() public onlyOwner {
        bool lastState = DeadLinkzStorage.layout().whitelistSale;
        DeadLinkzStorage.layout().whitelistSale = !lastState;
    }

    function getWhitelistSale() public view returns (bool) {
        return DeadLinkzStorage.layout().whitelistSale;
    }

    /**
     * @notice Set the maximum mints per wallet
     * @param quantity Maximum quantity
     */
    function setMaxMintQuantity(uint256 quantity) public onlyOwner {
        DeadLinkzStorage.layout().maxMintQuantity = quantity;
    }

    /**
     * @dev Returns the starting token ID.
     */
    function _startTokenId()
        internal
        view
        virtual
        override(ERC721AUpgradeable)
        returns (uint256)
    {
        return 1;
    }
}