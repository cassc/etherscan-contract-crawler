// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract GoonzPortal is ERC721, IERC721Receiver, Ownable, ReentrancyGuard, IERC2981, AccessControl {
    using Strings for uint256;
    event GoonTransported(uint256 indexed tokenId, uint256 indexed worldId);
    event GoonReturned(uint256 indexed tokenId);
    CryptoonGoonz immutable cryptoonGoonzContract;
    uint256 private _mintCounter = 1;

    address public royaltiesAddress;
    uint256 public royaltiesBasisPoints;
    uint256 private constant ROYALTY_DENOMINATOR = 10_000;

    address private _proxyRegistryAddress;
    bool public isOpenSeaProxyActive = true;

    bool public transfersEnabled = true;
    bool public exitingEnabled = true;
    uint256 private preserveTimeTransfer = 1;

    struct World {
        string baseURI;
        bool isOpen;
    }

    struct PassPortal {
        uint64 startTime;
        uint64 totalTime;
        uint64 currentWorldStartTime;
        uint48 aux;
        uint16 currentWorld;
    }

    // world id -> world
    mapping(uint256 => World) private _worlds;
    // token id -> pass portal
    mapping(uint256 => PassPortal) private _passPortals;

    bytes32 public constant AUX_WRITER_ROLE = keccak256("AUX_WRITER_ROLE");

    constructor(
        string memory _initBaseURI,
        address _cryptoonGoonzContract,
        address proxyRegistryAddress,
        address royaltiesAddress_,
        uint256 royaltiesBasisPoints_
    ) ERC721("CryptoonGoonzPortal", "CGP") {
        _worlds[0].baseURI = _initBaseURI;
        royaltiesAddress = royaltiesAddress_;
        _proxyRegistryAddress = proxyRegistryAddress;
        royaltiesBasisPoints = royaltiesBasisPoints_;
        cryptoonGoonzContract = CryptoonGoonz(_cryptoonGoonzContract);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _mintCounter - 1;
    }

    function transportMany(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            cryptoonGoonzContract.safeTransferFrom(msg.sender, address(this), tokenIds[i], "");
        }
    }

    function transportManyWithWorld(uint256[] memory tokenIds, uint256 worldId) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            cryptoonGoonzContract.safeTransferFrom(msg.sender, address(this), tokenIds[i], abi.encode((worldId)));
        }
    }

    function exitMany(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _safeTransfer(msg.sender, address(this), tokenIds[i], "");
        }
    }

    function exitPortal(uint256 tokenId) public {
        _safeTransfer(msg.sender, address(this), tokenId, "");
    }

    function changeWorlds(uint256[] memory tokenIds, uint256 worldId) public {
        require(_worlds[worldId].isOpen, "world is not open currently");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_passPortals[tokenIds[i]].currentWorld != worldId, "already in this world");
            _passPortals[tokenIds[i]].currentWorld = uint16(worldId);
            _passPortals[tokenIds[i]].currentWorldStartTime = uint64(block.timestamp);
            emit GoonTransported(tokenIds[i], worldId);
        }
    }

    function passPortalInfo(uint256 tokenId)
        external
        view
        returns (
            uint256 worldCurrent,
            uint256 current,
            uint256 total
        )
    {
        require(_exists(tokenId), "nonexistent token id");
        PassPortal memory passportal = _passPortals[tokenId];
        worldCurrent = passportal.currentWorldStartTime <= 1
            ? 0
            : uint256(block.timestamp - passportal.currentWorldStartTime);
        current = passportal.startTime <= 1 ? 0 : uint256(block.timestamp - passportal.startTime);
        total = uint256(current + passportal.totalTime);
    }

    function worlds(uint256 worldId)
        public
        view
        returns (
            uint256 id,
            string memory baseURI,
            bool isOpen
        )
    {
        id = worldId;
        World memory world = _worlds[id];
        baseURI = world.baseURI;
        isOpen = world.isOpen;
    }

    function currentWorld(uint256 tokenId)
        public
        view
        returns (
            uint256 id,
            string memory baseURI,
            bool isOpen
        )
    {
        require(_exists(tokenId), "nonexistent token id");
        return worlds(_passPortals[tokenId].currentWorld);
    }

    function upsertWorld(uint256 worldId, string memory baseURI) external onlyOwner {
        _worlds[worldId].baseURI = baseURI;
    }

    function toggleWorldOpen(uint256 worldId) external onlyOwner {
        require(bytes(_worlds[worldId].baseURI).length > 0, "World hasn't been created yet");
        World storage world = _worlds[worldId];
        world.isOpen = !world.isOpen;
    }

    /**
     * @dev To disable OpenSea gasless listings proxy in case of an issue
     */
    function toggleOpenSeaActive() external onlyOwner {
        isOpenSeaProxyActive = !isOpenSeaProxyActive;
    }

    function toggleTransfersEnabled() external onlyOwner {
        transfersEnabled = !transfersEnabled;
    }

    function toggleExitingEnabled() external onlyOwner {
        exitingEnabled = !exitingEnabled;
    }

    function safeTransferPreserveTime(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(to != address(this), "can't exit the portal");
        preserveTimeTransfer = 2;
        safeTransferFrom(from, to, tokenId);
        preserveTimeTransfer = 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint256 worldId = _passPortals[tokenId].currentWorld;
        World memory world = _worlds[worldId];
        return
            bytes(world.baseURI).length > 0 ? string(abi.encodePacked(world.baseURI, tokenId.toString(), ".json")) : "";
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        uint256 i = 0;
        for (uint256 tokenId = 1; tokenId <= 6969; tokenId++) {
            if (!_exists(tokenId)) {
                continue;
            }
            if (ownerTokenCount == i) {
                break;
            }
            if (ownerOf(tokenId) == _owner) {
                tokenIds[i] = tokenId;
                i++;
            }
        }
        return tokenIds;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        revert();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, AccessControl, ERC721)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @notice enable OpenSea gasless listings
     * @dev Overriding `isApprovedForAll` to allowlist user's OpenSea proxy accounts
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        if (isOpenSeaProxyActive && address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function setRoyaltiesAddress(address _royaltiesAddress) external onlyOwner {
        royaltiesAddress = _royaltiesAddress;
    }

    function setRoyaltiesBasisPoints(uint256 _royaltiesBasisPoints) external onlyOwner {
        require(_royaltiesBasisPoints < royaltiesBasisPoints, "New royalty amount must be lower");
        royaltiesBasisPoints = _royaltiesBasisPoints;
    }

    function setAux(uint256 tokenId, uint48 newAux) external onlyRole(AUX_WRITER_ROLE) {
        _passPortals[tokenId].aux = newAux;
    }

    function getAux(uint256 tokenId) external view returns (uint256) {
        return uint256(_passPortals[tokenId].aux);
    }

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Non-existent token");
        return (royaltiesAddress, (salePrice * royaltiesBasisPoints) / ROYALTY_DENOMINATOR);
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override nonReentrant returns (bytes4) {
        require(
            msg.sender == address(cryptoonGoonzContract) || msg.sender == address(this),
            "Operator not Cryptoon Goonz or Goonz Portal contract"
        );

        bool enteringPortal = msg.sender == address(cryptoonGoonzContract);
        if (enteringPortal) {
            // validate that it can decode properly
            uint256 worldId = data.length > 0 ? abi.decode(data, (uint256)) : 0;
            require(_worlds[worldId].isOpen, "world is not open currently");
            if (_passPortals[tokenId].currentWorld != worldId) {
                unchecked {
                    _passPortals[tokenId].currentWorld = uint16(worldId);
                }
            }

            if (_exists(tokenId)) {
                _safeTransfer(address(this), from, tokenId, "");
            } else {
                _safeMint(from, tokenId);
                _mintCounter++;
            }
            emit GoonTransported(tokenId, worldId);
        } else {
            require(exitingEnabled, "exiting not allowed right now");
            cryptoonGoonzContract.safeTransferFrom(address(this), from, tokenId, "");
            emit GoonReturned(tokenId);
        }

        return this.onERC721Received.selector;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        unchecked {
            // enter the portal
            if (from == address(this) || from == address(0)) {
                _passPortals[tokenId].currentWorldStartTime = uint64(block.timestamp);
                _passPortals[tokenId].startTime = uint64(block.timestamp);
                // exit the portal
            } else if (to == address(this)) {
                _passPortals[tokenId].currentWorldStartTime = 1;
                _passPortals[tokenId].totalTime += uint64(block.timestamp - _passPortals[tokenId].startTime);
                _passPortals[tokenId].startTime = 1;
                // transfer/sell your NFT
            } else {
                if (preserveTimeTransfer == 1) {
                    require(transfersEnabled, "Traveling the gooniverse");
                    _passPortals[tokenId].currentWorldStartTime = uint64(block.timestamp);
                    _passPortals[tokenId].totalTime += uint64(block.timestamp - _passPortals[tokenId].startTime);
                    _passPortals[tokenId].startTime = uint64(block.timestamp);
                }
            }
        }
    }
}

interface CryptoonGoonz {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}