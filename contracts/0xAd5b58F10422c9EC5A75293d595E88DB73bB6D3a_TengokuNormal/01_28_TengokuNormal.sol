// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "../interface/IIncubator.sol";

contract TengokuNormal is
    ERC1155,
    AccessControl,
    Pausable,
    ReentrancyGuard,
    DefaultOperatorFilterer,
    ERC1155Burnable,
    ERC1155Supply
{
    using Strings for uint256;
    uint256 public constant NORMAL_TOKEN_ID = 0;
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public name = "TENGOKU SPACE";
    string public symbol = "TengokuNormal";

    address public tengoku2d;
    address public validator;
    address public incubator;
    uint256 public tengokuNormalSize = 2879;
    mapping(bytes32 => bool) private signatureUsed;
    mapping(uint256 => bool) public tokenClaimed;

    constructor(
        address _validator,
        address _tengoku2D,
        address _incubator
    )
        ERC1155(
            "https://droaqyb4mp3w7.cloudfront.net/incubation/metadata_3d/proto/"
        )
    {
        tengoku2d = _tengoku2D;
        validator = _validator;
        incubator = _incubator;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function setTenguku2D(address _tengoku2d)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tengoku2d = _tengoku2d;
    }

    function setValidator(address _validator)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        validator = _validator;
    }

    function setIncubator(address _incubator)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        incubator = _incubator;
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory baseUrl = super.uri(tokenId);
        return string(abi.encodePacked(baseUrl, tokenId.toString(), ".json"));
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function hashMessage(uint256[] memory tokenIds, uint256[] memory amounts)
        public
        view
        returns (bytes32)
    {
        require(
            tokenIds.length == amounts.length,
            "tokens length must be equal to amounts"
        );
        return
            keccak256(
                abi.encode(block.chainid, address(this), tokenIds, amounts)
            );
    }

    function mintBatch(
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory signature
    ) public whenNotPaused nonReentrant {
        bytes32 hash = ECDSA.toEthSignedMessageHash(
            hashMessage(tokenIds, amounts)
        );
        require(!signatureUsed[hash], "hash used");
        require(
            SignatureChecker.isValidSignatureNow(validator, hash, signature),
            "invalid signature"
        );
        require(_checkTokenIds(tokenIds, msg.sender), "token id invalid");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(!tokenClaimed[tokenIds[i]], "token already claimed");
            tokenClaimed[tokenIds[i]] = true;
        }
        _mint(msg.sender, NORMAL_TOKEN_ID, tokenIds.length, "");
        signatureUsed[hash] = true;
        require(
            totalSupply(NORMAL_TOKEN_ID) <= tengokuNormalSize,
            "reached max"
        );
    }

    function _checkTokenIds(uint256[] memory tokenIds, address owner)
        internal
        view
        returns (bool result)
    {
        uint256[] memory incubatorTokenIds = IIncubator(incubator).tokenIds(
            owner
        );
        result = true;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (IERC721(tengoku2d).ownerOf(tokenIds[i]) == owner) {
                continue;
            }
            for (uint256 j = 0; j < incubatorTokenIds.length; j++) {
                if (tokenIds[i] == incubatorTokenIds[j]) {
                    break;
                } else if (j == incubatorTokenIds.length - 1) {
                    result = false;
                    return result;
                }
            }
        }
    }

    function tokensExists(uint256[] calldata tokenIds)
        public
        view
        returns (bool[] memory)
    {
        bool[] memory results = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            results[i] = tokenClaimed[tokenIds[i]];
        }
        return results;
    }

    function burnBatch(uint256[] memory ids, uint256[] memory amounts) public {
        _burnBatch(msg.sender, ids, amounts);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}