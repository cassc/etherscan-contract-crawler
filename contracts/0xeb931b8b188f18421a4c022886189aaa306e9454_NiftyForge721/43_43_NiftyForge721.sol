//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './NFT/ERC721Full.sol';

import './Modules/INFModuleWithEvents.sol';
import './Modules/INFModuleTokenURI.sol';
import './Modules/INFModuleRenderTokenURI.sol';
import './Modules/INFModuleWithRoyalties.sol';
import './Modules/INFModuleMutableURI.sol';

import './NiftyForge/NiftyForgeWithModules.sol';
import './INiftyForge721.sol';

/// @title NiftyForge721
/// @author Simon Fremaux (@dievardump)
contract NiftyForge721 is NiftyForgeWithModules, ERC721Full {
    error AlreadyMinted();
    error OutOfJpegs();
    error UnknownToken();
    error AlreadySet();

    uint256 internal _totalMinted;
    uint256 internal _burned;

    /// @dev incremential token id counter
    uint256 private _counter;

    /// @notice offset used to start token id at 0 if needed
    uint256 public offsetId;

    bool public isMintingOpenToAll;

    /// @notice maxSupply this can be set only once by the owner of the contract
    // this is used to ensure a max token creation that can be used
    // for example when people create a series of XX elements
    // since this contract works with "Minters", it is good to
    // be able to set in it that there is a max number of elements
    // and that this can not change
    uint256 public maxSupply;

    mapping(uint256 => address) public tokenIdToModule;

    /// @notice this is the constructor of the contract, called at the time of creation
    ///         Although it uses what are called upgradeable contracts, this is only to
    ///         be able to make deployment cheap using a Proxy but NiftyForge contracts
    ///         ARE NOT UPGRADEABLE => the proxy used is not an upgradeable proxy, the implementation is immutable
    /// @param name_ name of the contract (see ERC721)
    /// @param symbol_ symbol of the contract (see ERC721)
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param baseURI_ the contract baseURI (if there is)  - can be empty ""
    /// @param owner_ Address to whom transfer ownership
    /// @param modulesInit_ modules to add / enable directly at creation
    /// @param contractRoyaltiesRecipient the recipient, if the contract has "contract wide royalties"
    /// @param contractRoyaltiesValue the value, modules to add / enable directly at creation
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory baseURI_,
        address owner_,
        INiftyForge721.ModuleInit[] memory modulesInit_,
        address contractRoyaltiesRecipient,
        uint256 contractRoyaltiesValue
    ) external initializer {
        __ERC721Full_init(name_, symbol_, contractURI_, baseURI_, address(0));

        for (uint256 i; i < modulesInit_.length; i++) {
            _attachModule(modulesInit_[i].module, modulesInit_[i].enabled);
            if (modulesInit_[i].enabled && modulesInit_[i].minter) {
                _grantRole(ROLE_MINTER, modulesInit_[i].module);
            }
        }

        // here, if  contractRoyaltiesRecipient is not address(0) but
        // contractRoyaltiesValue is 0, this will mean that this contract will
        // NEVER have royalties, because whenever default royalties are set, it is
        // always used for every tokens.
        if (
            contractRoyaltiesRecipient != address(0) ||
            contractRoyaltiesValue != 0
        ) {
            _setDefaultRoyalties(
                contractRoyaltiesRecipient,
                contractRoyaltiesValue
            );
        }

        // transfer owner only after attaching modules
        if (owner_ != address(0)) {
            transferOwnership(owner_);
        }
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
        return hex'000001';
    }

    /// @notice Since this contract can only mint in sequence, we can keep track of totalSupply easily
    /// @return the current total supply
    function totalSupply() external view returns (uint256) {
        return _totalMinted - _burned;
    }

    /// @notice Helper to know if an address can do the action a Minter can
    /// @param user the address to check
    function canMint(address user) public view virtual override returns (bool) {
        return super.canMint(user) || isMintingOpenToAll;
    }

    /// @notice returns a tokenURI
    /// @dev This function will first check if the token comes from a Module, and if yes, try to get the tokenURI from it
    ///      else it will try to get the tokenURI directly from the storage
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
        if (!_exists(tokenId)) {
            revert UnknownToken();
        }

        // first, try to get the URI from the module that might have created it
        (bool support, address module) = _moduleSupports(
            tokenId,
            type(INFModuleTokenURI).interfaceId
        );

        if (support) {
            uri = INFModuleTokenURI(module).tokenURI(address(this), tokenId);
        }

        // if uri not set, get it with the normal tokenURI
        if (bytes(uri).length == 0) {
            uri = super.tokenURI(tokenId);
        }
    }

    /// @notice function that returns a string that can be used to render the current token
    ///         this can be an URL but also any other data uri
    ///         This is something that I would like to present as an EIP later to allow dynamique
    ///         render URL
    /// @param tokenId tokenId
    /// @return uri the URI to render token
    function renderTokenURI(uint256 tokenId)
        public
        view
        returns (string memory uri)
    {
        if (!_exists(tokenId)) {
            revert UnknownToken();
        }

        // Try to get the URI from the module that might have created this token
        (bool support, address module) = _moduleSupports(
            tokenId,
            type(INFModuleRenderTokenURI).interfaceId
        );
        if (support) {
            uri = INFModuleRenderTokenURI(module).renderTokenURI(tokenId);
        }
    }

    /// @notice function that returns a string that can be used to add metadata on top of what is in tokenURI
    ///         This function has been added because sometimes, we want some metadata to be completly immutable
    ///         But to have others that aren't (for example if a token is linked to a physical token, and the physical
    ///         token state can change over time)
    ///         This way we can reflect those changes without risking breaking the base meta (tokenURI)
    /// @param tokenId tokenId
    /// @return uri the URI where mutable can be found
    function mutableURI(uint256 tokenId)
        public
        view
        override
        returns (string memory uri)
    {
        if (!_exists(tokenId)) {
            revert UnknownToken();
        }

        // first, try to get the URI from the module that might have created it
        (bool support, address module) = _moduleSupports(
            tokenId,
            type(INFModuleMutableURI).interfaceId
        );
        if (support) {
            uri = INFModuleMutableURI(module).mutableURI(tokenId);
        }

        // if uri not set, get it with the normal mutableURI
        if (bytes(uri).length == 0) {
            uri = super.mutableURI(tokenId);
        }
    }

    ////////////////////////////////////////////////////////////
    // Editors / Minters                                      //
    ////////////////////////////////////////////////////////////

    /// @notice Toggle minting open to all state
    /// @param isOpen if the new state is open or not
    function setMintingOpenToAll(bool isOpen) external onlyEditor(msg.sender) {
        isMintingOpenToAll = isOpen;
    }

    /// @notice allows owner to set a maxSupply (be careful, this is a one time call function)
    ///      When set, the max supply can not be reverted nor changed
    /// @param maxSupply_ the max token id possible
    function setMaxSupply(uint256 maxSupply_) external onlyEditor(msg.sender) {
        if (maxSupply != 0) {
            revert AlreadySet();
        }
        maxSupply = maxSupply_;
    }

    /// @notice Mint next token to `to`
    /// @param to address of recipient
    /// @return tokenId the tokenId
    function mint(address to)
        public
        onlyMinter(msg.sender)
        returns (uint256 tokenId)
    {
        tokenId = _counter + 1 - offsetId;
        mint(to, '', tokenId, address(0), 0, address(0));
        _counter++;
    }

    /// @notice Mint next token to `to` and then transfers to `transferTo`
    /// @param to address of first recipient
    /// @param transferTo address to transfer token to
    /// @return tokenId the tokenId
    function mint(address to, address transferTo)
        public
        onlyMinter(msg.sender)
        returns (uint256 tokenId)
    {
        tokenId = _counter + 1 - offsetId;
        mint(to, '', tokenId, address(0), 0, transferTo);
        _counter++;
    }

    /// @notice Mint token to `to` with `uri`
    /// @param to address of recipient
    /// @param uri token metadata uri
    /// @param feeRecipient the recipient of royalties
    /// @param feeAmount the royalties amount. From 0 to 10000
    ///        where 10000 == 100.00%; 1000 == 10.00%; 250 == 2.50%
    /// @param transferTo the address to transfer the NFT to after mint
    ///        this is used when we want to mint the NFT to the creator address
    ///        before transfering it to a recipient
    /// @return tokenId the tokenId
    function mint(
        address to,
        string memory uri,
        address feeRecipient,
        uint256 feeAmount,
        address transferTo
    ) public onlyMinter(msg.sender) returns (uint256 tokenId) {
        tokenId = _counter + 1 - offsetId;
        mint(to, uri, tokenId, feeRecipient, feeAmount, transferTo);
        _counter++;
    }

    /// @notice Mint batch tokens to `to[i]` with `uri[i]`
    /// @param to array of address of recipients
    /// @param uris array of token metadata uris
    /// @param feeRecipients the recipients of royalties for each id
    /// @param feeAmounts the royalties amounts for each id. From 0 to 10000
    ///        where 10000 == 100.00%; 1000 == 10.00%; 250 == 2.50%
    /// @return startId the first id
    /// @return endId the last id
    function mintBatch(
        address[] memory to,
        string[] memory uris,
        address[] memory feeRecipients,
        uint256[] memory feeAmounts
    ) public onlyMinter(msg.sender) returns (uint256 startId, uint256 endId) {
        require(
            to.length == uris.length &&
                to.length == feeRecipients.length &&
                to.length == feeAmounts.length,
            '!LENGTH_MISMATCH!'
        );

        uint256 offset = offsetId;
        uint256 counter = _counter;

        uint256 length = to.length;

        startId = counter + 1 - offset;
        endId = startId + length - 1;

        // verify that we don't mint more than maxSupply
        _verifyMaxSupply((_totalMinted += length));

        bool isModule = modulesStatus[msg.sender] == ModuleStatus.ENABLED;
        for (uint256 i; i < length; i++) {
            _mint(
                to[i],
                uris[i],
                startId + i,
                feeRecipients[i],
                feeAmounts[i],
                isModule
            );
        }

        // setting _counter after will ensure that any reEntrancy will fail
        // to mint, because the minting will throw with a duplicate id
        _counter = counter + length;
    }

    /// @notice Mint `tokenId` to to` with `uri` and transfer to transferTo if not null
    ///         Because not all tokenIds have incremental ids
    ///         be careful with this function, it does not increment _counter
    ///         and expects the minter to actually know what it is doing.
    /// @param to address of recipient
    /// @param uri token metadata uri
    /// @param tokenId token id wanted
    /// @param feeRecipient the recipient of royalties
    /// @param feeAmount the royalties amount. From 0 to 10000
    ///        where 10000 == 100.00%; 1000 == 10.00%; 250 == 2.50%
    /// @param transferTo the address to transfer the NFT to after mint
    ///        this is used when we want to mint the NFT to the creator address
    ///        before transfering it to a recipient
    /// @return the tokenId
    function mint(
        address to,
        string memory uri,
        uint256 tokenId,
        address feeRecipient,
        uint256 feeAmount,
        address transferTo
    ) public onlyMinter(msg.sender) returns (uint256) {
        // minting will throw if the tokenId already exists

        // verify that we don't mint more than maxSupply
        _verifyMaxSupply(++_totalMinted);

        _mint(
            to,
            uri,
            tokenId,
            feeRecipient,
            feeAmount,
            modulesStatus[msg.sender] == ModuleStatus.ENABLED
        );

        if (transferTo != address(0)) {
            _transfer(to, transferTo, tokenId);
        }

        return tokenId;
    }

    /// @notice Mint batch tokens to `to[i]` with `uris[i]`
    ///         Because not all tokenIds have incremental ids
    ///         be careful with this function, it does not increment _counter
    ///         and expects the minter to actually know what it's doing.
    ///         this also means, this function does not verify maxTokenId
    /// @param to array of address of recipients
    /// @param uris array of token metadata uris
    /// @param tokenIds array of token ids wanted
    /// @param feeRecipients the recipients of royalties for each id
    /// @param feeAmounts the royalties amounts for each id. From 0 to 10000
    ///        where 10000 == 100.00%; 1000 == 10.00%; 250 == 2.50%
    function mintBatch(
        address[] memory to,
        string[] memory uris,
        uint256[] memory tokenIds,
        address[] memory feeRecipients,
        uint256[] memory feeAmounts
    ) public onlyMinter(msg.sender) {
        // minting will throw if any tokenIds[i] already exists

        // saves gas
        uint256 length = to.length;

        require(
            length == uris.length &&
                length == tokenIds.length &&
                length == feeRecipients.length &&
                length == feeAmounts.length,
            '!LENGTH_MISMATCH!'
        );

        uint256 highestId;

        // we also verify maxSupply in this case
        // because else it would allow owners to mint arbitrary tokens
        // after setting the max
        _verifyMaxSupply((_totalMinted += length));

        bool isModule = modulesStatus[msg.sender] == ModuleStatus.ENABLED;
        for (uint256 i; i < length; i++) {
            if (tokenIds[i] > highestId) {
                highestId = tokenIds[i];
            }
            _mint(
                to[i],
                uris[i],
                tokenIds[i],
                feeRecipients[i],
                feeAmounts[i],
                isModule
            );
        }
    }

    /// @notice Attach a module
    /// @param module a module to attach
    /// @param enabled if the module is enabled by default
    /// @param moduleCanMint if the module has to be given the minter role
    function attachModule(
        address module,
        bool enabled,
        bool moduleCanMint
    ) external onlyEditor(msg.sender) {
        // give the minter role if enabled and moduleCanMint
        if (moduleCanMint && enabled) {
            _grantRole(ROLE_MINTER, module);
        }

        _attachModule(module, enabled);
    }

    /// @dev Allows owner to enable a module
    /// @param module to enable
    /// @param moduleCanMint if the module has to be given the minter role
    function enableModule(address module, bool moduleCanMint)
        external
        onlyEditor(msg.sender)
    {
        // give the minter role if moduleCanMint
        if (moduleCanMint) {
            _grantRole(ROLE_MINTER, module);
        }

        _enableModule(module);
    }

    /// @dev Allows owner to disable a module
    /// @param module to disable
    function disableModule(address module, bool keepListeners)
        external
        onlyEditor(msg.sender)
    {
        _disableModule(module, keepListeners);
    }

    /// @notice This function allows to offset minted in order to start ids at 0
    function startAtZero() external onlyEditor(msg.sender) {
        if (_totalMinted != 0) revert AlreadyMinted();
        offsetId = 1;
    }

    ////////////////////////////////////////////////////////////
    // Internal                                               //
    ////////////////////////////////////////////////////////////

    /// @dev Internal mint function
    /// @param to token recipient
    /// @param uri token uri
    /// @param tokenId token Id
    /// @param feeRecipient the recipient of royalties
    /// @param feeAmount the royalties amounts. From 0 to 10000
    ///        where 10000 == 100.00%; 1000 == 10.00%; 250 == 2.50%
    /// @param isModule if the minter is a module
    function _mint(
        address to,
        string memory uri,
        uint256 tokenId,
        address feeRecipient,
        uint256 feeAmount,
        bool isModule
    ) internal {
        _safeMint(to, tokenId, '');

        if (bytes(uri).length > 0) {
            _setTokenURI(tokenId, uri);
        }

        if (feeAmount > 0) {
            _setTokenRoyalty(tokenId, feeRecipient, feeAmount);
        }

        if (isModule) {
            tokenIdToModule[tokenId] = msg.sender;
        }
    }

    // here we override _mint, _transfer and _burn because we want the event to be fired
    // only after the action is done
    // else we would have done that in _beforeTokenTransfer
    /// @dev _mint override to be able to fire events
    /// @inheritdoc ERC721Upgradeable
    function _mint(address to, uint256 tokenId) internal virtual override {
        super._mint(to, tokenId);
        _fireEvent(INFModuleWithEvents.Events.MINT, tokenId, address(0), to);
    }

    /// @dev _transfer override to be able to fire events
    /// @inheritdoc ERC721Upgradeable
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._transfer(from, to, tokenId);

        if (to == address(0xdEaD)) {
            _fireEvent(INFModuleWithEvents.Events.BURN, tokenId, from, to);
        } else {
            _fireEvent(INFModuleWithEvents.Events.TRANSFER, tokenId, from, to);
        }
    }

    /// @dev _burn override to be able to fire event
    /// @inheritdoc ERC721Upgradeable
    function _burn(uint256 tokenId) internal virtual override {
        address owner_ = ownerOf(tokenId);
        super._burn(tokenId);
        _burned++;
        _fireEvent(
            INFModuleWithEvents.Events.BURN,
            tokenId,
            owner_,
            address(0)
        );
    }

    function _disableModule(address module, bool keepListeners)
        internal
        override
    {
        // always revoke the minter role when disabling a module
        _revokeRole(ROLE_MINTER, module);

        super._disableModule(module, keepListeners);
    }

    /// @dev Verifies that we do not create more token than the max supply
    /// @param nextSupply the next supply
    function _verifyMaxSupply(uint256 nextSupply) internal view {
        uint256 maxSupply_ = maxSupply;
        if (maxSupply_ != 0 && nextSupply > maxSupply_) {
            revert OutOfJpegs();
        }
    }

    /// @dev Gets token royalties taking modules into account
    /// @param tokenId the token id for which we check the royalties
    function _getTokenRoyalty(uint256 tokenId)
        internal
        view
        override
        returns (address royaltyRecipient, uint256 royaltyAmount)
    {
        (royaltyRecipient, royaltyAmount) = super._getTokenRoyalty(tokenId);

        // if there are no royalties set either contract wide or per token
        if (royaltyAmount == 0) {
            // try to see if the token was created by a module that manages royalties
            (bool support, address module) = _moduleSupports(
                tokenId,
                type(INFModuleWithRoyalties).interfaceId
            );
            if (support) {
                (royaltyRecipient, royaltyAmount) = INFModuleWithRoyalties(
                    module
                ).royaltyInfo(address(this), tokenId);
            }
        }
    }

    function _moduleSupports(uint256 tokenId, bytes4 interfaceId)
        internal
        view
        returns (bool support, address module)
    {
        module = tokenIdToModule[tokenId];
        support =
            module != address(0) &&
            IERC165Upgradeable(module).supportsInterface(interfaceId);
    }
}