//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract TIALSWorldMembershipPass is
    ERC721A,
    ERC2981,
    Ownable,
    ReentrancyGuard
{
    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public constant PUBLIC_SALE_MINT_LIMIT = 10;

    string private _baseTokenUri;
    uint256 public maxSaleSupply = 2222;

    string public previewUri;
    bool public isRevealed = false;

    // Presale
    bool public isPresaleActive = false;
    bytes32 public presaleMerkleRoot;

    // Public sale
    bool public isPublicSaleActive = false;
    bytes32 public publicSaleMerkleRoot;
    uint256 public publicSalePrice = 0.06 ether;

    constructor(string memory _previewUri, uint96 _feeNumerator)
        ERC721A("TIALS.World Membership Pass", "TIALS")
    {
        previewUri = _previewUri;
        _setDefaultRoyalty(_msgSender(), _feeNumerator);
    }

    function publicSaleMint(uint256 quantity, address to)
        external
        payable
        nonReentrant
    {
        require(isPublicSaleActive, "Public sale not active");
        require(
            totalSupply() + quantity <= maxSaleSupply,
            "Max supply reached"
        );
        require(
            _getAux(to) + quantity <= PUBLIC_SALE_MINT_LIMIT,
            "Mint limit reached"
        );
        require(publicSalePrice * quantity == msg.value, "Incorrect payment");

        _safeMint(to, quantity);
        _setAux(to, uint64(_getAux(to) + quantity));
    }

    function publicSaleAllowlistMint(
        bytes32[] calldata merkleProof,
        uint256 quantityAllowed,
        uint256 quantity,
        address to
    ) external payable nonReentrant {
        require(isPublicSaleActive, "Public sale not active");
        require(
            totalSupply() + quantity <= maxSaleSupply,
            "Max supply reached"
        );
        require(
            calculateMintPrice(to, quantity) == msg.value,
            "Incorrect payment"
        );
        require(
            MerkleProof.verify(
                merkleProof,
                publicSaleMerkleRoot,
                keccak256(abi.encodePacked(to, quantityAllowed))
            ),
            "Incorrect merkle proof"
        );
        require(
            _getAux(to) + quantity <= quantityAllowed,
            "Mint limit reached"
        );

        _safeMint(to, quantity);
        _setAux(to, uint64(_getAux(to) + quantity));
    }

    function presaleMint(
        bytes32[] calldata merkleProof,
        uint256 quantityAllowed,
        uint256 quantity,
        address to
    ) external payable nonReentrant {
        require(isPresaleActive, "Presale sale not active");
        require(
            totalSupply() + quantity <= maxSaleSupply,
            "Max supply reached"
        );
        require(
            calculateMintPrice(to, quantity) == msg.value,
            "Incorrect payment"
        );
        require(
            MerkleProof.verify(
                merkleProof,
                presaleMerkleRoot,
                keccak256(abi.encodePacked(to, quantityAllowed))
            ),
            "Incorrect merkle proof"
        );
        require(
            _getAux(to) + quantity <= quantityAllowed,
            "Mint limit reached"
        );

        _safeMint(to, quantity);
        _setAux(to, uint64(_getAux(to) + quantity));
    }

    // Price helpers
    function getPrice(uint256 quantity) public pure returns (uint256 price) {
        if (quantity <= 1) price = 0 ether;
        else if (quantity == 2) price = 0.06 ether;
        else if (quantity == 3) price = 0.10 ether;
        else if (quantity == 4) price = 0.12 ether;
        else price = (quantity - 1) * 0.03 ether;
    }

    function calculateMintPrice(address owner, uint256 quantity)
        public
        view
        returns (uint256 price)
    {
        uint256 amountMinted = _getAux(owner);
        if (amountMinted > 0) price = getPrice(quantity + 1);
        else price = getPrice(quantity);
    }

    function getAmountMinted(address owner) external view returns (uint256) {
        return _getAux(owner);
    }

    // Paper helpers
    function getPublicSaleAllowlistEligibility(
        bytes32[] calldata merkleProof,
        uint256 quantityAllowed,
        uint256 quantity,
        address to
    ) external view returns (string memory) {
        if (!isPublicSaleActive) return "Public sale not active";
        if (totalSupply() + quantity > maxSaleSupply)
            return "Max supply reached";
        if (
            !MerkleProof.verify(
                merkleProof,
                publicSaleMerkleRoot,
                keccak256(abi.encodePacked(to, quantityAllowed))
            )
        ) return "Incorrect merkle proof";
        if (_getAux(to) + quantity > quantityAllowed)
            return "Mint limit reached";
        return "";
    }

    function getPresaleEligibility(
        bytes32[] calldata merkleProof,
        uint256 quantityAllowed,
        uint256 quantity,
        address to
    ) external view returns (string memory) {
        if (!isPresaleActive) return "Presale not active";
        if (totalSupply() + quantity > maxSaleSupply)
            return "Max supply reached";
        if (
            !MerkleProof.verify(
                merkleProof,
                presaleMerkleRoot,
                keccak256(abi.encodePacked(to, quantityAllowed))
            )
        ) return "Incorrect merkle proof";
        if (_getAux(to) + quantity > quantityAllowed)
            return "Mint limit reached";
        return "";
    }

    function getPublicSaleEligibility(uint256 quantity, address to)
        external
        view
        returns (string memory)
    {
        if (!isPublicSaleActive) return "Public sale not active";
        if (totalSupply() + quantity > maxSaleSupply)
            return "Max supply reached";
        if (_getAux(to) + quantity > PUBLIC_SALE_MINT_LIMIT)
            return "Mint limit reached";
        return "";
    }

    // Admin
    function adminMint(uint256 quantity, address to) public onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply reached");
        _safeMint(to, quantity);
    }

    function adminBatchMint(
        uint256[] calldata quantities,
        address[] calldata receivers
    ) external onlyOwner {
        for (uint256 i = 0; i < receivers.length; i++) {
            adminMint(quantities[i], receivers[i]);
        }
    }

    // Sale config
    function setMaxSaleSupply(uint256 supply) external onlyOwner {
        maxSaleSupply = supply > MAX_SUPPLY ? MAX_SUPPLY : supply;
    }

    function setPublicSalePrice(uint256 price) external onlyOwner {
        publicSalePrice = price;
    }

    function setPublicSaleActive(bool isActive) external onlyOwner {
        isPublicSaleActive = isActive;
    }

    function setPresaleActive(bool isActive) external onlyOwner {
        isPresaleActive = isActive;
    }

    function setPresaleMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        presaleMerkleRoot = merkleRoot;
    }

    function setPublicSaleMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        publicSaleMerkleRoot = merkleRoot;
    }

    // Token URI
    function setPreviewUri(string memory uri) external onlyOwner {
        previewUri = uri;
    }

    function setIsRevealed(bool revealed) external onlyOwner {
        isRevealed = revealed;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenUri = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenUri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!isRevealed) return previewUri;
        return super.tokenURI(tokenId);
    }

    // Royalty
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}