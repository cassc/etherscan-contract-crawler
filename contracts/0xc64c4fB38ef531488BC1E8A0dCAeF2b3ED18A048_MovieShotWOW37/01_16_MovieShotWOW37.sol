// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//   ███    ███  ██████  ██    ██ ██ ███████ ███████ ██   ██  ██████  ████████ ███████   //
//   ████  ████ ██    ██ ██    ██ ██ ██      ██      ██   ██ ██    ██    ██    ██        //
//   ██ ████ ██ ██    ██ ██    ██ ██ █████   ███████ ███████ ██    ██    ██    ███████   //
//   ██  ██  ██ ██    ██  ██  ██  ██ ██           ██ ██   ██ ██    ██    ██         ██   //
//   ██      ██  ██████    ████   ██ ███████ ███████ ██   ██  ██████     ██    ███████   //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////

contract MovieShotWOW37 is
    ERC721AQueryable,
    IERC2981,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    struct BonusMintDetail {
        uint256 quantityFrom;
        uint256 quantityTo;
        uint256 bonusAmount;
    }

    uint256 public immutable maxSupply;
    uint256 public immutable publicSupply;
    bool public isPublicSaleActive = false;
    bool public isPresaleActive = false;
    bool public isBonusMintActive = true;
    bytes32 public whitelistMerkleRoot;
    bytes32 public freemintMerkleRoot;
    address public adminMinter;
    address public beneficiaryAddress;
    address public royaltyAddress;
    uint256 public royaltyShare10000;
    uint256 public publicSalePrice;
    uint256 public publicSaleMaxMintAmount;
    uint256 public presalePrice;
    uint256 public presaleMaxMintAmount;
    mapping(address => uint256) public totalPresaleAddressMint;
    mapping(address => bool) public freeMintClaimed;

    BonusMintDetail[] public bonusMintDetails;
    string private baseUri;
    string private baseExtension;

    constructor(
        uint256 _maxSupply,
        address _adminMinter,
        address _beneficiaryAddress,
        address _owner,
        address _royaltyAddress,
        string memory _baseUri,
        string memory _baseExtension
    ) ERC721A("MovieShots - Way Out West", "MSHOT-WOW37") {
        presalePrice = .0555 ether;
        presaleMaxMintAmount = 50;
        publicSalePrice = .111 ether;
        publicSaleMaxMintAmount = 100;
        baseUri = _baseUri;
        baseExtension = _baseExtension;

        maxSupply = _maxSupply;
        // Final credits are reserved
        publicSupply = _maxSupply - 1;

        transferOwnership(_owner);
        adminMinter = _adminMinter;
        beneficiaryAddress = _beneficiaryAddress;
        royaltyAddress = _royaltyAddress;
        royaltyShare10000 = 420;

        bonusMintDetails.push(
            BonusMintDetail({quantityFrom: 5, quantityTo: 9, bonusAmount: 1})
        );
        bonusMintDetails.push(
            BonusMintDetail({quantityFrom: 10, quantityTo: 19, bonusAmount: 3})
        );
        bonusMintDetails.push(
            BonusMintDetail({quantityFrom: 20, quantityTo: 999, bonusAmount: 8})
        );
    }

    modifier preSaleActive() {
        require(isPresaleActive, "Presale not active");
        _;
    }

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale not active");
        _;
    }

    modifier onlyAdminMinter() {
        require(adminMinter == msg.sender, "Caller is not the admin minter");
        _;
    }

    function mint(uint256 quantity)
        external
        payable
        publicSaleActive
        nonReentrant
    {
        require(
            msg.value == publicSalePrice * quantity,
            "Incorrect eth amount"
        );
        require(
            quantity <= publicSaleMaxMintAmount,
            "Attempting to mint too many tokens"
        );

        uint256 totalMints = getBonusMintsCount(quantity) + quantity;
        require(
            (totalSupply() + totalMints) <= publicSupply,
            "Public supply exceeded"
        );

        _safeMint(msg.sender, totalMints);
    }

    function whitelistMint(uint256 quantity, bytes32[] calldata merkleProof)
        external
        payable
        preSaleActive
        nonReentrant
    {
        require(
            MerkleProof.verify(
                merkleProof,
                whitelistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "You're not whitelisted"
        );
        require(msg.value == presalePrice * quantity, "Incorrect eth amount");
        require(
            totalPresaleAddressMint[msg.sender] + quantity <=
                presaleMaxMintAmount,
            "Attempting to mint too many tokens"
        );

        uint256 totalMints = getBonusMintsCount(quantity) + quantity;
        require(
            (totalSupply() + totalMints) <= publicSupply,
            "Public supply exceeded"
        );

        totalPresaleAddressMint[msg.sender] += totalMints;
        _safeMint(msg.sender, totalMints);
    }

    function freeMint(uint256 quantity, bytes32[] calldata merkleProof)
        external
        preSaleActive
        nonReentrant
    {
        require(
            MerkleProof.verify(
                merkleProof,
                freemintMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, quantity))
            ),
            "You're not whitelisted"
        );
        require(
            (totalSupply() + quantity) <= publicSupply,
            "Public supply exceeded"
        );
        require(!freeMintClaimed[msg.sender], "Free mints already claimed");

        freeMintClaimed[msg.sender] = true;
        _safeMint(msg.sender, quantity);
    }

    function getBonusMintsCount(uint256 quantity)
        internal
        view
        returns (uint256)
    {
        if (!isBonusMintActive) {
            return 0;
        }
        if (
            bonusMintDetails.length > 0 &&
            quantity >= bonusMintDetails[0].quantityFrom
        ) {
            for (uint256 i = 0; i < bonusMintDetails.length; i++) {
                if (
                    quantity >= bonusMintDetails[i].quantityFrom &&
                    quantity <= bonusMintDetails[i].quantityTo
                ) {
                    return bonusMintDetails[i].bonusAmount;
                }
            }
        }
        return 0;
    }

    function adminMint(address recipient, uint256 quantity)
        external
        onlyAdminMinter
    {
        require(totalSupply() + quantity <= maxSupply, "Max supply exceeded");
        _safeMint(recipient, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            bytes(baseUri).length > 0
                ? string(
                    abi.encodePacked(
                        baseUri,
                        Strings.toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }

    function addBonusMintDetail(
        uint256 quantityFrom,
        uint256 quantityTo,
        uint256 bonusMintAmount
    ) external onlyOwner {
        bonusMintDetails.push(
            BonusMintDetail(quantityFrom, quantityTo, bonusMintAmount)
        );
    }

    function updateBonusMintDetail(
        uint256 index,
        uint256 quantityFrom,
        uint256 quantityTo,
        uint256 bonusMintAmount
    ) external onlyOwner {
        require(index < bonusMintDetails.length, "Wrong index");

        bonusMintDetails[index].quantityFrom = quantityFrom;
        bonusMintDetails[index].quantityTo = quantityTo;
        bonusMintDetails[index].bonusAmount = bonusMintAmount;
    }

    function removeLastBonusMintDetail() external onlyOwner {
        bonusMintDetails.pop();
    }

    function getBonusMintDetails()
        public
        view
        returns (BonusMintDetail[] memory)
    {
        return bonusMintDetails;
    }

    function setMaxMintAmounts(uint256 presaleMax, uint256 publicSaleMax)
        external
        onlyOwner
    {
        presaleMaxMintAmount = presaleMax;
        publicSaleMaxMintAmount = publicSaleMax;
    }

    function setPrices(uint256 prePrice, uint256 publicPrice)
        external
        onlyOwner
    {
        presalePrice = prePrice;
        publicSalePrice = publicPrice;
    }

    function setBaseUriExtension(string memory baseUriExtension)
        external
        onlyOwner
    {
        baseExtension = baseUriExtension;
    }

    function setBaseTokenUri(string memory uri) external onlyOwner {
        baseUri = uri;
    }

    function setWhitelistMerkleRoot(bytes32 merkleroot) external onlyOwner {
        whitelistMerkleRoot = merkleroot;
    }

    function setFreeMintMerkleRoot(bytes32 merkleroot) external onlyOwner {
        freemintMerkleRoot = merkleroot;
    }

    function setPresale(bool presaleValue) external onlyOwner {
        isPresaleActive = presaleValue;
    }

    function setPublicSale(bool publicSaleValue) external onlyOwner {
        isPublicSaleActive = publicSaleValue;
    }

    function setBonusMintActive(bool bonusMintActive) external onlyOwner {
        isBonusMintActive = bonusMintActive;
    }

    function setRoyaltyShare(uint256 royaltyShare) external onlyOwner {
        royaltyShare10000 = royaltyShare;
    }

    function setRoyaltyReceiver(address royaltyReceiver) external onlyOwner {
        royaltyAddress = royaltyReceiver;
    }

    function setAdminMinter(address admin) external onlyOwner {
        adminMinter = admin;
    }

    function setBeneficiaryAddress(address beneficiary) external onlyOwner {
        beneficiaryAddress = beneficiary;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Non-existent token");
        return (royaltyAddress, (salePrice * royaltyShare10000) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC721A, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(beneficiaryAddress).call{value: balance}("");
        require(success, "Withdraw failed");
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
}