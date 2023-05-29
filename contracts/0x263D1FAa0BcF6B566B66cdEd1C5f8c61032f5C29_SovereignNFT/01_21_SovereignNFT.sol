// contracts/token/ERC721/sovereign/SovereignNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable-0.7.2/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable-0.7.2/token/ERC721/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable-0.7.2/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable-0.7.2/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable-0.7.2/utils/CountersUpgradeable.sol";
import "../IERC721Creator.sol";
import "../../../royalty/ERC2981Upgradeable.sol";

contract SovereignNFT is
    OwnableUpgradeable,
    ERC165Upgradeable,
    ERC721Upgradeable,
    IERC721Creator,
    ERC721BurnableUpgradeable,
    ERC2981Upgradeable
{
    using SafeMathUpgradeable for uint256;
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct MintBatch {
        uint256 startTokenId;
        uint256 endTokenId;
        string baseURI;
    }

    bool public disabled;

    // Mapping from token ID to the creator's address
    mapping(uint256 => address) private tokenCreators;

    // Mapping from tokenId to if it was burned or not (for batch minting)
    mapping(uint256 => bool) private tokensBurned;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Counter to keep track of the current token id.
    CountersUpgradeable.Counter private tokenIdCounter;

    MintBatch[] private mintBatches;

    // Default royalty percentage
    uint256 public defaultRoyaltyPercentage;

    event ContractDisabled(address indexed user);

    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed fromAddress,
        address indexed toAddress
    );

    function init(
        string calldata _name,
        string calldata _symbol,
        address _creator
    ) public initializer {
        require(_creator != address(0));
        defaultRoyaltyPercentage = 10;
        disabled = false;

        __Ownable_init();
        __ERC721_init(_name, _symbol);
        __ERC165_init();
        __ERC2981__init();

        _setDefaultRoyaltyReceiver(_creator);

        _registerInterface(calcIERC721CreatorInterfaceId());

        super.transferOwnership(_creator);
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "Must be owner of token.");
        _;
    }

    modifier ifNotDisabled() {
        require(!disabled, "Contract must not be disabled.");
        _;
    }

    function batchMint(string calldata _baseURI, uint256 _numberOfTokens)
        public
        onlyOwner
        ifNotDisabled
    {
        uint256 startTokenId = tokenIdCounter.current() + 1;
        uint256 endTokenId = startTokenId + _numberOfTokens - 1;

        tokenIdCounter = CountersUpgradeable.Counter(endTokenId);

        mintBatches.push(MintBatch(startTokenId, endTokenId, _baseURI));

        emit ConsecutiveTransfer(startTokenId, endTokenId, address(0), owner());
    }

    function addNewToken(string memory _uri) public onlyOwner ifNotDisabled {
        _createToken(
            _uri,
            msg.sender,
            msg.sender,
            defaultRoyaltyPercentage,
            msg.sender
        );
    }

    function mintTo(
        string calldata _uri,
        address _receiver,
        address _royaltyReceiver
    ) external onlyOwner ifNotDisabled {
        _createToken(
            _uri,
            msg.sender,
            _receiver,
            defaultRoyaltyPercentage,
            _royaltyReceiver
        );
    }

    function renounceOwnership() public view override onlyOwner {
        revert("unsupported");
    }

    function transferOwnership(address) public view override onlyOwner {
        revert("unsupported");
    }

    function deleteToken(uint256 _tokenId) public onlyTokenOwner(_tokenId) {
        burn(_tokenId);
    }

    function burn(uint256 _tokenId) public virtual override {
        (bool wasBatchMinted, , ) = _batchMintInfo(_tokenId);

        tokensBurned[_tokenId] = true;

        if (wasBatchMinted && !ERC721Upgradeable._exists(_tokenId)) {
            return;
        }

        ERC721BurnableUpgradeable.burn(_tokenId);
    }

    function tokenCreator(uint256)
        public
        view
        override
        returns (address payable)
    {
        return payable(owner());
    }

    function disableContract() public onlyOwner {
        disabled = true;
        emit ContractDisabled(msg.sender);
    }

    function setDefaultRoyaltyReceiver(address _receiver) external onlyOwner {
        _setDefaultRoyaltyReceiver(_receiver);
    }

    function setRoyaltyReceiverForToken(address _receiver, uint256 _tokenId)
        external
        onlyOwner
    {
        royaltyReceivers[_tokenId] = _receiver;
    }

    function _setTokenCreator(uint256 _tokenId, address _creator) internal {
        tokenCreators[_tokenId] = _creator;
    }

    function _createToken(
        string memory _uri,
        address _creator,
        address _to,
        uint256 _royaltyPercentage,
        address _royaltyReceiver
    ) internal returns (uint256) {
        tokenIdCounter.increment();
        uint256 tokenId = tokenIdCounter.current();
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _uri);
        _setTokenCreator(tokenId, _creator);
        _setRoyaltyPercentage(tokenId, _royaltyPercentage);
        _setRoyaltyReceiver(tokenId, _royaltyReceiver);
        return tokenId;
    }

    ///////////////////////////////////////////////
    // Overriding Methods to support batch mints
    ///////////////////////////////////////////////
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        (bool wasBatchMinted, , string memory baseTokenUri) = _batchMintInfo(
            _tokenId
        );

        if (!wasBatchMinted) {
            return super.tokenURI(_tokenId);
        } else {
            return
                string(
                    abi.encodePacked(
                        baseTokenUri,
                        "/",
                        _tokenId.toString(),
                        ".json"
                    )
                );
        }
    }

    function ownerOf(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        (bool wasBatchMinted, , ) = _batchMintInfo(_tokenId);

        if (!wasBatchMinted) {
            return ERC721Upgradeable.ownerOf(_tokenId);
        } else if (tokensBurned[_tokenId]) {
            return ERC721Upgradeable.ownerOf(_tokenId);
        } else {
            if (!ERC721Upgradeable._exists(_tokenId)) {
                return owner();
            } else {
                return ERC721Upgradeable.ownerOf(_tokenId);
            }
        }
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function _isApprovedOrOwner(address _spender, uint256 _tokenId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        address owner = ownerOf(_tokenId);
        return (_spender == owner ||
            getApproved(_tokenId) == _spender ||
            isApprovedForAll(owner, _spender));
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal override {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId); // internal owner
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address receiver = royaltyReceivers[_tokenId];
        (bool wasBatchMinted, , ) = _batchMintInfo(_tokenId);
        bool exists = (wasBatchMinted || receiver != address(0)) &&
            !tokensBurned[_tokenId];

        require(exists, "ERC721: approved query for nonexistent token");

        return _tokenApprovals[_tokenId];
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override {
        require(_tokenId != 0);

        (bool wasBatchMinted, , ) = _batchMintInfo(_tokenId);

        if (
            wasBatchMinted &&
            !ERC721Upgradeable._exists(_tokenId) &&
            !tokensBurned[_tokenId]
        ) {
            _mint(_from, _tokenId);
        }

        ERC721Upgradeable._transfer(_from, _to, _tokenId);
    }

    function totalSupply() public view virtual override returns (uint256) {
        return tokenIdCounter.current();
    }

    function _batchMintInfo(uint256 _tokenId)
        internal
        view
        returns (
            bool _wasBatchMinted,
            uint256 _batchIndex,
            string memory _baseTokenUri
        )
    {
        for (uint256 i = 0; i < mintBatches.length; i++) {
            if (
                _tokenId >= mintBatches[i].startTokenId &&
                _tokenId <= mintBatches[i].endTokenId
            ) {
                return (true, i, mintBatches[i].baseURI);
            }
        }

        return (false, 0, "");
    }
}