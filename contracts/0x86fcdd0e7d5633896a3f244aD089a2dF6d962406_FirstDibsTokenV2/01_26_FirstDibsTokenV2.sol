//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';

import './IERC721CreatorV2.sol';
import './FirstDibsPayments.sol';
import './SplitForwarderFactory.sol';
import './FirstDibsERC2771Context.sol';

contract FirstDibsTokenV2 is
    ERC721,
    Ownable,
    AccessControl,
    ERC721Burnable,
    ERC721Pausable,
    ERC721URIStorage,
    IERC721CreatorV2,
    FirstDibsPayments,
    FirstDibsERC2771Context,
    SplitForwarderFactory
{
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 public constant MINT_WITH_CREATOR = keccak256('MINT_WITH_CREATOR');
    bytes32 public constant MINTER_ROLE_ADMIN = keccak256('MINTER_ROLE_ADMIN');

    /**
     * @dev token ID mapping to payable creator address
     */
    mapping(uint256 => address payable) private tokenCreators;

    /**
     * @dev Owner address to token ID mapping. Allows the marketplace to
     * manage tokens airdropped to creators
     */
    mapping(address => mapping(uint256 => bool)) private approveAirdropForDibsMarketplace;

    /**
     * @dev Verified dibs marketplace
     */
    address public dibsMarketplace;

    /**
     * @dev Emitted when `approved` enables or disables approval for dibsMarketplace to manage `tokenId`
     */
    event ApprovedDibsMarketplaceByAirdrop(
        address indexed approved,
        uint256 indexed tokenId,
        bool isApproved
    );

    /**
     * @dev Auto-incrementing counter for token IDs
     */
    Counters.Counter private tokenIds;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, `MINT_WITH_CREATOR`,
     * and `MINTER_ROLE_ADMIN` to the account that deploys the contract.
     * Also sets dibsMarketplace
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _splitForwarder,
        address _splitPool,
        address _trustedForwarder,
        address _dibsMarketplace
    )
        ERC721(_name, _symbol)
        FirstDibsERC2771Context(_trustedForwarder)
        SplitForwarderFactory(_splitForwarder, _splitPool)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(MINT_WITH_CREATOR, _msgSender());
        _setupRole(MINTER_ROLE_ADMIN, _msgSender());
        _setRoleAdmin(MINTER_ROLE, MINTER_ROLE_ADMIN);

        dibsMarketplace = _dibsMarketplace;
    }

    /**
     * @dev Internal function for setting the token's creator.
     * @param _creator address of the creator of the token.
     * @param _tokenId uint256 id of the token.
     */
    function _setTokenCreator(address payable _creator, uint256 _tokenId) private {
        tokenCreators[_tokenId] = _creator;
    }

    /**
     * @dev External function to get the token's creator
     * @param _tokenId uint256 id of the token.
     */
    function tokenCreator(uint256 _tokenId) external view override returns (address payable) {
        return tokenCreators[_tokenId];
    }

    /**
     * @dev internal function that mints a token. Sets _creator to creator and owner
     * @param _tokenURI string metadata URI of the token.
     * @param _creator address of the creator of the token.
     * @param _paymentAddress address to send royalty payments to
     * @param _tokenRoyalty uint32 royalty basis points for a token
     */
    function _mint(
        string memory _tokenURI,
        address payable _creator,
        address payable _paymentAddress,
        uint32 _tokenRoyalty
    ) internal returns (uint256 newTokenId) {
        tokenIds.increment();
        newTokenId = tokenIds.current();

        _safeMint(_creator, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);
        _setTokenCreator(_creator, newTokenId);
        _setTokenPaymentAddress(_paymentAddress, newTokenId);
        if (_tokenRoyalty > 0) {
            _setPerTokenRoyalties(newTokenId, _tokenRoyalty);
        }
    }

    /**
     * @dev Public function that mints a token. Sets msg.sender to creator and owner and requires MINTER_ROLE
     * @param _tokenURI uint256 metadata URI of the token.
     */
    function mint(string memory _tokenURI) public returns (uint256) {
        require(hasRole(MINTER_ROLE, _msgSender()), 'mint: must have MINTER_ROLE');
        address payable _creator = payable(_msgSender());
        return _mint(_tokenURI, _creator, _creator, 0);
    }

    /**
     * @dev Admin only function that allows admin to mint a token with custom params, including creator
     * Also approves the marketplace as an operator of the token on the creator's behalf.
     * @param _tokenURI uint256 metadata URI of the token.
     * @param _merkleRoot bytes32 merkle root to create a split for, this will take precedence over _paymentAddress
     * @param _paymentAddress address custom payment address to send creator royalties to
     * @param _tokenRoyalty uint32 custom royalty basis shares to set for creator royalties
     * @param _creatorAddress address creator of the token
     */
    function airdropMintToCreator(
        string memory _tokenURI,
        bytes32 _merkleRoot,
        address payable _paymentAddress,
        uint32 _tokenRoyalty,
        address _creatorAddress
    ) public {
        require(
            hasRole(MINT_WITH_CREATOR, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            'airdropMintToCreator: must have MINT_WITH_CREATOR or DEFAULT_ADMIN_ROLE'
        );
        require(
            _creatorAddress != address(0),
            'airdropMintToCreator: creator cannot be zero address'
        );
        address paymentAddress = _creatorAddress;
        if (_merkleRoot != 0) {
            paymentAddress = createSplitForwarder(_merkleRoot);
        } else if (_paymentAddress != address(0)) {
            paymentAddress = _paymentAddress;
        }
        uint256 tokenId = _mint(
            _tokenURI,
            payable(_creatorAddress),
            payable(paymentAddress),
            _tokenRoyalty
        );
        approveAirdropForDibsMarketplace[_creatorAddress][tokenId] = true;
        emit ApprovedDibsMarketplaceByAirdrop(_creatorAddress, tokenId, true);
    }

    /**
     * @dev Public function that allows addresses with MINTER_ROLE to mint a token with custom parameters
     * @param _tokenURI uint256 metadata URI of the token.
     * @param _merkleRoot bytes32 merkle root to create a split for, takes precedence over payment address
     * @param _paymentAddress address custom payment address to send creator royalties to
     * @param _tokenRoyalty uint32 custom royalty basis shares to set for creator royalties
     * @param _approveDibsMarketplaceForAll bool if true, this and future tokens minted on this contract will be approved for the marketplace
     * @param _approveDibsMarketplaceForOne bool if true, this token will be approved for the contracts marketplace address
     */
    function mintWithParams(
        string memory _tokenURI,
        bytes32 _merkleRoot,
        address payable _paymentAddress,
        uint32 _tokenRoyalty,
        bool _approveDibsMarketplaceForAll,
        bool _approveDibsMarketplaceForOne
    ) public {
        require(hasRole(MINTER_ROLE, _msgSender()), 'mintWithParams: must have MINTER_ROLE');
        address paymentAddress = _msgSender();

        if (_merkleRoot != 0) {
            paymentAddress = createSplitForwarder(_merkleRoot);
        } else if (_paymentAddress != address(0)) {
            paymentAddress = _paymentAddress;
        }

        uint256 newTokenId = _mint(
            _tokenURI,
            payable(_msgSender()),
            payable(paymentAddress),
            _tokenRoyalty
        );

        if (_approveDibsMarketplaceForAll) {
            setApprovalForAll(dibsMarketplace, true);
        } else if (_approveDibsMarketplaceForOne) {
            approve(dibsMarketplace, newTokenId);
        }
    }

    /**
     * @dev Uses ERC721 _safeTransfer but also allows marketplaces to transfer airdropped tokens
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(
            _isOwnerApprovedOrMarketplace(_msgSender(), tokenId),
            'FirstDibsTokenV2: transfer caller is not owner nor approved nor verified'
        );
        _safeTransfer(from, to, tokenId, '');
    }

    /**
     * @dev Returns whether `operator` is allowed to manage `tokenId`. If token owner => token ID is in the
     * approvedForDibsMarketplace mapping then dibsMarketplace is allowed to manage the token.
     */
    function _isOwnerApprovedOrMarketplace(address operator, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(_exists(tokenId), 'FirstDibsTokenV2: operator query for nonexistent token');
        address tokenOwner = ERC721.ownerOf(tokenId);
        return (operator == tokenOwner ||
            getApproved(tokenId) == operator ||
            isApprovedForAll(tokenOwner, operator) ||
            // Allow the marketplace to manage the token if token has been airdropped to the creator
            // This should only be true for owners that had tokens airdropped to them using airdropMintToCreator.
            (approveAirdropForDibsMarketplace[tokenOwner][tokenId] && operator == dibsMarketplace));
    }

    /**
     * @dev Returns whether `operator` is allowed to manage `tokenId`. If token owner => token ID is in the
     * approvedForDibsMarketplace mapping then dibsMarketplace is allowed to manage the token.
     *
     */
    function isOwnerApprovedOrMarketplace(address operator, uint256 tokenId)
        external
        view
        returns (bool)
    {
        return _isOwnerApprovedOrMarketplace(operator, tokenId);
    }

    function setDibsMarketplace(address _dibsMarketplace) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            'setDibsMarketplace: must have DEFAULT_ADMIN_ROLE'
        );
        dibsMarketplace = _dibsMarketplace;
    }

    /**
     * @dev Pauses all token transfers.
     * See {ERC721Pausable} and {Pausable-_pause}.
     * Requirements: the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function pause() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'pause: must have DEFAULT_ADMIN_ROLE');
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     * See {ERC721Pausable} and {Pausable-_unpause}.
     * Requirements: the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function unpause() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'unpause: must have DEFAULT_ADMIN_ROLE');
        _unpause();
    }

    // The following functions are overrides required by Solidity.

    /**
     * @dev Must override this function since both ERC721, ERC721Pausable define it
     * Checks that the contract isn't paused before doing a transfer
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override(ERC721, ERC721Pausable) whenNotPaused {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _msgSender()
        internal
        view
        override(Context, FirstDibsERC2771Context)
        returns (address sender)
    {
        return super._msgSender();
    }

    function _msgData()
        internal
        view
        override(Context, FirstDibsERC2771Context)
        returns (bytes calldata)
    {
        return super._msgData();
    }
}