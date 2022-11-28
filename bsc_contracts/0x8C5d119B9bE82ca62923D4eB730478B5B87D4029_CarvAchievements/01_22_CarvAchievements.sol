// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "ERC1155Upgradeable.sol";
import "AccessControlUpgradeable.sol";
import "PausableUpgradeable.sol";
import "ERC1155BurnableUpgradeable.sol";
import "ERC1155SupplyUpgradeable.sol";
import "ERC1155URIStorageUpgradeable.sol";
import "Initializable.sol";
import "UUPSUpgradeable.sol";

/**
 * @title CarvAchievements Collection
 * @author Carv
 * @custom:security-contact [email protected]
 */
contract CarvAchievements is Initializable, ERC1155Upgradeable, AccessControlUpgradeable, PausableUpgradeable, ERC1155BurnableUpgradeable, ERC1155SupplyUpgradeable, ERC1155URIStorageUpgradeable, UUPSUpgradeable {
    // DEFAULT_ADMIN_ROLE - 0x0000000000000000000000000000000000000000000000000000000000000000
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");  // 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");  // 0x189ab7a9244df0848122154315af71fe140f3db0fe014031783b0946b8c9d2e3

    // Trusted forwarders for relayer usage, for ERC2771 support
    mapping(address => bool) private _trustedForwarders;
    // Collection name
    string private _name;
    // Collection symbol
    string private _symbol;
    // Mapping from badge ID to the carved amount
    mapping(uint256 => uint256) private _carvedAmount;
    // Global supply of all token IDs
    uint256 private _globalSupply;
    // Mapping from pathId to URIs. pathId 0 is reserved as the 'zero' path.
    mapping(uint256 => string) private _pathURI;
    // Mapping from pathId to the level to tokenId mapping
    mapping(uint256 => mapping(uint256 => uint256)) private _pathTokens;
    // Max level of a path
    mapping(uint256 => uint256) private _maxLevel;
    // Mapping from tokenId to pathId
    mapping(uint256 => uint256) private _tokenPath;
    // Mapping from tokenId to its level on a path
    mapping(uint256 => uint256) private _tokenLevel;
    // Mapping from address to path level
    mapping(address => mapping(uint256 => uint256)) private _userLevelOnPath;
    // Mapping signature used per transaction.
    mapping(uint256 => bool) private minted;

    event TrustedForwarderAdded(address forwarder);
    event TrustedForwarderRemoved(address forwarder);
    event TokenAddedToPath(uint256 indexed pathId, uint256 indexed level, uint256 indexed tokenId);
    event AchievementCarved(address indexed to, uint256 indexed pathId, uint256 level);

    function initialize() initializer public {
        __ERC1155_init("");
        __AccessControl_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __ERC1155URIStorage_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        _name = "Carv Achievements";
        _symbol = "CARV-ACHV";
    }

    function _authorizeUpgrade(address newImplementation) internal onlyRole(UPGRADER_ROLE) override {}

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function addTrustedForwarder(address forwarder) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _trustedForwarders[forwarder] = true;
        emit TrustedForwarderAdded(forwarder);
    }

    function removeTrustedForwarder(address forwarder) external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete _trustedForwarders[forwarder];
        emit TrustedForwarderRemoved(forwarder);
    }

    function uri(uint256 tokenId) override(ERC1155Upgradeable, ERC1155URIStorageUpgradeable) public view returns (string memory) {
        return super.uri(tokenId);
    }

    function setURI(uint256 tokenId, string memory tokenURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bytes(uri(tokenId)).length == 0, "CarvAchievements: URI cannot be updated");
        _setURI(tokenId, tokenURI);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function carvedAmount(uint256 tokenId) external view returns (uint256) {
        return (_carvedAmount[tokenId]);
    }

    function totalSupply() external view returns (uint256) {
        return (_globalSupply);
    }

    function pathURI(uint256 pathId) external view returns (string memory) {
        require(pathId != 0, "CarvAchievements: pathId 0 is reserved as the null path");
        return _pathURI[pathId];
    }

    function pathTokens(uint256 pathId, uint256 level) external view returns (uint256) {
        require(pathId != 0, "CarvAchievements: pathId 0 is reserved as the null path");
        require(level > 0 && level <= _maxLevel[pathId], "CarvAchievements: Invalid level");
        return _pathTokens[pathId][level];
    }

    function pathMaxLevel(uint256 pathId) external view returns (uint256) {
        require(pathId != 0, "CarvAchievements: pathId 0 is reserved as the null path");
        return _maxLevel[pathId];
    }

    function tokenPath(uint256 tokenId) external view returns (uint256) {
        return _tokenPath[tokenId];
    }

    function tokenLevel(uint256 tokenId) external view returns (uint256) {
        return _tokenLevel[tokenId];
    }

    function userLevelOnPath(address user, uint256 pathId) external view returns (uint256) {
        require(pathId != 0, "CarvAchievements: pathId 0 is reserved as the null path");
        return _userLevelOnPath[user][pathId];
    }

    function setPathURI(uint pathId, string memory newPathURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(pathId != 0, "CarvAchievements: pathId 0 is reserved as the null path");
        _pathURI[pathId] = newPathURI;
    }

    // Append a tokenId to the end of a path
    function addTokenToPath(uint pathId, uint256 level, uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(pathId != 0, "CarvAchievements: pathId 0 is reserved as the null path");
        require(bytes(_pathURI[pathId]).length > 0, "CarvAchievements: path is not yet configured");
        require(_tokenPath[tokenId] == 0, "CarvAchievements: The tokenId already exists in a path");
        require(level == _maxLevel[pathId] + 1, "CarvAchievements: Can only append tokenId to the end of the path");
        _maxLevel[pathId] = level;
        _pathTokens[pathId][level] = tokenId;
        _tokenLevel[tokenId] = level;
        _tokenPath[tokenId] = pathId;
        emit TokenAddedToPath(pathId, level, tokenId);
    }

    // Carv an achievement token to an address
    function carv(address to, uint256 pathId, uint256 level) external onlyRole(MINTER_ROLE) {
        require(pathId != 0, "CarvAchievements: pathId 0 is reserved as the null path");
        uint256 currentLevel = _userLevelOnPath[to][pathId];
        require(level <= _maxLevel[pathId] && level > currentLevel, "CarvAchievements: Invalid level");
        if (currentLevel > 0) {
            // If the user already has a lower-level token on the path, burn it before minting the new token
            uint256 currentLevelToken = _pathTokens[pathId][currentLevel];
            _burnBatch(to, _asSingletonArray(currentLevelToken), _asSingletonArray(1));
        }
        _userLevelOnPath[to][pathId] = level;
        _mint(to, _pathTokens[pathId][level], 1, "");
        emit AchievementCarved(to, pathId, level);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal whenNotPaused override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                require(totalSupply(ids[i]) >= amounts[i], "ERC1155Supply: Insufficient supply");
                _userLevelOnPath[from][_tokenPath[ids[i]]] = 0;
            }
        }

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _carvedAmount[ids[i]] += amounts[i];
                _globalSupply += amounts[i];
            }
        }

        // Achievement tokens are nontransferable
        if (from != address(0) && to != address(0)) {
            revert("CarvAchievements: Soulbound achievement tokens are nontransferable");
        }

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
    * Below functions are for ERC2771 support
    */

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return _trustedForwarders[forwarder];
    }

    /**
    * Below functions are for meta transaction personal signature support
    */
    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function metaCarv(address userAddr, uint256 cid, bytes memory functionSignature,
        bytes32 sigR, bytes32 sigS, uint8 sigV) public payable returns (bytes memory) {

        require(!minted[cid], "Already carved");
        minted[cid] = true;
        require(verify(userAddr, cid, getChainID(), functionSignature, sigR, sigS, sigV), "Signer and signature do not match");

        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(abi.encodePacked(functionSignature, userAddr));
        require(success, "Function call not successful");

        return returnData;
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function verify(address userAddr, uint256 cid, uint256 chainID, bytes memory functionSignature,
        bytes32 sigR, bytes32 sigS, uint8 sigV) public view returns (bool) {
        bytes32 hash = prefixed(keccak256(abi.encodePacked(cid, this, chainID, functionSignature)));
        address signer = ecrecover(hash, sigV, sigR, sigS);
        require(signer != address(0), "Invalid signature");
        return (userAddr == signer);
    }

    function _msgSender() internal view override returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
            // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            return super._msgSender();
        }
    }

    /**
    * Below functions are overrides required by Solidity.
    */
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}