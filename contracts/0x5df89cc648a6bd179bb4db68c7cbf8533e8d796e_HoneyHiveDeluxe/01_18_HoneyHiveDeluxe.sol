// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract HoneyHiveDeluxe is ERC721Enumerable, AccessControlEnumerable, Ownable {
    uint256 public constant MAX_SUPPLY = 6900;
    uint8 public lockedUrlChange = 0;
    uint8 public MAX_USAGE_PER_HIVE = 3;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PROPERTIES_ROLE = keccak256("PROPERTIES_ROLE");

    // Id's that were claimed by bears owners, by bears id. This is used to enforce just 1 hive per 1 bear
    mapping(uint16 => bool) private claimedByBearsIds;
    mapping(uint16 => string) private customTokenUris;
    mapping(uint16 => uint8) private mintedBeesBeforeInactive;

    address public bearsAddress;

    string private baseUri = "https://ipfs.io/ipfs/QmXW6fpWaqbbDXLRZSW6HQpZfLeA4jeGH1rjFccEvvohFB/";

    event IncreasedUsageOfMintingBee(uint256 hiveId);
    event ResetUsageOfMintingBeeTriggered(uint256 hiveId);
    event LockedUrl();
    event UrlChanged(uint256 indexed _id, string newUrl);
    event ChangedMaxUsagePerHive(uint8 _max);
    event SetContract(string indexed _contract, address _target);

    constructor() ERC721("Honey Hive Deluxe", "HoneyHiveDeluxe") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PROPERTIES_ROLE, _msgSender());
    }

    //****** EXTERNAL *******/

    function mint(address _owner, uint256 _bearId) external {
        uint16 bearsId = uint16(_bearId);
        require(hasRole(MINTER_ROLE, _msgSender()), "Missing MINTER_ROLE");
        require(!claimedByBearsIds[bearsId], "Already minted");
        require(_owner != address(0), "Owner can not be address 0");
        require(IERC721(bearsAddress).ownerOf(_bearId) == _owner, "You don't owe this Bear");
        require(totalSupply() <= MAX_SUPPLY, "Max supply reached");
        require(_bearId > 0 && _bearId <= MAX_SUPPLY, "Token out of bound");

        claimedByBearsIds[bearsId] = true;
        super._safeMint(_owner, _bearId);
    }

    /**
     * @dev every hive can mint up to MAX_USAGE_PER_HIVE bees until it becomes inactive, then you need to burn honey
     */
    function increaseUsageOfMintingBee(uint256 _hiveId) external {
        uint16 id = uint16(_hiveId);
        require(hasRole(PROPERTIES_ROLE, _msgSender()), "Missing PROPERTIES_ROLE");
        require(mintedBeesBeforeInactive[id] < MAX_USAGE_PER_HIVE, "Inactive Hive, burn Honey");

        mintedBeesBeforeInactive[id] += 1;
        emit IncreasedUsageOfMintingBee(_hiveId);
    }

    /**
     * @dev called by the queen after it burns the necessary honey to reset the usage
     * and being able to mint bees again
     */
    function resetUsageOfMintingBee(uint256 _hiveId) external {
        uint16 id = uint16(_hiveId);
        require(hasRole(PROPERTIES_ROLE, _msgSender()), "Missing PROPERTIES_ROLE");
        require(ownerOf(_hiveId) != address(0), "No Hive owned");
        require(mintedBeesBeforeInactive[id] >= MAX_USAGE_PER_HIVE, "Not paused yet");

        mintedBeesBeforeInactive[id] = 0;
        emit ResetUsageOfMintingBeeTriggered(_hiveId);
    }

    /**
     * @dev Changing base uri for reveals or in case something happens with the IPFS
     */
    function setBaseUri(string calldata _newBaseUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Missing DEFAULT_ADMIN_ROLE");
        require(lockedUrlChange == 0, "Locked");

        baseUri = _newBaseUri;
        emit UrlChanged(0, _newBaseUri);
    }

    function setBears(address _bearsAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Missing DEFAULT_ADMIN_ROLE");
        require(_bearsAddress != address(0), "Can not be address 0");

        bearsAddress = _bearsAddress;
        emit SetContract("BearsDeluxe", _bearsAddress);
    }

    /**
     * @dev lock changing url for ever.
     */
    function lockUrlChanging() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Missing DEFAULT_ADMIN_ROLE");

        lockedUrlChange = 1;
        emit LockedUrl();
    }

    /**
     * @dev in case something happens with a token, metadata can be changed by the owner.
     * only emergency
     */
    function setTokenUri(uint256 _tokenId, string calldata _tokenURI) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Missing DEFAULT_ADMIN_ROLE");

        require(lockedUrlChange == 0, "Locked");
        _setTokenURI(_tokenId, _tokenURI);
        emit UrlChanged(_tokenId, _tokenURI);
    }

    function setMaxUsageOfMintingBee(uint8 _max) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Missing DEFAULT_ADMIN_ROLE");

        MAX_USAGE_PER_HIVE = _max;
        emit ChangedMaxUsagePerHive(_max);
    }

    function eligibleToMint(uint16 _hiveId) external view returns (bool eligible) {
        return !claimedByBearsIds[_hiveId] && IERC721(bearsAddress).ownerOf(_hiveId) == msg.sender;
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function getUsageOfMintingBee(uint256 _hiveId) external view returns (uint8) {
        return mintedBeesBeforeInactive[uint16(_hiveId)];
    }

    function getMaxSupply() external pure returns (uint256) {
        return MAX_SUPPLY;
    }

    /**
     * @dev returns token ids owned by a owner
     */
    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint16 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    //****** PUBLIC *******/

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721: URI query for nonexistent token");

        string memory _tokenURI = customTokenUris[uint16(_tokenId)];

        // If custom token is set then we return it
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        return string(abi.encodePacked(baseUri, Strings.toString(_tokenId)));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //****** INTERNAL *******/

    function _setTokenURI(uint256 tokenId, string calldata _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721: URI set of nonexistent token");
        customTokenUris[uint16(tokenId)] = _tokenURI;
    }
}