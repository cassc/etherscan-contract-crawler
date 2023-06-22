// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../BaseCollection.sol";

contract DropCollection is
    BaseCollection,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using MerkleProofUpgradeable for bytes32[];

    mapping(address => uint256) private _mintCount;
    bytes32 private _merkleRoot;
    string private _tokenBaseURI;

    // Sales Parameters
    uint256 private _maxAmount;
    uint256 private _maxPerMint;
    uint256 private _maxPerWallet;
    uint256 private _price;

    // States
    bool private _presaleActive = false;
    bool private _saleActive = false;

    modifier onlyMintable(uint64 quantity) {
        require(quantity > 0, "Greater than 0");
        require(
            _mintCount[_msgSender()].add(quantity) <= _maxPerWallet,
            "Exceeded max per wallet"
        );
        require(
            _maxAmount > 0 ? totalSupply().add(quantity) <= _maxAmount : true,
            "Exceeded max supply"
        );
        require(quantity <= _maxPerMint, "Exceeded max per mint");
        _;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address treasury_,
        address royalty_,
        uint96 royaltyFee_
    ) public initializer {
        __ERC721_init(name_, symbol_);
        __ERC721Enumerable_init();
        __BaseCollection_init(treasury_, royalty_, royaltyFee_);
    }

    function mint(uint64 quantity) external payable onlyMintable(quantity) {
        require(!_presaleActive, "Presale active");
        require(_saleActive, "Sale not active");

        _purchaseMint(quantity, _msgSender());
    }

    function presaleMint(
        uint64 quantity,
        uint256 allowed,
        bytes32[] calldata proof
    ) external payable onlyMintable(quantity) {
        require(_presaleActive, "Presale not active");
        require(_merkleRoot != "", "Presale not set");
        require(
            _mintCount[_msgSender()].add(quantity) <= allowed,
            "Exceeded max per wallet"
        );
        require(
            MerkleProofUpgradeable.verify(
                proof,
                _merkleRoot,
                keccak256(abi.encodePacked(_msgSender(), allowed))
            ),
            "Presale invalid"
        );

        _purchaseMint(quantity, _msgSender());
    }

    function batchAirdrop(
        uint64[] calldata quantities,
        address[] calldata recipients
    ) external onlyOwner {
        require(quantities.length == recipients.length);

        for (uint64 i = 0; i < recipients.length; i++) {
            _mint(quantities[i], recipients[i]);
        }
    }

    function setMerkleRoot(bytes32 newRoot) external onlyOwner {
        _merkleRoot = newRoot;
    }

    function startSale(
        uint256 newMaxAmount,
        uint256 newMaxPerMint,
        uint256 newMaxPerWallet,
        uint256 newPrice,
        bool presale
    ) external onlyOwner {
        _saleActive = true;
        _presaleActive = presale;

        _maxAmount = newMaxAmount;
        _maxPerMint = newMaxPerMint;
        _maxPerWallet = newMaxPerWallet;
        _price = newPrice;
    }

    function stopSale() external onlyOwner {
        _saleActive = false;
        _presaleActive = false;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _tokenBaseURI = newBaseURI;
    }

    function maxAmount() external view returns (uint256) {
        return _maxAmount;
    }

    function maxPerMint() external view returns (uint256) {
        return _maxPerMint;
    }

    function maxPerWallet() external view returns (uint256) {
        return _maxPerWallet;
    }

    function price() external view returns (uint256) {
        return _price;
    }

    function presaleActive() external view returns (bool) {
        return _presaleActive;
    }

    function saleActive() external view returns (bool) {
        return _saleActive;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    function _purchaseMint(uint64 quantity, address to) internal {
        require(quantity > 0, "Must be greater than 1");
        require(_price.mul(quantity) <= msg.value, "Value incorrect");

        unchecked {
            _totalRevenue = _totalRevenue.add(msg.value);
            _mintCount[to] = _mintCount[to].add(quantity);
        }

        _niftyKit.addFees(msg.value);
        _mint(quantity, to);
    }

    function _mint(uint64 quantity, address to) internal {
        for (uint64 i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply().add(1);
            _safeMint(to, mintIndex);
        }
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, BaseCollection)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}