// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//   ███    ███  ██████  ██    ██ ██ ███████ ███████ ██   ██  ██████  ████████ ███████   //
//   ████  ████ ██    ██ ██    ██ ██ ██      ██      ██   ██ ██    ██    ██    ██        //
//   ██ ████ ██ ██    ██ ██    ██ ██ █████   ███████ ███████ ██    ██    ██    ███████   //
//   ██  ██  ██ ██    ██  ██  ██  ██ ██           ██ ██   ██ ██    ██    ██         ██   //
//   ██      ██  ██████    ████   ██ ███████ ███████ ██   ██  ██████     ██    ███████   //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////

contract MovieShotLR98 is ERC721AQueryable, IERC2981, AccessControl, ReentrancyGuard {
    struct BonusMintDetail {
        uint256 quantityFrom;
        uint256 quantityTo;
        uint256 bonusAmount;
    }

    bytes32 public constant ADMIN_MINTER_ROLE = keccak256("ADMIN_MINTER_ROLE");

    uint256 public immutable maxSupply;
    uint256 public immutable publicSupply;
    bool public isPublicSaleActive = false;
    bool public isPresaleActive = false;
    bytes32 public whitelistMerkleRoot;
    bytes32 public freemintMerkleRoot;
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
    string private baseTokenUri;
    string private baseExtension;

    constructor(
        uint256 maxTokenSupply,
        address adminMinter,
        address beneficiary,
        address defaultAdmin,
        address royaltyReceiver,
        string memory baseUri,
        string memory baseUriExtension
    ) ERC721A("MovieShots - Run Lola Run", "MSHOT-LR98") {
        presalePrice = .042 ether;
        presaleMaxMintAmount = 20;
        publicSalePrice = .069 ether;
        publicSaleMaxMintAmount = 20;
        baseTokenUri = baseUri;
        baseExtension = baseUriExtension;
        _setupRole(ADMIN_MINTER_ROLE, adminMinter);
        _setupRole(DEFAULT_ADMIN_ROLE, defaultAdmin);

        maxSupply = maxTokenSupply;
        // Final credits are reserved
        publicSupply = maxSupply - 1;

        royaltyAddress = royaltyReceiver;
        royaltyShare10000 = 420;
        beneficiaryAddress = beneficiary;

        bonusMintDetails.push(
            BonusMintDetail({quantityFrom: 4, quantityTo: 6, bonusAmount: 1})
        );
        bonusMintDetails.push(
            BonusMintDetail({quantityFrom: 7, quantityTo: 99, bonusAmount: 3})
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

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _;
    }

    modifier onlyAdminMinter() {
        require(hasRole(ADMIN_MINTER_ROLE, msg.sender), "Caller is not an admin minter");
        _;
    }

    function mint(uint256 quantity)
        external
        payable
        publicSaleActive
        nonReentrant
    {
        require(msg.value == publicSalePrice * quantity, "Incorrect eth amount");
        require(
            quantity <= publicSaleMaxMintAmount,
            "Attempting to mint too many tokens"
        );
        require(
            (totalSupply() + quantity) <= publicSupply,
            "Public supply exceeded"
        );

        _safeMint(msg.sender, quantity);
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

    function adminMint(address recipient, uint256 quantity) external onlyAdminMinter {
        require(totalSupply() + quantity <= maxSupply, "Max supply exceeded");
        _safeMint(recipient, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            bytes(baseTokenUri).length > 0
                ? string(
                    abi.encodePacked(
                        baseTokenUri,
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
    ) external onlyAdmin {
        bonusMintDetails.push(
            BonusMintDetail(quantityFrom, quantityTo, bonusMintAmount)
        );
    }

    function updateBonusMintDetail(
        uint256 index,
        uint256 quantityFrom,
        uint256 quantityTo,
        uint256 bonusMintAmount
    ) external onlyAdmin {
        require(index < bonusMintDetails.length, "Wrong index");

        bonusMintDetails[index].quantityFrom = quantityFrom;
        bonusMintDetails[index].quantityTo = quantityTo;
        bonusMintDetails[index].bonusAmount = bonusMintAmount;
    }

    function removeLastBonusMintDetail() external onlyAdmin {
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
        onlyAdmin
    {
        presaleMaxMintAmount = presaleMax;
        publicSaleMaxMintAmount = publicSaleMax;
    }

    function setPrices(uint256 prePrice, uint256 publicPrice)
        external
        onlyAdmin
    {
        presalePrice = prePrice;
        publicSalePrice = publicPrice;
    }

    function setBaseUriExtension(string memory baseUriExtension)
        external
        onlyAdmin
    {
        baseExtension = baseUriExtension;
    }

    function setBaseTokenUri(string memory baseUri) external onlyAdmin {
        baseTokenUri = baseUri;
    }

    function setWhitelistMerkleRoot(bytes32 merkleroot) external onlyAdmin {
        whitelistMerkleRoot = merkleroot;
    }

    function setFreeMintMerkleRoot(bytes32 merkleroot) external onlyAdmin {
        freemintMerkleRoot = merkleroot;
    }

    function setPresale(bool presaleValue) external onlyAdmin {
        isPresaleActive = presaleValue;
    }

    function setPublicSale(bool publicSaleValue) external onlyAdmin {
        isPublicSaleActive = publicSaleValue;
    }

    function setRoyaltyShare(uint256 royaltyShare) external onlyAdmin {
        royaltyShare10000 = royaltyShare;
    }

    function setRoyaltyReceiver(address royaltyReceiver) external onlyAdmin {
        royaltyAddress = royaltyReceiver;
    }

    function setBeneficiaryAddress(address beneficiary) external onlyAdmin {
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
        override(ERC721A, IERC165, AccessControl)
        returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
    }

    function withdraw() external onlyAdmin {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(beneficiaryAddress).call{value: balance}("");
        require(success, "Withdraw failed");
    }
}