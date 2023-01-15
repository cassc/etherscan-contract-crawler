// SPDX-License-Identifier: MIT

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////                ___ _  _ ____    ____ _   _ ___  ____ ____    ____ ____ _  _ _ ____                      ////
////                 |  |__| |___    |     \_/  |__] |___ |__/    | __ |___ |\ | | |___                      ////
////                 |  |  | |___    |___   |   |__] |___ |  \    |__] |___ | \| | |___                      ////
////                                                                                                         ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @custom:security-contact [email protected]
contract CyberGenie is ERC721A, Pausable, Ownable {
    struct PartnerConditions {
        uint256 maxMintPerAddress;
        uint256 price;
    }
    // Max allowed minting per address
    uint256 public constant MAX_MINT_PER_ADDRESS = 5;
    // Max token supply
    uint256 public constant MAX_SUPPLY = 5000;
    // Public mint price
    uint256 public mintPrice = 0.07 ether;
    // Whitelist mint price
    uint256 public whitelistMintPrice = 0.05 ether;
    // Validation of metadata order
    string public provenanceHash =
        "4347a3f0a341c2537ba3f1a42440052014f864fb8b06dca9e6ca944d1ac66aba";
    // Keep track of already minted whitelist wallets
    mapping(address => bool) private whitelistClaimed;
    // blacklistd sc partners
    mapping(address => bool) private partnersSCBlacklist;
    // List of partners sc with discounted price i.e nft community partners, a small list
    address[] public partnersSCListKeys;
    mapping(address => uint256) public partnersSCList;
    // List of partners wallets with discounted price and max_per_address i.e collaborator wallets, a small list
    mapping(address => PartnerConditions) public partnersWalletList;

    bytes32 public whitelistMerkleRoot;
    bool public isPublicSaleActive;
    bool public isWhitelistMintEnabled = true;
    string private baseTokenURI =
        "https://cybergenie.mypinata.cloud/ipfs/Qmbt8fZnCdXJaE9bwYpMuu5XV88NKjbHGVo35vUSg7LicM/";

    constructor() ERC721A("The Cyber Genie", "CG") {}

    modifier validateCount(uint256 _count, uint8 _partnershipType) {
        uint256 _maxMintPerAddress;
        if (_partnershipType == 1) {
            _maxMintPerAddress = getMaxMintPerAddress(_msgSender());
        } else {
            _maxMintPerAddress = MAX_MINT_PER_ADDRESS;
        }

        require(
            _count > 0 &&
                _count + _numberMinted(_msgSender()) - _getAux(_msgSender()) <=
                _maxMintPerAddress,
            "CG: Exceeded maxMintPerAddress"
        );
        require(
            totalSupply() + _count <= MAX_SUPPLY,
            "CG: Exceeded max supply"
        );
        _;
    }

    modifier validatePrice(uint256 _count, uint8 _partnershipType) {
        uint256 _price;

        if (_partnershipType == 1) {
            _price = getPartnerWalletMintPrice(_msgSender());
        } else if (_partnershipType == 2) {
            _price = getPartnerSCMintPrice(_msgSender());
        } else {
            _price = (isWhitelistMintEnabled) ? whitelistMintPrice : mintPrice;
        }
        require(msg.value >= _count * _price, "CG: Insufficient funds");
        _;
    }

    modifier validateProvenance() {
        require(
            bytes(provenanceHash).length == 0,
            "CG: Provenance already set!"
        );
        _;
    }

    /**
     * @dev Get the max mint per address some wallet partners might have
     * different max per address constraint i.e collaborators
     */
    function getMaxMintPerAddress(address _claimer)
        public
        view
        returns (uint256)
    {
        uint256 _maxMintPerAddress = MAX_MINT_PER_ADDRESS;

        if (partnersWalletList[_claimer].maxMintPerAddress > 0) {
            _maxMintPerAddress = partnersWalletList[_claimer].maxMintPerAddress;
        }

        return _maxMintPerAddress;
    }

    /**
     * @dev Get the minting price for partner wallet
     *
     */
    function getPartnerWalletMintPrice(address _claimer)
        public
        view
        returns (uint256)
    {
        uint256 _price = (isWhitelistMintEnabled)
            ? whitelistMintPrice
            : mintPrice;
        if (partnersWalletList[_claimer].price > 0) {
            _price = partnersWalletList[_claimer].price;
        }

        return _price;
    }

    /**
     * @dev Get the minting price for partner SC
     *
     */
    function getPartnerSCMintPrice(address _claimer)
        public
        view
        returns (uint256)
    {
        uint256 _price = (isWhitelistMintEnabled)
            ? whitelistMintPrice
            : mintPrice;
        for (uint256 i = 0; i < partnersSCListKeys.length; i++) {
            // check if claimer has tokens with partner sc
            if (
                IERC721A(partnersSCListKeys[i]).balanceOf(_claimer) >= 1 &&
                !partnersSCBlacklist[partnersSCListKeys[i]]
            ) {
                uint256 _tmpPrice;
                _tmpPrice = partnersSCList[partnersSCListKeys[i]];
                if (_tmpPrice < _price) {
                    _price = _tmpPrice;
                }
            }
        }

        return _price;
    }

    /**
     * @dev sets the base uri for {baseURI}
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    /**
     * @dev sets the mint price in wei for {price}
     */
    function setMintPrice(uint256 _newMintPrice) external onlyOwner {
        mintPrice = _newMintPrice;
    }

    /**
     * @dev sets the whitelist mint price in wei for {price}
     */
    function setWhitelistMintPrice(uint256 _newWhitelistMintPrice)
        external
        onlyOwner
    {
        whitelistMintPrice = _newWhitelistMintPrice;
    }

    /**
     * @dev sets the state of public sale for {isPublicSaleActive}
     */
    function setIsPublicSaleActive(bool _isPublicSaleActive)
        external
        onlyOwner
    {
        isPublicSaleActive = _isPublicSaleActive;
    }

    /**
     * @dev sets the state of whitelist public sale for {isWhitelistMintEnabled}
     */
    function setIsWhitelistMintEnabled(bool _newState) external onlyOwner {
        isWhitelistMintEnabled = _newState;
    }

    /**
     * @dev sets the merkle root for {whitelistMerkleRoot}
     */
    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    /**
     * @dev adds a partner to the partner wallet list {partnersWalletList}
     *
     * Requirements:
     *
     * - onlyOwner
     *
     */
    function setPartnersSCList(address _address, uint256 _price)
        external
        onlyOwner
    {
        partnersSCListKeys.push(_address);
        partnersSCList[_address] = _price;
    }

    /**
     * @dev adds a partner to the partner sc blacklist {partnersSCBlacklist}
     *
     * Requirements:
     *
     * - onlyOwner
     *
     */
    function setPartnersSCBlackList(address _address) external onlyOwner {
        partnersSCBlacklist[_address] = true;
    }

    /**
     * @dev adds a partner to the partner wallet list {partnersWalletList}
     *
     * Requirements:
     *
     * - onlyOwner
     *
     */
    function setPartnersWalletList(
        address[] calldata _addrs,
        uint256[] calldata _maxMintPerAddress,
        uint256[] calldata _price
    ) external onlyOwner {
        for (uint256 i = 0; i < _addrs.length; i++) {
            partnersWalletList[_addrs[i]] = PartnerConditions({
                maxMintPerAddress: _maxMintPerAddress[i],
                price: _price[i]
            });
        }
    }

    /**
     * @dev sets the provinance hash for {provenanceHash}
     * only allowed one time, can be used to verify that metadata order was not altered before reveal
     *
     * Requirements:
     *
     * - onlyOwner
     * - validateProvenance
     *
     */
    function setProvenanceHash(string memory _newProvenanceHash)
        external
        onlyOwner
        validateProvenance
    {
        provenanceHash = _newProvenanceHash;
    }

    /**
     * @dev Activate emergency stop mechanism
     *
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev De-activate emergency stop mechanism
     *
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev See {ERC721A-_beforeTokenTransfer}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override whenNotPaused {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {ERC721A-_startTokenId}.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev See {ERC721A-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev See {ERC721A-tokenURI}.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Nonexistent token");

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _toString(_tokenId)))
                : "";
    }

    /**
     * @dev Owner minting
     *
     * Requirements:
     *
     * - onlyOwner
     *
     */
    function airdropOwner(address[] calldata _addrs, uint256[] calldata _counts)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _addrs.length; i++) {
            _mint(_addrs[i], _counts[i]);
            _setAux(_addrs[i], uint64(_getAux(_addrs[i]) + _counts[i]));
        }
    }

    /**
     * @dev Public minting for whitelist
     *
     * Requirements:
     *
     * - validateCount
     * - validatePrice
     * - `isWhitelistMintEnabled` must be true.
     *
     */
    function whitelistMint(
        uint32 _count,
        bytes32[] calldata _merkleProof,
        uint8 partnershipType
    )
        public
        payable
        validateCount(_count, partnershipType)
        validatePrice(_count, partnershipType)
    {
        require(isWhitelistMintEnabled, "CG: Whitelist sale is not active");
        require(
            !whitelistClaimed[_msgSender()],
            "CG: Address already claimed whitelist spot"
        );
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf),
            "CG: Invalid Merkle Proof"
        );

        whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _count);
    }

    /**
     * @dev Public minting during public sale
     *
     * Requirements:
     *
     * - validateCount
     * - validatePrice
     * - `isPublicSaleActive` must be true.
     *
     */
    function mint(uint32 _count, uint8 partnershipType)
        external
        payable
        validateCount(_count, partnershipType)
        validatePrice(_count, partnershipType)
    {
        require(isPublicSaleActive, "CG: Public Sale is not active");
        _mint(_msgSender(), _count);
    }

    /**
     * @dev Withdraw contract balance
     *
     * Requirements:
     *
     * - onlyOwner
     * - `success` must be true.
     *
     */
    function withdraw() external payable onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "CG: Withdraw failed.");
    }
}