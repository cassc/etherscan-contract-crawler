// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

enum SaleStage {
    None,
    WhiteList,
    PublicSale
}

contract MoaiFamilyNFT is Ownable, ReentrancyGuard, ERC721A {
    using Strings for uint256;
    using MerkleProof for bytes32[];

    uint256 public salePhaseId;

    uint256 public whiteListSaleStartTime;
    uint256 public whiteListSaleEndTime;
    uint256 public whiteListSaleMintPrice;
    uint256 public publicSaleStartTime;
    uint256 public publicSaleEndTime;
    uint256 public publicSaleMintPrice;
    uint256 public publicSaleMaxQuantityPerTx;
    uint256 public remainingQuantity;
    address public minter;
    address public constant multisig =
        0x49bcE3a729749397F1D6EBDEbbaEfDdF3a4CaBC3;

    mapping(uint256 => bytes32) public whiteListMerkleRoots;
    mapping(uint256 => bytes32) public prepaidWhiteListMerkleRoots;
    // salePhaseId to address to quantityPurchased
    mapping(uint256 => mapping(address => uint256)) public whiteListPurchased;
    // salePhaseId to address to isDelivered
    mapping(uint256 => mapping(address => bool))
        public prepaidWhiteListDelivered;

    uint256 public constant maxTotalSupply = 3600;

    string private _baseURIExtended;
    event Minted(address to, uint256 quantity);

    modifier onlyMinter() {
        require(msg.sender == minter, "not minter");
        _;
    }

    constructor(
        address _minter,
        address _owner,
        address _receiver,
        string memory _uri
    ) ERC721A("Moai Family NFT", "MF") {
        minter = _minter;
        _baseURIExtended = _uri;
        transferOwnership(_owner);
        safeMint(_receiver, 180);
    }

    /* *************** */
    /* ADMIN FUNCTIONS */
    /* *************** */

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    function mintPrepaidWhiteList(
        bytes32[] calldata proof,
        address receiver,
        uint256 quantity
    ) external onlyMinter nonReentrant {
        SaleStage currentActiveSaleStage = getCurrentActiveSaleStage();
        require(
            currentActiveSaleStage == SaleStage.WhiteList,
            "function can only be called during whitelist sale"
        );
        require(
            proof.verify(
                prepaidWhiteListMerkleRoots[salePhaseId],
                keccak256(abi.encodePacked(receiver, quantity))
            ),
            "failed to verify merkle root"
        );
        require(
            !prepaidWhiteListDelivered[salePhaseId][receiver],
            "prepaid NFTs have been delivered already"
        );
        require(
            remainingQuantity >= quantity,
            "remaining quantity not enough left for this mint"
        );
        prepaidWhiteListDelivered[salePhaseId][receiver] = true;
        remainingQuantity -= quantity;

        safeMint(receiver, quantity);
        emit Minted(receiver, quantity);
    }

    function setSaleData(
        uint256 _whiteListSaleStartTime,
        uint256 _whiteListSaleEndTime,
        uint256 _whiteListSaleMintPrice,
        bytes32 _whiteListMerkleRoot,
        bytes32 _prepaidWhiteListMerkleRoot,
        uint256 _publicSaleStartTime,
        uint256 _publicSaleEndTime,
        uint256 _publicSaleMintPrice,
        uint256 _publicSaleMaxQuantityPerTx,
        uint256 _remainingQuantity
    ) external onlyOwner {
        salePhaseId += 1;
        whiteListSaleStartTime = _whiteListSaleStartTime;
        whiteListSaleEndTime = _whiteListSaleEndTime;
        whiteListSaleMintPrice = _whiteListSaleMintPrice;
        whiteListMerkleRoots[salePhaseId] = _whiteListMerkleRoot;
        prepaidWhiteListMerkleRoots[salePhaseId] = _prepaidWhiteListMerkleRoot;
        publicSaleStartTime = _publicSaleStartTime;
        publicSaleEndTime = _publicSaleEndTime;
        publicSaleMintPrice = _publicSaleMintPrice;
        publicSaleMaxQuantityPerTx = _publicSaleMaxQuantityPerTx;
        remainingQuantity = _remainingQuantity;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = multisig.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    /* ************** */
    /* USER FUNCTIONS */
    /* ************** */

    // @notice This function returns the current active sale stage
    // @notice 0: NONE, 1: Whitelist Sale 2: PublicSale
    function getCurrentActiveSaleStage() public view returns (SaleStage) {
        bool whiteListSaleIsActive = (block.timestamp >
            whiteListSaleStartTime) && (block.timestamp < whiteListSaleEndTime);
        if (whiteListSaleIsActive) {
            return SaleStage.WhiteList;
        }
        bool publicSaleIsActive = (block.timestamp > publicSaleStartTime) &&
            (block.timestamp < publicSaleEndTime);
        if (publicSaleIsActive) {
            return SaleStage.PublicSale;
        }
        return SaleStage.None;
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
        string memory base = _baseURI();
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function joinFamily(
        bytes32[] calldata proof,
        uint256 merkleQuantity,
        uint256 quantity
    ) external payable nonReentrant {
        require(
            tx.origin == msg.sender,
            "smart contracts are not allowed to buy"
        );
        SaleStage currentActiveSaleStage = getCurrentActiveSaleStage();
        require(
            currentActiveSaleStage != SaleStage.None,
            "no active sale right now"
        );
        require(quantity > 0, "quantity cannot be 0");
        if (currentActiveSaleStage == SaleStage.WhiteList) {
            _joinFamilyWhiteList(proof, merkleQuantity, quantity);
        } else if (currentActiveSaleStage == SaleStage.PublicSale) {
            _joinFamilyPublicSale(quantity);
        }
    }

    function ownedTokenIds(address user)
        external
        view
        returns (uint256[] memory tokenIds)
    {
        uint256 balance = balanceOf(user);
        tokenIds = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(user, i);
        }
        return tokenIds;
    }

    /* ****************** */
    /* INTERNAL FUNCTIONS */
    /* ****************** */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function safeMint(address to, uint256 quantity) internal {
        require(
            totalSupply() + quantity <= maxTotalSupply,
            "max total supply reached"
        );
        super._safeMint(to, quantity);
    }

    function _joinFamilyWhiteList(
        bytes32[] calldata proof,
        uint256 merkleQuantity,
        uint256 quantity
    ) internal {
        require(whiteListMerkleRoots[salePhaseId] != 0, "merkle root not set");
        require(
            proof.verify(
                whiteListMerkleRoots[salePhaseId],
                keccak256(abi.encodePacked(msg.sender, merkleQuantity))
            ),
            "failed to verify merkle root"
        );
        require(
            whiteListPurchased[salePhaseId][msg.sender] + quantity <=
                merkleQuantity,
            "whiteList quantity exceeded"
        );

        require(
            remainingQuantity >= quantity,
            "remaining quantity not enough left for this purchase"
        );
        require(
            msg.value == whiteListSaleMintPrice * quantity,
            "sent ether value incorrect"
        );
        whiteListPurchased[salePhaseId][msg.sender] += quantity;
        remainingQuantity -= quantity;

        safeMint(msg.sender, quantity);
        emit Minted(msg.sender, quantity);
    }

    function _joinFamilyPublicSale(uint256 quantity) internal {
        require(
            quantity <= publicSaleMaxQuantityPerTx,
            "quantity exceeds publicSaleMaxQuantityPerTx"
        );
        require(
            remainingQuantity >= quantity,
            "remaining quantity not enough left for this purchase"
        );
        require(
            msg.value == publicSaleMintPrice * quantity,
            "sent ether value incorrect"
        );
        remainingQuantity -= quantity;

        safeMint(msg.sender, quantity);
        emit Minted(msg.sender, quantity);
    }
}