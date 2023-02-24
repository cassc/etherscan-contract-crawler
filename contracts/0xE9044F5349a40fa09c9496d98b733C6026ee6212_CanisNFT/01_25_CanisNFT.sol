// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "./interfaces/ISignatureMintERC721.sol";

/// @title Canis NFT contract
/// @author Think and Dev
contract CanisNFT is ERC721URIStorage, ERC721Enumerable, ERC2981, AccessControlEnumerable {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    /// @dev Max amount of NFTs to be minted
    uint256 public immutable CAP;
    /// @dev ContractUri
    string public contractUri;
    /// @dev Primary Sale Price
    uint256 public primarySalePrice;
    /// @dev Primary Sale Receiver Address
    address payable public primarySaleReceiverAddress;
    /// @dev Address of owner
    address private _owner;
    /// @dev Private counter to make internal security checks
    Counters.Counter private _tokenIdCounter;

    /**
     * @dev Minter rol
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant TYPEHASH = keccak256("MintRequest(address to,string uri,uint256 tokenId)");

    mapping(uint256 => bool) private availableToMint;

    event Initialized(
        address owner,
        address minter,
        uint256 cap,
        string name,
        string symbol,
        address defaultRoyaltyReceiver,
        uint96 defaultFeeNumerator,
        string contractUri,
        uint256 primarySalePrice,
        address primarySaleReceiverAddress
    );
    event DefaultRoyaltyUpdated(address indexed royaltyReceiver, uint96 feeNumerator);
    event Claimed(address indexed to, uint256 tokenId);
    event ContractURIUpdated(string indexed contractUri);
    event PrimarySaleUpdated(address receiver, uint256 price);

    /// @notice Init contract
    /// @param cap_ Max amount of NFTs to be minted. Cannot change
    /// @param name NFT name
    /// @param symbol NFT symbol
    /// @param defaultRoyaltyReceiver NFT Royalties receiver for all the collection
    /// @param defaultFeeNumerator Fees to be charged for royalties
    /// @param _contractUri Contract Uri
    /// @param _primarySalePrice Primary Sale Price
    /// @param _primarySaleReceiverAddress Primary Sale Receiver Address
    constructor(
        address owner,
        address minter,
        uint256 cap_,
        string memory name,
        string memory symbol,
        address defaultRoyaltyReceiver,
        uint96 defaultFeeNumerator,
        string memory _contractUri,
        uint256 _primarySalePrice,
        address _primarySaleReceiverAddress
    ) ERC721(name, symbol) {
        require(owner != address(0), "NFTCapped: owner is 0");
        require(minter != address(0), "NFTCapped: minter is 0");
        require(cap_ > 0, "NFTCapped: cap is 0");
        require(_primarySalePrice > 0, "NFTCapped: primarySalePrice is 0");
        require(_primarySaleReceiverAddress != address(0), "NFTCapped: primarySaleReceiverAddress is 0");
        _owner = owner;
        CAP = cap_;
        contractUri = _contractUri;
        primarySalePrice = _primarySalePrice;
        primarySaleReceiverAddress = payable(_primarySaleReceiverAddress);
        super._setDefaultRoyalty(defaultRoyaltyReceiver, defaultFeeNumerator);
        super._setupRole(DEFAULT_ADMIN_ROLE, _owner);
        super._setupRole(MINTER_ROLE, _owner);
        super._setupRole(MINTER_ROLE, minter);
        emit Initialized(_owner, minter, CAP, name, symbol, defaultRoyaltyReceiver, defaultFeeNumerator, contractUri, _primarySalePrice, _primarySaleReceiverAddress);
    }

    /********** GETTERS ***********/

    /// @inheritdoc	IERC2981
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) public view override returns (address receiver, uint256 royaltyAmount) {
        require(tokenId <= CAP, "CANISNFT: TOKEN ID DOES NOT EXIST");
        return super.royaltyInfo(tokenId, salePrice);
    }

    /********** SETTERS ***********/

    /// @notice Royalties config
    /// @dev Set royalty receiver and feenumerator to be charged
    /// @param receiver Royalty beneficiary
    /// @param feeNumerator fees to be charged to users on sales
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        super._setDefaultRoyalty(receiver, feeNumerator);
        emit DefaultRoyaltyUpdated(receiver, feeNumerator);
    }

    /// @notice Primary sale config
    /// @dev Set receiver and price to be charged
    /// @param receiver Primary sale beneficiary
    /// @param price Primary sale price
    function setPrimarySaleReceiverAddress(address receiver, uint256 price) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(receiver != address(0), "NFTCapped: primarySaleReceiverAddress is 0");
        require(price > 0, "NFTCapped: primarySalePrice is 0");
        primarySaleReceiverAddress = payable(receiver);
        primarySalePrice = price;
        emit PrimarySaleUpdated(receiver, price);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }


    /********** INTERFACE ***********/

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable, ERC2981, AccessControlEnumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Mint NFT initialized in lazyMint
    /// @return id of the new minted NFT
    function safeMint(
        address to,
        uint256 tokenID,
        string calldata uri
    ) public onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
        require(tokenID <= CAP, "NFTCAPPED: cap exceeded");
        require(availableToMint[tokenID] == true, "NFTCAPPED: tokenId not available to minted");
        require(bytes(uri).length > 0, "CANISNFT: Empty URI");
        //mint nft
        availableToMint[tokenID] = false;
        _safeMint(to, tokenID);
        // set token uri
        super._setTokenURI(tokenID, uri);
        return tokenID;
    }

    /// @custom:notice The following function is override required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    /// @custom:notice The following function is override required by Solidity.
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /// @notice openSea integration royalty. See https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    /// @notice Lazy Mint NFTs
    /// @return id of the next NFT to be minted
    function safeLazyMint() external onlyRole(MINTER_ROLE) returns (uint256) {
        _tokenIdCounter.increment();
        uint256 currentTokenId = _tokenIdCounter.current();
        require(currentTokenId <= CAP, "NFTCAPPED: cap exceeded");
        availableToMint[currentTokenId] = true;
        return currentTokenId;
    }

    /// @notice Laxy Batch Mint NFTs
    /// @param quantity amount of NFTs to be minted
    /// @return id of the next NFT to be minted
    function safeLazyMintBatch(uint256 quantity) external onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 currentTokenId = _tokenIdCounter.current();
        require(currentTokenId + quantity <= CAP, "NFTCAPPED: cap exceeded");
        for (uint256 i = 0; i < quantity; i++) {
            _tokenIdCounter.increment();
            currentTokenId = _tokenIdCounter.current();
            availableToMint[currentTokenId] = true;
        }
        return currentTokenId;
    }

    /// @notice Modify contractUri for NFT collection
    /// @param _contractUri contractUri
    function setContractURI(string memory _contractUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractUri = _contractUri;
        emit ContractURIUpdated(contractUri);
    }

    /// @notice Claim an nft by signature
    /// @dev  Function that users has to call to get an NFT by signature
    /// @param request request data signed to claim a nft
    /// @param signature signature necesary for claim
    function claim(
        ISignatureMintERC721.MintRequest calldata request,
        bytes calldata signature
    ) public payable returns (uint256) {
        require(msg.value >= primarySalePrice, "CANISNFT: Payment is less than primarySalePrice");
        (bool sent, ) = primarySaleReceiverAddress.call{value: msg.value}("");
        require(sent, "CANISNFT: Failed to send payment");
        //validate request
        _processRequest(request, signature);
        //mint nft
        availableToMint[request.tokenId] = false;
        _safeMint(_msgSender(), request.tokenId);
        // set token uri
        super._setTokenURI(request.tokenId, request.uri);

        emit Claimed(_msgSender(), request.tokenId);
        return request.tokenId;
    }

    /// @dev Verifies that a mint request is signed by an authorized account.
    function verify(
        ISignatureMintERC721.MintRequest calldata _req,
        bytes calldata _signature
    ) public view returns (address signer) {
        return _verify(_req, _signature);
    }

    /// @dev Verifies that a mint request is signed by an authorized account.
    function _verify(
        ISignatureMintERC721.MintRequest calldata _req,
        bytes calldata _signature
    ) internal view returns (address signer) {
        signer = _recoverAddress(_req, _signature);
        require(availableToMint[_req.tokenId], "CANISNFT: tokenId not available");
        require(hasRole(MINTER_ROLE, signer), "CANISNFT: must have minter role to mint");
    }

    /// @dev Verifies a mint request and marks the request as minted.
    function _processRequest(
        ISignatureMintERC721.MintRequest calldata _req,
        bytes calldata _signature
    ) internal view returns (address signer) {
        //validate signer
        signer = _verify(_req, _signature);

        require(_req.to != address(0), "CANISNFT: recipient undefined");
        require(_req.tokenId <= CAP, "CANISNFT: cap exceeded");
        require(_req.tokenId <= _tokenIdCounter.current(), "CANISNFT: request token id cannot be greater than minted");
        require(_req.chainId == block.chainid, "CANISNFT: the chain id must be the same as the network");
        require(bytes(_req.uri).length > 0, "CANISNFT: Empty URI");
    }

    /// @dev Returns the address of the signer of the mint request.
    function _recoverAddress(
        ISignatureMintERC721.MintRequest calldata _req,
        bytes calldata _signature
    ) internal pure returns (address) {
        return keccak256(_encodeRequest(_req)).toEthSignedMessageHash().recover(_signature);
    }

    /// @dev Resolves 'stack too deep' error in `recoverAddress`.
    function _encodeRequest(ISignatureMintERC721.MintRequest calldata _req) internal pure returns (bytes memory) {
        return abi.encodePacked(_req.to, keccak256(bytes(_req.uri)), _req.tokenId, _req.chainId);
    }
}