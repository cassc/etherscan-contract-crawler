// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Owned} from "solmate/src/auth/Owned.sol";
import {ReentrancyGuard} from "solmate/src/utils/ReentrancyGuard.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {LibBitmap} from "solady/src/utils/LibBitmap.sol";
import {MerkleProofLib} from "solady/src/utils/MerkleProofLib.sol";

contract WhosJi is ERC721A, Owned(msg.sender), ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                        VARIABLES & MAPPINGS
    //////////////////////////////////////////////////////////////*/

    //Used to control paused status for different functions on the contract.
    using LibBitmap for LibBitmap.Bitmap;

    LibBitmap.Bitmap bitmap;

    //General purpose variables for different functions on the contract.
    uint256 public constant PRICE = 0.033 ether;
    uint256 public constant MAX_MINT = 3;
    uint256 public constant MAX_SUPPLY = 5555;

    uint256 private constant _MAX_MINT_OG = 1;
    uint256 private constant _AVAILABLE_WHITELIST = 2777;
    uint256 private constant _PAUSE_PUBLIC_INDEX = 1;
    uint256 private constant _PAUSE_OG_INDEX = 2;
    uint256 private constant _PAUSE_WHITELIST_INDEX = 3;
    uint256 private constant _TOGGLE_URI_INDEX = 4;
    uint64 private constant _SET_AUX = 1;
    string private _tokenURI;
    string private _unrevealedURI;

    //Merkle root for Whitelist mints.
    bytes32 public immutable merkleRootWL;
    //Merkle root for OG mints
    bytes32 public immutable merkleRootOG;

    /*//////////////////////////////////////////////////////////////
                            MINT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function mintPublic(uint256 amount)
        external
        payable
        nonReentrant
        callerIsUser
        requireMintablePublic(MAX_MINT, amount, msg.sender)
        requireExactPrice(amount)
    {
        _mint(msg.sender, amount);
    }

    //One time claim for OG addresses
    //No need to check for exact price because the merkleTree already checks this.
    function mintOG(bytes32[] calldata proof)
        external
        payable
        nonReentrant
        requireProof(merkleRootOG, proof, msg.sender, _MAX_MINT_OG)
        requireMintableOji(msg.sender, _MAX_MINT_OG)
        requireExactPrice(_MAX_MINT_OG)
    {
        _mint(msg.sender, _MAX_MINT_OG);
    }

    //One time claim for Whitelisted addresses
    function mintWhitelist(uint256 amount, bytes32[] calldata proof)
        external
        payable
        nonReentrant
        requireProof(merkleRootWL, proof, msg.sender, amount)
        requireMintableWhitelist(msg.sender, amount)
    {
        _setAux(msg.sender, _SET_AUX);
        _mint(msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    //Sorry gnosis users.
    modifier callerIsUser() {
        require(msg.sender == tx.origin, "NO_CONTRACTS");
        _;
    }

    modifier requireProof(
        bytes32 root,
        bytes32[] calldata proof,
        address addy,
        uint256 amount
    ) {
        //Validades proof from expected leaf and root.
        require(
            MerkleProofLib.verify(
                proof,
                root,
                keccak256(abi.encodePacked(addy, amount))
            ),
            "INVALID_PROOF"
        );
        _;
    }

    //Max mint check and max public supply check.
    modifier requireMintablePublic(
        uint256 maxMint,
        uint256 quantity,
        address addy
    ) {
        unchecked {
            require(LibBitmap.get(bitmap, _PAUSE_PUBLIC_INDEX), "PUBLIC_PAUSE");
            require(
                quantity + _numberMinted(addy) <= maxMint,
                "MAX_MINT_PUBLIC"
            );
            require(
                _totalMinted() + quantity + _AVAILABLE_WHITELIST <= MAX_SUPPLY,
                "MAX_SUPPLY_PUBLIC"
            );
        }
        _;
    }

    //Max public supply check. No need to check for max mint since if validated on the mintOG function.
    modifier requireMintableOji(address addy, uint256 quantity) {
        unchecked {
            require(LibBitmap.get(bitmap, _PAUSE_OG_INDEX), "OG_PAUSE");
            require(
                quantity + _numberMinted(addy) <= _MAX_MINT_OG,
                "MAX_MINT_OG"
            );
            require(
                _totalMinted() + quantity + _AVAILABLE_WHITELIST <= MAX_SUPPLY,
                "MAX_SUPPLY_OG"
            );
        }
        _;
    }

    //Max supply check. No need to check for max mint since if validated on the mintWhitelist function.
    modifier requireMintableWhitelist(address addy, uint256 amount) {
        //Uses the getAux provided by ERC721A to check if the address has minted or not.
        require(_getAux(addy) == 0, "MAX_MINT");
        require(LibBitmap.get(bitmap, _PAUSE_WHITELIST_INDEX), "WL_PAUSED");
        unchecked {
            require(_totalMinted() + amount <= MAX_SUPPLY, "MAX_SUPPLY");
        }
        _;
    }

    //msg.value must match the calculated amount.
    modifier requireExactPrice(uint256 quantity) {
        require(msg.value == PRICE * quantity, "INVALID_PRICE");
        _;
    }

    //Helper function to see the amount available for public.
    function availableMintsForPublic() external view returns (uint256) {
        return MAX_SUPPLY - (_totalMinted() + _AVAILABLE_WHITELIST);
    }

    //Helper function to see the different paused states.
    function getPausedStatus(uint256 pauseId) external view returns (bool) {
        return LibBitmap.get(bitmap, pauseId);
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function withdraw() external payable onlyOwner {
        SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
    }

    //Index 1 - Controls public mint,
    //Index 2 - Controls og mint,
    //Index 3 - Controls whitelist mint,
    //Index 4 - Controls metadata reveal,
    function tooglePauseState(uint256 index) external onlyOwner {
        LibBitmap.toggle(bitmap, index);
    }

    //Gated at max supply.
    function adminMint(uint256 amount) external payable onlyOwner {
        unchecked {
            require(amount + _totalMinted() <= MAX_SUPPLY, "MAX_SUPPLY");
        }

        _mint(msg.sender, amount);
    }

    function setTokenURI(string calldata tokenURI_) external onlyOwner {
        _tokenURI = tokenURI_;
    }

    function setUnrevealedURI(string calldata unrevealedURI_)
        external
        onlyOwner
    {
        _unrevealedURI = unrevealedURI_;
    }

    /*//////////////////////////////////////////////////////////////
                        METADATA FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    //Saves gas for first minter.
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        require(_exists(tokenId), "URIQueryForNonexistentToken");

        if (!LibBitmap.get(bitmap, _TOGGLE_URI_INDEX)) {
            return _unrevealedURI;
        }

        return string.concat(_tokenURI, _toString(tokenId));
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory unrevealedURI_,
        // Mint config:
        bytes32 _merkleRootWL,
        bytes32 _merkleRootOG
    ) ERC721A("WhosjiLabs", "WhosjiLabs") {
        _unrevealedURI = unrevealedURI_;
        merkleRootWL = _merkleRootWL;
        merkleRootOG = _merkleRootOG;
    }
}