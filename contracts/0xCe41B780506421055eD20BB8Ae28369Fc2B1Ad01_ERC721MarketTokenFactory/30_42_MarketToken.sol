// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ContextMixin.sol";
import "./IMarketToken.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "../royalties-upgradeable/contracts/RoyaltiesV2Upgradeable.sol";
import "../lib-part/LibPart.sol";
import "../royalties/contracts/LibRoyaltiesV2.sol";
import "./LibERC721LazyMint.sol";
import "../interfaces/ICollectionContractInitializer.sol";

contract MarketToken is
    ICollectionContractInitializer,
    AccessControlUpgradeable,
    ERC721URIStorageUpgradeable,
    ContextMixin,
    RoyaltiesV2Upgradeable,
    RoyaltiesV2Impl,
    IMarketToken,
    OwnableUpgradeable
{
    string private _contractMetaURI;
    address public _trustedProxy;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    mapping(address => uint256) private _shares;
    address[] private _payees = new address[](0);
    address private _royaltyRecipient;
    string private _baseuri;
    bool public revealed = true;
    string public notRevealedUri;

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory contractMetaURI_,
        string memory baseuri_,
        bool _revealed,
        string memory notRevealedUri_,
        address contractOwner_,
        address trustedProxy_,
        address royaltyRecipient_,
        address[] memory payees,
        uint256[] memory shares_
    ) public override initializer {
        __ERC721_init(name_, symbol_);
        _setupRole(DEFAULT_ADMIN_ROLE, msgSender());
        _contractMetaURI = contractMetaURI_;
        _trustedProxy = trustedProxy_;
        _transferOwnership(contractOwner_);
        _setupRole(MINTER_ROLE, trustedProxy_);
        _royaltyRecipient = royaltyRecipient_;
        _baseuri = baseuri_;
        revealed = _revealed;
        notRevealedUri = notRevealedUri_;
        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    function _addPayee(address account, uint256 shares_) private {
        require(
            account != address(0),
            "PaymentSplitter: account is the zero address"
        );
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(
            _shares[account] == 0,
            "PaymentSplitter: account already has shares"
        );

        _payees.push(account);
        _shares[account] = shares_;
    }

    function mintInternal(
        address to,
        address from,
        uint256 tokenId,
        string memory tokenHash
    ) internal {
        require(
            hasRole(MINTER_ROLE, msgSender()),
            "Caller doesnot have minter role"
        );

        _mint(from, tokenId);
        _setTokenURI(tokenId, tokenHash);
        _setRoyalties(tokenId);
        _transfer(from, to, tokenId);
    }

    function transferFromOrMint(
        LibERC721LazyMint.Mint721Data memory data,
        address from,
        address to
    ) external override {
        if (_exists(data.tokenId)) {
            safeTransferFrom(from, to, data.tokenId);
        } else {
            mintAndTransfer(data, from, to);
        }
    }

    function mint(
        address to,
        uint256 tokenId,
        string memory tokenHash
    ) public override {
        mintInternal(to, tx.origin, tokenId, tokenHash);
    }

    function mintAndTransfer(
        LibERC721LazyMint.Mint721Data memory data,
        address from,
        address to
    ) internal virtual {
        require(
            hasRole(MINTER_ROLE, msgSender()),
            "Caller doesnot have minter role"
        );
        mintInternal(to, from, data.tokenId, data.tokenURI);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721Upgradeable, IMarketToken) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Add Token URI On IPFS by TokenId
     */
    function _setTokenURI(uint256 tokenId, string memory hash)
        internal
        virtual
        override
    {
        ERC721URIStorageUpgradeable._setTokenURI(tokenId, hash);
    }

    function reveal(string memory baseUri_) public {
        require(
            hasRole(MINTER_ROLE, msgSender()),
            "Caller doesnot have minter role"
        );
        _baseuri = baseUri_;
        revealed = true;
    }

    function setBaseURI(string memory baseUri_) public {
        require(
            hasRole(MINTER_ROLE, msgSender()),
            "Caller doesnot have minter role"
        );
        _baseuri = baseUri_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        return super.tokenURI(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseuri;
    }

    function _setRoyalties(uint256 _tokenId) internal virtual {
        if (_payees.length > 0) {
            uint256 _royaltyAmount;
            LibPart.Part[] memory _royalties = new LibPart.Part[](1);
            for (uint256 i = 0; i < _payees.length; i++) {
                _royaltyAmount += uint96(_shares[_payees[i]]);
            }
            _royalties[0].value = uint96(_royaltyAmount);
            _royalties[0].account = payable(_royaltyRecipient);
            _saveRoyalties(_tokenId, _royalties);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC165Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    /**
     * Override isApprovedForAll to auto-approve OS's proxy contract
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        if (_operator == _trustedProxy) {
            return true;
        }

        // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }

    function contractURI() public view returns (string memory) {
        return _contractMetaURI;
    }
}