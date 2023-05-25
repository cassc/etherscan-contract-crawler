// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./operator-filter-registry/DefaultOperatorFilterer.sol";
import "./operator-filter-registry/IOperatorFilterRegistry.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

///@author Charles
contract QuartanPrimesNFT is
    ERC721,
    ERC2981,
    Ownable,
    ReentrancyGuard,
    ERC721Burnable,
    DefaultOperatorFilterer
{
    error IncorrectSignature();
    error MaxMintedForThisUser();
    error AllNFTsMinted();
    error CannotSetZeroAddress();
    error ShouldCallItInPhase(uint32 phase);
    error ShouldInHighIDRange();
    error YouAreNotOwner();

    event OpenedOneBox(address indexed from, uint indexed mechID);

    using Address for address;
    using ECDSA for bytes32;

    uint256 public constant MAX_SUPPLY = 641;
    uint32 private constant BOX_ID_OFFSET = 10000; //highID(10001~10641) to Box, and lowID(1~641) to Mech
    uint32 private constant PHASE_1_STARTTOKENID = 1 + BOX_ID_OFFSET;
    uint32 private constant PHASE_1_ENDTOKENID = 625 + BOX_ID_OFFSET;
    uint32 private constant PHASE_2_STARTTOKENID = 626 + BOX_ID_OFFSET;
    uint32 private constant PHASE_2_ENDTOKENID = 641 + BOX_ID_OFFSET;

    // uint32 private constant GENESIS_NFT_STARTTOKENID = 1;
    // uint32 private constant GENESIS_NFT_ENDTOKENID = 641;

    address public treasuryAddress;

    string private _baseTokenURI;
    address private _signerAddress; // provided by our backend fellow

    mapping(address => uint256) public _mintedCountPerAddress_phase1;
    mapping(address => uint256) public _mintedCountPerAddress_phase2;

    uint32 private _nextMintableIndex_phase1 = PHASE_1_STARTTOKENID;
    uint32 private _nextMintableIndex_phase2 = PHASE_2_STARTTOKENID;
    uint32 public currentPhase = 1;

    constructor(
        address defaultTreasury,
        string memory defaultBaseURI,
        address signerAddress_
    ) ERC721("Fusionist - Quartan Primes", "FQP") {
        setBaseURI(defaultBaseURI);
        setRoyaltyInfo(payable(defaultTreasury), 500);
        setSignerAddress(signerAddress_);
    }

    //EXTERNAL ---------
    function setPhase(uint32 phase) external onlyOwner {
        currentPhase = phase;
    }

    ///@dev User call this function in Phase1
    function phase1Mint(
        uint256 quantity,
        uint256 maxMintable,
        bytes calldata signature
    ) external payable nonReentrant {
        if (currentPhase != 1) {
            revert ShouldCallItInPhase(1);
        }
        address sender = msg.sender;
        uint256 mintedCount = _mintedCountPerAddress_phase1[sender];
        if (mintedCount + quantity > maxMintable) {
            revert MaxMintedForThisUser();
        }
        uint32 localNextID = _nextMintableIndex_phase1;
        if ((localNextID + quantity - 1) > PHASE_1_ENDTOKENID) {
            // _nextMintableIndex_phase1 = 1, phase1EndTokenID = 1 , quantity = 1, pass
            revert AllNFTsMinted();
        }
        if (verifySig(sender, quantity, maxMintable, 1, signature) == false) {
            revert IncorrectSignature();
        }

        _mintedCountPerAddress_phase1[sender] = mintedCount + quantity;

        for (uint i = 0; i < quantity; i++) {
            _safeMint(sender, localNextID);
            unchecked {
                ++localNextID;
            }
        }
        _nextMintableIndex_phase1 = localNextID;
    }

    ///@dev User call this function in Phase2
    function phase2Mint(
        uint256 quantity,
        uint256 maxMintable,
        bytes calldata signature
    ) external payable nonReentrant {
        if (currentPhase != 2) {
            revert ShouldCallItInPhase(2);
        }
        address sender = msg.sender;
        uint256 mintedCount = _mintedCountPerAddress_phase2[sender];
        if (mintedCount + quantity > maxMintable) {
            revert MaxMintedForThisUser();
        }
        uint32 localNextID = _nextMintableIndex_phase2;
        if ((localNextID + quantity - 1) > PHASE_2_ENDTOKENID) {
            // _nextMintableIndex_phase2 = 626, phase2EndTokenID = 626 , quantity = 1, pass
            revert AllNFTsMinted();
        }
        if (verifySig(sender, quantity, maxMintable, 2, signature) == false) {
            revert IncorrectSignature();
        }

        _mintedCountPerAddress_phase2[sender] = mintedCount + quantity;

        for (uint i = 0; i < quantity; i++) {
            _safeMint(sender, localNextID);
            unchecked {
                ++localNextID;
            }
        }
        _nextMintableIndex_phase2 = localNextID;
    }

    ///@dev user can call this function at any time, even ten years later
    function openBox(uint256 boxID) external nonReentrant {
        address account = msg.sender;
        if (ownerOf(boxID) != account) {
            revert YouAreNotOwner();
        }
        burnBoxAndMintMech(account, boxID);
    }

    function totalSupply() external view returns (uint256) {
        return
            _nextMintableIndex_phase1 -
            PHASE_1_STARTTOKENID +
            _nextMintableIndex_phase2 -
            PHASE_2_STARTTOKENID;
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(treasuryAddress), address(this).balance);
    }

    function mintAllExpiredBoxesToOfficialPhase1() external onlyOwner {
        address account = msg.sender;
        uint256 nextID = _nextMintableIndex_phase1;
        uint256 leftNFTCount = PHASE_1_ENDTOKENID - nextID + 1;
        _nextMintableIndex_phase1 = PHASE_1_ENDTOKENID + 1;
        for (uint i = 0; i < leftNFTCount; i++) {
            uint256 tokenID = nextID + i;
            _safeMint(account, tokenID);
        }
    }

    function mintAllExpiredBoxesToOfficialPhase2() external onlyOwner {
        if (currentPhase != 2) {
            revert ShouldCallItInPhase(2);
        }
        address account = msg.sender;
        uint256 nextID = _nextMintableIndex_phase2;
        uint256 leftNFTCount = PHASE_2_ENDTOKENID - nextID + 1;
        _nextMintableIndex_phase2 = PHASE_2_ENDTOKENID + 1;
        for (uint i = 0; i < leftNFTCount; i++) {
            uint256 tokenID = nextID + i;
            _safeMint(account, tokenID);
        }
    }

    function changeOperatorFiltererRegister(IOperatorFilterRegistry newRegistry)
        external
        onlyOwner
    {
        OPERATOR_FILTER_REGISTRY = newRegistry;
    }    

    //PUBLIC ---------

    function setSignerAddress(address signerAddress) public onlyOwner {
        _signerAddress = signerAddress;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function setRoyaltyInfo(
        address payable newAddress,
        uint96 newRoyaltyPercentage
    ) public onlyOwner {
        if (newAddress == address(0)) revert CannotSetZeroAddress();
        treasuryAddress = newAddress;
        _setDefaultRoyalty(treasuryAddress, newRoyaltyPercentage);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return
            ERC2981.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    //INTERNAL --------

    function burnBoxAndMintMech(address account, uint256 boxID) internal {
        if (boxID < BOX_ID_OFFSET) {
            revert ShouldInHighIDRange();
        }
        burn(boxID);
        uint256 mechID = boxID - BOX_ID_OFFSET;
        _safeMint(account, mechID);
        emit OpenedOneBox(account, mechID);
    }

    function verifySig(
        address sender,
        uint256 quantity,
        uint256 maxMintable,
        uint256 phase,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 messageHash = keccak256(
            abi.encode(sender, phase, maxMintable, quantity)
        );
        return
            _signerAddress ==
            messageHash.toEthSignedMessageHash().recover(signature);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}