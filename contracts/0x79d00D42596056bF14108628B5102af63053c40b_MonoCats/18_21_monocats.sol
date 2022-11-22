// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {DefaultOperatorFilterer, OperatorFilterer} from './opensea/DefaultOperatorFilterer.sol';

contract MonoCats is ERC721, AccessControl, ERC2981, DefaultOperatorFilterer, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public constant imageHash = '080a47b46e0507ea40d250e3f06330a870b23301f1178fe195376b14c5fb15b1';

    bytes32 private constant INCREASE_CATS_ROLE = keccak256('INCREASE_CATS_ROLE');

    uint256 public constant MAX_CATS = 2000;
    uint256 public constant MAX_MINT_ONCE = 20;

    string private _baseTokenURI;

    mapping(address => uint256) private userCatsNumberOnFlow;

    event IncreaseCatsNumberEvent(address addr, uint256 num);
    event MintEvent(address addr, uint256 tokenId);
    event AirdropEvent(address addrs, uint256[] tokenIds);

    constructor(
        address admin,
        address increase,
        string memory baseURI,
        address _royaltyAddress,
        uint96 _feeNumerator
    ) ERC721('MonoCats: Evolved!', 'MCAT') {
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
            'https://static.mono.fun/public/contents/projects/a73c1a41-be88-4c7c-a32e-929d453dbd39/nft/monocatsv2/MonoCatsv2.json';
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

    function increaseCatsNumber(address[] calldata addrs, uint256[] calldata nums)
        external
        onlyRole(INCREASE_CATS_ROLE)
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            _increaseCatsNumber(addrs[i], nums[i]);
        }
    }

    function _increaseCatsNumber(address addr, uint256 num) internal {
        userCatsNumberOnFlow[addr] = userCatsNumberOnFlow[addr] + num;

        emit IncreaseCatsNumberEvent(addr, num);
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
                if (tokenId < MAX_CATS) {
                    _safeMint(addr, tokenId);
                }
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

    function getUserCatsNumber() public view returns (uint256) {
        return userCatsNumberOnFlow[msg.sender];
    }

    function mint() public nonReentrant {
        address to = msg.sender;
        require(userCatsNumberOnFlow[to] >= 5, 'must have 5 above cats on flow to mint a cat');
        require(_tokenIds.current() < MAX_CATS, 'tokenID out of range');
        uint256 maxMint = userCatsNumberOnFlow[to] / 5;

        for (uint256 i = 0; i < Math.min(maxMint, MAX_MINT_ONCE); i++) {
            if (_tokenIds.current() < MAX_CATS) {
                userCatsNumberOnFlow[to] = userCatsNumberOnFlow[to] - 5;
                _safeMint(to, _tokenIds.current());
                emit MintEvent(to, _tokenIds.current());
                _tokenIds.increment();
            }
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