// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC721A, ERC721A} from "erc721a/contracts/ERC721A.sol";
import {ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

error InsufficientEth();
error SoldOut();
error MaxMints();
error SaleNotActive();
error InvalidSignature();
error BurnNotEnabled();
error CallerNotOwner();

contract ArkpiaPass is ERC721AQueryable, OperatorFilterer, Ownable, ERC2981 {
    using ECDSA for bytes32;

    uint256 public maxTotalMints = 1;
    uint256 public price;
    bool public operatorFilteringEnabled;
    bool public prePurchaseActive;
    address private signer = 0xc07064aC4aBa6A5893ab89F04e4a8913f7623C70;
    string private __baseURI = "ipfs://QmPAfLJUheQHYB3EAtdCfzK1LeqEPz3SpqtVq2bnromenA/";
    string private _baseExtension = ".json";
    string private goldMetadata;
    uint256 public prePurchaseCounter;
    uint256 public activePhase;
    bool public burnEnabled;

    mapping(uint256 => Phase) public phases;
    mapping(address => uint256) public prePurchases;
    mapping(uint256 => bool) public isSpecialId;

    event Prepurchase(address indexed user, uint256 amount);

    struct Phase {
        bool whitelistActive;
        bool publicActive;
        uint240 maxSupply;
    }

    constructor() ERC721A("Arkpia Pass", "ARK") {
        _registerForOperatorFiltering();
        _setDefaultRoyalty(address(0x2405679aC65DB5C8FF938aFb590631304d920baD), 500);
        operatorFilteringEnabled = true;
        phases[0] = Phase(false, false, 400);
        phases[1] = Phase(false, false, 850);
        phases[2] = Phase(false, false, 1000);
    }

    function mint(uint256 amount) external payable {
        Phase memory phase = phases[activePhase];
        if (!phase.publicActive) _revert(SaleNotActive.selector);
        uint256 totalMinted = _totalMinted();
        uint256 _prepurchaseCounter = prePurchaseCounter;
        uint256 numUserMints = _numberMinted(msg.sender);
        uint256 numPrepurchased = prePurchases[msg.sender];
        if (msg.value < price * amount) {
            _revert(InsufficientEth.selector);
        }
        if (totalMinted + amount + _prepurchaseCounter > phase.maxSupply) {
            _revert(SoldOut.selector);
        }
        if (numUserMints + amount + numPrepurchased > maxTotalMints) _revert(MaxMints.selector);
        if (prePurchaseActive) {
            prePurchases[msg.sender] = numPrepurchased + amount;
            prePurchaseCounter = _prepurchaseCounter + amount;
            emit Prepurchase(msg.sender, amount);
        } else {
            _mint(msg.sender, amount);
        }
    }

    function whitelistMint(uint256 amount, uint256 max, bytes calldata signature) external payable {
        Phase memory phase = phases[activePhase];
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, max, activePhase));
        if (hash.toEthSignedMessageHash().recover(signature) != signer) _revert(InvalidSignature.selector);
        if (!phase.whitelistActive) _revert(SaleNotActive.selector);
        uint256 totalMinted = _totalMinted();
        uint256 _prepurchaseCounter = prePurchaseCounter;
        uint256 numUserMints = _numberMinted(msg.sender);
        uint256 numPrepurchased = prePurchases[msg.sender];
        if (msg.value < price * amount) {
            _revert(InsufficientEth.selector);
        }
        if (totalMinted + amount + _prepurchaseCounter > phase.maxSupply) {
            _revert(SoldOut.selector);
        }
        if (numUserMints + amount + numPrepurchased > maxTotalMints) _revert(MaxMints.selector);

        if (prePurchaseActive) {
            prePurchases[msg.sender] = numPrepurchased + amount;
            prePurchaseCounter = _prepurchaseCounter + amount;
            emit Prepurchase(msg.sender, amount);
        } else {
            _mint(msg.sender, amount);
        }
    }

    function burn5(uint256[5] calldata tokenIds) external {
        if (!burnEnabled) _revert(BurnNotEnabled.selector);
        for (uint256 i; i < tokenIds.length - 1;) {
            _burn(tokenIds[i], true);
            unchecked {
                ++i;
            }
        }

        uint256 _lastTokenId = tokenIds[tokenIds.length - 1];
        if (msg.sender != ownerOf(_lastTokenId)) _revert(CallerNotOwner.selector);
        isSpecialId[_lastTokenId] = true;
    }

    function burn(uint256 tokenId) external {
        if (!burnEnabled) _revert(BurnNotEnabled.selector);
        _burn(tokenId, true);
    }

    function airdropPrepurchasers(address[] calldata recipients) public onlyOwner {
        unchecked {
            for (uint256 i; i < recipients.length; ++i) {
                uint256 amount = prePurchases[recipients[i]];
                delete prePurchases[recipients[i]];
                _mint(recipients[i], amount);
            }
        }
    }

    // ==========================
    // ========= GETTERS ========
    // ==========================
    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function activePhaseInfo() public view returns (Phase memory) {
        return phases[activePhase];
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    function tokenURI(uint256 tokenId) public view override(IERC721A, ERC721A) returns (string memory) {
        if (isSpecialId[tokenId]) return goldMetadata;
        return string(abi.encodePacked(__baseURI, _toString(tokenId), _baseExtension));
    }

    function baseURI() public view returns (string memory) {
        return __baseURI;
    }

    function numberMinted(address account) external view returns (uint256) {
        return _numberMinted(account);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    // ==========================
    // ========= SETTERS ========
    // ==========================
    function setPrice(uint256 _price) public onlyOwner {
        assembly {
            sstore(price.slot, _price)
        }
    }

    function setMaxTotalMints(uint256 _maxTotalMints) public onlyOwner {
        assembly {
            sstore(maxTotalMints.slot, _maxTotalMints)
        }
    }

    function setPrepurchaseStatus(bool _prePurchaseActive) public onlyOwner {
        prePurchaseActive = _prePurchaseActive;
    }

    function setPhase(uint256 phase, bool whitelistActive, bool publicActive) public onlyOwner {
        Phase memory _phase = phases[phase];
        _phase.whitelistActive = whitelistActive;
        _phase.publicActive = publicActive;
        phases[phase] = _phase;
        activePhase = phase;
    }

    function setPhaseEmergency(uint256 phase, bool whitelistActive, bool publicActive, uint240 maxSupply)
        public
        onlyOwner
    {
        Phase memory _phase = Phase(whitelistActive, publicActive, maxSupply);
        phases[phase] = _phase;
        activePhase = phase;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        __baseURI = baseURI;
    }

    function setGoldenURI(string memory goldenURI) public onlyOwner {
        goldMetadata = goldenURI;
    }

    function setBaseExtension(string memory baseExtension) public onlyOwner {
        _baseExtension = baseExtension;
    }

    function setBurnEnabled(bool _burnEnabled) public onlyOwner {
        burnEnabled = _burnEnabled;
    }

    // ==========================
    // ========= Overrides ========
    // ==========================
    function setApprovalForAll(address operator, bool approved)
        public
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    // ==========================
    // ========= WITHDRAW ========
    // ==========================
    function withdraw() external onlyOwner {
        address receiver = address(0x2405679aC65DB5C8FF938aFb590631304d920baD);
        assembly {
            if iszero(call(gas(), receiver, balance(address()), 0x0, 0x0, 0x0, 0x0)) { revert(0x0, 0x0) }
        }
    }

    function _revert(bytes4 selector) internal pure {
        assembly {
            mstore(0x0, selector)
            revert(0x0, 0x4)
        }
    }
}