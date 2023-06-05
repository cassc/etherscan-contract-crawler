//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './NFT/ERC721Slim.sol';

import './Modules/INFModuleWithRoyalties.sol';
import './Modules/INFModuleTokenURI.sol';
import './INiftyForge721Slim.sol';

/// @title NiftyForge721Slim
/// @author Simon Fremaux (@dievardump)
/// @dev This is a "slim" version of an ERC721 for NiftyForge
///      Slim ERC721 do not have all the bells and whistle (no roles, no modules, no events)
///      Slim is mostly made for series (Generative stuff, Series with incremntial token ids, PFPs...)
///      or for controlled env
///      The mint starts from 1 (or 0) and goes up, until maxTokenId
///      If a minter is set at initialisation, only this address can mint. forever.
///      else, only the owner can mint.
///      royalties are not managed per item, but are contract wide.
contract NiftyForge721Slim is ERC721Slim {
    error NotAuthorized();
    error OutOfJpegs();
    error MaxTokenAlreadySet();
    error AlreadyMinted();
    error NotZeroMint();
    error WrongTransferTo();

    /// @notice the only address that can mint on this collection. It can never be changed
    address public minter;

    /// @notice how many were minted so far
    uint256 public minted;

    /// @notice offset used to start token id at 0 if needed
    uint256 public offsetId;

    // count the burned to get totalSuply()
    uint256 internal _burned;

    /// @notice maximum tokens that can be created on this contract
    // this can be set only once by the owner of the contract
    // this is used to ensure a max token creation that can be used
    // for example when people create a series of XX elements
    // since this contract works with "Minters", it is good to
    // be able to set in it that there is a max number of elements
    // and that this can not change
    uint256 public maxSupply;

    /// @notice this is the constructor of the contract, called at the time of creation
    ///         Although it uses what are called upgradeable contracts, this is only to
    ///         be able to make deployment cheap using a Proxy but NiftyForge contracts
    ///         ARE NOT UPGRADEABLE => the proxy used is not an upgradeable proxy, the implementation is immutable
    /// @param name_ name of the contract (see ERC721)
    /// @param symbol_ symbol of the contract (see ERC721)
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param baseURI_ the contract baseURI (if there is)  - can be empty ""
    /// @param owner_ Address to whom transfer ownership
    /// @param minter_ The address that has the right to mint on the collection
    /// @param contractRoyaltiesRecipient the recipient, if the contract has "contract wide royalties"
    /// @param contractRoyaltiesValue the value, modules to add / enable directly at creation
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory baseURI_,
        address owner_,
        address minter_,
        address contractRoyaltiesRecipient,
        uint256 contractRoyaltiesValue
    ) external initializer {
        __ERC721Slim__init(name_, symbol_, contractURI_, baseURI_, address(0));

        if (address(0) != minter_) {
            minter = minter_;
        }

        _setDefaultRoyalties(
            contractRoyaltiesRecipient,
            contractRoyaltiesValue
        );

        // transfer owner only after attaching modules
        if (owner_ != address(0)) {
            transferOwnership(owner_);
        }
    }

    ////////////////////////////////////////////////////////////
    // Modifiers                                              //
    ////////////////////////////////////////////////////////////

    modifier onlyMinter() {
        // make sure minter has the right to mint (minter if set, else owner)
        address _minter = minter;
        address sender = msg.sender;
        if (_minter != address(0)) {
            if (sender != _minter) revert NotAuthorized();
        } else if (sender != owner()) {
            revert NotAuthorized();
        }
        _;
    }

    ////////////////////////////////////////////////////////////
    // Getters                                                //
    ////////////////////////////////////////////////////////////

    /// @notice getter for the version of the implementation
    /// @return the current implementation version following the scheme 0x[erc][type][version]
    /// erc: 00 => ERC721 | 01 => ERC1155
    /// type: 00 => full | 01 => slim
    /// version: 00, 01, 02, 03...
    function version() external view returns (bytes3) {
        return hex'000101';
    }

    /// @notice Since this contract can only mint in sequence, we can keep track of totalSupply easily
    /// @return the current total supply
    function totalSupply() external view returns (uint256) {
        return minted - _burned;
    }

    /// @notice returns a tokenURI
    /// @dev This function will first check if the minter is an INFModuleTokenURI
    ///      if yes, tries to get the tokenURI from it
    ///      else it lets the tokenURI be built as usual using _baseURI
    ///
    /// @param tokenId the tokenId
    /// @return uri the tokenURI
    /// @inheritdoc	ERC721Upgradeable
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory uri)
    {
        require(_exists(tokenId), '!UNKNOWN_TOKEN!');

        address _minter = minter;

        if (
            _minter != address(0) &&
            AddressUpgradeable.isContract(_minter) &&
            IERC165Upgradeable(_minter).supportsInterface(
                type(INFModuleTokenURI).interfaceId
            )
        ) {
            uri = INFModuleTokenURI(_minter).tokenURI(address(this), tokenId);
        }

        // if uri not set, get it with the normal tokenURI
        if (bytes(uri).length == 0) {
            uri = super.tokenURI(tokenId);
        }
    }

    ////////////////////////////////////////////////////////////
    // Interaction                                            //
    ////////////////////////////////////////////////////////////

    /// @notice Mint one token to `to`
    /// @param to the recipient
    /// @return tokenId the tokenId minted
    function mint(address to) public onlyMinter returns (uint256 tokenId) {
        tokenId = _singleMint(to, address(0));
    }

    /// @notice Mint one token to `to` and transfers to `transferTo`
    /// @param to the first recipient
    /// @param transferTo the end recipient
    /// @return tokenId the tokenId minted
    function mint(address to, address transferTo)
        public
        onlyMinter
        returns (uint256 tokenId)
    {
        tokenId = _singleMint(to, transferTo);
    }

    /// @notice Mint `count` tokens to `to`
    /// @param to array of address of recipients
    /// @return startId and endId
    function mintBatch(address to, uint256 count)
        public
        onlyMinter
        returns (uint256 startId, uint256 endId)
    {
        if (count == 0) revert NotZeroMint();

        uint256 offset = offsetId;
        uint256 minted_ = minted;

        startId = minted_ + 1 - offset;
        endId = startId + count - 1;

        // in the case we start ids at 0, the maxId is: maxSupply - 1
        if (maxSupply != 0 && endId > (maxSupply - offset)) {
            revert OutOfJpegs();
        }

        for (uint256 i; i < count; i++) {
            _safeMint(to, startId + i);
        }

        // updating after mint, so a reEntrancy would throw.
        minted = minted_ + count;
    }

    ////////////////////////////////////////////////////////////
    // Owner                                                  //
    ////////////////////////////////////////////////////////////

    /// @notice allows owner to set maxsupply
    /// @dev be careful, this is a one time call function.
    ///      When set, the maxSupply can not be reverted nor changed
    /// @param maxSupply_ the max supply for this contract
    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        if (maxSupply != 0) revert MaxTokenAlreadySet();
        maxSupply = maxSupply_;
    }

    /// @notice This function allows to offset the next id in order to start ids at 0
    function startAtZero() external onlyOwner {
        if (minted != 0) revert AlreadyMinted();
        offsetId = 1;
    }

    ////////////////////////////////////////////////////////////
    // Internal                                               //
    ////////////////////////////////////////////////////////////

    function _singleMint(address to, address transferTo)
        internal
        returns (uint256 tokenId)
    {
        uint256 offset = offsetId;

        tokenId = minted + 1 - offset;

        // in the case we start ids at 0, the maxId is: maxSupply - 1
        if (maxSupply != 0 && tokenId > (maxSupply - offset)) {
            revert OutOfJpegs();
        }

        _safeMint(to, tokenId);
        if (transferTo != address(0)) {
            _transfer(to, transferTo, tokenId);
        }

        // updating after mint, so a reEntrancy would throw.
        minted++;
    }

    /// @inheritdoc ERC721Upgradeable
    function _burn(uint256 tokenId) internal virtual override {
        _burned++;
        super._burn(tokenId);
    }

    /// @dev Gets token royalties taking modules into account
    /// @param tokenId the token id for which we check the royalties
    function _getTokenRoyalty(uint256 tokenId)
        internal
        view
        override
        returns (address royaltyRecipient, uint256 royaltyAmount)
    {
        require(_exists(tokenId), '!UNKNOWN_TOKEN!');
        (royaltyRecipient, royaltyAmount) = super._getTokenRoyalty(tokenId);

        // if there are no royalties set already
        // try to see if "minter" is set and is supposed to manage royalties
        if (royaltyAmount == 0) {
            address _minter = minter;

            if (
                _minter != address(0) &&
                AddressUpgradeable.isContract(_minter) &&
                IERC165Upgradeable(_minter).supportsInterface(
                    type(INFModuleWithRoyalties).interfaceId
                )
            ) {
                (royaltyRecipient, royaltyAmount) = INFModuleWithRoyalties(
                    _minter
                ).royaltyInfo(address(this), tokenId);
            }
        }
    }
}