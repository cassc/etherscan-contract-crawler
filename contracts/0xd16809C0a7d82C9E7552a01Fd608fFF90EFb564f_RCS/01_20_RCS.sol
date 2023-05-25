// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Errors.sol";
import "./MagicNumbers.sol";
import "./Base64.sol";
import "./Ownable.sol";

import "@divergencetech/ethier/contracts/utils/DynamicBuffer.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title RCS
/// @author @0x__jj, @llio (Deca)
contract RCS is ERC721, ReentrancyGuard, AccessControl, Ownable, MagicNumbers {
    using Address for address;
    using DynamicBuffer for bytes;

    mapping(address => bool) public minted;
    mapping(uint256 => uint256) public expiryTime;
    mapping(uint256 => string) public colours;

    string public _name_;
    string public _description;
    string public _attribute;

    uint256 public totalSupply = 0;
    bool public attestationEnabled = false;

    uint256 public constant MAX_SUPPLY = 1025;
    uint256 public constant ONE_YEAR = 60 * 60 * 24 * 365;

    bytes32 public merkleRoot;

    event Mint(uint256 indexed tokenId, address indexed minter);

    constructor(
        string memory name_,
        string memory description_,
        string memory attribute_,
        address[] memory admins_
    ) ERC721("RCS", "RCS") {
        _setOwnership(msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        for (uint256 i = 0; i < admins_.length; i++) {
            _grantRole(DEFAULT_ADMIN_ROLE, admins_[i]);
        }

        colours[0] = "ffffff";
        colours[1] = "ffffff";
        colours[2] = "ffffff";
        colours[3] = "ffffff";

        _name_ = name_;
        _description = description_;
        _attribute = attribute_;

        totalSupply++;
        _safeMint(address(0xDeCaDECadECadecADecadeCAdECadECAdeCAdecA), 0);
    }

    function setMerkleRoot(bytes32 merkleRoot_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleRoot = merkleRoot_;
    }

    function setMetadata(
        string memory name_,
        string memory description_,
        string memory attribute_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _name_ = name_;
        _description = description_;
        _attribute = attribute_;
    }

    function setOwnership(address newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setOwnership(newOwner);
    }

    function setColor(uint256 index, string memory value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        colours[index] = value;
    }

    function enableAttestation() external onlyRole(DEFAULT_ADMIN_ROLE) {
        attestationEnabled = true;
    }

    function isAttested(uint256 tokenId_) public view returns (bool) {
        return (expiryTime[tokenId_] > block.timestamp);
    }

    function attestToken(uint256 tokenId_) external {
        if (!attestationEnabled) revert AttestationIsNotEnabled();
        if (ownerOf(tokenId_) != msg.sender) revert DoesNotOwnToken();
        expiryTime[tokenId_] = block.timestamp + ONE_YEAR;
    }

    function mint(bytes32[] calldata _merkleProof) external nonReentrant returns (uint256) {
        if (totalSupply >= MAX_SUPPLY) revert MaxSupplyReached();
        if (minted[msg.sender]) revert AlreadyMinted();
        if (msg.sender.isContract()) revert CannotMintFromContract();

        uint256 tokenId = totalSupply;

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf)) revert ProofInvalidOrNotInAllowlist();

        totalSupply++;
        minted[msg.sender] = true;
        _safeMint(msg.sender, tokenId);

        return tokenId;
    }

    function tokenURI(uint256 tokenId_) public view override(ERC721) returns (string memory) {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        _name_,
                        toString(tokenId_),
                        '", "description": "',
                        _description,
                        '", "image": "data:image/svg+xml;base64,',
                        Base64.encode(_renderSVG(tokenId_)),
                        '", "attributes": [{"trait_type":"',
                        _attribute,
                        '", "value": "',
                        toString(tokenId_),
                        '"}]}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function renderSVG(uint256 tokenId_) public view returns (string memory) {
        return string(_renderSVG(tokenId_));
    }

    // Inspired by Every Icon by @divergenceharri and @divergencearran
    // 0xf9a423b86afbf8db41d7f24fa56848f56684e43f
    function _renderSVG(uint256 tokenId_) internal view returns (bytes memory) {
        if (!_exists(tokenId_)) revert NonexistentToken();
        if (tokenId_ != 0) {
            return
                abi.encodePacked(
                    "<svg width='100%' height='100%' viewBox='0 0 24 24' fill='none' xmlns='http://www.w3.org/2000/svg'> <rect x='0' y='0' width='100%' height='100%' fill='#",
                    !isAttested(tokenId_) ? "ffffff" : colours[magic[tokenId_]],
                    "'/></svg>"
                );
        } else {
            bytes memory svg = DynamicBuffer.allocate(2**16); // 64KB
            svg.appendSafe(
                abi.encodePacked(
                    "<svg width='1024' height='1024' id='token-0' xmlns='http://www.w3.org/2000/svg'> <style>#token-0{shape-rendering: crispedges;} rect{width:32px;height:32px}.a{fill:#",
                    colours[0],
                    "}.b{fill:#",
                    colours[1],
                    "}.c{fill:#",
                    colours[2],
                    "}.d{fill:#",
                    colours[3],
                    "}.w{fill:#ffffff}</style>"
                )
            );
            string[4] memory classes = ["a", "b", "c", "d"];
            uint256 x;
            uint256 y;
            for (uint256 i = 0; i < 1024; i++) {
                x = (i % 32) * 32;
                y = (i / 32) * 32;

                svg.appendSafe(
                    abi.encodePacked(
                        "<rect x='",
                        toString(x),
                        "' y='",
                        toString(y),
                        "' class='",
                        isAttested(i + 1) ? classes[magic[i + 1]] : "w",
                        "'/>"
                    )
                );
            }
            svg.appendSafe("</svg>");
            return svg;
        }
    }

    function getTokensOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        uint256 seen = 0;
        for (uint256 i; i < totalSupply; i++) {
            if (ownerOf(i) == _owner) {
                tokenIds[seen] = i;
                seen++;
            }
            if (seen == tokenCount) break;
        }
        return tokenIds;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}