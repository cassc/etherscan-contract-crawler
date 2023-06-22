// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {DefaultOperatorFilterer, OperatorFilterer} from './opensea/DefaultOperatorFilterer.sol';

contract MonoCatsOrientalYokai is ERC721, AccessControl, ERC2981, DefaultOperatorFilterer, Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;
    bytes32 private constant INCREASE_CATS_ROLE = keccak256('INCREASE_CATS_ROLE');

    uint256 public constant MAX_CATS = 12;

    string private _baseTokenURI;

    struct userCats {
        address addr;
        uint256[] catIds;
    }

    mapping(address => EnumerableSet.UintSet) private userCatIdsOnFlow;

    event AddCatsIdEvent(address addr, uint256 ids);
    event MintEvent(address addr, uint256 tokenId);
    event AirdropEvent(address addrs, uint256[] tokenIds);

    constructor(
        address admin,
        address increase,
        string memory baseURI,
        address _royaltyAddress,
        uint96 _feeNumerator
    ) ERC721(unicode'MonoCats: Oriental Yōkai', 'MCOY') {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(INCREASE_CATS_ROLE, increase);
        _baseTokenURI = baseURI;
        _setDefaultRoyalty(_royaltyAddress, _feeNumerator);
    }

    /* ------------ Public Operations ------------ */

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function contractURI() public pure returns (string memory) {
        return
            'https://static.mono.fun/public/contents/projects/a73c1a41-be88-4c7c-a32e-929d453dbd39/nft/monocatsv2/MonoCatsv2_Yokai.json';
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /* ------------ Management Operations ------------ */

    function addUserCatIds(userCats[] calldata _userCats) external {
        require(hasRole(INCREASE_CATS_ROLE, msg.sender), 'must have increase role');
        for (uint256 i = 0; i < _userCats.length; i++) {
            address addr = _userCats[i].addr;
            uint256[] memory catIds = _userCats[i].catIds;
            for (uint256 j = 0; j < _userCats[i].catIds.length; j++) {
                EnumerableSet.add(userCatIdsOnFlow[addr], catIds[j]);
                emit AddCatsIdEvent(addr, catIds[j]);
            }
        }
    }

    function airdropNfts(address[] calldata addrs, uint256[][] calldata tokenIds)
        external
        onlyRole(INCREASE_CATS_ROLE)
    {
        require(addrs.length == tokenIds.length, 'amount of addresses must equal amount of length of tokenId');
        for (uint256 i = 0; i < addrs.length; i++) {
            address addr = addrs[i];
            for (uint256 j = 0; j < tokenIds[i].length; j++) {
                uint256 tokenId = tokenIds[i][j];
                _safeMint(addr, tokenId);
            }
            emit AirdropEvent(addr, tokenIds[i]);
        }
    }

    function setBaseURI(string memory baseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = baseURI;
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint96 _feeNumerator
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _resetTokenRoyalty(tokenId);
    }

    /* ------------ Users Operations ------------ */

    function getUserCatsIds() public view returns (uint256[] memory) {
        return EnumerableSet.values(userCatIdsOnFlow[msg.sender]);
    }

    function mint() public nonReentrant {
        address to = msg.sender;
        require(userCatIdsOnFlow[to].length() > 0, unicode'must have Oriental Yōkai cats on flow to mint a cat');
        for (uint256 i = 0; i < userCatIdsOnFlow[to].length(); i++) {
            uint256 tokenId = EnumerableSet.at(userCatIdsOnFlow[to], i);
            EnumerableSet.remove(userCatIdsOnFlow[to], tokenId);

            _safeMint(to, tokenId);

            emit MintEvent(to, tokenId);
        }
    }

    /* ------------ OpenSea Overrides --------------*/

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}