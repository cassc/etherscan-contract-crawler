// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interface/ILand.sol";
import "./Abstract/NFT.sol";

contract Land is
    Initializable,
    ILand,
    NFT,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private tokenID;

    address owner;
    address landSale;

    mapping(uint256 => uint256) public linkedTokenId;
    mapping(uint256 => uint256) public linkedLandId;

    mapping(address => uint256[]) public userLand;
    mapping(uint256 => LandData) landDetails;

    mapping(uint256 => bool) landIdStatus;

    mapping(uint256 => uint256) idIndex;
    mapping(address => bool) blacklisted;

    modifier islandIdAvaialble(uint256 x, uint256 y) {
        uint256 _landId = _encodeLandId(x, y);
        require(!landIdStatus[_landId], "already mint");
        _;
    }

    modifier isCategoriesExist(uint256 _categories) {
        require(
            Type(_categories) == Type.Normal ||
                Type(_categories) == Type.Platinum ||
                Type(_categories) == Type.Premium,
            "categories not exist"
        );
        _;
    }

    modifier isLandIdExist(uint256 _landId) {
        require(landIdStatus[_landId], "landId not exist");
        _;
    }

    modifier isNotNull(uint256 _length) {
        require(_length != 0, "zero length");
        _;
    }

    modifier isLengthEqual(uint256 x, uint256 y) {
        require(x == y, "The coordinates should have the same length");
        _;
    }

    modifier isLandOwner(uint256 x, uint256 y) {
        require(msg.sender == _ownerOfLand(x, y), "not land owner");
        _;
    }

    modifier isNotNullAddress(address _address) {
        require(_address != address(0), "null address");
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not a owner");
        _;
    }

    modifier onlyLandSale() {
        require(landSale == msg.sender, "not land Sale COntract");
        _;
    }

    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol
    ) external initializer {
        __ERC721_init(_name, _symbol);
        owner = _owner;
    }

    function updatedPlatformOwner(address _owner)
        external
        onlyOwner
        nonReentrant
    {
        owner = _owner;
        emit PlatFormOwnerUpdate(msg.sender, _owner);
    }

    function blackListAddress(address _landOwner, bool _status)
        external
        onlyOwner
        nonReentrant
    {
        blacklisted[_landOwner] = _status;
        emit Blacklisted(_landOwner, _status);
    }

    function pause() external onlyOwner nonReentrant {
        _pause();
    }

    function unpaused() external onlyOwner nonReentrant {
        _unpause();
    }

    function setLandSale(address _landSale) external onlyOwner nonReentrant {
        landSale = _landSale;
    }

    function createLand(
        address _beneficiary,
        uint256 x,
        uint256 y,
        uint256 _categories,
        string memory _uri
    )
        external
        isNotNullAddress(_beneficiary)
        isCategoriesExist(_categories)
        islandIdAvaialble(x, y)
        nonReentrant
        onlyLandSale
    {
        _create(_beneficiary, x, y, _categories,_uri);
        emit CreateLand(_beneficiary, x, y, _categories);
    }

    function transferLand(
        uint256 x,
        uint256 y,
        address to
    )
        external
        isLandOwner(x, y)
        isNotNullAddress(to)
        isLandIdExist(_encodeLandId(x, y))
        nonReentrant
    {
        uint256 landId = _encodeLandId(x, y);

        _transferLand(msg.sender, to, landId);

        _safeTransfer(msg.sender, to, landId, "");

        emit TransferLand(msg.sender, to, x, y);
    }

    function transferManyLand(
        uint256[] memory x,
        uint256[] memory y,
        address to
    )
        external
        isNotNull(x.length)
        isNotNullAddress(to)
        isLengthEqual(x.length, y.length)
        nonReentrant
    {
        _isMultipleLandIdExist(x, y);

        for (uint256 i = 0; i < x.length; i++) {
            uint256 landId = _encodeLandId(x[i], y[i]);
            _transferLand(msg.sender, to, landId);
            _safeTransfer(msg.sender, to, landId, "");
        }

        emit TransferManyLand(msg.sender, to, x, y);
    }

    function updateLandData(uint256 _landId, string memory _tokenURI)
        external
        isNotNull(_landId)
        nonReentrant
        onlyOwner
    {
        _updateLandData(_landId, _tokenURI);
        emit UpdateLandData(msg.sender, _landId, _tokenURI);
    }

    function updateMultipleLandData(
        uint256[] memory _landId,
        string[] memory _tokenURI
    )
        external
        isNotNull(_landId.length)
        isLengthEqual(_landId.length, _tokenURI.length)
        nonReentrant
        onlyOwner
    {
        for (uint256 i = 0; i < _landId.length; i++) {
            _updateLandData(_landId[i], _tokenURI[i]);
        }

        emit UpdateMultipleLandData(msg.sender, _landId, _tokenURI);
    }

    function updateManyLandData(
        uint256[] memory x,
        uint256[] memory y,
        string[] memory _tokenURI
    )
        external
        isNotNull(x.length)
        isLengthEqual(x.length, y.length)
        nonReentrant
        onlyOwner
    {
        for (uint256 i = 0; i < x.length; i++) {
            uint256 landId = _encodeLandId(x[i], y[i]);
            _updateLandData(landId, _tokenURI[i]);
        }

        emit UpdateManyLandData(msg.sender, x, y, _tokenURI);
    }

    function encodeLandId(uint256 x, uint256 y)
        external
        pure
        returns (uint256)
    {
        return _encodeLandId(x, y);
    }

    function decodeLandId(uint256 _landId)
        external
        pure
        returns (uint256, uint256)
    {
        return _decodeLandId(_landId);
    }

    function userLandInfo(uint256 _landId)
        external
        view
        returns (LandData memory)
    {
        return landDetails[_landId];
    }

    function ownerOfLand(uint256 x, uint256 y) external view returns (address) {
        return _ownerOfLand(x, y);
    }

    function ownerOfLandMany(uint256[] memory x, uint256[] memory y)
        external
        view
        returns (address[] memory)
    {
        require(x.length > 0, "You should supply at least one coordinate");
        require(
            x.length == y.length,
            "The coordinates should have the same length"
        );

        address[] memory addrs = new address[](x.length);
        for (uint256 i = 0; i < x.length; i++) {
            addrs[i] = _ownerOfLand(x[i], y[i]);
        }

        return addrs;
    }

    function landData(uint256 x, uint256 y)
        external
        view
        returns (string memory)
    {
        return tokenURI(_encodeLandId(x, y));
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 _landId
    ) public virtual override {
        safeTransferFrom(from, to, _landId, "");
        _transferLand(from, to, _landId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 _landId,
        bytes memory data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), _landId),
            "ERC721: caller is not token owner or approved"
        );
        _transferLand(from, to, _landId);
        _safeTransfer(from, to, _landId, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 _landId
    ) public virtual override isLandIdExist(_landId) {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), _landId),
            "ERC721: caller is not token owner or approved"
        );

        _transferLand(from, to, _landId);

        _safeTransfer(from, to, _landId, "");
    }

    function _create(
        address _beneficiary,
        uint256 x,
        uint256 y,
        uint256 _categories,
        string memory _uri
    ) internal {
        uint256 _landId = _encodeLandId(x, y);

        idIndex[_landId] = userLand[_beneficiary].length;
        userLand[_beneficiary].push(_landId);

        landDetails[_landId] = LandData(_categories, block.timestamp);

        landIdStatus[_landId] = true;

        uint256 tokenId = generateTokenId(_landId);

        _mintLand(_beneficiary, tokenId);
        _updateLandData(_landId, _uri);
    }

    function _mintLand(address _beneficiary, uint256 _tokenId) internal {
        _mintNFT(_beneficiary, _tokenId);
    }

    function _transferLand(
        address _from,
        address _to,
        uint256 _landId
    ) internal {
        delete userLand[_from][(idIndex[_landId])];

        idIndex[_landId] = userLand[_to].length;
        userLand[_to].push(_landId);

        landDetails[_landId].timestamp = block.timestamp;
    }

    function _encodeLandId(uint256 x, uint256 y)
        internal
        pure
        returns (uint256 result)
    {
        require(
            x < 10000 && y < 10000,
            "The coordinates should be inside bounds"
        );
        return ((uint256(x) * factor) & clearLow) | (uint256(y) & clearHigh);
    }

    function _decodeLandId(uint256 _landId)
        internal
        pure
        returns (uint256 x, uint256 y)
    {
        x = _expandNegative128BitCast((_landId & clearLow) >> 128);
        y = _expandNegative128BitCast(_landId & clearHigh);

        require(
            x < 10000 && y < 10000,
            "The coordinates should be inside bounds"
        );
    }

    function _expandNegative128BitCast(uint256 value)
        internal
        pure
        returns (uint256)
    {
        if (value & (1 << 127) != 0) {
            return uint256(value | clearLow);
        }
        return uint256(value);
    }
    
    function generateTokenId(uint256 _landId) internal returns (uint256) {
        tokenID.increment();

        linkedTokenId[_landId] = tokenID.current();
        linkedLandId[(tokenID.current())] = _landId;

        return tokenID.current();
    }

    function _isMultipleLandIdExist(uint256[] memory x, uint256[] memory y)
        internal
        view
    {
        for (uint256 i = 0; i < x.length; i++) {
            uint256 _landId = _encodeLandId(x[i], y[i]);
            require(landIdStatus[_landId], "landId not exist");
        }
    }

    function _ownerOfLand(uint256 x, uint256 y)
        internal
        view
        returns (address)
    {
        return ownerOf(_encodeLandId(x, y));
    }

    function _updateLandData(uint256 _landId, string memory _tokenURI)
        internal
    {
        uint256 _tokenId = linkedTokenId[_landId];  
        _updateURI(_tokenId, _tokenURI);
    }
}