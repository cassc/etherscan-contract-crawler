//SPDX-License-Identifier: Unlicense
// Creator: Pixel8 Labs
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "erc721a/contracts/ERC721A.sol";
import "@sigpub/signatures-verify/Signature.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

error InvalidSignature();
error InvalidAmount(uint amount);
error ExceededMaxSupply();
error ExceededMintQuota(uint amount, uint quota);
error InvalidSource();

contract HungryHamsterClub is ERC721A, ERC2981, Ownable, AccessControl, Pausable, ReentrancyGuard, DefaultOperatorFilterer {
    uint public MAX_SUPPLY = 5555;
    uint public maxPerTx = 2;
    string public baseURI;

    // Phases
    enum Phases {
        CLOSED,
        PRIVATE
    }
    Phases public phase = Phases.CLOSED;
    address public signer;

    modifier canMint(uint amount) {
        uint256 supply = totalSupply();
        if(amount > maxPerTx) revert InvalidAmount(maxPerTx);
        if(supply + amount > MAX_SUPPLY) revert ExceededMaxSupply();
        if(msg.sender != tx.origin) revert InvalidSource();
        _;
    }

    constructor (
        string memory uri,
        address receiver
    ) ERC721A("Hungry Hamster Club", "HHC") Ownable() { 
        baseURI = uri;
        _transferOwnership(0x3680fd6cfdec94d2FCA9fAC09E3a62B5C2B970d1);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setDefaultRoyalty(receiver, 750); // 750 = 7.5%
    }

    // Metadata
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (bytes(baseURI).length == 0) return "";

        return string(abi.encodePacked(baseURI, "/", _toString(tokenId), ".json"));
    }

    function privateMint(uint64 amount, uint64 maxAmount, bytes memory signature) external canMint(amount) whenNotPaused nonReentrant {
        require(phase == Phases.PRIVATE, 'mint is not open');

        uint64 aux = _getAux(msg.sender);
        if(Signature.verify(maxAmount, msg.sender, signature) != signer) revert InvalidSignature();
        if(aux + amount > maxAmount) revert ExceededMintQuota(aux + amount, maxAmount);

        _setAux(msg.sender, aux + amount);
        _safeMint(msg.sender, amount);
    }

    function airdrop(address wallet, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 supply = totalSupply();
        if(supply + amount > MAX_SUPPLY) revert ExceededMaxSupply();
        _safeMint(wallet, amount);
    }
    
    function claimed(address target) external view returns (uint256) {
        return _getAux(target);
    }

    function setTokenURI(string calldata uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = uri;
    }

    function setSigner(address value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        signer = value;
    }

    function setMaxSupply(uint _maxSupply) external onlyRole(DEFAULT_ADMIN_ROLE) {
        MAX_SUPPLY = _maxSupply;
    }

     // Phases
    function setPause(bool pause) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (pause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setPhase(Phases _phase) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_phase == Phases.PRIVATE) {
            require(signer != address(0), 'Signer address is not set');
        }
        phase = _phase;
    }

    // Set default royalty to be used for all token sale
    function setDefaultRoyalty(address _receiver, uint96 _fraction) public onlyRole(DEFAULT_ADMIN_ROLE) { 
        _setDefaultRoyalty(_receiver, _fraction);
    }

    function setTokenRoyalty(uint256 _tokenId, address _receiver, uint96 _fraction) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenRoyalty(_tokenId, _receiver, _fraction);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981, AccessControl) returns (bool) {
        return 
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

     // Operator Filter Registry
    bool filter;
    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        if(filter) {
        filteredTransferFrom(from, to, tokenId);
        } else {
        super.transferFrom(from, to, tokenId);
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        if(filter) {
        filteredSafeTransferFrom(from, to, tokenId);
        } else {
        super.safeTransferFrom(from, to, tokenId);
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public payable override onlyAllowedOperator(from) {
        if(filter) {
        filteredSafeTransferFrom(from, to, tokenId, data);
        } else {
        super.safeTransferFrom(from, to, tokenId, data);
        }
    }

    function filteredTransferFrom(address from, address to, uint256 tokenId) public onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function filteredSafeTransferFrom(address from, address to, uint256 tokenId) public onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function filteredSafeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}