// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import { ERC721AQueryable } from "ERC721A/extensions/ERC721AQueryable.sol";
import { ERC721ABurnable } from "ERC721A/extensions/ERC721ABurnable.sol";
import "ERC721A/ERC721A.sol";
import { DefaultOperatorFilterer } from "operator-filter-registry/DefaultOperatorFilterer.sol";
import { IERC2981, ERC2981 } from "openzeppelin-contracts/token/common/ERC2981.sol";
import "openzeppelin-contracts/access/AccessControl.sol";
import "./IERC4906.sol";

enum TicketID {
    AllowList,
    OGSale,
    NicoleBestShot
}

contract NicoleNFT is ERC721A, ERC721AQueryable, ERC721ABurnable, IERC4906, ERC2981, Ownable, Pausable, DefaultOperatorFilterer, AccessControl {
    string private baseURI = "ar://xuWxIEini4fbGSWEQP-Lwv3j7llIywv3298X5JE3wdA/";

    address private constant FUND_ADDRESS = 0x9c6310C1f96f769b7EdED764Be114861083C1064;
    address private constant ADMIN_ADDRESS = 0x73FcB275B2840387f10a619216887ae85Cbc84BE;
    bool private constant OWNER_MINT_PROTECT_SUPPLY = true;

    bool public publicSale = false;
    uint256 public publicCost = 0.1256 ether;

    uint256 public bestShotSupply = 10;
    bool public bestShotSale = false;
    uint256 public bestShotCost = 0.12 ether;

    bool public mintable = false;

    uint256 public constant MAX_SUPPLY = 365;
    string private constant BASE_EXTENSION = ".json";
    uint256 private constant PUBLIC_MAX_PER_TX = 5;
    uint256 private constant PRE_MAX_CAP = 20;
    mapping(uint256 => string) private metadataURI;

    mapping(TicketID => uint256) public presaleCost;
    mapping(TicketID => bool) public presalePhase;
    mapping(TicketID => bytes32) public merkleRoot;
    mapping(TicketID => mapping(address => uint256)) public whiteListClaimed;

    constructor() ERC721A("NicoleNFT", "NICOLE") {
        _grantRole(DEFAULT_ADMIN_ROLE, owner());
        _grantRole(DEFAULT_ADMIN_ROLE, ADMIN_ADDRESS);
        _setDefaultRoyalty(FUND_ADDRESS, 1000);
    }

    modifier whenMintable() {
        require(mintable == true, "Mintable: paused");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (bytes(metadataURI[tokenId]).length == 0) {
            return string(abi.encodePacked(ERC721A.tokenURI(tokenId), BASE_EXTENSION));
        } else {
            return metadataURI[tokenId];
        }
    }

    function setTokenMetadataURI(uint256 tokenId, string memory metadata) external onlyRole(DEFAULT_ADMIN_ROLE) {
        metadataURI[tokenId] = metadata;
        emit MetadataUpdate(tokenId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Set the merkle root for the allow list mint
     */
    function setMerkleRoot(bytes32 _merkleRoot, TicketID ticket) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleRoot[ticket] = _merkleRoot;
    }

    function publicMint(address _to, uint256 _mintAmount) external payable whenNotPaused whenMintable {
        uint256 cost = publicCost * _mintAmount;
        require(_mintAmount > 0, "Mint amount cannot be zero");
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "MAXSUPPLY over");
        require(msg.value >= cost, "Not enough funds");
        require(publicSale, "Public Sale is not Active.");
        require(_mintAmount <= PUBLIC_MAX_PER_TX, "Mint amount over");

        _mint(_to, _mintAmount);
    }

    function bestShotMint(address _to, uint256 _mintAmount) external payable whenNotPaused whenMintable {
        uint256 cost = bestShotCost * _mintAmount;
        require(_mintAmount > 0, "Mint amount cannot be zero");
        require(totalSupply() + _mintAmount <= bestShotSupply, "MAXSUPPLY over");
        require(msg.value >= cost, "Not enough funds");
        require(bestShotSale, "Best Shot Sale is not Active.");
        require(_mintAmount <= PUBLIC_MAX_PER_TX, "Mint amount over");

        _mint(_to, _mintAmount);
    }

    function checkClaimEligibilityBestShot(uint256 quantity) external view returns (string memory) {
        if (paused()) {
            return "Sale period is not live.";
        } else if (mintable == false) {
            return "Sale period is not live.";
        } else if (bestShotSale == false) {
            return "Sale period is not live.";
        } else if (quantity <= 0) {
            return "Quantity can not be 0";
        } else if (quantity > PUBLIC_MAX_PER_TX) {
            return "Exceeded max mint amount per transaction.";
        } else if (totalSupply() + quantity > bestShotSupply) {
            return "Not enough supply";
        }
        return "";
    }

    function checkClaimEligibilityPublic(uint256 quantity) external view returns (string memory) {
        if (paused()) {
            return "Sale period is not live.";
        } else if (mintable == false) {
            return "Sale period is not live.";
        } else if (publicSale == false) {
            return "Sale period is not live.";
        } else if (quantity <= 0) {
            return "Quantity can not be 0";
        } else if (quantity > PUBLIC_MAX_PER_TX) {
            return "Exceeded max mint amount per transaction.";
        } else if (totalSupply() + quantity > bestShotSupply) {
            return "Not enough supply";
        }
        return "";
    }

    function preMint(
        uint256 _mintAmount,
        uint256 _presaleMax,
        bytes32[] calldata _merkleProof,
        TicketID ticket
    ) external payable whenMintable whenNotPaused {
        uint256 cost = presaleCost[ticket] * _mintAmount;
        require(_presaleMax <= PRE_MAX_CAP, "presale max can not exceed");
        require(_mintAmount > 0, "Mint amount cannot be zero");
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "MAXSUPPLY over");
        require(msg.value >= cost, "Not enough funds");
        require(presalePhase[ticket], "Presale is not active.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _presaleMax));
        require(MerkleProof.verifyCalldata(_merkleProof, merkleRoot[ticket], leaf), "Invalid Merkle Proof");
        require(whiteListClaimed[ticket][msg.sender] + _mintAmount <= _presaleMax, "Already claimed max");

        _mint(msg.sender, _mintAmount);
        whiteListClaimed[ticket][msg.sender] += _mintAmount;
    }

    function ownerMint(address _address, uint256 count) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(count > 0, "Mint amount is zero");
        require(!OWNER_MINT_PROTECT_SUPPLY || totalSupply() + count <= MAX_SUPPLY, "MAXSUPPLY over");
        _safeMint(_address, count);
    }

    function setPresalePhase(bool _state, TicketID ticket) external onlyRole(DEFAULT_ADMIN_ROLE) {
        presalePhase[ticket] = _state;
    }

    function setPresaleCost(uint256 _preCost, TicketID ticket) external onlyRole(DEFAULT_ADMIN_ROLE) {
        presaleCost[ticket] = _preCost;
    }

    function setPublicCost(uint256 _publicCost) external onlyRole(DEFAULT_ADMIN_ROLE) {
        publicCost = _publicCost;
    }

    function setPublicPhase(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
        publicSale = _state;
    }

    function setBestShotCost(uint256 _cost) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bestShotCost = _cost;
    }

    function setBestShotPhase(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bestShotSale = _state;
    }

    function setBestShotSupply(uint256 _supply) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bestShotSupply = _supply;
    }

    function setMintable(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintable = _state;
    }

    function setBaseURI(string memory _newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _newBaseURI;
        emit BatchMetadataUpdate(_startTokenId(), totalSupply());
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        Address.sendValue(payable(FUND_ADDRESS), address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC721A, ERC2981, AccessControl) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
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