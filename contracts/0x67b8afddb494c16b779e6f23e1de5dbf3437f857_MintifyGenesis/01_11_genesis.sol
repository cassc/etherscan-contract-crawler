// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";

error MaxPerOrderExceeded();
error MaxSupplyExceeded();
error MaxPerWalletExceeded();
error PresaleClosed();
error NotInPresaleList();
error PublicSaleClosed();
error BridgingClosed();
error NoTokenIdsProvided();
error AlreadyBridged();
error NotTokenOwner();
error TransfersLocked();
error NotAllowedByRegistry();
error RegistryNotSet();
error WrongWeiSent();
error MaxFeeExceeded();
error InputLengthsMismatch();
error EmptyInput();
error NotSnapshotOwner();

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IRegistry {
    function isAllowedOperator(address operator) external view returns (bool);
}

contract MintifyGenesis is Ownable, OperatorFilterer, ERC2981, ERC721A {
    using BitMaps for BitMaps.BitMap;

    IERC721 private constant LIFETIME_PASS = IERC721(0x6712545A0d1d8595D1045Ea18f2f386ffcA7CA90);
    IERC721 private constant LITE_PASS = IERC721(0x0eB82f969ff477AdC95F7f17Eb4099c6CBF14912);
    IERC721 private constant FUTR_ONE = IERC721(0xB948f35C1C35206a5fB23b77F9e52a01B793c909);

    bool public presaleOpen;
    bool public publicOpen;
    bool public bridgeOpen;
    uint256 private maxSupply;
    uint256 private maxPerWallet;
    uint256 private maxPerOrder;
    uint256 private publicPrice = 6900000000000000;
    uint256 private presalePrice = 5000000000000000;

    BitMaps.BitMap private lifetimePassClaims;
    BitMaps.BitMap private litePassClaims;
    BitMaps.BitMap private futrOneClaims;
    BitMaps.BitMap private tier1Tokens;
    BitMaps.BitMap private tier2Tokens;
    mapping(address => bool) public allowlist;
    mapping(uint256 => address) public futrOneSnapshot;

    bool public operatorFilteringEnabled = true;
    bool public initialTransferLockOn = true;
    bool public isRegistryActive;
    address public registryAddress;

    string public _baseTokenURI = "https://genesis-metas.mintify.xyz";

    constructor() ERC721A("Mintify Genesis", "MNFGEN") {
        _registerForOperatorFiltering();

        // Set initial 2.5% royalty
        _setDefaultRoyalty(owner(), 250);
    }


    // PreSale Mint
    function presaleMint(uint256 quantity) external payable {
        if (maxPerOrder != 0 && quantity > maxPerOrder) {
            revert MaxPerOrderExceeded();
        }
        if (maxSupply != 0 && totalSupply() + quantity > maxSupply) {
            revert MaxSupplyExceeded();
        }
        if (maxPerWallet != 0 && balanceOf(msg.sender) + quantity > maxPerWallet) {
            revert MaxPerWalletExceeded();
        }
        if (!presaleOpen) {
            revert PresaleClosed();
        }
        if (msg.value != (presalePrice * quantity)) {
            revert WrongWeiSent();
        }
        if (!allowlist[msg.sender]) {
            revert NotInPresaleList();
        }
        allowlist[msg.sender] = false;
         _mint(msg.sender, quantity);
    }

    // Public Mint
    function publicMint(uint256 quantity) external payable {
        if (maxPerOrder != 0 && quantity > maxPerOrder) {
            revert MaxPerOrderExceeded();
        }
        if (maxSupply != 0 && totalSupply() + quantity > maxSupply) {
            revert MaxSupplyExceeded();
        }
        if (maxPerWallet != 0 && balanceOf(msg.sender) + quantity > maxPerWallet) {
            revert MaxPerWalletExceeded();
        }
        if (!publicOpen) {
            revert PublicSaleClosed();
        }
        if (msg.value != (publicPrice * quantity)) {
            revert WrongWeiSent();
        }
        _mint(msg.sender, quantity);
    }


    // Bridge Lifetime Passes
     function lifetimeBridge(uint256[] calldata lifeTimeIds) external {

        if (!bridgeOpen) {
            revert BridgingClosed();
        }
        uint256 quantity;
        if (lifeTimeIds.length == 0) {
            revert NoTokenIdsProvided();
        }
        for (; quantity < lifeTimeIds.length;) {
            if (lifetimePassClaims.get(lifeTimeIds[quantity])) {
                revert AlreadyBridged();
            }
            if (LIFETIME_PASS.ownerOf(lifeTimeIds[quantity]) != msg.sender) {
                revert NotTokenOwner();
            }

            // Require burn here
            LIFETIME_PASS.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, lifeTimeIds[quantity]);

            lifetimePassClaims.set(lifeTimeIds[quantity]);
            unchecked {
                ++quantity;
            }
        }
        uint256 currentIdCursor = totalSupply() + 1;
        _mint(msg.sender, quantity);
        for (uint256 i = currentIdCursor; i <= totalSupply();) {
            tier1Tokens.set(i);
            unchecked {
                i++;
            }
        }
        
    }

    // Bridge Lite Passes
     function liteBridge(uint256[] calldata liteIds) external {

        if (!bridgeOpen) {
            revert BridgingClosed();
        }
        uint256 quantity;
        if (liteIds.length == 0) {
            revert NoTokenIdsProvided();
        }
        for (; quantity < liteIds.length;) {
            if (litePassClaims.get(liteIds[quantity])) {
                revert AlreadyBridged();
            }
            if (LITE_PASS.ownerOf(liteIds[quantity]) != msg.sender) {
                revert NotTokenOwner();
            }

            // Require burn here
            LITE_PASS.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, liteIds[quantity]);

            litePassClaims.set(liteIds[quantity]);
            unchecked {
                ++quantity;
            }
        }
        uint256 currentIdCursor = totalSupply() + 1;
        _mint(msg.sender, quantity);
        for (uint256 i = currentIdCursor; i <= totalSupply();) {
            tier2Tokens.set(i); 
            unchecked {
                i++;
            }
        }
        
    }

    // Claim FutrOne Passes
     function futrOneClaim(uint256[] calldata futrOneIds) external {

        if (!bridgeOpen) {
            revert BridgingClosed();
        }
        uint256 quantity;
        if (futrOneIds.length == 0) {
            revert NoTokenIdsProvided();
        }
        for (; quantity < futrOneIds.length;) {
            if (futrOneClaims.get(futrOneIds[quantity])) {
                revert AlreadyBridged();
            }
            if (futrOneSnapshot[futrOneIds[quantity]] != msg.sender) {
                revert NotSnapshotOwner();
            }
            futrOneClaims.set(futrOneIds[quantity]);
            unchecked {
                ++quantity;
            }
        }
        _mint(msg.sender, quantity);
        
    }


    // =========================================================================
    //                           Owner Only Functions
    // =========================================================================

    // Owner unrestricted mint
    function ownerMint(address to, uint256 quantity) external onlyOwner {
        if (maxSupply != 0 && totalSupply() + quantity > maxSupply) {
            revert MaxSupplyExceeded();
        }
        _mint(to, quantity);
    }

    // Enables or disables public sale
    function setPublicState(bool newState) external onlyOwner {
        publicOpen = newState;
    }

    // Enables or disables presale
    function setPresaleState(bool newState) external onlyOwner {
        presaleOpen = newState;
    }

    // Enables or disables bridging
    function setBridgeState(bool newState) external onlyOwner {
        bridgeOpen = newState;
    }

    // Add to allowlist
    function setAllowlist(address[] calldata addresses) external onlyOwner {
        if (addresses.length == 0) {
            revert EmptyInput();
        }
        for (uint256 i; i < addresses.length;) {
            allowlist[addresses[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    // Remove from allowlist
    function removeAllowlist(address[] calldata addresses) external onlyOwner {
        for (uint256 i; i < addresses.length;) {
            delete allowlist[addresses[i]];
            unchecked {
                ++i;
            }
        }
    }

    // Add to allowlist
    function setFutrOneSnapshot(uint256[] calldata tokenIds, address[] calldata addresses) external onlyOwner {
        if (tokenIds.length == 0) {
            revert EmptyInput();
        }
        if (tokenIds.length != addresses.length) {
            revert InputLengthsMismatch();
        }
        for (uint256 i; i < tokenIds.length;) {
            futrOneSnapshot[tokenIds[i]] = addresses[i];
            unchecked {
                ++i;
            }
        }
    }

    // Set max supply
    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }

    // Set max per wallet
    function setMaxPerWallet(uint256 newMaxPerWallet) external onlyOwner {
        maxPerWallet = newMaxPerWallet;
    }

    // Set max per order
    function setMaxPerOrder(uint256 newMaxPerOrder) external onlyOwner {
        maxPerOrder = newMaxPerOrder;
    }

    // Set public sale price
    function setPublicSalePrice(uint256 newPrice) external onlyOwner {
        publicPrice = newPrice;
    }

    // Set presale price
    function setPresalePrice(uint256 newPrice) external onlyOwner {
        presalePrice = newPrice;
    }

    // Withdraw Balance to owner
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // Withdraw Balance to Address
    function withdrawTo(address payable _to) public onlyOwner {
        _to.transfer(address(this).balance);
    }

    // Break Transfer Lock
    function breakLock() external onlyOwner {
        initialTransferLockOn = false;
    }

    // =========================================================================
    //                             ERC721A Misc
    // =========================================================================

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // =========================================================================
    //                           Operator filtering
    // =========================================================================

    function setApprovalForAll(address operator, bool approved)
        public
        override (ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        if (initialTransferLockOn) {
            revert TransfersLocked();
        }
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        if (initialTransferLockOn) {
            revert TransfersLocked();
        }
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    // =========================================================================
    //                             Registry Check
    // =========================================================================
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (initialTransferLockOn && from != address(0) && to != address(0)) {
            revert TransfersLocked();
        }
        if (_isValidAgainstRegistry(msg.sender)) {
            super._beforeTokenTransfers(from, to, startTokenId, quantity);
        } else {
            revert NotAllowedByRegistry();
        }
    }

    function _isValidAgainstRegistry(address operator)
        internal
        view
        returns (bool)
    {
        if (isRegistryActive) {
            IRegistry registry = IRegistry(registryAddress);
            return registry.isAllowedOperator(operator);
        }
        return true;
    }

    function setIsRegistryActive(bool _isRegistryActive) external onlyOwner {
        if (registryAddress == address(0)) revert RegistryNotSet();
        isRegistryActive = _isRegistryActive;
    }

    function setRegistryAddress(address _registryAddress) external onlyOwner {
        registryAddress = _registryAddress;
    }

    // =========================================================================
    //                                  ERC165
    // =========================================================================

    function supportsInterface(bytes4 interfaceId) public view override (ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    // =========================================================================
    //                                 ERC2891
    // =========================================================================

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        if (feeNumerator > 1000) {
            revert MaxFeeExceeded();
        }
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        if (feeNumerator > 1000) {
            revert MaxFeeExceeded();
        }
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    // =========================================================================
    //                                 Metadata
    // =========================================================================

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        if (tier1Tokens.get(tokenId)) {
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, "/tier1/", _toString(tokenId))) : "";
        }
        else if (tier2Tokens.get(tokenId)) {
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, "/tier2/", _toString(tokenId))) : "";
        }
        else {
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, "/tier3/", _toString(tokenId))) : "";
        }
    }

    function isTier1(uint256 tokenId) public view returns (bool) {
        return tier1Tokens.get(tokenId);
    }

    function isTier2(uint256 tokenId) public view returns (bool) {
        return tier2Tokens.get(tokenId);
    }
}