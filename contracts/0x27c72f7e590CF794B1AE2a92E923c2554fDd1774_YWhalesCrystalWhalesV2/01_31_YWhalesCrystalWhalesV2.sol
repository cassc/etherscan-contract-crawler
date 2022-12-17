// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract YWhalesCrystalWhalesV2 is
    Initializable,
    ERC721Upgradeable,
    ERC721BurnableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    mapping(uint256 => uint16) public TOKEN_ID_TO_WHALE_TYPE;
    mapping(address => bool) public hasClaimed;
    bytes32 public merkleRoot;
    string public baseURI;
    uint16 MEMBER_WHALE_TYPE;
    uint16 BOARD_MEMBER_WHALE_TYPE;
    uint16 ADVISOR_WHALE_TYPE;
    uint16 INVESTOR_WHALE_TYPE;
    uint16 STAFF_WHALE_TYPE;
    uint16 EXPERT_WHALE_TYPE;
    uint16 VIP_WHALE_TYPE;
    uint16 OCULUS_WHALE_TYPE;
    bool public HAS_OCULUS_WHALE_BEEN_DISTRIBUTED;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(bytes32 _merkleRoot) public initializer {
        __ERC721_init("CrystalWhalesV2", "YWHALES");
        __ERC721Burnable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        baseURI = "https://tomato-capitalist-mollusk-258.mypinata.cloud/ipfs/QmTCPfeDamia7DfeMuD57zNKbB9HYzibcZarHM1UZcgdS7/";
        MEMBER_WHALE_TYPE = 0;
        BOARD_MEMBER_WHALE_TYPE = 1;
        ADVISOR_WHALE_TYPE = 2;
        INVESTOR_WHALE_TYPE = 3;
        STAFF_WHALE_TYPE = 4;
        EXPERT_WHALE_TYPE = 5;
        VIP_WHALE_TYPE = 6;
        OCULUS_WHALE_TYPE = 7;
        HAS_OCULUS_WHALE_BEEN_DISTRIBUTED = false;

        merkleRoot = _merkleRoot;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _setBaseURI(string memory _uri) internal {
        baseURI = _uri;
    }

    function setMerkleRoot(bytes32 _merkleRoot)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string memory _uri)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setBaseURI(_uri);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    Strings.toString(TOKEN_ID_TO_WHALE_TYPE[_tokenId]),
                    ".json"
                )
            );
    }

    function _mint(address _to) internal returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_to, tokenId);
        return tokenId;
    }

    function claim(
        bytes32[] calldata merkleProof,
        address _to,
        bytes32 data,
        uint16[] calldata _whaleTypes
    ) external {
        require(
            !hasClaimed[_to],
            "YWhalesCrystalWhalesV2: Address already claimed"
        );

        require(
            MerkleProof.verify(merkleProof, merkleRoot, data),
            "YWhalesCrystalWhalesV2: Invalid proof."
        );

        hasClaimed[_to] = true;

        _mintWhales(_to, _whaleTypes);
    }

    function _mintWhales(address _to, uint16[] memory _whaleTypes) internal {
        for (uint256 i = 0; i < _whaleTypes.length; i++) {
            if (_whaleTypes[i] == OCULUS_WHALE_TYPE) {
                require(
                    !HAS_OCULUS_WHALE_BEEN_DISTRIBUTED,
                    "YWhalesCrystalWhalesV2: Oculus whale has already been distributed"
                );
                HAS_OCULUS_WHALE_BEEN_DISTRIBUTED = true;
            }
            uint256 tokenId = _mint(_to);
            TOKEN_ID_TO_WHALE_TYPE[tokenId] = _whaleTypes[i];
        }
    }

    function balanceOf(address _addr) public view override returns (uint256) {
        return super.balanceOf(_addr);
    }

    function airdrop(
        address[] memory _memberAddresses,
        address[] memory _boardMemberAddresses,
        address[] memory _advisorAddresses,
        address[] memory _investorAddresses,
        address[] memory _staffAddresses,
        address[] memory _expertAddresses,
        address[] memory _vipAddresses,
        address _oculusAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _memberAddresses.length; i++) {
            uint256 tokenId = _mint(_memberAddresses[i]);
            TOKEN_ID_TO_WHALE_TYPE[tokenId] = 0;
        }

        for (uint256 i = 0; i < _boardMemberAddresses.length; i++) {
            uint256 tokenId = _mint(_boardMemberAddresses[i]);
            TOKEN_ID_TO_WHALE_TYPE[tokenId] = 1;
        }

        for (uint256 i = 0; i < _advisorAddresses.length; i++) {
            uint256 tokenId = _mint(_advisorAddresses[i]);
            TOKEN_ID_TO_WHALE_TYPE[tokenId] = 2;
        }

        for (uint256 i = 0; i < _investorAddresses.length; i++) {
            uint256 tokenId = _mint(_investorAddresses[i]);
            TOKEN_ID_TO_WHALE_TYPE[tokenId] = 3;
        }

        for (uint256 i = 0; i < _staffAddresses.length; i++) {
            uint256 tokenId = _mint(_staffAddresses[i]);
            TOKEN_ID_TO_WHALE_TYPE[tokenId] = 4;
        }

        for (uint256 i = 0; i < _expertAddresses.length; i++) {
            uint256 tokenId = _mint(_expertAddresses[i]);
            TOKEN_ID_TO_WHALE_TYPE[tokenId] = 5;
        }

        for (uint256 i = 0; i < _vipAddresses.length; i++) {
            uint256 tokenId = _mint(_vipAddresses[i]);
            TOKEN_ID_TO_WHALE_TYPE[tokenId] = 6;
        }

        if (!HAS_OCULUS_WHALE_BEEN_DISTRIBUTED && _oculusAddress != address(0)) {
            uint256 tokenId = _mint(_oculusAddress);
            TOKEN_ID_TO_WHALE_TYPE[tokenId] = 7;
            HAS_OCULUS_WHALE_BEEN_DISTRIBUTED = true;
        }
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function withdraw(address _to)
        external
        payable
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        payable(_to).transfer(address(this).balance);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function bulkTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds
    ) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }
}