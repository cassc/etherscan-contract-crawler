//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title X-Gals
 * @author XiNG YUNJiA
 *
 * XTENDED iDENTiTY Projects - X-Gals
 */
contract XGals is ERC2981, Ownable, ReentrancyGuard, ERC721AQueryable {
    using ECDSA for bytes32;
    /* ============ Events ============= */
    event PausedStateUpdated(bool indexed _isPaused);
    event MintWithMetadata(
        address indexed _to,
        uint256 indexed _tokenId,
        bytes32 indexed _mintHash
    );

    /* ============ Modifiers ============ */
    /**
     * Throws if the sender is not a EOA wallet
     */
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Only EOA wallets can mint");
        _;
    }

    /* ============ State Variables ============ */
    // is mint paused
    bool public isPause = false;
    // metadata URI
    string private _baseTokenURI;
    // signer for verifying signatures
    address public signer;
    // mint record
    mapping(bytes32 => bool) public mintRecord;

    /* ============ Constructor ============ */

    constructor() ERC721A("X-Gals", "X-Gals") {}

    /* ============ External Functions ============ */
    function mint(
        address _to,
        bytes32 _mintHash,
        bytes calldata _signature
    ) external payable onlyEOA nonReentrant {
        require(mintRecord[_mintHash] == false, "Already minted");
        require(verify(_mintHash, _signature), "Invalid signature");

        mintRecord[_mintHash] = true;

        emit MintWithMetadata(_to, _nextTokenId(), _mintHash);

        _mint(_to, 1);
    }

    function verify(bytes32 _hash, bytes memory _signature)
        internal
        view
        returns (bool)
    {
        return _hash.toEthSignedMessageHash().recover(_signature) == signer;
    }

    function setPause() external onlyOwner {
        isPause = !isPause;
        emit PausedStateUpdated(isPause);
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /* ============ External Getter Functions ============ */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}