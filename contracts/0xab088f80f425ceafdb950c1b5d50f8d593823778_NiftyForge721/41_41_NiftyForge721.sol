//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './NFT/ERC721Helpers/ERC721Full.sol';

import './NiftyForge/Modules/INFModuleWithEvents.sol';
import './NiftyForge/Modules/INFModuleTokenURI.sol';
import './NiftyForge/Modules/INFModuleRenderTokenURI.sol';
import './NiftyForge/Modules/INFModuleWithRoyalties.sol';
import './NiftyForge/Modules/INFModuleMutableURI.sol';

import './NiftyForge/NiftyForgeModules.sol';
import './INiftyForge721.sol';

/// @title NiftyForge721
/// @author Simon Fremaux (@dievardump)
contract NiftyForge721 is INiftyForge721, NiftyForgeModules, ERC721Full {
    /// @dev This contains the last token id that was created
    uint256 public lastTokenId;

    uint256 public totalSupply;

    bool private _mintingOpenToAll;

    // this can be set only once by the owner of the contract
    // this is used to ensure a max token creation that can be used
    // for example when people create a series of XX elements
    // since this contract works with "Minters", it is good to
    // be able to set in it that there is a max number of elements
    // and that this can not change
    uint256 public maxTokenId;

    mapping(uint256 => address) public tokenIdToModule;

    /// @notice modifier allowing only safe listed addresses to mint
    ///         safeListed addresses have roles Minter, Editor or Owner
    modifier onlyMinter(address minter) virtual override {
        require(isMintingOpenToAll() || canMint(minter), '!NOT_MINTER!');
        _;
    }

    /// @notice this is the constructor of the contract, called at the time of creation
    ///         Although it uses what are called upgradeable contracts, this is only to
    ///         be able to make deployment cheap using a Proxy but NiftyForge contracts
    ///         ARE NOT UPGRADEABLE => the proxy used is not an upgradeable proxy, the implementation is immutable
    /// @param name_ name of the contract (see ERC721)
    /// @param symbol_ symbol of the contract (see ERC721)
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param openseaProxyRegistry_ OpenSea's proxy registry to allow gas-less listings - can be address(0)
    /// @param owner_ Address to whom transfer ownership
    /// @param modulesInit_ modules to add / enable directly at creation
    /// @param contractRoyaltiesRecipient the recipient, if the contract has "contract wide royalties"
    /// @param contractRoyaltiesValue the value, modules to add / enable directly at creation
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        address openseaProxyRegistry_,
        address owner_,
        ModuleInit[] memory modulesInit_,
        address contractRoyaltiesRecipient,
        uint256 contractRoyaltiesValue
    ) external initializer {
        __ERC721Full_init(
            name_,
            symbol_,
            contractURI_,
            openseaProxyRegistry_,
            owner_
        );

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
    }

    /// @notice helper to know if everyone can mint or only minters
    function isMintingOpenToAll() public view override returns (bool) {
        return _mintingOpenToAll;
    }

    /// @notice returns a tokenURI
    /// @dev This function will first check if there is a tokenURI registered for this token in the contract
    ///      if not it will check if the token comes from a Module, and if yes, try to get the tokenURI from it
    ///
    /// @param tokenId a parameter just like in doxygen (must be followed by parameter name)
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

        // first, try to get the URI from the module that might have created it
        (bool support, address module) = _moduleSupports(
            tokenId,
            type(INFModuleTokenURI).interfaceId
        );
        if (support) {
            uri = INFModuleTokenURI(module).tokenURI(tokenId);
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
        override
        returns (string memory uri)
    {
        require(_exists(tokenId), '!UNKNOWN_TOKEN!');

        // Try to get the URI from the module that might have created this token
        (bool support, address module) = _moduleSupports(
            tokenId,
            type(INFModuleRenderTokenURI).interfaceId
        );
        if (support) {
            uri = INFModuleRenderTokenURI(module).renderTokenURI(tokenId);
        }
    }

    /// @notice Toggle minting open to all state
    /// @param isOpen if the new state is open or not
    function setMintingOpenToAll(bool isOpen)
        external
        override
        onlyEditor(msg.sender)
    {
        _mintingOpenToAll = isOpen;
    }

    /// @notice allows owner to set maxTokenId
    /// @dev be careful, this is a one time call function.
    ///      When set, the maxTokenId can not be reverted nor changed
    /// @param maxTokenId_ the max token id possible
    function setMaxTokenId(uint256 maxTokenId_)
        external
        onlyEditor(msg.sender)
    {
        require(maxTokenId == 0, '!MAX_TOKEN_ALREADY_SET!');
        maxTokenId = maxTokenId_;
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
        require(_exists(tokenId), '!UNKNOWN_TOKEN!');

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
    ) public override onlyMinter(msg.sender) returns (uint256 tokenId) {
        tokenId = lastTokenId + 1;
        lastTokenId = mint(
            to,
            uri,
            tokenId,
            feeRecipient,
            feeAmount,
            transferTo
        );
    }

    /// @notice Mint batch tokens to `to[i]` with `uri[i]`
    /// @param to array of address of recipients
    /// @param uris array of token metadata uris
    /// @param feeRecipients the recipients of royalties for each id
    /// @param feeAmounts the royalties amounts for each id. From 0 to 10000
    ///        where 10000 == 100.00%; 1000 == 10.00%; 250 == 2.50%
    /// @return tokenIds the tokenIds
    function mintBatch(
        address[] memory to,
        string[] memory uris,
        address[] memory feeRecipients,
        uint256[] memory feeAmounts
    )
        public
        override
        onlyMinter(msg.sender)
        returns (uint256[] memory tokenIds)
    {
        require(
            to.length == uris.length &&
                to.length == feeRecipients.length &&
                to.length == feeAmounts.length,
            '!LENGTH_MISMATCH!'
        );

        uint256 tokenId = lastTokenId;

        tokenIds = new uint256[](to.length);
        // verify that we don't overflow
        // done here instead of in _mint so we do one read
        // instead of to.length
        _verifyMaxTokenId(tokenId + to.length);

        bool isModule = modulesStatus[msg.sender] == ModuleStatus.ENABLED;
        for (uint256 i; i < to.length; i++) {
            tokenId++;
            _mint(
                to[i],
                uris[i],
                tokenId,
                feeRecipients[i],
                feeAmounts[i],
                isModule
            );
            tokenIds[i] = tokenId;
        }

        // setting lastTokenId after will ensure that any reEntrancy will fail
        // to mint, because the minting will throw with a duplicate id
        lastTokenId = tokenId;
    }

    /// @notice Mint `tokenId` to to` with `uri` and transfer to transferTo if not null
    ///         Because not all tokenIds have incremental ids
    ///         be careful with this function, it does not increment lastTokenId
    ///         and expects the minter to actually know what it is doing.
    ///         this also means, this function does not verify maxTokenId
    /// @param to address of recipient
    /// @param uri token metadata uri
    /// @param tokenId_ token id wanted
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
        uint256 tokenId_,
        address feeRecipient,
        uint256 feeAmount,
        address transferTo
    ) public override onlyMinter(msg.sender) returns (uint256) {
        // minting will throw if the tokenId_ already exists

        // we also verify maxTokenId in this case
        // because else it would allow owners to mint arbitrary tokens
        // after setting the max
        _verifyMaxTokenId(tokenId_);

        _mint(
            to,
            uri,
            tokenId_,
            feeRecipient,
            feeAmount,
            modulesStatus[msg.sender] == ModuleStatus.ENABLED
        );

        if (transferTo != address(0)) {
            _transfer(to, transferTo, tokenId_);
        }

        return tokenId_;
    }

    /// @notice Mint batch tokens to `to[i]` with `uris[i]`
    ///         Because not all tokenIds have incremental ids
    ///         be careful with this function, it does not increment lastTokenId
    ///         and expects the minter to actually know what it's doing.
    ///         this also means, this function does not verify maxTokenId
    /// @param to array of address of recipients
    /// @param uris array of token metadata uris
    /// @param tokenIds array of token ids wanted
    /// @param feeRecipients the recipients of royalties for each id
    /// @param feeAmounts the royalties amounts for each id. From 0 to 10000
    ///        where 10000 == 100.00%; 1000 == 10.00%; 250 == 2.50%
    /// @return tokenIds the tokenIds
    function mintBatch(
        address[] memory to,
        string[] memory uris,
        uint256[] memory tokenIds,
        address[] memory feeRecipients,
        uint256[] memory feeAmounts
    ) public override onlyMinter(msg.sender) returns (uint256[] memory) {
        // minting will throw if any tokenIds[i] already exists

        require(
            to.length == uris.length &&
                to.length == tokenIds.length &&
                to.length == feeRecipients.length &&
                to.length == feeAmounts.length,
            '!LENGTH_MISMATCH!'
        );

        uint256 highestId;
        for (uint256 i; i < tokenIds.length; i++) {
            if (tokenIds[i] > highestId) {
                highestId = tokenIds[i];
            }
        }

        // we also verify maxTokenId in this case
        // because else it would allow owners to mint arbitrary tokens
        // after setting the max
        _verifyMaxTokenId(highestId);

        bool isModule = modulesStatus[msg.sender] == ModuleStatus.ENABLED;
        for (uint256 i; i < to.length; i++) {
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

        return tokenIds;
    }

    /// @notice Attach a module
    /// @param module a module to attach
    /// @param enabled if the module is enabled by default
    /// @param moduleCanMint if the module has to be given the minter role
    function attachModule(
        address module,
        bool enabled,
        bool moduleCanMint
    ) external override onlyEditor(msg.sender) {
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
        override
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
        override
        onlyEditor(msg.sender)
    {
        _disableModule(module, keepListeners);
    }

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
        totalSupply++;

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
        totalSupply--;
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

    /// @dev Verifies that we do not create more token ids than the max if set
    /// @param tokenId the tokenId to verify
    function _verifyMaxTokenId(uint256 tokenId) internal view {
        uint256 maxTokenId_ = maxTokenId;
        require(maxTokenId_ == 0 || tokenId <= maxTokenId_, '!MAX_TOKEN_ID!');
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
                ).royaltyInfo(tokenId);
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