// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "closedsea/src/OperatorFilterer.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/ITheFutureIsHistory.sol";
import "./interfaces/INiftyKit.sol";
import "./MultiStage.sol";
import "./SignaturePresale.sol";

contract TheFutureIsHistory is
    ITheFutureIsHistory,
    MultiStage,
    SignaturePresale,
    Ownable,
    AccessControl,
    ERC2981,
    ERC721A,
    ERC721AQueryable,
    OperatorFilterer
{
    using Address for address;
    using SafeMath for uint256;
    using MerkleProof for bytes32[];

    bool public operatorFilteringEnabled;

    address private _treasury;
    string private _tokenBaseURI;
    uint256 private _globalMaxAmount;
    INiftyKit private _niftyKit;

    mapping(uint256 => bool) private _saleCreated;

    modifier onlyMintable(uint256 stageId, uint64 quantity) {
        require(_saleActive[stageId], "Sale not active");
        require(quantity != 0, "Quantity is 0");
        require(
            _globalMaxAmount > 0
                ? totalSupply().add(quantity) <= _globalMaxAmount
                : true,
            "Exceeded global max supply"
        );
        require(
            _maxAmount[stageId] != 0
                ? _supply[stageId].add(quantity) <= _maxAmount[stageId]
                : true,
            "Exceeded max supply"
        );
        require(quantity <= _maxPerMint[stageId], "Exceeded max per mint");
        require(
            _mintCount[stageId][_msgSender()].add(quantity) <=
                _maxPerWallet[stageId],
            "Exceeded max per wallet"
        );
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxAmount_,
        address niftyKit_,
        address treasury_,
        address royalty_,
        uint96 royaltyFee_
    ) ERC721A(name_, symbol_) {
        _treasury = treasury_;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setDefaultRoyalty(royalty_, royaltyFee_);
        _niftyKit = INiftyKit(niftyKit_);
        _globalMaxAmount = maxAmount_;
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
    }

    function createSale(
        uint256 stageId,
        uint256 maxAmount,
        uint256 maxPerWallet,
        uint256 maxPerMint,
        uint256 price,
        uint256[] calldata discountQuantities,
        uint256[] calldata discountPrices,
        bool presale,
        bytes32 merkleRoot
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!_saleCreated[stageId], "Sale already exists");
        require(
            discountQuantities.length == discountPrices.length,
            "Invalid Arguments"
        );
        require(
            discountQuantities.length <= maxPerMint,
            "Discount quantities exceed max per mint"
        );

        _createSale(
            stageId,
            maxAmount,
            maxPerWallet,
            maxPerMint,
            price,
            discountQuantities,
            discountPrices,
            presale,
            merkleRoot
        );

        _saleCreated[stageId] = true;

        emit SaleCreated(
            stageId,
            maxAmount,
            maxPerWallet,
            maxPerMint,
            price,
            discountQuantities,
            discountPrices,
            presale,
            merkleRoot
        );
    }

    function startSale(uint256[] calldata stageIds)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 length = stageIds.length;
        for (uint256 i = 0; i < length; ) {
            uint256 stageId = stageIds[i];
            require(_saleCreated[stageId], "Sale does not exist");
            require(!_saleActive[stageId], "Sale already active");
            _startSale(stageId);

            unchecked {
                i++;
            }
        }
    }

    function stopSale(uint256[] calldata stageIds)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 length = stageIds.length;
        for (uint256 i = 0; i < length; ) {
            uint256 stageId = stageIds[i];
            require(_saleActive[stageId], "Sale not active");
            _stopSale(stageId);

            unchecked {
                i++;
            }
        }
    }

    function mint(
        uint256 stageId,
        uint64 quantity,
        address recipient
    ) external payable onlyMintable(stageId, quantity) {
        require(!_presaleActive[stageId], "Presale active");

        _purchaseMint(stageId, recipient, quantity);
    }

    function redeem(
        uint256 stageId,
        uint64 quantity,
        address recipient,
        uint256 expiration,
        bytes32 data,
        bytes calldata signature
    ) external payable onlyMintable(stageId, quantity) {
        require(_presaleActive[stageId], "Presale not active");
        _verifySignature(stageId, expiration, data, signature);

        _purchaseMint(stageId, recipient, quantity);
    }

    function presaleMint(
        uint256 stageId,
        uint64 quantity,
        address recipient,
        uint256 allowed,
        bytes32[] calldata proof
    ) external payable onlyMintable(stageId, quantity) {
        uint256 mintQuantity = _mintCount[stageId][recipient].add(quantity);
        require(_presaleActive[stageId], "Presale not active");
        require(_merkleRoot[stageId] != "", "Presale not set");
        require(mintQuantity <= allowed, "Exceeded max per wallet");
        require(
            MerkleProof.verify(
                proof,
                _merkleRoot[stageId],
                keccak256(abi.encodePacked(recipient, allowed))
            ),
            "Presale invalid"
        );

        _purchaseMint(stageId, recipient, quantity);
    }

    function batchAirdrop(
        uint64[] calldata quantities,
        address[] calldata recipients
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = recipients.length;
        require(quantities.length == length, "Invalid Arguments");

        for (uint256 i = 0; i < length; ) {
            _safeMint(recipients[i], quantities[i]);
            unchecked {
                i++;
            }
        }
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(this).balance != 0, "0 balance");

        INiftyKit niftyKit = _niftyKit;
        uint256 balance = address(this).balance;
        uint256 fees = niftyKit.getFees(address(this));
        niftyKit.addFeesClaimed(fees);
        Address.sendValue(payable(address(niftyKit)), fees);
        Address.sendValue(payable(_treasury), balance.sub(fees));
    }

    function setSigner(address signer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setSigner(signer);
    }

    function setTreasury(address newTreasury)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _treasury = newTreasury;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function setBaseURI(string memory newBaseURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _tokenBaseURI = newBaseURI;
    }

    function setGlobalMaxAmount(uint256 globalMaxAmount_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _globalMaxAmount = globalMaxAmount_;
    }

    function getPrice(uint256 stageId, uint256 quantity)
        external
        view
        returns (uint256)
    {
        if (_discount[stageId][quantity].isValue) {
            return _discount[stageId][quantity].price;
        }

        return _price[stageId].mul(quantity);
    }

    function globalMaxAmount() external view returns (uint256) {
        return _globalMaxAmount;
    }

    function treasury() external view returns (address) {
        return _treasury;
    }

    function isRedeemed(uint256 stageId, bytes32 data)
        public
        view
        returns (bool)
    {
        return _isVerified(stageId, data);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _purchaseMint(
        uint256 stageId,
        address to,
        uint64 quantity
    ) internal {
        PricingEntry memory discount = _discount[stageId][quantity];

        if (discount.isValue) {
            require(discount.price == msg.value, "Discount price mismatch");
        } else {
            require(
                _price[stageId].mul(quantity) <= msg.value,
                "Value incorrect"
            );
        }

        _supply[stageId] = _supply[stageId].add(quantity);
        _mintCount[stageId][to] = _mintCount[stageId][to].add(quantity);
        _niftyKit.addFees(msg.value);
        _mint(to, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC721A, ERC2981, AccessControl)
        returns (bool)
    {
        return
            ERC2981.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId) ||
            ERC721A.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return operatorFilteringEnabled;
    }
}