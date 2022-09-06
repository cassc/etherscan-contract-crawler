// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./interfaces/IERC721.sol";
import "./utils/Address.sol";
import "./utils/Context.sol";
import "./utils/Strings.sol";
import "./utils/ERC165.sol";
import "./extensions/IERC721Metadata.sol";
import "./extensions/IERC721Enumerable.sol";
import "./ERC721Receiver.sol";
import "./utils/Ownable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is
    Context,
    ERC165,
    IERC721,
    IERC721Enumerable,
    IERC721Metadata,
    ERC721Receiver,
    Ownable
{
    using Address for address;
    using Strings for uint256;

    event AdminSet(address _admin, bool _isAdmin);

    event SetNewPlatformFee(uint256 _newFee);

    event SetNewDefaultRoyalties(uint256 _min, uint256 _max);

    event SetNewPool(address _pool);

    event SetNewLaunchPad(address _launchPad);

    event SetNewPlatformFeeAddress(address _platformFeeAddress);

    event Mint(
        uint256 indexed tokenId,
        address indexed creator,
        address indexed to,
        uint256 royalty,
        bool isRoot
    );

    bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;

    string private _name;

    string private _symbol;

    uint256 public MAX_FRAGMENT = 5000;

    uint256[] internal _allTokens;

    mapping(uint256 => address) internal _owners;

    mapping(address => uint256) internal _balances;

    mapping(uint256 => mapping(address => uint256)) internal _balancesOfToken;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(address => bool) internal _admins;

    mapping(uint256 => bool) internal lockedTokens;

    mapping(uint256 => string) internal _tokenURIs;

    mapping(address => mapping(uint256 => uint256)) internal _ownedTokens;

    mapping(uint256 => uint256) private _ownedTokensIndex;

    mapping(uint256 => uint256) private _allTokensIndex;

    mapping(uint256 => uint256) internal _rootIdOf;

    mapping(uint256 => uint256[]) internal _fragments;

    mapping(uint256 => bool) internal _rootTokens;

    mapping(uint256 => bool) internal _fragmentTokens;

    mapping(uint256 => address[]) internal _subOwners;

    mapping(uint256 => mapping(address => uint256)) private _indexSubOwners;

    address internal _launchPad;

    struct Token {
        uint256 id;
        uint256 rootId;
        uint256 price;
        address token;
        address owner;
        address creator;
        string uri;
        bool status;
        bool isRoot;
        bool isFragment;
    }

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        transferOwnership(msg.sender);
        _admins[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(
            _admins[msg.sender] ||
                owner() == msg.sender ||
                _launchPad == msg.sender,
            "Only admin or owner or launchpad"
        );
        _;
    }

    modifier onlyLaunchpad() {
        require(_launchPad == msg.sender, "Only launchpad");
        _;
    }

    modifier tokenNotFound(uint256 _tokenId) {
        require(exists(_tokenId), "isn't exist");
        _;
    }

    modifier isNotRootToken(uint256 _tokenId) {
        require(!_rootTokens[_tokenId], "is root");
        _;
    }

    modifier isNotFragments(uint256 _tokenId) {
        require(!_fragmentTokens[_tokenId], "is fragments");
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address _owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(_owner != address(0), "Zero address");
        return _balances[_owner];
    }

    function balanceOfToken(uint256 _tokenId, address _owner)
        public
        view
        virtual
        returns (uint256)
    {
        require(_owner != address(0), "Zero address");
        return _balancesOfToken[_tokenId][_owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address _owner = _owners[tokenId];
        require(_owner != address(0), "Not existed");
        return _owner;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address _owner = ERC721.ownerOf(tokenId);
        require(to != _owner, "Bad owner");

        require(
            _msgSender() == _owner || isApprovedForAll(_owner, _msgSender()),
            "not owner nor approved all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(exists(tokenId), "Not existed");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "Bad operator");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address _owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[_owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Bad sender");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Bad sender");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "non ERC721Receiver"
        );
    }

    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(exists(tokenId), "Bad tokenId");
        address _owner = ERC721.ownerOf(tokenId);
        return (spender == _owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(_owner, spender));
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        uint256 rootId,
        string memory uri
    ) internal virtual {
        _safeMint(to, tokenId, rootId, "", uri);
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        uint256 rootId,
        bytes memory _data,
        string memory _uri
    ) internal virtual {
        _mint(to, tokenId, rootId, _uri);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "non ERC721Receiver"
        );
    }

    function _mint(
        address to,
        uint256 tokenId,
        uint256 rootId,
        string memory uri
    ) internal virtual {
        require(to != address(0), "Zero address");
        require(!exists(tokenId), "Existed");
        require(
            _fragments[rootId].length < MAX_FRAGMENT,
            "Max fragment exceeded"
        );
        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;
        _setTokenURI(tokenId, uri);
        _rootIdOf[tokenId] = rootId;

        _fragments[rootId].push(tokenId);
        if (rootId != 0) {
            _fragmentTokens[tokenId] = true;
            if (_balancesOfToken[rootId][to] == 0) {
                _indexSubOwners[rootId][to] =
                    _subOwners[_rootIdOf[tokenId]].length +
                    1;
                _subOwners[rootId].push(to);
            }
            _balancesOfToken[rootId][to] += 1;
        }
        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "Not owner");
        require(to != address(0), "Zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        if (_fragmentTokens[tokenId]) {
            if (_balancesOfToken[_rootIdOf[tokenId]][to] == 0) {
                _indexSubOwners[_rootIdOf[tokenId]][to] =
                    _subOwners[_rootIdOf[tokenId]].length +
                    1;
                _subOwners[_rootIdOf[tokenId]].push(to);
            }
            _balancesOfToken[_rootIdOf[tokenId]][from] -= 1;

            if (_balancesOfToken[_rootIdOf[tokenId]][from] == 0) {
                _removeSubOwner(from, _rootIdOf[tokenId]);
            }

            _balancesOfToken[_rootIdOf[tokenId]][to] += 1;
        }

        emit Transfer(from, to, tokenId);
    }

    function _burn(address account, uint256 tokenId) internal virtual {
        require(account != address(0), "Bad account");

        _beforeTokenTransfer(account, address(0), tokenId);

        uint256 accountBalance = _balances[account];
        require(accountBalance > 0, "Bad balance");
        unchecked {
            _balances[account] = accountBalance - 1;
        }
        _owners[tokenId] = address(0);

        emit Transfer(account, address(0), tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _removeSubOwner(address subOwner, uint256 tokenId)
        internal
        virtual
    {
        uint256 subOwnerIndex = _indexSubOwners[tokenId][subOwner];
        uint256 toDeleteIndex = subOwnerIndex - 1;
        uint256 lastSubOwnerIndex = _subOwners[tokenId].length - 1;

        if (toDeleteIndex != lastSubOwnerIndex) {
            address lastSubOwner = _subOwners[tokenId][lastSubOwnerIndex];

            _subOwners[tokenId][toDeleteIndex] = lastSubOwner;
            _indexSubOwners[tokenId][lastSubOwner] = toDeleteIndex + 1;
        }

        delete _indexSubOwners[tokenId][subOwner];
        _subOwners[tokenId].pop();
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                ERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == ERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("non ERC721Receiver");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function tokenOfOwnerByIndex(address _owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(index < ERC721.balanceOf(_owner), "out of bounds");
        return _ownedTokens[_owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(index < totalSupply(), "global index out of bounds");
        return _allTokens[index];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (from == address(0)) {
            _allTokensIndex[tokenId] = _allTokens.length;
            _allTokens.push(tokenId);
        } else if (from != to) {
            uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
            uint256 tokenIndex = _ownedTokensIndex[tokenId];

            if (tokenIndex != lastTokenIndex) {
                uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

                _ownedTokens[from][tokenIndex] = lastTokenId;
                _ownedTokensIndex[lastTokenId] = tokenIndex;
            }

            delete _ownedTokensIndex[tokenId];
            delete _ownedTokens[from][lastTokenIndex];
        }
        if (to == address(0)) {
            uint256 lastTokenIndex = _allTokens.length - 1;
            uint256 tokenIndex = _allTokensIndex[tokenId];

            uint256 lastTokenId = _allTokens[lastTokenIndex];

            _allTokens[tokenIndex] = lastTokenId;
            _allTokensIndex[lastTokenId] = tokenIndex;

            delete _allTokensIndex[tokenId];
            // delete all framents if existed
            delete _fragments[tokenId];
            _allTokens.pop();
        } else if (to != from) {
            uint256 length = ERC721.balanceOf(to);
            _ownedTokens[to][length] = tokenId;
            _ownedTokensIndex[tokenId] = length;
        }
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        require(ERC721.exists(tokenId), "Existed");
        return _tokenURIs[tokenId];
    }

    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(ERC721.exists(tokenId), "Existed");
        _tokenURIs[tokenId] = uri;
    }

    function setAdmin(address _user, bool _isAdmin) public onlyOwner {
        require(_user != address(0));
        _admins[_user] = _isAdmin;

        emit AdminSet(_user, _isAdmin);
    }

    function isAdmin(address _admin) public view returns (bool) {
        return _admins[_admin];
    }

    function isRootTokenOwner(uint256 _tokenId, address owner)
        public
        view
        returns (bool)
    {
        return _rootTokens[_tokenId] && ownerOf(_tokenId) == owner;
    }
}