// SPDX-License-Identifier: MIT
// Author: Philipp Adrian (ph101pp.eth)

pragma solidity ^0.8.12;

import "./ERC1155MintRangeUpdateable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./Ph101ppDailyPhotoUtils.sol";
import "./IPh101ppDailyPhotoListener.sol";
import "./OpenseaOperatorFilterer.sol";

contract Ph101ppDailyPhoto is
    ERC1155MintRangeUpdateable,
    ERC2981,
    Ownable,
    OpenseaOperatorFilterer
{
    uint public constant START_DATE = 1661990400; // Sept 1, 2022
    uint public constant CLAIM_TOKEN_ID = 0;
    string private constant _CLAIM_TOKEN = "CLAIM";

    uint private constant TREASURY_ID = 0;
    uint private constant VAULT_ID = 1;

    uint[][] private _initialSupplies;
    uint[] private _initialSupplyRanges;
    string[] private _permanentUris;
    uint[] private _permanentUriRanges;
    string[] private _periods;
    uint[] private _periodRanges;
    string private _proxyUri;

    uint public lastRangeTokenIdWithPermanentUri;
    bool public isInitialHoldersRangeUpdatePermanentlyDisabled;

    address public transferEventListenerAddress;
    bool public isTransferEventListenerAddressPermanentlyFrozen = false;

    constructor(
        string memory newProxyUri,
        // string memory newPermanentUri,
        address[] memory initialHolders
    ) ERC1155_("") ERC1155MintRange(initialHolders) {
        // require(initialHolders.length == 2);

        // set initial max supply to 2-3;
        _initialSupplyRanges.push(0);
        _initialSupplies.push([2, 3]);

        // _permanentUriRanges.push(0);
        // _permanentUris.push(newPermanentUri);

        _periodRanges.push(0);
        _periods.push("Init");

        _proxyUri = newProxyUri;
        _setDefaultRoyalty(msg.sender, 500);
        // mintClaims(initialHolders[TREASURY_ID], 10, "");
    }

    ///////////////////////////////////////////////////////////////////////////////
    // Token Balances
    ///////////////////////////////////////////////////////////////////////////////

    // Defines initial balances for lazy minted photo nfts
    function initialBalanceOf(
        address account,
        uint tokenId
    ) internal view override returns (uint) {
        address[] memory addresses = initialHolders(tokenId);

        // if account is treasury account:
        if (account == addresses[TREASURY_ID]) {
            uint[] memory _initialSupply = initialSupply(tokenId);

            // calculate deterministic random initial balance between min / max initialSupply.
            uint supply = (uint(
                keccak256(abi.encode(tokenId, address(this), _initialSupply))
            ) % (_initialSupply[1] - _initialSupply[0] + 1)) +
                _initialSupply[0];

            return supply;
        }

        // if account is vault account initial balance is 1
        if (account == addresses[VAULT_ID]) {
            return 1;
        }

        // all other accounts have no initial balance
        return 0;
    }

    ///////////////////////////////////////////////////////////////////////////////
    // Uris
    ///////////////////////////////////////////////////////////////////////////////

    // Returns permanent uri where already available, otherwise proxy uri.
    function uri(uint tokenId) public view override returns (string memory) {
        string memory base = (exists(tokenId) &&
            lastRangeTokenIdWithPermanentUri >= tokenId)
            ? permanentBaseUri() // ... uri updated since token -> immutable uri
            : proxyBaseUri(); // else ... uri not yet updated since token -> mutable uri

        return string.concat(base, tokenSlugFromTokenId(tokenId));
    }

    // Returns all histoical uris that include tokenId
    function uriHistory(uint tokenId) public view returns (string[][] memory) {
        if (tokenId > lastRangeTokenIdWithPermanentUri) {
            return new string[][](0);
        }
        uint permanentUriIndex = _findLowerBound(_permanentUriRanges, tokenId);
        string memory slug = tokenSlugFromTokenId(tokenId);
        string[][] memory history = new string[][](
            _permanentUris.length - permanentUriIndex
        );
        for (uint i = permanentUriIndex; i < _permanentUris.length; i++) {
            string[] memory item = new string[](2);
            item[0] = string.concat(_permanentUris[i], slug);
            item[1] = period(_permanentUriRanges[i]);
            history[i - permanentUriIndex] = item;
        }
        return history;
    }

    // Returns proxy base Uri that is used for
    // tokens not included in the permanent Uris yet.
    function proxyBaseUri() public view returns (string memory) {
        return _proxyUri;
    }

    // Returns latest permanent base Uri
    function permanentBaseUri() public view returns (string memory) {
        return _permanentUris[_permanentUris.length - 1];
    }

    // Returns permanent base uris ranges for the record.
    function permanentBaseUriRanges()
        public
        view
        returns (string[] memory permanentBaseUris, uint256[] memory ranges)
    {
        return (_permanentUris, _permanentUriRanges);
    }

    // Updates latest permanent base Uri.
    // New uri must include more token Ids than previous one.
    function setPermanentBaseUriUpTo(
        string memory newUri,
        uint validUpToTokenId
    ) public whenNotPaused onlyOwner {
        require(
            !isZeroMinted ||
                (validUpToTokenId > lastRangeTokenIdWithPermanentUri &&
                    validUpToTokenId <= lastRangeTokenIdMinted),
            "P:01" // !(lastIdWithPermanentUri < TokenId <= lastIdMinted)
        );
        if (validUpToTokenId == 0) {
            _permanentUris.push(newUri);
            _permanentUriRanges.push(0);
            lastRangeTokenIdWithPermanentUri = 0;
        } else {
            _permanentUris.push(newUri);
            _permanentUriRanges.push(lastRangeTokenIdWithPermanentUri + 1);
            lastRangeTokenIdWithPermanentUri = validUpToTokenId;
        }
    }

    // Update proxy base Uri that is used for
    // tokens not included in the permanent Uris yet.
    function setProxyBaseUri(
        string memory newProxyUri
    ) public whenNotPaused onlyOwner {
        _proxyUri = newProxyUri;
    }

    ///////////////////////////////////////////////////////////////////////////////
    // Periods
    ///////////////////////////////////////////////////////////////////////////////

    // Returns Period when token was minted
    function period(uint tokenId) public view returns (string memory) {
        uint periodIndex = _findLowerBound(_periodRanges, tokenId);
        return _periods[periodIndex];
    }

    // Returns all period ranges.
    function periodRanges()
        public
        view
        returns (string[] memory periods, uint256[] memory ranges)
    {
        return (_periods, _periodRanges);
    }

    // Sets new period for current permanent uri
    function setPeriod(
        string memory periodName
    ) public whenNotPaused onlyOwner {
        uint lastPeriodIndex = _periodRanges.length - 1;
        uint tokenId = _permanentUriRanges[_permanentUriRanges.length - 1];

        if (tokenId == _periodRanges[lastPeriodIndex]) {
            _periods[lastPeriodIndex] = periodName;
        } else {
            _periods.push(periodName);
            _periodRanges.push(tokenId);
        }
    }

    ///////////////////////////////////////////////////////////////////////////////
    // Claims
    ///////////////////////////////////////////////////////////////////////////////

    // Mint new claims to a wallet.
    function mintClaims(
        address to,
        uint amount,
        bytes memory data
    ) public onlyOwner {
        _mint(to, CLAIM_TOKEN_ID, amount, data);
    }

    // Redeem multiple claim tokens for photo nfts (n:n).
    function redeemClaims(
        uint[] memory tokenIds,
        uint[] memory amounts
    ) public {
        uint claimsRequired = amounts[0];
        address[] memory initialHolders0 = initialHolders(tokenIds[0]);
        for (uint i = 1; i < amounts.length; i++) {
            claimsRequired += amounts[i];
        }
        _burn(msg.sender, CLAIM_TOKEN_ID, claimsRequired);
        _safeBatchTransferFrom(
            initialHolders0[TREASURY_ID],
            msg.sender,
            tokenIds,
            amounts,
            ""
        );
    }

    ///////////////////////////////////////////////////////////////////////////////
    // Mint Photos (Mint Range)
    ///////////////////////////////////////////////////////////////////////////////

    // Lazy mint a new batch of unrevealed / future photos.
    // Use getMintRangeInput(uint numberOfTokens) to generate input.
    function mintPhotos(
        MintRangeInput memory input,
        bytes32 checksum
    ) public onlyOwner {
        _mintRange(input, checksum);
    }

    ///////////////////////////////////////////////////////////////////////////////
    // Initial Supply
    ///////////////////////////////////////////////////////////////////////////////

    // Update initial supply range [min, max] for future mints.
    function setInitialSupply(
        uint[] memory newInitialSupply
    ) public whenNotPaused onlyOwner {
        require(
            newInitialSupply.length == 2 &&
                newInitialSupply[0] <= newInitialSupply[1],
            "P:02"
        );
        uint firstId = isZeroMinted ? lastRangeTokenIdMinted + 1 : 0;
        uint lastIndex = _initialSupplyRanges.length - 1;
        uint lastId = _initialSupplyRanges[lastIndex];

        if (lastId == firstId) {
            _initialSupplies[lastIndex] = newInitialSupply;
        } else {
            _initialSupplyRanges.push(firstId);
            _initialSupplies.push(newInitialSupply);
        }
    }

    // Returns initial supply range that was used for a tokenId.
    function initialSupply(uint tokenId) public view returns (uint[] memory) {
        // optimization for mintRange
        uint lastIndex = _initialSupplyRanges.length - 1;
        if (_initialSupplyRanges[lastIndex] <= tokenId) {
            return _initialSupplies[lastIndex];
        }
        uint supplyIndex = _findLowerBound(_initialSupplyRanges, tokenId);
        return _initialSupplies[supplyIndex];
    }

    // Return current initial supply Ranges
    function initialSupplyRanges()
        public
        view
        returns (uint[][] memory supplies, uint[] memory ranges)
    {
        return (_initialSupplies, _initialSupplyRanges);
    }

    ///////////////////////////////////////////////////////////////////////////////
    // Initial Holders
    ///////////////////////////////////////////////////////////////////////////////

    // Update initial holder accounts for future mints.
    function setInitialHolders(
        address treasury,
        address vault
    ) public whenNotPaused onlyOwner {
        address[] memory addresses = new address[](2);
        addresses[0] = treasury;
        addresses[1] = vault;
        _setInitialHolders(addresses);
    }

    // Update initial holder accounts for existing mints.
    // This method allows unsold & never transfered & non-locked tokens
    // in the treasury & vault to be moved to new treasury & vault
    // wallets without having to transfer them through ERC1155.
    // This method doesnt affect ERC1155.balances, so tokens that
    // have been sold or transfered before can't ever be affected by this method.
    function updateInitialHolders(
        UpdateInitialHoldersInput memory input,
        bytes32 checksum
    ) public onlyOwner {
        require(!isInitialHoldersRangeUpdatePermanentlyDisabled, "P:03");
        _updateInitialHoldersSafe(input, checksum);
    }

    // Lock initial holders up to tokenId
    // so they cant be updated via updateInitialHolders.
    function setLockInitialHoldersUpTo(
        uint256 tokenId
    ) public whenNotPaused onlyOwner {
        _setLockInitialHoldersUpTo(tokenId);
    }

    // Permanently disable updateInitialHolders.
    function permanentlyDisableInitialHoldersRangeUpdate()
        public
        whenNotPaused
        onlyOwner
    {
        isInitialHoldersRangeUpdatePermanentlyDisabled = true;
    }

    ///////////////////////////////////////////////////////////////////////////////
    // ERC2981 Royalties
    ///////////////////////////////////////////////////////////////////////////////

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public whenNotPaused onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(
        uint tokenId,
        address receiver,
        uint96 feeNumerator
    ) public whenNotPaused onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint tokenId) public whenNotPaused onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    ///////////////////////////////////////////////////////////////////////////////
    // Pausable
    ///////////////////////////////////////////////////////////////////////////////

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    ///////////////////////////////////////////////////////////////////////////////
    // Token ID < > Date helpers
    ///////////////////////////////////////////////////////////////////////////////

    function tokenSlugFromTokenId(
        uint tokenId
    ) public pure returns (string memory tokenSlug) {
        return Ph101ppDailyPhotoUtils.tokenSlugFromTokenId(tokenId);
    }

    function tokenSlugFromDate(
        uint year,
        uint month,
        uint day
    ) public pure returns (string memory tokenSlug) {
        return Ph101ppDailyPhotoUtils.tokenSlugFromDate(year, month, day);
    }

    ///////////////////////////////////////////////////////////////////////////////
    // Opensea Operator Filterer
    ///////////////////////////////////////////////////////////////////////////////

    // Owner can mint new tokens and make updates to the contract
    function owner()
        public
        view
        override(OpenseaOperatorFilterer, Ownable)
        returns (address)
    {
        return super.owner();
    }

    // Update address to OperatorFilterRegistry contract.
    // Set to address(0) to disable registry checks.
    function setOperatorFilterRegistryAddress(
        address _operatorFilterRegistryAddress
    ) public whenNotPaused onlyOwner {
        _setOperatorFilterRegistryAddress(_operatorFilterRegistryAddress);
    }

    // Permanently freeze operator filter registry address
    function permanentlyFreezeOperatorFilterRegistryAddress()
        public
        whenNotPaused
        onlyOwner
    {
        _permanentlyFreezeOperatorFilterRegistryAddress();
    }

    ///////////////////////////////////////////////////////////////////////////////
    // Transfer Event Listener Address
    ///////////////////////////////////////////////////////////////////////////////

    function setTransferEventListenerAddress(
        address listener
    ) public whenNotPaused onlyOwner {
        require(!isTransferEventListenerAddressPermanentlyFrozen, "P:04");
        transferEventListenerAddress = listener;
    }

    // Permanently freeze transfer listener address
    function permanentlyFreezeTransferEventListenerAddress()
        public
        whenNotPaused
        onlyOwner
    {
        isTransferEventListenerAddressPermanentlyFrozen = true;
    }

    ///////////////////////////////////////////////////////////////////////////////
    // Transfer & Approval mods for Opensea Operator Filterer & Transfer Event
    ///////////////////////////////////////////////////////////////////////////////

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override whenNotPaused onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint[] memory ids,
        uint[] memory amounts,
        bytes memory data
    ) internal virtual override onlyAllowedOperator(from) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // Notify custom listener about token transfers
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint[] memory ids,
        uint[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._afterTokenTransfer(operator, from, to, ids, amounts, data);
        if (transferEventListenerAddress != address(0)) {
            IPh101ppDailyPhotoListener(transferEventListenerAddress)
                .Ph101ppDailyPhotoTransferHandler(
                    operator,
                    from,
                    to,
                    ids,
                    amounts,
                    data
                );
        }
    }

    ///////////////////////////////////////////////////////////////////////////////
    // Interface
    ///////////////////////////////////////////////////////////////////////////////

    // The following functions are overrides required by Solidity.
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155_, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}