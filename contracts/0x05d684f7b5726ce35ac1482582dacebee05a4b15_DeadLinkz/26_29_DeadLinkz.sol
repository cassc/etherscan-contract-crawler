// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721AQueryableUpgradeable, ERC721AUpgradeable, IERC721AUpgradeable} from "@erc721a-upgradable/extensions/ERC721AQueryableUpgradeable.sol";
import {Ownable} from "@solidstate-solidity/access/ownable/Ownable.sol";
import {AddressUtils} from "@solidstate-solidity/utils/AddressUtils.sol";
import {ECDSA} from "@solady/utils/ECDSA.sol";
import {DeadLinkzStorage} from "./DeadLinkzStorage.sol";
import {OperatorFiltererUpgradeable, Initializable} from "@os/upgradeable/OperatorFiltererUpgradeable.sol";
import {IDeadCrew} from "./interfaces/IDeadCrew.sol";
import {IDeadLinkz} from "./interfaces/IDeadLinkz.sol";

contract DeadLinkz is
    IDeadLinkz,
    ERC721AQueryableUpgradeable,
    OperatorFiltererUpgradeable,
    Ownable
{
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
     * @notice Initialize OpenSea royalties
     */
    function initializeReveal(
        string memory revealBaseUri_,
        uint256 price,
        address deadCrew_
    ) public initializer {
        __OperatorFilterer_init(
            address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6),
            true
        );
        DeadLinkzStorage.layout().revealPrice = price;
        DeadLinkzStorage.layout().revealBaseURI = revealBaseUri_;
        DeadLinkzStorage.layout().deadCrew = IDeadCrew(deadCrew_);
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
     * @notice Reveal mechanism
     */
    function reveal(
        uint256[] memory tokenIds,
        uint256 nonce,
        bytes calldata signature
    ) public payable {
        require(
            msg.value >=
                tokenIds.length * DeadLinkzStorage.layout().revealPrice,
            "Not enough funds to reveal"
        );
        require(tokenIds.length > 0, "Nothing to reveal");
        for (uint256 i; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            require(_exists(tokenId), "Token does not exist");
            require(
                !DeadLinkzStorage.layout().tokenRevealed[tokenId],
                "Already revealed"
            );
            DeadLinkzStorage.layout().tokenRevealed[tokenId] = true;
        }
        if (nonce != 0) {
            bytes32 data = keccak256(abi.encodePacked(msg.sender, nonce));
            address signer_ = data.toEthSignedMessageHash().recover(signature);
            require(DeadLinkzStorage.layout().signer == signer_, "Not allowed");
            if (!DeadLinkzStorage.layout().crewNonce[nonce]) {
                DeadLinkzStorage.layout().deadCrew.mint(
                    msg.sender,
                    tokenIds.length
                );
                DeadLinkzStorage.layout().crewNonce[nonce] = true;
            }
        }
    }

    /**
     * @notice Return the list of tokens that are not revealed
     */
    function getAllUnrevealedFor(address address_)
        public
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256 tokenIdsIdx;
            uint256[] memory tokenIds = new uint256[](MAX_SUPPLY);
            for (uint256 i = _startTokenId(); i != MAX_SUPPLY; ++i) {
                if (
                    !_exists(i) ||
                    (address_ != address(0) && ownerOf(i) != address_)
                ) {
                    continue;
                }
                if (!revealed(i)) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @notice Return the list of tokens that are not revealed
     */
    function getAllUnrevealed() public view returns (uint256[] memory) {
        return getAllUnrevealedFor(address(0));
    }

    /**
     * @notice Burns only unrevealed tokens
     */
    function burnUnrevealed(uint256[] memory tokenIds) public onlyOwner {
        for (uint256 i; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            if (!DeadLinkzStorage.layout().tokenRevealed[tokenId]) {
                _burn(tokenId);
            }
        }
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
     * @notice Set the base token URI
     */
    function setRevealBaseUri(string memory baseURI_) public onlyOwner {
        DeadLinkzStorage.layout().revealBaseURI = baseURI_;
    }

    /**
     * @notice Set the dead crew contract
     */
    function setDeadCrewContract(address contract_) public onlyOwner {
        DeadLinkzStorage.layout().deadCrew = IDeadCrew(contract_);
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
        string memory baseURI = revealed(tokenId)
            ? DeadLinkzStorage.layout().revealBaseURI
            : _baseURI();
        string memory result = string(
            abi.encodePacked(baseURI, _toString(tokenId), ".json")
        );
        return bytes(baseURI).length != 0 ? result : "";
    }

    /**
     * @notice Return if revealed
     */
    function revealed(uint256 tokenId) public view returns (bool) {
        return DeadLinkzStorage.layout().tokenRevealed[tokenId];
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
     * @notice Set price to reveal
     * @param price Price
     */
    function setRevealPrice(uint256 price) public onlyOwner {
        DeadLinkzStorage.layout().revealPrice = price;
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

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        AddressUtils.sendValue(payable(0xB445E26A0Ac154EC3812d6290A0746cAaF6a5ebD), (balance * 40) / 100);
        AddressUtils.sendValue(payable(0xf5eEbDceE6D696619a7C43552926A34f42B8C36C), (balance * 40) / 100);
        AddressUtils.sendValue(payable(0xB97f66Dac6Bb559809682C3f7a839019174D1CA8), (balance * 20) / 100);
    }
}