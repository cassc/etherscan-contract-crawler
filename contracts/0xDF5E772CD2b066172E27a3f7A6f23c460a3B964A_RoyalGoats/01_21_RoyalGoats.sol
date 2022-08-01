// SPDX-License-Identifier: UNLICENSED
/**
  _____   _____  _____   _           _         
 |  __ \ / ____|/ ____| | |         | |        
 | |__) | |  __| |      | |     __ _| |__  ___ 
 |  _  /| | |_ | |      | |    / _` | '_ \/ __|
 | | \ \| |__| | |____  | |___| (_| | |_) \__ \
 |_|  \_\\_____|\_____| |______\__,_|_.__/|___/
                                            
 */

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "@metacrypt/contracts/src/erc721/ERC721EnumerableSupply.sol";
import "@metacrypt/contracts/src/access/OwnableClaimable.sol";
import "@metacrypt/contracts/src/security/ContractSafe.sol";

/// @title ERC721 Contract for Royal Goats Club
/// @author metacrypt.org
contract RoyalGoats is ERC721, ERC721EnumerableSupply, Pausable, AccessControl, OwnableClaimable, ContractSafe {
    using ECDSA for bytes32;

    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

    string private baseURIStorage = "https://metadata.metacrypt.org/api/royal-goats-club/";

    constructor(address _signer) ERC721("Royal Goats Club", "GOAT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CONTROLLER_ROLE, msg.sender);

        signerAccount = _signer;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURIStorage;
    }

    function setBaseURI(string calldata newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURIStorage = newBaseURI;
    }

    function approveController(address controller) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(CONTROLLER_ROLE, controller);
    }

    function pause() public onlyRole(CONTROLLER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(CONTROLLER_ROLE) {
        _unpause();
    }

    /**
     ** Sale Parameters
     */

    uint256 public constant MAX_GOATS = 10_000;

    address private signerAccount;
    bytes32 eip712DomainHash =
        keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("RoyalGoats")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

    uint256 public mintTimestampPublic = 0;
    uint256 public mintTimestampAllowlist = 0;

    uint256 public mintPricePublic = 0.1 ether;
    uint256 public mintPriceAllowlist = 0.08 ether;

    uint256 public mintLimitPublic = type(uint256).max - 1;
    uint256 public mintLimitAllowlist = 6;

    mapping(address => uint256) public mintedDuringPublicSale;
    mapping(address => uint256) public mintedDuringAllowlistSale;

    function isPublicSaleOpen() public view returns (bool) {
        return mintTimestampPublic == 0 ? false : (block.timestamp >= mintTimestampPublic);
    }

    function isAllowlistSaleOpen() public view returns (bool) {
        return mintTimestampAllowlist == 0 ? false : (block.timestamp >= mintTimestampAllowlist);
    }

    function setMintingTime(uint256 _public, uint256 _allowlist) external onlyOwner {
        mintTimestampPublic = _public;
        mintTimestampAllowlist = _allowlist;
    }

    function setMintingPrice(uint256 _public, uint256 _allowlist) external onlyOwner {
        mintPricePublic = _public;
        mintPriceAllowlist = _allowlist;
    }

    function setMintingLimits(uint256 _public, uint256 _allowlist) external onlyOwner {
        mintLimitPublic = _public;
        mintLimitAllowlist = _allowlist;
    }

    modifier passesRequirements(uint256 numberOfTokens, uint16 mode) {
        require(!isContract(msg.sender) && isSentViaEOA(), "Must be sent via EOA");
        require(totalSupply() + numberOfTokens <= MAX_GOATS, "Purchase would exceed limit");

        if (mode == 0) {
            // Public Sale
            require(isPublicSaleOpen(), "Public sale not open yet");
            require(mintedDuringPublicSale[msg.sender] + numberOfTokens <= mintLimitPublic, "Minting Limit Exceeded");
            require(msg.value >= (mintPricePublic * numberOfTokens), "Incorrect amount");
        } else if (mode == 1) {
            // Allowlist Sale
            require(isAllowlistSaleOpen(), "Allowlist sale not open yet");
            require(mintedDuringAllowlistSale[msg.sender] + numberOfTokens <= mintLimitAllowlist, "Minting Limit Exceeded");
            require(msg.value >= (mintPriceAllowlist * numberOfTokens), "Incorrect amount");
        }
        _;
    }

    function mintTokens(uint256 numberOfTokens, address target) internal {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 nextMint = totalSupply();
            _safeMint(target, nextMint);
        }
    }

    function mintPublic(uint256 numberOfTokens) public payable passesRequirements(numberOfTokens, 0) {
        mintedDuringPublicSale[msg.sender] += numberOfTokens;

        mintTokens(numberOfTokens, msg.sender);
    }

    function mintAllowlist(
        uint256 numberOfTokens,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable passesRequirements(numberOfTokens, 1) {
        bytes32 hashStruct = keccak256(abi.encode(keccak256("Data(address target)"), msg.sender));
        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
        address signer = ecrecover(hash, v, r, s);

        require(signer == signerAccount, "ECDSA: invalid signature");

        mintedDuringAllowlistSale[msg.sender] += numberOfTokens;

        mintTokens(numberOfTokens, msg.sender);
    }

    function mintOwner(uint256 numberOfTokens, address to) public payable onlyRole(CONTROLLER_ROLE) {
        require(totalSupply() + numberOfTokens <= MAX_GOATS, "Mint would exceed limit");

        mintTokens(numberOfTokens, to);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}