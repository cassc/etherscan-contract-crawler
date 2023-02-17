// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract RainiCardPacksv2 is 
    ERC721,
    IERC2981,
    AccessControl,
    Ownable2Step,
    DefaultOperatorFilterer
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    struct PackType {
        uint32 packClassId;
        uint128 costInEth;
        uint16 maxMintsPerAddress;
        uint32 tokenIdStart; // the first token id
        uint32 supply;
        uint32 mintTimeStart; // the timestamp from which the pack can be minted
    }

    string public contractURIString;
    string public baseUri;

    uint256 public maxPackTypeId = 0;

    address private _royaltiesRecipient;
    uint256 private _royaltiesBasisPoints;

    mapping(uint256 => PackType) public packTypes;
    mapping(uint256 => uint256) public numberOfPackMinted;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "caller is not a minter");
        _;
    }

    // userId => cardId => count
    mapping(address => mapping(uint256 => uint256))
        public numberMintedByAddress; // Number of a card minted by an address

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _uri,
        string memory _contractURIString
    ) ERC721(name_, symbol_) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());
        baseUri = _uri;
        contractURIString = _contractURIString;
    }

    function getPackClass(uint256 tokenId) public view returns (uint256) {
        for (uint256 i = 1; i <= maxPackTypeId; i++) {
            if (
                tokenId >= packTypes[i].tokenIdStart &&
                tokenId <= packTypes[i].tokenIdStart + packTypes[i].supply - 1
            ) {
                return packTypes[i].packClassId;
            }
        }
        revert("dne");
    }

    function updatePacks(
        uint256[] memory _id,
        uint256[] memory _costInEth,
        uint256[] memory _maxMintsPerAddress,
        uint32[] memory _mintTimeStart
    ) external onlyAdmin {
        for (uint256 i; i < _id.length; i++) {
            PackType memory _packType = packTypes[_id[i]];
            _packType.costInEth = uint128(_costInEth[i]);
            _packType.maxMintsPerAddress = uint16(_maxMintsPerAddress[i]);
            _packType.mintTimeStart = _mintTimeStart[i];
            packTypes[_id[i]] = _packType;
        }
    }

    function updateMintTimeStarts(
        uint256[] memory _id,
        uint32[] memory _mintTimeStart
    ) external onlyAdmin {
        for (uint256 i; i < _id.length; i++) {
            PackType memory _packType = packTypes[_id[i]];
            _packType.mintTimeStart = _mintTimeStart[i];
            packTypes[_id[i]] = _packType;
        }
    }

    function setcontractURI(string memory _contractURIString)
        external
        onlyAdmin
    {
        contractURIString = _contractURIString;
    }

    function setBaseURI(string memory _baseURIString) external onlyAdmin {
        baseUri = _baseURIString;
    }

    function addToNumberMintedByAddress(
        address _address,
        uint256 _cardId,
        uint256 _amount
    ) external onlyMinter {
        numberMintedByAddress[_address][_cardId] += _amount;
    }

    function initPacks(
        uint256[] memory _packTypeId,
        uint256[] memory _packClassId,
        uint256[] memory _tokenIdStart,
        uint256[] memory _supply,
        uint256[] memory _costInEth,
        uint256[] memory _maxMintsPerAddress,
        uint32[] memory _mintTimeStart
    ) external onlyAdmin {

        uint256 _maxPackTypeId = maxPackTypeId;
        for (uint256 i; i < _packClassId.length; i++) {
            packTypes[_packTypeId[i]] = PackType({
                packClassId: uint32(_packClassId[i]),
                costInEth: uint128(_costInEth[i]),
                maxMintsPerAddress: uint16(_maxMintsPerAddress[i]),
                mintTimeStart: uint32(_mintTimeStart[i]),
                tokenIdStart: uint32(_tokenIdStart[i]),
                supply: uint32(_supply[i])
            });
            if (_packTypeId[i] > _maxPackTypeId) {
                _maxPackTypeId = _packTypeId[i];
            }
        }
        if (_maxPackTypeId > maxPackTypeId) {
            maxPackTypeId = _maxPackTypeId;
        }
    }

    function mint(
        address _to,
        uint256 _packTypeId,
        uint256 _amount
    ) external {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "RainiNft721: caller is not a minter"
        );
        PackType memory _packType = packTypes[_packTypeId];
        uint256 _numberOfPackMinted = numberOfPackMinted[_packTypeId];
        uint256 start = _packType.tokenIdStart;
        require(
            _amount <= _packType.supply - _numberOfPackMinted,
            "not enough packs"
        );
        for (uint256 i = 0; i < _amount; i++) {
            _mint(_to, start + _numberOfPackMinted + i);
        }
        numberOfPackMinted[_packTypeId] += _amount;
    }

    function burn(uint256 _tokenId) external {
        require(
            hasRole(BURNER_ROLE, _msgSender()),
            "RainiNft721: caller is not a burner"
        );
        _burn(_tokenId);
    }

    function tokenURI(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        uint256 packId = getPackClass(id);
        return
            string(
                abi.encodePacked(
                    baseUri,
                    "?pid=",
                    Strings.toString(packId),
                    "&tid=",
                    Strings.toString(id)
                )
            );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // Mimic RainiNFT1155 in order to allow to be traded in the market

    function balanceOf(address _owner, uint256 _id)
        external
        pure
        returns (uint256)
    {
        // always returns 1 for market contract to work, use 'ownerOf' for actual info
        return 1;
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external {
        require(_value == 1);
        safeTransferFrom(_from, _to, _id, _data);
    }

    function uri(uint256 id) public view returns (string memory) {
        return tokenURI(id);
    }

    struct TokenVars {
        uint128 cardId;
        uint32 level;
        uint32 number; // to assign a numbering to NFTs
        bytes1 mintedContractChar;
    }

    function tokenVars(uint256 _tokenId)
        external
        view
        returns (TokenVars memory)
    {
        return
            TokenVars({
                cardId: uint128(getPackClass(_tokenId)),
                level: 1,
                number: 0,
                mintedContractChar: ""
            });
    }



    /** EIP2981 royalties implementation. */

    function setRoyalties(address newRecipient, uint256 basisPoints) external onlyOwner {
        require(newRecipient != address(0), "Royalties: new recipient is the zero address");
        _royaltiesRecipient = newRecipient;
        _royaltiesBasisPoints = basisPoints;
    }

    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_royaltiesRecipient, (_salePrice * _royaltiesBasisPoints) / 10000);
    }



    // Implementing DefaultOperatorFilterer for royalty enforcement
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}