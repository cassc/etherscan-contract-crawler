// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract FanzJohnMotson is Ownable, ERC721A, ReentrancyGuard, Pausable {
    using ECDSA for bytes32;

    event UpdatePublicSaleActive(bool publicSaleActive);
    event UpdatePrivateSaleActive(bool privateSaleActive);
    event UpdateMaxPerTx(uint256 maxPerTx);
    event UpdateReserveTeamTokens(uint256 reserveTeamTokens);
    event UpdateTreasury(address treasury);
    event UpdateWhitelistSigner(address whitelistSigner);
    event UpdateBaseURI(string baseURI);
    event UpdatePlaceholderURI(string placeholderURI);
    event UpdatePublicSalePrice(uint256 publicSalePrice);
    event UpdatePrivateSalePrice(uint256 privateSalePrice);
    event UpdateStartingIndex(uint256 startingIndex);
    event UpdatePrivateSaleMaxMint(uint256 privateSaleMaxMint);
    event UpdateMaxMintTotalPerAddress(uint256 maxMintTotalPerAddress);
    event UpdateStartingIndexBlock(uint256 startingIndex);

    bool public publicSaleActive;
    bool public privateSaleActive = true;

    uint256 public maxPerTx = 5;
    uint256 public collectionSupply = 5000;
    uint256 public reserveTeamTokens = 600;
    uint256 public publicSalePrice = .1 ether;
    uint256 public privateSalePrice = .07 ether;
    uint256 public maxMintTotalPerAddress = 50;
    uint256 public privateSaleMaxMint = 2;
    uint256 private startingIndex;
    uint256 private startingIndexBlock;

    address public treasury;
    address public whitelistSigner;

    string public baseURI;
    string public placeholderURI;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PRESALE_TYPEHASH =
        keccak256("PrivateSale(address buyer)");

    constructor() ERC721A("FANZJM", "MOTTY") {
        _pause();

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("FANZJM")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );

        whitelistSigner = owner();
    }

    /* ======== MODIFIERS ======== */

    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "The caller is another contract");
        _;
    }

    modifier callerIsTreasury() {
        require(treasury == _msgSender(), "The caller is another address");
        _;
    }

    modifier callerIsTreasuryOrOwner() {
        require(
            treasury == _msgSender() || owner() == _msgSender(),
            "The caller is another address"
        );
        _;
    }

    /* ======== SETTERS ======== */

    function setPaused(bool paused_) external onlyOwner {
        if (paused_) _pause();
        else _unpause();
    }

    function setSales(bool publicSaleActive_, bool privateSaleActive_)
        external
        onlyOwner
    {
        require(
            publicSaleActive_ != privateSaleActive_,
            "FanzJohnMotson: Only 1 sale can be active"
        );
        publicSaleActive = publicSaleActive_;
        privateSaleActive = privateSaleActive_;
        emit UpdatePublicSaleActive(publicSaleActive_);
        emit UpdatePrivateSaleActive(privateSaleActive_);
    }

    function setPrivateSalePrice(uint256 privateSalePrice_) external onlyOwner {
        privateSalePrice = privateSalePrice_;
        emit UpdatePrivateSalePrice(privateSalePrice_);
    }

    function setPublicSalePrice(uint256 publicSalePrice_) external onlyOwner {
        publicSalePrice = publicSalePrice_;
        emit UpdatePublicSalePrice(publicSalePrice_);
    }

    function setMaxPerTx(uint256 maxPerTx_) external onlyOwner {
        maxPerTx = maxPerTx_;
        emit UpdateMaxPerTx(maxPerTx_);
    }

    function setReserveTeamTokens(uint256 reserveTeamTokens_)
        external
        onlyOwner
    {
        reserveTeamTokens = reserveTeamTokens_;
        emit UpdateReserveTeamTokens(reserveTeamTokens_);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
        emit UpdateBaseURI(baseURI_);
    }

    function setPlaceholderURI(string memory placeholderURI_)
        external
        onlyOwner
    {
        placeholderURI = placeholderURI_;
        emit UpdatePlaceholderURI(placeholderURI_);
    }

    function setTreasury(address treasury_) external onlyOwner {
        treasury = treasury_;
        emit UpdateTreasury(treasury_);
    }

    function setPrivateSaleMaxMint(uint256 privateSaleMaxMint_)
        external
        onlyOwner
    {
        privateSaleMaxMint = privateSaleMaxMint_;
        emit UpdatePrivateSaleMaxMint(privateSaleMaxMint_);
    }

    function setMaxMintTotalPerAddress(uint256 maxMintTotalPerAddress_)
        external
        onlyOwner
    {
        maxMintTotalPerAddress = maxMintTotalPerAddress_;
        emit UpdateMaxMintTotalPerAddress(maxMintTotalPerAddress_);
    }

    function setWhitelistSigner(address whitelistSigner_) external onlyOwner {
        whitelistSigner = whitelistSigner_;
        emit UpdateWhitelistSigner(whitelistSigner_);
    }

    function setStartingIndex() external onlyOwner {
        require(
            startingIndex == 0,
            "FanzJohnMotson: Starting index is already set"
        );
        require(
            startingIndexBlock != 0,
            "FanzJohnMotson: Starting index block must be set"
        );
        startingIndex =
            uint256(blockhash(startingIndexBlock)) %
            collectionSupply;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if ((block.number - startingIndexBlock) > 255) {
            startingIndex =
                uint256(blockhash(block.number - 1)) %
                collectionSupply;
        }

        emit UpdateStartingIndex(startingIndex);
    }

    /* ======== INTERNAL ======== */

    function _validateMint(
        bool sale,
        uint256 price_,
        uint256 quantity_
    ) private {
        require(sale, "FanzJohnMotson: Sale has not begun yet");
        require(
            (totalSupply() + quantity_) <= collectionSupply,
            "FanzJohnMotson: Reached max supply"
        );
        require(
            quantity_ > 0 && quantity_ <= maxPerTx,
            "FanzJohnMotson: Reached max mint per tx"
        );
        require(
            (_numberMinted(_msgSender()) + quantity_) <= maxMintTotalPerAddress,
            "FanzJohnMotson: Reached max mint"
        );
        refundIfOver(price_ * quantity_);
    }

    function _startIndex() private {
        if (startingIndexBlock == 0) {
            startingIndexBlock = block.number;
            emit UpdateStartingIndexBlock(block.number);
        }
    }

    function _validatePrivateSaleSignature(bytes memory signature_)
        private
        view
    {
        // Verify EIP-712 signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PRESALE_TYPEHASH, _msgSender()))
            )
        );
        address recoveredAddress = digest.recover(signature_);
        require(
            recoveredAddress != address(0) &&
                recoveredAddress == address(whitelistSigner),
            "FanzJohnMotson: Invalid signature"
        );
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    /* ======== EXTERNAL ======== */

    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function publicSaleMint(uint256 quantity_) external payable whenNotPaused {
        _validateMint(publicSaleActive, publicSalePrice, quantity_);

        _safeMint(_msgSender(), quantity_);
        _startIndex();
    }

    function privateSaleMint(uint256 quantity_, bytes memory signature_)
        external
        payable
        whenNotPaused
    {
        require(
            (_numberMinted(_msgSender()) + quantity_) <= privateSaleMaxMint,
            "FanzJohnMotson: Reached max mint"
        );
        _validateMint(privateSaleActive, privateSalePrice, quantity_);
        _validatePrivateSaleSignature(signature_);

        _safeMint(_msgSender(), quantity_);
        _startIndex();
    }

    function teamTokensMint(address to_, uint256 quantity_)
        external
        callerIsTreasuryOrOwner
    {
        require(
            (totalSupply() + quantity_) <= collectionSupply,
            "FanzJohnMotson: Reached max supply"
        );
        require(
            (reserveTeamTokens - quantity_) >= 0,
            "FanzJohnMotson: Reached team tokens mint"
        );

        reserveTeamTokens = reserveTeamTokens - quantity_;
        emit UpdateReserveTeamTokens(reserveTeamTokens);

        _safeMint(to_, quantity_);
    }

    function withdrawEth() external callerIsTreasury nonReentrant {
        payable(address(treasury)).transfer(address(this).balance);
    }

    function withdrawPortionOfEth(uint256 withdrawAmount_) external callerIsTreasury nonReentrant {
        payable(address(treasury)).transfer(withdrawAmount_);
    }

    function burn(uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        require(
            _msgSender() == owner,
            "FanzJohnMotson: Is not the owner of this token"
        );

        _burn(tokenId);
    }

    /* ======== OVERRIDES ======== */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        if (startingIndex == 0) {
            return placeholderURI;
        }

        uint256 moddedId = (tokenId + startingIndex) % collectionSupply;
        string memory uri = _baseURI();
        return string(abi.encodePacked(uri, Strings.toString(moddedId)));
    }
}