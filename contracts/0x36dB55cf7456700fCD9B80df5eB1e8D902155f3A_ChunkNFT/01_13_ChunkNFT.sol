// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "hardhat/console.sol";

/**
 * @title ChunkNFT contract
 */
contract ChunkNFT is ERC721, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    struct GlobalState {
        uint16 totalMinted;
        uint16 mintSupplyCount;
        uint16 startIndex;
        uint16 currentIndex;
        uint16 maxMintPerAddressPreSale;
        uint16 maxMintPerAddressPublicSale;
        uint16 ownerMintReserveCount;
        uint16 ownerMintCount;
        bool isMintEnabled;
        bool isAllowListSaleEnded;
    }
    GlobalState public globalState;
    /**
    @dev price per mint
    */
    uint256 public constant PRICE_PER_TOKEN = 0.03 ether;
    /**
    @dev Admin signature. 
    */
    address public adminSigner;
    /**
    @dev commit-reveal hash. 
    */
    bytes32 immutable commit;
    /**
     * @dev Provenance hash.
     * @notice It proves that the assets that exist on-chain are the same ones that were initially generated.
     */
    bytes32 immutable provenance;

    /**
    @dev IPFS URI
    */
    string public ipfsGateway = "https://ipfs.io/ipfs/";
    /**
    @dev IPFS final metadata content id
    */
    string public metadataIpfsCid = "";
    /**
    @dev IPFS final metadata lock
     */
    bool public metadataIpfsCidLocked;
    /**
    @dev IPFS placeholder content id. 
    */
    string public placeholderCid = "";

    /**
    @dev Map containing IPFS hashes for each token ID.
    @notice Stores updated IPFS hashes when the token owner updates the metadata. 
    */
    mapping(uint256 => string) public tokenIdMetadataIpfsHashes;

    /**
    @dev Mints per address
    @notice Custom map to prevent addresses being emptied to overcome the max mint per address limit.
    */
    mapping(address => uint16) private addressMintCount;

    modifier mintingAllowed(uint16 _numberOfTokens) {
        require(
            globalState.isMintEnabled && globalState.startIndex > 0,
            "Minting unavailable"
        );
        require(
            globalState.totalMinted + _numberOfTokens <
                globalState.mintSupplyCount + 1,
            "Over total supply"
        );
        _;
    }

    modifier callerIsUser() {
        require(!_isContract(_msgSender()), "The caller is another contract");
        _;
    }

    /*************
     * ChunkNFT  *
     *************/

    /**
    @dev ChunkNFT constructor
    @param _placeholderCid: Placeholder IPFS cid
    @param _mintSupplyCount: Total supply
    @param _ownerMintReserveCount: Team supply
    @param _maxMintPerAddressPublicSale: Max mint per address for public sale
    @param _maxMintPerAddressPreSale: Max mints per address for pre sale
    @param _adminSigner: Admin signature
    @param _commit: Commit hash 
    @param _provenanceHash: Provenance hash
     */
    constructor(
        string memory _placeholderCid,
        uint16 _mintSupplyCount,
        uint16 _ownerMintReserveCount,
        uint16 _maxMintPerAddressPublicSale,
        uint16 _maxMintPerAddressPreSale,
        address _adminSigner,
        bytes32 _commit,
        bytes32 _provenanceHash
    ) ERC721("ChunkPassport", "CHUNKPASSPORT") {
        GlobalState memory gs = globalState;
        placeholderCid = _placeholderCid;
        gs.mintSupplyCount = _mintSupplyCount;
        gs.ownerMintReserveCount = _ownerMintReserveCount;
        gs.maxMintPerAddressPublicSale = _maxMintPerAddressPublicSale;
        gs.maxMintPerAddressPreSale = _maxMintPerAddressPreSale;
        adminSigner = _adminSigner;
        commit = _commit;
        provenance = _provenanceHash;
        globalState = gs;
    }

    /*************
     * Mint      *
     *************/

    /**
    @dev Mint token
    @param _numberOfTokens Amount of tokens to mint within the batch
    @param _signature Signature needed to mint during presale
    */
    function mint(uint16 _numberOfTokens, bytes calldata _signature)
        external
        payable
        callerIsUser
        mintingAllowed(_numberOfTokens)
    {
        GlobalState memory gs = globalState;
        mintPreCheck(gs, _numberOfTokens, _signature);
        completeMint(gs, _numberOfTokens);
    }

    function mintPreCheck(
        GlobalState memory gs,
        uint16 _numberOfTokens,
        bytes calldata _signature
    ) private view {
        require(
            msg.value == PRICE_PER_TOKEN * _numberOfTokens,
            "Invalid value sent"
        );
        if (!gs.isAllowListSaleEnded) {
            bytes32 digest = keccak256(abi.encodePacked(_msgSender()));
            require(
                matchSigner(digest, _signature),
                "Account not allowlisted during allowlist sale"
            );
        }
        uint256 maxMintPerAddress = (
            gs.isAllowListSaleEnded
                ? gs.maxMintPerAddressPublicSale
                : gs.maxMintPerAddressPreSale
        );
        require(
            addressMintCount[_msgSender()] + _numberOfTokens <
                maxMintPerAddress + 1,
            "You cannot mint more"
        );
    }

    function completeMint(GlobalState memory gs, uint16 _numberOfTokens)
        private
    {
        uint16 startIndex = gs.totalMinted + gs.startIndex;
        uint16 mintSupplyCount = gs.mintSupplyCount;
        uint16 currentIndex;
        addressMintCount[_msgSender()] += _numberOfTokens;
        gs.totalMinted += _numberOfTokens;
        for (uint16 i = 0; i < _numberOfTokens; i++) {
            currentIndex = uint16(((startIndex + i - 1) % mintSupplyCount) + 1);
            _mint(_msgSender(), currentIndex);
        }
        gs.currentIndex = currentIndex;
        globalState = gs;
    }

    function teamMint(uint16 _numberOfTokens)
        external
        onlyOwner
        mintingAllowed(_numberOfTokens)
    {
        GlobalState memory gs = globalState;
        require(
            gs.ownerMintCount + _numberOfTokens < gs.ownerMintReserveCount + 1,
            "Owner mint limit reached"
        );
        gs.ownerMintCount += _numberOfTokens;
        completeMint(gs, _numberOfTokens);
    }

    /*************
     * Metadata  *
     *************/

    /**
    @dev Update metadadta IPFS hash
    @notice Only the token owner can update the metadata.
    @notice It requires the admin signature.
    @notice No other metadata besides the image can be updated.
    */
    function updateMetadataIpfsHash(
        uint256 _tokenId,
        string calldata _newMetadataIpfsHash,
        bytes calldata signature
    ) external {
        require(
            _msgSender() == ownerOf(_tokenId),
            "You are not the owner of this token"
        );
        require(isRevealed(), "Not yet revealed");
        require(
            keccak256(abi.encodePacked(tokenIdMetadataIpfsHashes[_tokenId])) !=
                keccak256(abi.encodePacked(_newMetadataIpfsHash)),
            "This IPFS hash has already been assigned"
        );

        // Check if valid signature
        bytes32 digest = keccak256(
            abi.encodePacked(_msgSender(), _newMetadataIpfsHash, _tokenId)
        );
        require(matchSigner(digest, signature), "Invalid signature");

        tokenIdMetadataIpfsHashes[_tokenId] = _newMetadataIpfsHash;
    }

    /**
    @dev Set metadata IPFS cid
    */
    function setMetadataIpfsCid(string calldata _metadataIpfsCid)
        external
        onlyOwner
    {
        require(!metadataIpfsCidLocked, "Metadata IPFS CID Locked");
        metadataIpfsCid = _metadataIpfsCid;
    }

    function lockMetadataIpfsCid() external onlyOwner {
        metadataIpfsCidLocked = true;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "This token does not exist");
        if (!isRevealed()) {
            return string(abi.encodePacked(ipfsGateway, placeholderCid));
        }
        return
            bytes(tokenIdMetadataIpfsHashes[_tokenId]).length == 0
                ? string(
                    abi.encodePacked(
                        ipfsGateway,
                        metadataIpfsCid,
                        "/",
                        _tokenId.toString()
                    )
                ) // genesis tokenUri
                : string(
                    abi.encodePacked(
                        ipfsGateway,
                        tokenIdMetadataIpfsHashes[_tokenId]
                    )
                ); // tokenUri with updated image
    }

    function isRevealed() internal view returns (bool) {
        return (bytes(metadataIpfsCid).length != 0);
    }

    function matchSigner(bytes32 _hash, bytes memory _signature)
        internal
        view
        returns (bool)
    {
        address signer = _hash.toEthSignedMessageHash().recover(_signature);
        require(signer != address(0), "ECDSA: invalid signature"); // Added check for zero address
        return signer == adminSigner;
    }

    /**
    @dev Set IPFS Uri
    @notice For emergency purpose
    */
    function setDefaultIpfs(string calldata ipfsGateway_) external onlyOwner {
        ipfsGateway = ipfsGateway_;
    }

    /*************
     * Withdraw  *
     *************/

    /**
    @dev Withdraw funds
    */
    function withdraw() external onlyOwner {
        (bool sent, ) = owner().call{value: address(this).balance}("");
        require(sent, "Withdraw failed");
    }

    /*************
     * AllowList *
     *************/

    /**
    @dev Enable/Disable presale
    */
    function setAllowListSale() external onlyOwner {
        globalState.isAllowListSaleEnded = !globalState.isAllowListSaleEnded;
    }

    /**
    @dev Enable/Disable mint sale
    */
    function setMintEnabled() external onlyOwner {
        globalState.isMintEnabled = !globalState.isMintEnabled;
    }

    function setAdminSigner(address _adminSigner) external onlyOwner {
        adminSigner = _adminSigner;
    }

    /**
    @dev Max mints per address on presale
    */
    function setMaxMintPerAddressPreSale(uint16 _maxMintPerAddressPreSale)
        external
        onlyOwner
    {
        require(
            globalState.maxMintPerAddressPublicSale > _maxMintPerAddressPreSale,
            "Public sale max mint must be greater"
        );

        globalState.maxMintPerAddressPreSale = _maxMintPerAddressPreSale;
    }

    /**
    @dev Max mints per address on public sale
    */
    function setMaxMintPerAddressPublicSale(uint16 _maxMintPerAddressPublicSale)
        external
        onlyOwner
    {
        require(
            _maxMintPerAddressPublicSale > globalState.maxMintPerAddressPreSale,
            "Public sale max mint must be greater"
        );

        globalState.maxMintPerAddressPublicSale = _maxMintPerAddressPublicSale;
    }

    /***************
     * Start Index *
     ***************/

    function revealStartIndex(bytes calldata _reveal) external onlyOwner {
        require(
            keccak256(abi.encodePacked(_reveal)) == commit,
            "Invalid reveal"
        );

        uint16 _startIndex = uint16(
            uint256(
                keccak256(
                    abi.encodePacked(blockhash(block.number - 1), _reveal)
                )
            )
        ) % globalState.mintSupplyCount;

        if (_startIndex == 0) {
            _startIndex++;
        }

        //console.log("Start index %s", _startIndex);

        globalState.startIndex = _startIndex;
    }

    /***************
     * Supply      *
     ***************/

    /**
    @dev Get total supply
    */
    function totalSupply() external view returns (uint256) {
        return globalState.totalMinted;
    }

    function _isContract(address addr_) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr_)
        }
        return size > 0;
    }
}