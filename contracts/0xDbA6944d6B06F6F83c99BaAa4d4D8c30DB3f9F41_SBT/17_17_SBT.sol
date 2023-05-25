// SPDX-License-Identifier: MIT
/**
 _____
/  __ \
| /  \/ ___  _ ____   _____ _ __ __ _  ___ _ __   ___ ___
| |    / _ \| '_ \ \ / / _ \ '__/ _` |/ _ \ '_ \ / __/ _ \
| \__/\ (_) | | | \ V /  __/ | | (_| |  __/ | | | (_|  __/
 \____/\___/|_| |_|\_/ \___|_|  \__, |\___|_| |_|\___\___|
                                 __/ |
                                |___/
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

import "../interfaces/IERC5484.sol";

contract SBT is ERC721Enumerable, Ownable, IERC5484 {
    /// @dev Enum about State Mint
    enum State {
        COMMUNITY,
        CVG
    }
    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            STORAGE
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */

    /// @dev State Mint
    State public state;

    /// @dev init first tokenId
    uint256 public nextTokenId = 1;

    bytes32 internal convergenceId = 0x434f4e56455247454e4345000000000000000000000000000000000000000000; //CONVERGENCE

    string internal baseURI;

    /// @dev Default Burn authentification
    BurnAuth public constant DEFAULT_BURN_AUTH = BurnAuth.OwnerOnly;

    /// @dev CommunityId associated to his data
    mapping(bytes32 => bytes32) public communityMerkleRoot; // communityId => merkleRoot

    /// @dev TokenId associated to his communityId
    mapping(uint256 => bytes32) public tokenCommunity; // tokenId => communityId

    /// @dev Address associated to the boolean minted
    mapping(address => bool) public minted; // address => already minted

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            CONSTRUCTOR
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */

    constructor(string memory _uri) ERC721("Convergence OG", "ogCVG") {
        baseURI = _uri;
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            INTERNALS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            EXTERNALS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */

    /**
     * @notice Mint a community SBT only for whitelisted users
     * @param _communityId targeted in hex bytes32
     * @param _merkleProof proof generated with the merkle tree in bytes32[]
     */
    function mint(bytes32 _communityId, bytes32[] calldata _merkleProof) external {
        require(state == State.COMMUNITY, "MINT_COMMUNITY_UNAVAILABLE");
        /// @dev check if already minted
        require(!minted[msg.sender], "ALREADY_MINTED");

        /// @dev get leaf from the msg.sender
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
        /// @dev get merkleRoot from the communityId
        bytes32 _merkleRoot = communityMerkleRoot[_communityId];
        /// @dev check the given proof with the merkleRoot
        require(MerkleProof.verify(_merkleProof, _merkleRoot, _leaf), "INVALID_PROOF");

        uint256 _nextTokenId = nextTokenId;
        tokenCommunity[_nextTokenId] = _communityId;

        /// @dev update bool minted for this user
        minted[msg.sender] = true;

        /// @dev mint tokenId to the user
        _mint(msg.sender, _nextTokenId);

        emit Issued(address(0), msg.sender, nextTokenId++, DEFAULT_BURN_AUTH);
    }

    function mintConvergence() external {
        require(state == State.CVG, "MINT_CVG_UNAVAILABLE");
        /// @dev check if already minted
        require(!minted[msg.sender], "ALREADY_MINTED");

        uint256 _nextTokenId = nextTokenId;
        tokenCommunity[_nextTokenId] = convergenceId; //CONVERGENCE

        /// @dev update bool minted for this user
        minted[msg.sender] = true;

        /// @dev mint tokenId to the user
        _mint(msg.sender, _nextTokenId);

        emit Issued(address(0), msg.sender, nextTokenId++, DEFAULT_BURN_AUTH);
    }

    /**
     * @notice Burn definitively an owned SBT
     * @param tokenId to burn
     */
    function burn(uint256 tokenId) external {
        /// @dev Check ownership of the tokenId
        require(ownerOf(tokenId) == msg.sender, "NOT_OWNER");
        /// @dev Burn tokenId
        _burn(tokenId);
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            GETTERS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    /// @notice method to get token URI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return string(abi.encodePacked(_baseURI(), bytes32ToString(tokenCommunity[tokenId])));
    }

    /// @notice method to get the burn authentification for an tokenId
    function burnAuth(uint256 tokenId) external view override returns (BurnAuth) {
        _requireMinted(tokenId);
        return DEFAULT_BURN_AUTH;
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            INTERNALS
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    /// @notice Overrided transfer that revert systematically
    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        revert("ERC5484: NON_TRANSFERABLE");
    }

    /* =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=
                            ONLYOWNER
    =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-= */
    /// @notice Set community roots
    function setCommunityRoots(bytes32[] calldata _communityIds, bytes32[] calldata _merkleRoots) external onlyOwner {
        uint256 len = _communityIds.length;
        require(len == _merkleRoots.length, "ERROR_LENGTH");
        for (uint256 i; i < len; ) {
            communityMerkleRoot[_communityIds[i]] = _merkleRoots[i];

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Set base URI for all communities
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /// @notice Set State of Mint
    function setState(State _state) external onlyOwner {
        state = _state;
    }
}