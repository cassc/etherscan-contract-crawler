// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./Authorizable.sol";
import "./UpdateableOperatorFilterer.sol";
import "./FeralfileSaleData.sol";
import "./ECDSASigner.sol";

import "./IFeralfileVault.sol";

contract FeralfileExhibitionV4 is
    ERC721,
    Authorizable,
    UpdateableOperatorFilterer,
    FeralfileSaleData,
    ECDSASigner
{
    using Strings for uint256;

    struct Artwork {
        uint256 seriesId;
        uint256 tokenId;
    }

    struct MintData {
        uint256 seriesId;
        uint256 tokenId;
        address owner;
    }

    // version code of contract
    string public constant codeVersion = "FeralfileExhibitionV4";

    // token base URI
    string public tokenBaseURI;

    // contract URI
    string public contractURI;

    // total supply
    uint256 public totalSupply;

    // burnable
    bool public burnable;

    // bridgeable
    bool public bridgeable;

    // selling
    bool private _selling;

    // mintable
    bool public mintable = true;

    // cost receiver
    address public costReceiver;

    // vault contract instance
    IFeralfileVault public vault;

    // series max supplies
    mapping(uint256 => uint256) internal _seriesMaxSupplies;

    // series total supplies
    mapping(uint256 => uint256) internal _seriesTotalSupplies;

    // all artworks
    mapping(uint256 => Artwork) internal _allArtworks;

    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    constructor(
        string memory name_,
        string memory symbol_,
        bool burnable_,
        bool bridgeable_,
        address signer_,
        address vault_,
        address costReceiver_,
        string memory contractURI_,
        uint256[] memory seriesIds_,
        uint256[] memory seriesMaxSupplies_
    ) ERC721(name_, symbol_) ECDSASigner(signer_) {
        // validations
        require(
            bytes(name_).length > 0,
            "FeralfileExhibitionV4: name_ is empty"
        );
        require(
            bytes(symbol_).length > 0,
            "FeralfileExhibitionV4: symbol_ is empty"
        );
        require(
            vault_ != address(0),
            "FeralfileExhibitionV4: vaultAddress_ is zero address"
        );
        require(
            costReceiver_ != address(0),
            "FeralfileExhibitionV4: costReceiver_ is zero address"
        );
        require(
            bytes(contractURI_).length > 0,
            "FeralfileExhibitionV4: contractURI_ is empty"
        );
        require(
            seriesIds_.length > 0,
            "FeralfileExhibitionV4: seriesIds_ is empty"
        );
        require(
            seriesMaxSupplies_.length > 0,
            "FeralfileExhibitionV4: _seriesMaxSupplies is empty"
        );
        require(
            seriesIds_.length == seriesMaxSupplies_.length,
            "FeralfileExhibitionV4: seriesMaxSupplies_ and seriesIds_ lengths are not the same"
        );

        burnable = burnable_;
        bridgeable = bridgeable_;
        costReceiver = costReceiver_;
        vault = IFeralfileVault(payable(vault_));
        contractURI = contractURI_;

        // initialize max supply map
        for (uint256 i = 0; i < seriesIds_.length; i++) {
            // Check duplicate with others
            for (uint256 j = i + 1; j < seriesIds_.length; j++) {
                if (seriesIds_[i] == seriesIds_[j]) {
                    revert("FeralfileExhibitionV4: duplicate seriesId");
                }
            }
            require(
                seriesMaxSupplies_[i] > 0,
                "FeralfileExhibitionV4: zero max supply"
            );

            _seriesMaxSupplies[seriesIds_[i]] = seriesMaxSupplies_[i];
        }
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256) {
        require(
            index < ERC721.balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return _ownedTokens[owner][index];
    }

    /// @notice Get token ID from owner
    function tokensOfOwner(
        address owner
    ) external view returns (uint256[] memory) {
        return _ownedTokens[owner];
    }

    /// @notice Get series max supply
    /// @param seriesId a series ID
    /// @return uint256 the max supply
    function seriesMaxSupply(
        uint256 seriesId
    ) external view virtual returns (uint256) {
        return _seriesMaxSupplies[seriesId];
    }

    /// @notice Get series total supply
    /// @param seriesId a series ID
    /// @return uint256 the total supply
    function seriesTotalSupply(
        uint256 seriesId
    ) external view virtual returns (uint256) {
        return _seriesTotalSupplies[seriesId];
    }

    /// @notice Get artwork data
    /// @param tokenId a token ID representing the artwork
    /// @return Artwork the Artwork object
    function getArtwork(
        uint256 tokenId
    ) external view virtual returns (Artwork memory) {
        require(_exists(tokenId), "ERC721: invalid token ID");
        return _allArtworks[tokenId];
    }

    /// @notice Set vault contract
    /// @dev don't allow to set vault as zero address
    function setVault(address vault_) external onlyOwner {
        require(
            vault_ != address(0),
            "FeralfileExhibitionV4: vault_ is zero address"
        );
        vault = IFeralfileVault(payable(vault_));
    }

    /// @notice Return flag _selling;
    function selling() external view returns (bool) {
        return _selling;
    }

    function _checkContractOwnedToken() private view {
        uint256 balance = balanceOf(address(this));
        require(
            balance > 0,
            "FeralfileExhibitionV4: No token owned by the contract"
        );
    }

    /// @notice Start token sale
    function startSale() external onlyOwner {
        mintable = false;
        resumeSale();
    }

    /// @notice Resume token sale
    function resumeSale() public onlyOwner {
        require(
            !mintable,
            "FeralfileExhibitionV4: mintable required to be false"
        );
        require(
            !_selling,
            "FeralfileExhibitionV4: _selling required to be false"
        );
        _checkContractOwnedToken();

        _selling = true;
    }

    /// @notice Pause token sale
    function pauseSale() public onlyOwner {
        require(
            !mintable,
            "FeralfileExhibitionV4: mintable required to be false"
        );
        require(
            _selling,
            "FeralfileExhibitionV4: _selling required to be true"
        );
        _selling = false;
    }

    /// @notice Stop token sale and burn remaining tokens
    function stopSaleAndBurn() external onlyOwner {
        pauseSale();

        // burn remaining tokens
        uint256[] memory tokenIds = _ownedTokens[address(this)];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _burnArtwork(tokenIds[i]);
        }
    }

    /// @notice Stop token selling and transfer remaining tokens back to the underlying addresses
    function stopSaleAndTransfer(
        uint256[] memory seriesIds,
        address[] memory recipientAddresses
    ) external onlyOwner {
        require(
            seriesIds.length > 0 && recipientAddresses.length > 0,
            "FeralfileExhibitionV4: seriesIds or recipientAddresses length is zero"
        );
        require(
            seriesIds.length == recipientAddresses.length,
            "FeralfileExhibitionV4: seriesIds length is different from recipientAddresses"
        );

        pauseSale();

        // transfer tokens back to the addresses
        address from = address(this);
        uint256[] memory tokenIds = _ownedTokens[from];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            Artwork memory artwork = _allArtworks[tokenId];

            for (uint16 j = 0; j < seriesIds.length; j++) {
                if (artwork.seriesId == seriesIds[j]) {
                    address to = recipientAddresses[j];
                    _safeTransfer(from, to, tokenId, "");
                    break;
                }
            }
        }
        require(
            balanceOf(from) == 0,
            "FeralfileExhibitionV4: Token for sale balance has to be zero"
        );
    }

    /// @dev override for OperatorFilterRegistry
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /// @dev override for OperatorFilterRegistry
    function approve(
        address operator,
        uint256 tokenId
    ) public override(ERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /// @dev override for OperatorFilterRegistry
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721) onlyAllowedOperator(from) {
        require(
            to != address(this),
            "FeralfileExhibitionV4: Contract isn't allowed to receive token"
        );
        super.transferFrom(from, to, tokenId);
    }

    /// @dev override for OperatorFilterRegistry
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721) onlyAllowedOperator(from) {
        require(
            to != address(this),
            "FeralfileExhibitionV4: Contract isn't allowed to receive token"
        );
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @dev override for OperatorFilterRegistry
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721) onlyAllowedOperator(from) {
        require(
            to != address(this),
            "FeralfileExhibitionV4: Contract isn't allowed to receive token"
        );
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            bytes(tokenBaseURI).length > 0,
            "ERC721Metadata: _tokenBaseURI is empty"
        );
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return string(abi.encodePacked(tokenBaseURI, "/", tokenId.toString()));
    }

    /// @notice Update the base URI for all tokens
    function setTokenBaseURI(string memory baseURI_) external onlyOwner {
        require(
            bytes(baseURI_).length > 0,
            "ERC721Metadata: baseURI_ is empty"
        );
        tokenBaseURI = baseURI_;
    }

    /// @notice the cost receiver address
    /// @param costReceiver_ - the address of cost receiver
    function setCostReceiver(address costReceiver_) external onlyOwner {
        require(
            costReceiver_ != address(0),
            "FeralfileExhibitionV4: costReceiver_ is zero address"
        );
        costReceiver = costReceiver_;
    }

    /// @notice pay to get artworks to a destination address. The pricing, costs and other details is included in the saleData
    /// @param r_ - part of signature for validating parameters integrity
    /// @param s_ - part of signature for validating parameters integrity
    /// @param v_ - part of signature for validating parameters integrity
    /// @param saleData_ - the sale data
    function buyArtworks(
        bytes32 r_,
        bytes32 s_,
        uint8 v_,
        SaleData calldata saleData_
    ) external payable {
        require(_selling, "FeralfileExhibitionV4: sale is not started");
        _checkContractOwnedToken();
        validateSaleData(saleData_);

        saleData_.payByVaultContract
            ? vault.payForSale(r_, s_, v_, saleData_)
            : require(
                saleData_.price == msg.value,
                "FeralfileExhibitionV4: invalid payment amount"
            );

        bytes32 message = keccak256(
            abi.encode(block.chainid, address(this), saleData_)
        );

        require(
            isValidSignature(message, r_, s_, v_),
            "FeralfileExhibitionV4: invalid signature"
        );

        uint256 itemRevenue;
        if (saleData_.price > saleData_.cost) {
            itemRevenue =
                (saleData_.price - saleData_.cost) /
                saleData_.tokenIds.length;
        }

        uint256 distributedRevenue;
        uint256 platformRevenue;
        for (uint256 i = 0; i < saleData_.tokenIds.length; i++) {
            // send NFT
            _safeTransfer(
                address(this),
                saleData_.destination,
                saleData_.tokenIds[i],
                ""
            );
            if (itemRevenue > 0) {
                // distribute royalty
                for (
                    uint256 j = 0;
                    j < saleData_.revenueShares[i].length;
                    j++
                ) {
                    uint256 rev = (itemRevenue *
                        saleData_.revenueShares[i][j].bps) / 10000;
                    if (
                        saleData_.revenueShares[i][j].recipient == costReceiver
                    ) {
                        platformRevenue += rev;
                        continue;
                    }
                    distributedRevenue += rev;
                    payable(saleData_.revenueShares[i][j].recipient).transfer(
                        rev
                    );
                }
            }

            emit BuyArtwork(saleData_.destination, saleData_.tokenIds[i]);
        }

        require(
            saleData_.price - saleData_.cost >=
                distributedRevenue + platformRevenue,
            "FeralfileExhibitionV4: total bps over 10,000"
        );

        // Transfer cost, platform revenue and remaining funds
        uint256 leftOver = saleData_.price - distributedRevenue;
        if (leftOver > 0) {
            payable(costReceiver).transfer(leftOver);
        }
    }

    /// @notice utility function for checking the series exists
    function _seriesExists(uint256 seriesId) private view returns (bool) {
        return _seriesMaxSupplies[seriesId] > 0;
    }

    /// @dev Modify from ERC721Enumerable
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;
        if (from != address(0) && from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to != address(0) && to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /// @dev Modify from ERC721Enumerable
    function _removeTokenFromOwnerEnumeration(
        address from,
        uint256 tokenId
    ) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).
        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        delete _ownedTokensIndex[tokenId];
        _ownedTokens[from].pop();
    }

    /// @dev Modify from ERC721Enumerable
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256[] storage tokens = _ownedTokens[to];
        uint256 length = tokens.length;
        tokens.push(tokenId);
        _ownedTokensIndex[tokenId] = length;
    }

    /// @notice Mint new collection of Artwork
    /// @dev the function iterates over the array of MintData to call the internal function _mintArtwork
    /// @param data an array of MintData
    function mintArtworks(
        MintData[] calldata data
    ) external virtual onlyAuthorized {
        require(
            mintable,
            "FeralfileExhibitionV4: contract doesn't allow to mint"
        );
        for (uint256 i = 0; i < data.length; i++) {
            _mintArtwork(data[i].seriesId, data[i].tokenId, data[i].owner);
        }
    }

    function _mintArtwork(
        uint256 seriesId,
        uint256 tokenId,
        address owner
    ) internal {
        // pre-condition checks
        require(
            _seriesExists(seriesId),
            string(
                abi.encodePacked(
                    "FeralfileExhibitionV4: seriesId doesn't exist: ",
                    Strings.toString(seriesId)
                )
            )
        );
        require(
            _seriesTotalSupplies[seriesId] < _seriesMaxSupplies[seriesId],
            "FeralfileExhibitionV4: no slots available"
        );

        // mint
        totalSupply += 1;
        _seriesTotalSupplies[seriesId] += 1;
        _allArtworks[tokenId] = Artwork(seriesId, tokenId);
        _mint(owner, tokenId);

        // emit event
        emit NewArtwork(owner, seriesId, tokenId);
    }

    /// @notice Burn a collection of artworks
    /// @dev the function iterates over the array of token ID to call the internal function _burnArtwork
    /// @param tokenIds an array of token ID
    function burnArtworks(uint256[] memory tokenIds) external {
        require(burnable, "FeralfileExhibitionV4: token is not burnable");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                _isApprovedOrOwner(_msgSender(), tokenIds[i]),
                "ERC721: caller is not token owner or approved"
            );
            _burnArtwork(tokenIds[i]);
        }
    }

    function _burnArtwork(uint256 tokenId) internal {
        require(_exists(tokenId), "ERC721: invalid token ID");

        // burn artwork
        Artwork memory artwork = _allArtworks[tokenId];
        _seriesTotalSupplies[artwork.seriesId] -= 1;
        totalSupply -= 1;
        delete _allArtworks[tokenId];
        _burn(tokenId);

        // emit event
        emit BurnArtwork(tokenId);
    }

    /// @notice able to receive fund from vault contract
    receive() external payable {
        require(
            msg.sender == address(vault),
            "FeralfileExhibitionV4: only accept fund from vault contract."
        );
    }

    /// @notice Event emitted when new Artwork has been minted
    event NewArtwork(
        address indexed owner,
        uint256 indexed seriesId,
        uint256 indexed tokenId
    );

    /// @notice Event emitted when Artwork has been burned
    event BurnArtwork(uint256 indexed tokenId);

    /// @notice Event emitted when Artwork has been sold
    event BuyArtwork(address indexed buyer, uint256 indexed tokenId);
}