//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';

import './ERC721Upgradeable.sol';

interface ISuperBunnies {
    function burn(uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function totalSupply() external view returns (uint256);
}

contract SuperTigers is OwnableUpgradeable, ERC721Upgradeable {
    struct VictimsMeta {
        uint8 bunnyType;
        uint16[3] tokenIds;
    }

    /**
     * @dev Emitted when bunnies were burnt for the `tokenId`.
     */
    event ComposeTiger(
        address indexed owner,
        uint256 indexed tokenId,
        VictimsMeta meta
    );

    uint256 public constant MAX_SUPPLY = 3333;

    ISuperBunnies public lightSBContract;
    ISuperBunnies public darkSBContract;

    address private _proxyRegistryAddress;
    address private _verifier;

    string private _baseTokenURI;

    bool public IS_BURNING_ACTIVE;

    struct TokenState {
        address owner;
        uint96 meta;
    }

    mapping(uint256 => TokenState) public tokenState;
    uint256[] private _tokenStateKeys;

    mapping(address => uint256) private _tokenOwnerState;

    // Mapping owner address to token count
    mapping(address => int16) private _balances;

    function initialize(
        address verifier_,
        address proxyRegistryAddress_,
        ISuperBunnies lightSBContract_,
        ISuperBunnies darkSBContract_
    ) public initializer {
        __ERC721_init('SuperTigers', 'ST');
        __Ownable_init();

        _verifier = verifier_;
        _proxyRegistryAddress = proxyRegistryAddress_;

        lightSBContract = lightSBContract_;
        darkSBContract = darkSBContract_;
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }

    function actualOwnerOf(uint256 tokenId) public view returns (address) {
        if (tokenState[tokenId].owner != address(0)) {
            return tokenState[tokenId].owner;
        }

        address tokenIdOwner = address(uint160(tokenId));
        uint16 tokenIndex = uint16(tokenId << 160);

        require(_tokenOwnerState[tokenIdOwner] != 0, 'ST: not minted');
        require(
            tokenIndex < _tokenOwnerState[tokenIdOwner],
            'ST: invalid index'
        );

        return tokenIdOwner;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner_)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner_ != address(0),
            'ERC721: balance query for the zero address'
        );

        return uint256(int256(_tokenOwnerState[owner_]) + _balances[owner_]);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        return actualOwnerOf(tokenId);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        if (tokenState[tokenId].owner != address(0)) {
            return true;
        }

        address tokenIdOwner = address(uint160(tokenId));
        uint16 tokenIndex = uint16(tokenId << 160);

        return
            (_tokenOwnerState[tokenIdOwner] != 0) &&
            (tokenIndex < _tokenOwnerState[tokenIdOwner]);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(
            ownerOf(tokenId) == from,
            'ERC721: transfer from incorrect owner'
        );
        require(to != address(0), 'ERC721: transfer to the zero address');

        require(to != from, "ERC721: can't transfer themself");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        if (tokenState[tokenId].owner == address(0)) {
            _tokenStateKeys.push(tokenId);
        }

        _balances[from] -= 1;
        _balances[to] += 1;

        tokenState[tokenId].owner = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function mint(uint256 bunnyType, uint256[3][] calldata bunnyTokenIds)
        external
        payable
    {
        require(IS_BURNING_ACTIVE, 'ST: Burning is not active');

        address sender = _msgSender();

        uint256 ownerBase = uint256(uint160(sender));

        uint256 batchAmount = bunnyTokenIds.length;
        ISuperBunnies bunniesContract = bunnyType == 0
            ? lightSBContract
            : darkSBContract;

        uint256 mintedAmount = _tokenOwnerState[sender];

        for (uint256 index; index < batchAmount; index++) {
            uint256[3] calldata tokens = bunnyTokenIds[index];

            require(
                bunniesContract.ownerOf(tokens[0]) == sender &&
                    bunniesContract.ownerOf(tokens[1]) == sender &&
                    bunniesContract.ownerOf(tokens[2]) == sender,
                'ST: should be owner'
            );

            bunniesContract.burn(tokens[0]);
            bunniesContract.burn(tokens[1]);
            bunniesContract.burn(tokens[2]);

            uint256 tigerTokenId = ownerBase | ((mintedAmount + index) << 160);

            emit Transfer(address(0), sender, tigerTokenId);

            emit ComposeTiger(sender, tigerTokenId, VictimsMeta({
                bunnyType: uint8(bunnyType),
                tokenIds: [
                    uint16(tokens[0]),
                    uint16(tokens[1]),
                    uint16(tokens[2])
                ]
            }));
        }

        _tokenOwnerState[sender] += batchAmount;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner_, address operator_)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner_)) == operator_) {
            return true;
        }

        return super.isApprovedForAll(owner_, operator_);
    }

    function getOwnerTokens(address owner_)
        public
        view
        returns (uint256[] memory)
    {
        require(
            owner_ != address(0),
            'ERC721: balance query for the zero address'
        );

        uint256 balance = balanceOf(owner_);

        uint256[] memory ownedTokens = new uint256[](balance);

        uint256 ownerBase = uint256(uint160(owner_));
        uint256 mintedAmount = _tokenOwnerState[owner_];
        uint256 resultIndex;

        for (uint256 index; index < mintedAmount; index++) {
            uint256 tokenId = ownerBase | (index << 160);

            if (tokenState[tokenId].owner == address(0)) {
                ownedTokens[resultIndex++] = tokenId;
            }
        }

        for (uint256 index = 0; index < _tokenStateKeys.length; index++) {
            uint256 tokenId = _tokenStateKeys[index];

            if (tokenState[tokenId].owner == owner_) {
                ownedTokens[resultIndex++] = tokenId;
            }
        }

        return ownedTokens;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return
            (10000 -
                (lightSBContract.totalSupply() +
                    darkSBContract.totalSupply())) / 3;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /* OwnerOnly */

    function setState(bool burningState) external onlyOwner {
        IS_BURNING_ACTIVE = burningState;
    }

    function setVerifier(address verifier_) external onlyOwner {
        _verifier = verifier_;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}