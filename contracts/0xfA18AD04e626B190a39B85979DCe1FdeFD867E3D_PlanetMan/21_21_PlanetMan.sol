// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


import {DefaultOperatorFilterer} from "./opensea/DefaultOperatorFilterer.sol";

contract PlanetMan is ERC721, ERC721Holder, DefaultOperatorFilterer, AccessControl, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    /**
     * @notice Admin role
     */
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /**
     * @notice Mint open status
     */
    bool public mintOpen = false;

    /**
     * @notice MerkleRoot of whitelist address
     */
    bytes32 public whitelistMerkleRoot;

    /**
     * @notice Whitelist is open or not
     */
    bool public whitelistOpen = false;

    /**
     * @notice MerkleRoot of each batch ipfs image's cids
     */
    mapping(uint256 => bytes32) public cidMerkleRoots;

    /**
     * @notice Counter of tokenId
    */
    Counters.Counter private _tokenIdCounter;

    /**
     * @notice maximum limit, 0 means unlimited
     */
    uint256 public mintMaximumLimit = 1000;

    /**
     * @notice Token baseURI
     */
    string public baseURI = "https://api.planetman.io/token/planetman/";

    /**
     * @notice SetTokenURI is available or not
     */
    bool public ableSetTokenURI = true;

    /**
     * @dev Record of already-minted wallet
     */
    mapping(address => bool) public walletMint;

    /**
     * @dev Record of already-used CIDs
     */
    mapping(string => bool) public usedCIDs;

    /**
     * @dev CIDs bind to token
     */
    mapping(uint256 => string[]) public tokenCIDs;

    /**
     * @dev Current cid index of tokenCIDs
     */
    mapping(uint256 => uint256) public tokenCIDIndex;

    /**
     * @dev Wallet bind to PlanetMan
     */
    mapping(address => uint256) public walletToToken;

    /**
     * @dev PlanetMan bind to wallet
     */
    mapping(uint256 => address) public tokenToWallet;

    /**
     * @dev SocialCredits of tokenId
     */
    mapping(uint256 => uint256) public socialCredits;

    /**
     * @dev Total socialCredits newly added
     */
    uint256 public newTotalSocialCredits;

    /**
     * @dev Total socialCredits of all tokens
     */
    uint256 public allTotalSocialCredits;

    /**
     * @notice MerkleRoot of socialCredits
     */
    bytes32 public socialCreditsMerkleRoot;

    // Events

    event MintPlanetMan(
        address indexed holder,
        uint256 tokenId,
        uint256 timestamp
    );

    event SetBaseURI(
        string baseURI
    );

    event SetTokenURI(
        uint256 tokenId,
        string cid,
        string interest
    );

    event BindWallet(
        uint256 tokenId,
        address wallet
    );

    event UnbindWallet(
        uint256 tokenId,
        address wallet
    );

    event SubmitSocialCredit(
        uint256 tokenId,
        uint256 socialCredit
    );

    event SetCidMerkleRoots(
        uint256 batch,
        bytes32 merkleRoot
    );

    event SetWhitelistMerkleRoot(
        bytes32 merkleRoot
    );

    event SetTotalSocialCredits(
        uint256 newTotalSocialCredits,
        uint256 allTotalSocialCredits,
        uint256 timestamp
    );

    modifier onlyOwnerOrAdmin() {
        require(owner() == _msgSender() || hasRole(ADMIN_ROLE, _msgSender()), "PlanetMan: caller is not owner or administrator");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address[] memory admins
    ) payable ERC721(name, symbol) {

        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        for (uint256 i = 0; i < admins.length; i++) {
            _grantRole(ADMIN_ROLE, admins[i]);
        }
    }


    /**
     * @notice Mint PlanetMan token
     * @param cid ipfs cid of the token image
     * @param batch batch number of each batch image's merkleRoot
     * @param whitelistProof whitelist leaf of the merkleProof
     * @param cidProof cid leaf of the merkleProof
     * @param interest interest bind to token
     */
    function mintPlanetMan(string memory cid, uint256 batch, bytes32[] calldata whitelistProof, bytes32[] calldata cidProof, string memory interest) public nonReentrant whenNotPaused {
        require(mintOpen, "PlanetMan: mint is not open");
        require(bytes(cid).length != 0, "PlanetMan: CID is empty");
        require(!usedCIDs[cid], "PlanetMan: image unavailable");
        require(!walletMint[_msgSender()], "PlanetMan: limited one token per wallet");

        bytes32 cidHash = keccak256(abi.encodePacked(cid));

        require(merkleTreeVerify(cidMerkleRoots[batch], cidHash, cidProof), "PlanetMan: invalid PlanetMan image");
        if (mintMaximumLimit != 0) {
            require(totalSupply() < mintMaximumLimit, "PlanetMan: current minting process is over");
        }
        if (whitelistOpen) {
            require(merkleTreeVerify(whitelistMerkleRoot, _toBytes32(msg.sender), whitelistProof), "PlanetMan: you are not in the whitelist");
        }

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(_msgSender(), tokenId);

        _setTokenURI(tokenId, cid, interest);

        // bind the token to the minter's wallet if not bind
        if (walletToToken[_msgSender()] == 0) {
            _bindWallet(tokenId, _msgSender());
        }

        // Initial social credits of 100
        socialCredits[tokenId] = 100;

        walletMint[_msgSender()] = true;

        emit MintPlanetMan(_msgSender(), tokenId, block.timestamp);
    }

    /**
     * @notice Convert address to bytes32
     * @param addr eth address
     */
    function _toBytes32(address addr) pure internal returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }


    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }


    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;

        emit SetBaseURI(baseURI_);
    }


    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }


    /**
     * @dev set tokenURI with interest
     * @param tokenId id of the token
     * @param cid ipfs cid of the PlanetMan image
     * @param batch batch number of each batch image's merkleRoot
     * @param cidProof cid leaf of the merkleProof
     * @param interest interest bind to token
     */
    function setTokenURI(uint256 tokenId, string memory cid, uint256 batch, bytes32[] calldata cidProof, string memory interest) public {
        require(ableSetTokenURI, "PlanetMan: PlanetMan customization is closed");
        require(ownerOf(tokenId) == _msgSender(), "PlanetMan: only owner");

        bytes32 cidHash = keccak256(abi.encodePacked(cid));

        require(merkleTreeVerify(cidMerkleRoots[batch], cidHash, cidProof), "PlanetMan: invalid PlanetMan image");

        _setTokenURI(tokenId, cid, interest);
    }


    function _setTokenURI(uint256 tokenId, string memory cid, string memory interest) internal {
        // if cid is used, check whether it is bind to the token or not
        if (usedCIDs[cid]) {
            string[] memory _tokenCIDs = tokenCIDs[tokenId];
            bool approved = false;
            uint256 length = _tokenCIDs.length;
            uint256 index;
            for (index = 0; index < length; index++) {
                if (keccak256(abi.encodePacked(cid)) == keccak256(abi.encodePacked(_tokenCIDs[index]))) {
                    approved = true;
                    break;
                }
            }
            require(approved, "PlanetMan: cid has been used");
            tokenCIDIndex[tokenId] = index;
        } else {
            usedCIDs[cid] = true;
            tokenCIDs[tokenId].push(cid);
            tokenCIDIndex[tokenId] = tokenCIDs[tokenId].length - 1;
        }

        emit SetTokenURI(tokenId, cid, interest);
    }

    /**
     * @notice merkle tree verify
     */
    function merkleTreeVerify(bytes32 root, bytes32 leaf, bytes32[] memory proof) public pure returns (bool){
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

    /**
     * @dev submit social credits
     */
    function submitSocialCredit(uint256 tokenId, uint256 socialCredit, bytes32[] calldata socialCreditProof) external onlyOwnerOrAdmin {
        require(socialCredit > 0, "PlanetMan: invalid socialCredit(zero)");
        require(_exists(tokenId), "PlanetMan: nonexistent token");

        string memory tokenSocialCredit = string.concat(Strings.toString(tokenId), "#", Strings.toString(socialCredit));
        bytes32 socialCreditHash = keccak256(abi.encodePacked(tokenSocialCredit));

        require(merkleTreeVerify(socialCreditsMerkleRoot, socialCreditHash, socialCreditProof), "PlanetMan: invalid socialCredit");

        socialCredits[tokenId] = socialCredit;

        emit SubmitSocialCredit(tokenId, socialCredit);
    }


    /**
     * @dev Bind wallet to token, limited one binded token per wallet
     */
    function bindWallet(uint256 tokenId) public {
        require(_exists(tokenId), "PlanetMan: nonexistent token");
        require(ownerOf(tokenId) == _msgSender(), "PlanetMan: only owner");

        // unbind wallet from the current token
        _unbindWallet(_msgSender());

        _bindWallet(tokenId, _msgSender());
    }

    function _bindWallet(uint256 tokenId, address to) internal {
        walletToToken[to] = tokenId;
        tokenToWallet[tokenId] = to;

        emit BindWallet(tokenId, to);
    }

    /**
     * @dev unbind wallet from the token
     */
    function _unbindWallet(address wallet) internal {
        uint256 beforeTokenId = walletToToken[wallet];
        if (beforeTokenId != 0) {
            delete walletToToken[wallet];
            delete tokenToWallet[beforeTokenId];

            emit UnbindWallet(beforeTokenId, wallet);
        }
    }


    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool){
        return super.supportsInterface(interfaceId);
    }


    /*
     * @dev After transfer, unbind wallet from the current token and bind the token to the receiver's wallet
     */
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal override(ERC721) {
        // if transfer via mint, DO NOT unbind wallet from the token
        if (from != address(0)) {
            // unbind wallet from the current token
            _unbindWallet(from);
            // bind the token to the receiver's wallet if not bind
            if (walletToToken[to] == 0) {
                _bindWallet(firstTokenId, to);
            }
        }
        super._afterTokenTransfer(from, to, firstTokenId, batchSize);
    }

    /*
     * @dev royalty
     */
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

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }


    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) external onlyOwnerOrAdmin {
        whitelistMerkleRoot = _whitelistMerkleRoot;

        emit SetWhitelistMerkleRoot(_whitelistMerkleRoot);
    }


    function setWhitelistOpen(bool _whitelistOpen) external onlyOwnerOrAdmin {
        whitelistOpen = _whitelistOpen;
    }

    function setCidMerkleRoots(uint256 batch, bytes32 _cidMerkleRoots) external onlyOwnerOrAdmin {
        cidMerkleRoots[batch] = _cidMerkleRoots;

        emit SetCidMerkleRoots(batch, _cidMerkleRoots);
    }

    function setSocialCreditsMerkleRoot(bytes32 _socialCreditsMerkleRoot) external onlyOwnerOrAdmin {
        socialCreditsMerkleRoot = _socialCreditsMerkleRoot;
    }

    function setMintMaximumLimit(uint256 _mintMaximumLimit) external onlyOwnerOrAdmin {
        mintMaximumLimit = _mintMaximumLimit;
    }

    function setAbleSetTokenURI(bool _ableSetTokenURI) external onlyOwnerOrAdmin {
        ableSetTokenURI = _ableSetTokenURI;
    }

    function setTotalSocialCredits(uint256 _newTotalSocialCredits, uint256 _allTotalSocialCredits) external onlyOwnerOrAdmin {
        newTotalSocialCredits = _newTotalSocialCredits;
        allTotalSocialCredits = _allTotalSocialCredits;

        emit SetTotalSocialCredits(newTotalSocialCredits, allTotalSocialCredits, block.timestamp);
    }

    function setMintOpen(bool _mintOpen) public onlyOwner {
        mintOpen = _mintOpen;
    }


    function withdraw() payable public onlyOwner {
        (bool sent,) = payable(msg.sender).call{value : address(this).balance}("");
        require(sent, "PlanetMan: Failed to withdraw");
    }

    function pause() external onlyOwner {
        super._pause();
    }


    function unpause() external onlyOwner {
        super._unpause();
    }

}