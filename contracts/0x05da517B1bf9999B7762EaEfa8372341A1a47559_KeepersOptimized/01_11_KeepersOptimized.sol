// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./ERC721A.sol";

import {ASingleAllowlistMerkle} from "../whitelist/ASingleAllowlistMerkle.sol";
import {AMultiFounderslistMerkle} from "../whitelist/AMultiFounderslistMerkle.sol";

//  ____  __.
// |    |/ _|____   ____ ______   ___________  ______
// |      <_/ __ \_/ __ \\____ \_/ __ \_  __ \/  ___/
// |    |  \  ___/\  ___/|  |_> >  ___/|  | \/\___ \
// |____|__ \___  >\___  >   __/ \___  >__|  /____  >
//         \/   \/     \/|__|        \/           \/

// Supply Errors
error ExceedingMaxSupply();

// Allow-list Errors
error ExceedingFoundersListEntitlements();
error ExceedingAllowListMaxMint();

// Withdrawal Errors
error ETHTransferFailed();
error RefundOverpayFailed();

// Minting Errors
error MaxMintPerAddressExceeded();

// Signature Errors
error HashMismatch();
error SignatureMismatch();
error NonceAlreadyUsed();

// Commit-Reveal errors
error AlreadyCommitted();
error NotCommitted();
error AlreadyRevealed();
error TooEarlyForReveal();

// Generic Errors
error ContractPaused();
error IncorrectPrice();
error ContractsNotAllowed();

/// @title Keepers NFT Contract
/// @author Karmabadger
/// @notice This is the main NFT contract for Keepers.
/// @dev This contract is used to mint NFTs for Keepers.
contract KeepersOptimized is ERC721A, ASingleAllowlistMerkle, AMultiFounderslistMerkle {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public constant MAX_SUPPLY = 10000;
    
    uint256 public mintedReservedSupply;
    uint256 public mintedAllowlistSupply;
    uint256 public mintedFounderslistSupply;
    uint256 public mintedPublicSupply;

    uint256 public publicPrice = 0.2 ether;
    
    uint256 public constant MAX_MINT_PER_ADDRESS = 3;
    uint256 public constant MAX_ALLOW_LIST_MINTS = 2;

    uint256 public futureBlockToUse;
    uint256 public tokenIdShift;

    string public baseURI;
    string public hiddenURI;

    string public provenanceHash;

    address public signerAddress;

    bool public paused = true;
    bool public revealed;

    mapping(bytes32 => bool) public nonceUsed;

    // Aux Storage (64 bits) Layout:
    // - [0..1]     `allowListMints`      (how many allow-list mints a wallet performed, up to 3)
    // - [2..17]    `foundersListMints`   (how many founders-list mints a wallet performs; this probably doesn't NEED 16 bits but we have space)
    // - [18..20]   `publicMints`         (how many public mints by a wallet, up to 5 - allowListMints)
    // - [20..63]   (unused)

    /// @notice This is the constructor for the Keepers NFT contract.
    /// @dev sets the default admin role of the contract.
    /// @param _owner the default admin to be set to the contract
    constructor(address _owner, bytes32 _allowlistMerkleRoot, bytes32 _foundersListMerkleRoot, address _signer)
        ERC721A("Keepers", "KPR")
        ASingleAllowlistMerkle(_allowlistMerkleRoot)
        AMultiFounderslistMerkle(_foundersListMerkleRoot)
    {
        transferOwnership(_owner);
        signerAddress = _signer;
    }

    /* Utility Methods */

    function getBits(uint256 _input, uint256 _startBit, uint256 _length) private pure returns (uint256) {
        uint256 bitMask = ((1 << _length) - 1) << _startBit;

        uint256 outBits = _input & bitMask;

        return outBits >> _startBit;
    }

    function getFoundersListMints(address _minter) public view returns (uint256) {
        return getBits(_getAux(_minter), 2, 16);
    }

    function getAllowListMints(address _minter) public view returns (uint256) {
        return getBits(_getAux(_minter), 0, 2);
    }

    function getPublicMints(address _minter) public view returns (uint256) {
        return getBits(_getAux(_minter), 18, 3);
    }

    /* Pausable */

    function setPaused(bool _state) external payable onlyOwner {
        paused = _state;
    }

    /* Signatures */

    function setSignerAddress(address _signer) external onlyOwner {
        signerAddress = _signer;
    }

    /* Pricing */

    function setPublicPrice(uint256 _pubPrice) external onlyOwner {
        publicPrice = _pubPrice;
    }

    /* ETH Withdrawals */

    function ownerPullETH() external onlyOwner {        
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!success) revert ETHTransferFailed();
    }

    /* Minting */

    /// @notice Safely mints NFTs in the reserved supply. Note: These will likely end up hidden on OpenSea
    /// @dev Only the Owner can mint reserved NFTs.
    /// @param _receiver The address of the receiver
    /// @param _amount The quantity to aidrop
    function mintReserved(address _receiver, uint256 _amount) external payable mintCompliance(_amount) onlyOwner {
        mintedReservedSupply += _amount;

        _mint(_receiver, _amount);
    }

    /// @notice Safely mints NFTs from founders list.
    /// @dev free
    function mintFounderslist(bytes32[] calldata _merkleProof, uint16 _entitlementAmount, uint256 _amount) external mintCompliance(_amount) onlyFounderslisted(_merkleProof, _entitlementAmount) whenNotPaused {        
        uint256 foundersListMints = getBits(_getAux(msg.sender), 2, 16);
        if (foundersListMints + _amount > _entitlementAmount) revert ExceedingFoundersListEntitlements();

        mintedFounderslistSupply += _amount;
        _setAux(msg.sender, _getAux(msg.sender) + uint64(_amount << 2));

        _mint(msg.sender, _amount);
    }

    /// @notice Safely mints NFTs from allowlist.
    /// @dev pays the lowest auction price
    function mintAllowlist(bytes32[] calldata _merkleProof, uint256 _amount) external payable mintCompliance(_amount) onlyAllowlisted(_merkleProof) whenNotPaused {
        uint256 totalPrice = publicPrice * _amount;
        if (msg.value != totalPrice) revert IncorrectPrice();

        uint256 allowListMints = getBits(_getAux(msg.sender), 0, 2);
        if (allowListMints + _amount > MAX_ALLOW_LIST_MINTS) revert ExceedingAllowListMaxMint();

        mintedAllowlistSupply += _amount;
        _setAux(msg.sender, _getAux(msg.sender) + uint64(_amount));

        _mint(msg.sender, _amount);
    }

    /// @notice mint function
    /// @param _amount The amount of NFTs to be minted
    /**
     ** @dev the user has to send at least the current price in ETH to buy the NFTs (extras are refunded).
     ** we removed nonReentrant since all external calls are moved to the end.
     ** transfer() only forwards 2300 gas units which garantees no reentrancy.
     ** the optimized mint() function uses _mint() which does not check ERC721Receiver since we do not allow contracts minting.
     ** @dev removed all auction logic, this is now just a flat-rate public mint
     */
    function mintPublic(uint256 _amount, bytes32 _nonce, bytes32 _hash, uint8 v, bytes32 r, bytes32 s) external payable mintCompliance(_amount) whenNotPaused {
        if (tx.origin != msg.sender) revert ContractsNotAllowed();
        
        // https://docs.openzeppelin.com/contracts/2.x/utilities
        if (nonceUsed[_nonce]) revert NonceAlreadyUsed();

        if (_hash != keccak256(
            abi.encodePacked(msg.sender, _nonce, address(this))
        )) revert HashMismatch();

        bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));

        if (signerAddress != ecrecover(messageDigest, v, r, s)) revert SignatureMismatch();

        nonceUsed[_nonce] = true;

        uint256 totalPrice = publicPrice * _amount;
        if (msg.value != totalPrice) revert IncorrectPrice();

        uint256 allowListMints = getBits(_getAux(msg.sender), 0, 2);
        uint256 publicMints = getBits(_getAux(msg.sender), 18, 3);
        if (allowListMints + publicMints + _amount > MAX_MINT_PER_ADDRESS) revert MaxMintPerAddressExceeded();

        mintedPublicSupply += _amount;
        _setAux(msg.sender, _getAux(msg.sender) + uint64(_amount << 18));

        _mint(msg.sender, _amount);
    }

    /* Commit-reveal and metadata */

    // Including all of the Metadata logic here now, as ABaseNFTCommitment and OptimizedERC721 were having some collision issues
    // https://medium.com/@cryptosecgroup/provably-fair-nft-launches-nftgoblins-commit-reveal-scheme-9aaf240bd4ad

    function commit(string calldata _provenanceHash) external payable onlyOwner {
        // Can only commit once
        // Note: A reveal has to happen within 256 blocks or this will break
        if (futureBlockToUse != 0) revert AlreadyCommitted();

        provenanceHash = _provenanceHash;
        futureBlockToUse = block.number + 5;
    }

    function reveal() external payable onlyOwner {
        if (futureBlockToUse == 0) revert NotCommitted();

        if (block.number < futureBlockToUse) revert TooEarlyForReveal();

        if (revealed) revert AlreadyRevealed();

        tokenIdShift = (uint256(blockhash(futureBlockToUse)) % MAX_SUPPLY) + 1;

        revealed = true;
    }

    function setHiddenURI(string memory _hiddenURI) external onlyOwner {
        hiddenURI = _hiddenURI;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (revealed) {
            uint256 shiftedTokenId = (_tokenId + tokenIdShift) % MAX_SUPPLY;

            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, shiftedTokenId.toString(), ".json")) : "";
        }
        else {
            return hiddenURI;
        }
    }

    /* Modifiers */

    modifier whenNotPaused() {
        if (paused) revert ContractPaused();
        _;
    }

    modifier mintCompliance(uint256 _amount) {
        if ((totalSupply() + _amount) > MAX_SUPPLY) revert ExceedingMaxSupply();
        _;
    }
}