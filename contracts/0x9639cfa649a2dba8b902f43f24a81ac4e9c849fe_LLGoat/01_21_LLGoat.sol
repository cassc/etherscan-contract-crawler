//  _                    _      _             _
// | |                  | |    | |           | |
// | |      ___    ___  | | __ | |      __ _ | |__   ___
// | |     / _ \  / _ \ | |/ / | |     / _` || '_ \ / __|
// | |____| (_) || (_) ||   <  | |____| (_| || |_) |\__ \
// \_____/ \___/  \___/ |_|\_\ \_____/ \__,_||_.__/ |___/
//
//
// Goat
//
// by LOOK LABS
//
// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error VerifyFailed();
error Claimed();
error InvalidType();
error InvalidAmount();

contract LLGoat is ERC721AQueryable, ERC721ABurnable, Pausable, Ownable, ReentrancyGuard {
    string public constant NAME = "LOOK LABS GOATS PFP";
    string public constant SYMBOL = "GOAT";
    string private _baseTokenURI;
    bytes32[] public merkleRoots;

    mapping(address => bool) public claimed;

    /* ==================== EVENTS ==================== */

    event Mint(address indexed _to, uint256 _startId, uint256 _ogQty, uint256 _nonOgQty);
    event VaultMint(address indexed _to, uint256 _qty);
    event SetMerkleRoot(bytes32[] _roots);

    /* ==================== METHODS ==================== */

    constructor(string memory _uri, bytes32[] memory _roots) ERC721A(NAME, SYMBOL) {
        _baseTokenURI = _uri;
        merkleRoots = _roots;

        _pause();
    }

    function mint(
        bytes32[] memory _ogProof,
        uint256 _ogQty,
        bytes32[] memory _nonOgProof,
        uint256 _nonOgQty
    ) external nonReentrant whenNotPaused {
        if (claimed[_msgSender()]) revert Claimed();

        uint256 qty = 0;
        if (_ogQty != 0) {
            bytes32 node = keccak256(abi.encodePacked(_msgSender(), _ogQty));
            if (!MerkleProof.verify(_ogProof, merkleRoots[0], node)) revert VerifyFailed();
            qty = _ogQty;
        }

        if (_nonOgQty != 0) {
            bytes32 node = keccak256(abi.encodePacked(_msgSender(), _nonOgQty));
            if (!MerkleProof.verify(_nonOgProof, merkleRoots[1], node)) revert VerifyFailed();
            qty += _nonOgQty;
        }

        claimed[_msgSender()] = true;
        emit Mint(_msgSender(), _nextTokenId(), _ogQty, _nonOgQty);

        if (qty != 0) {
            _safeMint(_msgSender(), qty);
        }
    }

    /* ==================== INTERNAL METHODS ==================== */

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /* ==================== GETTER METHODS ==================== */
    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    /* ==================== OWNER METHODS ==================== */

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setBaseURI(string memory _baseURIParam) external onlyOwner {
        _baseTokenURI = _baseURIParam;
    }

    function setMerkleRoot(bytes32[] memory _roots) external onlyOwner {
        merkleRoots = _roots;

        emit SetMerkleRoot(_roots);
    }

    function updateStatus(address[] memory _who, bool[] memory _status) external onlyOwner {
        uint256 length = _who.length;
        for (uint256 i = 0; i < length; ) {
            address _to = _who[i];
            claimed[_to] = _status[i];

            unchecked {
                ++i;
            }
        }
    }

    function vaultMint(address _to, uint256 _qty) external onlyOwner {
        _safeMint(_to, _qty);

        emit VaultMint(_to, _qty);
    }
}