// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

pragma solidity >=0.8.7;

contract DontDieMemeGenesis is
    ERC721,
    Ownable,
    AccessControlEnumerable,
    ERC2981
{
    using SafeMath for uint256;
    using Strings for uint256;

    string internal baseTokenURI;
    uint256 private _baseID;
    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => uint256) public tokenMaxSupply;
    mapping(uint256 => uint256) public currentTokenID;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant JUICING_ROLE = keccak256("JUICING_ROLE");

    constructor(
        string memory _name,
        string memory _symbol,
        address payable royaltyReceiver
    ) ERC721(_name, _symbol) {
        _setDefaultRoyalty(royaltyReceiver, 500);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    function maxSupply(uint256 _id) public view returns (uint256) {
        return tokenMaxSupply[_id];
    }

    function create(uint256 _maxSupply)
        external
        onlyRole(MINTER_ROLE)
        returns (uint256 tokenId)
    {
        uint256 _baseTokenID = _getNextBaseID();
        _incrementBaseID();
        creators[_baseTokenID] = msg.sender;
        tokenSupply[_baseTokenID] = 0;
        tokenMaxSupply[_baseTokenID] = _maxSupply;
        return _baseTokenID;
    }

    function mint(address _to, uint256 _baseTokenID)
        public
        onlyRole(MINTER_ROLE)  returns (uint256)
    {
        require(
            creators[_baseTokenID] != address(0),
            "baseTokenID not been created"
        );
        require(
            tokenSupply[_baseTokenID] < tokenMaxSupply[_baseTokenID],
            "Max supply reached"
        );
        uint256 tokenID = _getNextTokenID(_baseTokenID);
        _mint(_to, tokenID);
        _incrementTokenId(_baseTokenID);
        tokenSupply[_baseTokenID] = tokenSupply[_baseTokenID].add(1);
        return tokenID;
    }

    function _getNextBaseID() private view returns (uint256) {
        return _baseID.add(1000000);
    }

    function _incrementBaseID() private {
        _baseID = _baseID.add(1000000);
    }

    function _getNextTokenID(uint256 _baseTokenID)
        private
        view
        returns (uint256)
    {
        return (currentTokenID[_baseTokenID].add(1)).add(_baseTokenID);
    }

    function _incrementTokenId(uint256 _baseTokenID) private {
        currentTokenID[_baseTokenID]++;
    }

    /// @dev Returns an URI for a given token ID
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _tokenId.toString()))
                : "";
    }

    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /*
        Juicing
    */
    mapping(uint256 => uint256) private juicingStarted;
    mapping(uint256 => uint256) private juicingTaskId;

    event Juiced(uint256 indexed tokenId, uint256 indexed taskId);

    event UnJuiced(uint256 indexed tokenId, uint256 indexed taskId);

    function juicingStatus(uint256 tokenId)
        external
        view
        returns (
            bool juicing,
            uint256 start,
            uint256 task
        )
    {
        start = juicingStarted[tokenId];
        task = juicingTaskId[tokenId];
        if (start != 0) {
            juicing = true;
        } else {
            juicing = false;
        }
    }

    function _beforeTokenTransfer(
        address,
        address,
        uint256 tokenId
    ) internal virtual override {
        require(juicingStarted[tokenId] == 0, "can't transfer while juicing");
    }

    function toggleJuicing(
        uint256 tokenId,
        bool juicing,
        uint256 taskId
    ) internal {
        require(taskId > 0, "invalid task id");
        if (juicing) {
            juicingStarted[tokenId] = block.timestamp;
            juicingTaskId[tokenId] = taskId;
            emit Juiced(tokenId, taskId);
        } else {
            require(taskId == juicingTaskId[tokenId], "wrong taskid");
            juicingStarted[tokenId] = 0;
            juicingTaskId[tokenId] = 0;
            emit UnJuiced(tokenId, taskId);
        }
    }

    function toggleJuicing(
        uint256[] calldata tokenIds,
        bool juicing,
        uint256 taskId
    ) external onlyRole(JUICING_ROLE) {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            toggleJuicing(tokenIds[i], juicing, taskId);
        }
    }
}