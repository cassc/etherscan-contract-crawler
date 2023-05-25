// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title: Hedz
/// @notice: https://www.hedz.fun
/// @author ediv <https://github.com/ed-iv>

//////////////////////////////////////////////////
//    __    __  ________  _______   ________    //
//   /  |  /  |/        |/       \ /        |   //
//   $$ |  $$ |$$$$$$$$/ $$$$$$$  |$$$$$$$$/    //
//   $$ |__$$ |$$ |__    $$ |  $$ |    /$$/     //
//   $$    $$ |$$    |   $$ |  $$ |   /$$/      //
//   $$$$$$$$ |$$$$$/    $$ |  $$ |  /$$/       // 
//   $$ |  $$ |$$ |_____ $$ |__$$ | /$$/____    //
//   $$ |  $$ |$$       |$$    $$/ /$$      |   //
//   $$/   $$/ $$$$$$$$/ $$$$$$$/  $$$$$$$$/    //
//                                              //
//////////////////////////////////////////////////
//        Matt Furie x Chain/Saw 2022           //
//////////////////////////////////////////////////
                                        
import "./Revelator.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "erc721a/contracts/ERC721A.sol";

enum MintPhase {
    Paused,
    Collectors,
    Community,
    Public
}

error AlreadyClaimed();
error AlreadyRevealed();
error IncorrectMintPhase();
error IncorrectMintPrice();
error InvalidMintPhase();
error InvalidProof();
error MerkleRootNotSet();
error MetadataFrozen();
error OutOfHedz();
error TooManyHedz();

contract Hedz is ERC721A, Ownable, Revelator {
    using BitMaps for BitMaps.BitMap;
    using Strings for uint256;
    
    uint256 constant HEDZ_SUPPLY = 1000;
    uint256 constant MINT_PRICE = 0.666 ether;
    uint256 constant PUB_MINT_LIMIT = 3;
    bool public metadataFrozen = false;
    MintPhase public mintPhase = MintPhase.Paused;
    string baseTokenURI;
    mapping(MintPhase => bytes32) public merkleRoots;    
    mapping(bytes32 => BitMaps.BitMap) private _claimed;

    constructor(
        string memory _baseTokenURI,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,            
        bytes32 _merkleRoot
    ) ERC721A("Hedz", "HEDZ") Revelator(_vrfCoordinator, _keyHash, _subscriptionId) {
        baseTokenURI = _baseTokenURI;
        merkleRoots[MintPhase.Collectors] = _merkleRoot;
    }

    modifier whileSuppliesLast(uint256 amount) {
        if (_totalMinted() + amount > HEDZ_SUPPLY) revert OutOfHedz();
        if (msg.value != amount * MINT_PRICE) revert IncorrectMintPrice();
        _;
    }

    /// @notice Allows whitelisted minters to mint up to amountAllocated during various phases of mint.
    function preMint(
        uint256 index, 
        bytes32[] calldata proof, 
        uint256 amountAllocated, 
        uint256 amountRequested
    ) external payable whileSuppliesLast(amountRequested) {        
        if (mintPhase != MintPhase.Collectors && mintPhase != MintPhase.Community) revert IncorrectMintPhase();
        bytes32 merkleRoot = merkleRoots[mintPhase];
        if (_claimed[merkleRoot].get(index)) revert AlreadyClaimed();

        bytes32 node = keccak256(abi.encodePacked(msg.sender, index, amountAllocated));        
        if (!MerkleProof.verify(proof, merkleRoot, node)) revert InvalidProof();
        if (amountRequested > amountAllocated) revert TooManyHedz();
            
        _claimed[merkleRoot].set(index);
        _safeMint(msg.sender, amountRequested);
    }

    /// @notice Mint some Hedz. Limited to 3 per transaction while supplies last.
    function mint(uint256 amount) external payable whileSuppliesLast(amount) {        
        if (mintPhase != MintPhase.Public) revert IncorrectMintPhase();
        if (amount > PUB_MINT_LIMIT) revert TooManyHedz();        
        _safeMint(msg.sender, amount);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (revealed) {
            uint256 metaIndex = 1 + ((tokenId + metaOffset) % 1000);            
            return string(abi.encodePacked(baseTokenURI, "/", metaIndex.toString(),".json"));
        }
        return string(abi.encodePacked(baseTokenURI, "/placeholder.json"));
    }

    /// @notice Check whether address with specified index has already minted during _mintPhase
    function isClaimed(MintPhase _mintPhase, uint256 index) external view returns (bool) {
        bytes32 merkleRoot = merkleRoots[_mintPhase];
        return _claimed[merkleRoot].get(index);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Owner stuff:

    function setBaseTokenURI(string calldata _baseTokenURI) external onlyOwner {
        if (metadataFrozen) revert MetadataFrozen();
        baseTokenURI = _baseTokenURI;
    }

    /// @notice Irrevocably freeze metadata. 
    function freezeMetadata() external onlyOwner {
        metadataFrozen = true;
    }

    /// @notice Set merkle root for specified mint phase.
    function setMerkleRoot(MintPhase _mintPhase, bytes32 merkleRoot) external onlyOwner {
        if (_mintPhase != MintPhase.Collectors && _mintPhase != MintPhase.Community)
            revert InvalidMintPhase();
        merkleRoots[_mintPhase] = merkleRoot;
    }

    /// @notice Change the current mint phase.
    /// @dev Switching to a whitelisted mint phase requires that a valid (non-zero) merkle root is set .
    function setMintPhase(MintPhase _mintPhase) external onlyOwner {
        if (_mintPhase == MintPhase.Collectors && merkleRoots[MintPhase.Collectors] == 0x0)
            revert MerkleRootNotSet();
        if (_mintPhase == MintPhase.Community && merkleRoots[MintPhase.Community] == 0x0)
            revert MerkleRootNotSet();
        mintPhase = _mintPhase;
    }

    /// @notice Randomize and reveal Hedz. Any unmited Hedz will be minted to contract owner.
    function reveal() external onlyOwner {
        if (revealed) revert AlreadyRevealed();
        uint256 leftOvers = HEDZ_SUPPLY - _totalMinted();
        if (leftOvers > 0) _safeMint(owner(), leftOvers);
        _reveal();
    }

    /// @notice Manually toggle reveal status. For use in case of fuck-ups w/ random reveal or metadata.
    function toggleReveal() external onlyOwner {
        revealed = !revealed;
    }

    /// @notice Adjust ChainLink Coordinator parameters.
    function setCoordinatorConfig(
        address _vrfCoordinator, 
        bytes32 _keyHash,
        uint64 _subscriptionId,        
        uint32 _gasCallbackLimit
    ) external onlyOwner {
        _setCoordinatorConfig(_vrfCoordinator, _keyHash, _subscriptionId, _gasCallbackLimit);
    }

    /// @notice Get that Hedz money.
    function withdraw() public onlyOwner {
	    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
	}

    // Overrides:

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}