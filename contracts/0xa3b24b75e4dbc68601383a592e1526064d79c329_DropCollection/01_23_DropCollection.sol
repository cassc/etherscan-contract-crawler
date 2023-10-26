// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../interfaces/IOperatorRegistry.sol";
import "../BaseCollection.sol";

contract DropCollection is
    BaseCollection,
    ERC721AUpgradeable,
    ERC721AQueryableUpgradeable
{
    using SafeMathUpgradeable for uint256;

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

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier onlyMintable(uint64 quantity) {
        require(quantity > 0, "Quantity is 0");
        require(
            _maxAmount > 0 ? totalSupply().add(quantity) <= _maxAmount : true,
            "Exceeded max supply"
        );
        require(quantity <= _maxPerMint, "Exceeded max per mint");
        _;
    }

    function initialize(
        address owner_,
        string memory name_,
        string memory symbol_,
        address treasury_,
        address royalty_,
        uint96 royaltyFee_
    ) public initializerERC721A initializer {
        __ERC721A_init(name_, symbol_);
        __ERC721AQueryable_init();
        __BaseCollection_init(owner_, treasury_, royalty_, royaltyFee_);
    }

    function mint(uint64 quantity) external payable onlyMintable(quantity) {
        require(!_presaleActive, "Presale active");
        require(_saleActive, "Sale not active");
        require(
            _getAux(_msgSender()) + quantity <= _maxPerWallet,
            "Exceeded max per wallet"
        );

        _purchaseMint(quantity, _msgSender());
    }

    function mintTo(address recipient, uint64 quantity)
        external
        payable
        onlyMintable(quantity)
    {
        require(!_presaleActive, "Presale active");
        require(_saleActive, "Sale not active");
        require(
            _getAux(recipient) + quantity <= _maxPerWallet,
            "Exceeded max per wallet"
        );

        _purchaseMint(quantity, recipient);
    }

    function presaleMint(
        uint64 quantity,
        uint256 allowed,
        bytes32[] calldata proof
    ) external payable onlyMintable(quantity) {
        uint256 mintQuantity = _getAux(_msgSender()) + quantity;
        require(_presaleActive, "Presale not active");
        require(_merkleRoot != "", "Presale not set");
        require(mintQuantity <= _maxPerWallet, "Exceeded max per wallet");
        require(mintQuantity <= allowed, "Exceeded max per wallet");
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

    function presaleMintTo(
        address recipient,
        uint64 quantity,
        uint256 allowed,
        bytes32[] calldata proof
    ) external payable onlyMintable(quantity) {
        uint256 mintQuantity = _getAux(recipient) + quantity;
        require(_presaleActive, "Presale not active");
        require(_merkleRoot != "", "Presale not set");
        require(mintQuantity <= _maxPerWallet, "Exceeded max per wallet");
        require(mintQuantity <= allowed, "Exceeded max per wallet");
        require(
            MerkleProofUpgradeable.verify(
                proof,
                _merkleRoot,
                keccak256(abi.encodePacked(recipient, allowed))
            ),
            "Presale invalid"
        );

        _purchaseMint(quantity, recipient);
    }

    function batchAirdrop(
        uint64[] calldata quantities,
        address[] calldata recipients
    ) external onlyRolesOrOwner(MANAGER_ROLE) {
        uint256 length = recipients.length;
        require(quantities.length == length, "Invalid Arguments");

        for (uint256 i = 0; i < length; ) {
            _safeMint(recipients[i], quantities[i]);
            unchecked {
                i++;
            }
        }
    }

    function setMerkleRoot(bytes32 newRoot)
        external
        onlyRolesOrOwner(MANAGER_ROLE)
    {
        _merkleRoot = newRoot;
    }

    function startSale(
        uint256 newMaxAmount,
        uint256 newMaxPerMint,
        uint256 newMaxPerWallet,
        uint256 newPrice,
        bool presale
    ) external onlyRolesOrOwner(MANAGER_ROLE) {
        _saleActive = true;
        _presaleActive = presale;

        _maxAmount = newMaxAmount;
        _maxPerMint = newMaxPerMint;
        _maxPerWallet = newMaxPerWallet;
        _price = newPrice;
    }

    function stopSale() external onlyRolesOrOwner(MANAGER_ROLE) {
        _saleActive = false;
        _presaleActive = false;
    }

    function setBaseURI(string memory newBaseURI)
        external
        onlyRolesOrOwner(MANAGER_ROLE)
    {
        _tokenBaseURI = newBaseURI;
    }

    function burn(uint256 tokenId) external onlyRoles(BURNER_ROLE) {
        require(AddressUpgradeable.isContract(_msgSender()), "Not Allowed");
        _burn(tokenId);
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
        require(_price.mul(quantity) <= msg.value, "Value incorrect");

        unchecked {
            _totalRevenue = _totalRevenue.add(msg.value);
        }

        _setAux(to, _getAux(to) + quantity);
        _niftyKit.addFees(msg.value);
        _mint(to, quantity);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (bool isOperator)
    {
        if (_operatorRegistry != address(0)) {
            bytes32 identifier = IOperatorRegistry(_operatorRegistry)
                .getIdentifier(operator);

            if (_allowedOperators[identifier]) return true;
            if (_blockedOperators[identifier]) return false;
        }

        return ERC721AUpgradeable.isApprovedForAll(owner, operator);
    }

    function approve(address to, uint256 tokenId)
        public
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        preventBlockedOperator(to)
    {
        ERC721AUpgradeable.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        preventBlockedOperator(operator)
    {
        ERC721AUpgradeable.setApprovalForAll(operator, approved);
    }

    // The following functions are overrides required by Solidity.
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable, BaseCollection)
        returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            BaseCollection.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }
}