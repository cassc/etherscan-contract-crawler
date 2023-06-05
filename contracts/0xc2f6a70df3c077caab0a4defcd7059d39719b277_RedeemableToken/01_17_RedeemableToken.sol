// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';

contract RedeemableToken is ERC1155, ReentrancyGuard, AccessControlEnumerable {
    string public name;

    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

    struct RedeemInfo {
        string orderId;
        address owner;
        uint256 qty;
    }

    mapping(string => RedeemInfo) public redeemInfo; // mapping orderId to order info
    mapping(uint256 => mapping(address => uint256)) public tokensRedeemed;
    mapping(uint256 => string) public tokenURIs;

    event PhygitalRedeemed(
        address indexed wallet,
        uint256 indexed tokenId,
        uint256 amount,
        string indexed orderId
    );

    constructor(string memory _name) ERC1155('') {
        name = _name;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return tokenURIs[tokenId];
    }

    function mint(
        address _account,
        uint256 _tokenId,
        uint256 _amount
    ) public nonReentrant onlyRole(MINTER_ROLE) {
        _mint(_account, _tokenId, _amount, '');
    }

    function redeemPhygital(
        uint256 tokenId,
        uint256 amount,
        string memory orderId
    ) public {
        require(bytes(orderId).length > 0, 'Invalid orderId');
        _burn(msg.sender, tokenId, amount);
        require(redeemInfo[orderId].qty == 0, 'Duplicated orderId');
        tokensRedeemed[tokenId][msg.sender] += amount;
        redeemInfo[orderId] = RedeemInfo(orderId, msg.sender, amount);

        emit PhygitalRedeemed(msg.sender, tokenId, amount, orderId);
    }

    //// EIP1363 payable token
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerable, ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setTokenURIs(uint256 tokenId, string calldata newUri)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tokenURIs[tokenId] = newUri;
    }

    function setMinterRole(address account)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setupRole(MINTER_ROLE, account);
    }

    function removeMinterRole(address account)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _revokeRole(MINTER_ROLE, account);
    }
}