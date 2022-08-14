// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./IERC721G.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ERC721G is Context, ERC165, IERC721G, IERC721Metadata, AccessControl, Pausable {
    using Address for address;
    using Strings for uint256;

    string private _name;
    string private _symbol;
    mapping(uint256 => address) internal _owners;
    mapping(address => uint256) internal _balances;
    mapping(uint256 => address) internal _tokenApprovals;
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    //keccak256("MINTER_ROLE");
    bytes32 internal constant MINTER_ROLE = 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6;
    //keccak256("PAUSER_ROLE");
    bytes32 internal constant PAUSER_ROLE = 0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a;
    //keccak256("BURNER_ROLE");
    bytes32 internal constant BURNER_ROLE = 0x3c11d16cbaffd01df69ce1c404f6340ee057498f5f00246190ea54220576a848;

    uint256 internal _totalSupply;
    string internal __baseURI;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) {
        _name = name_;
        _symbol = symbol_;
        __baseURI = baseURI_;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
    }

    //functions from ERC721
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721G: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721G: invalid token ID");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return __baseURI;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721G.ownerOf(tokenId);
        require(to != owner, "ERC721G: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721G: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721G: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721G: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721G: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721G.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721G: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721G: mint to the zero address");
        require(!_exists(tokenId), "ERC721G: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721G.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721G.ownerOf(tokenId) == from, "ERC721G: transfer from incorrect owner");
        require(to != address(0), "ERC721G: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721G.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721G: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721G: invalid token ID");
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721G: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (from == address(0)) {
            _totalSupply++;
        }
        if (to == address(0)) {
            _totalSupply--;
        }

        require(!paused(), "ERC721G: token transfer while paused");
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    //operational functions
    function setBaseURI(string calldata baseURI_) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ERC721G: must be default admin");

        __baseURI = baseURI_;
        emit SetBaseURI(baseURI_);
    }

    function setPause(bool status) external {
        require(hasRole(PAUSER_ROLE, msg.sender), "ERC721G: must have pauser role to pause");

        if (status) _pause();
        else _unpause();
    }

    //view functions
    function exists(uint256 tokenId) external view virtual returns (bool) {
        return _exists(tokenId);
    }

    function totalSupply() external view virtual returns (uint256) {
        return _totalSupply;
    }

    //mint/burn/transfer
    function mint(address to, uint256 tokenId) public virtual {
        require(hasRole(MINTER_ROLE, msg.sender), "ERC721G: must have minter role to mint");

        _mint(to, tokenId);
    }

    function mintBatch(address to, uint256[] calldata tokenIds) external virtual {
        require(hasRole(MINTER_ROLE, msg.sender), "ERC721G: must have minter role to mint");

        _mintBatch(to, tokenIds);
    }

    function burn(uint256 tokenId) external virtual {
        require(hasRole(BURNER_ROLE, msg.sender), "ERC721G: must have burner role to burn");

        require(_isApprovedOrOwner(msg.sender, tokenId), "UNAUTHORIZED");
        _burn(tokenId);
    }

    function burnBatch(address from, uint256[] calldata tokenIds) external virtual {
        require(hasRole(BURNER_ROLE, msg.sender), "ERC721G: must have burner role to burn");

        require(from != address(0), "BURN_FROM_ADDRESS_0");
        uint256 amount = tokenIds.length;
        require(amount > 0, "INVALID_AMOUNT");
        bool passChecking;
        if (msg.sender == from || isApprovedForAll(from, msg.sender)) passChecking = true;

        _beforeTokenBatchTransfer(from, address(0), tokenIds);

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = tokenIds[i];
            require(_owners[tokenId] == from, "OWNER_FROM_NOT_EQUAL");
            if (!passChecking) require(getApproved(tokenId) == msg.sender, "UNAUTHORIZED");
            // Clear approvals
            _approve(address(0), tokenId);
            delete _owners[tokenId];
            emit Transfer(from, address(0), tokenId);
        }
        _balances[from] -= amount;
    }

    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds
    ) external virtual {
        require(from != address(0), "TRANSFER_FROM_ADDRESS_0");
        require(to != address(0), "TRANSFER_TO_ADDRESS_0");
        uint256 amount = tokenIds.length;
        require(amount > 0, "INVALID_AMOUNT");
        bool passChecking;
        if (msg.sender == from || isApprovedForAll(from, msg.sender)) passChecking = true;

        _beforeTokenBatchTransfer(from, to, tokenIds);

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = tokenIds[i];
            require(_owners[tokenId] == from, "OWNER_FROM_NOT_EQUAL");
            if (!passChecking) require(getApproved(tokenId) == msg.sender, "UNAUTHORIZED");
            // Clear approvals
            _approve(address(0), tokenId);
            _owners[tokenId] = to;
            emit Transfer(from, to, tokenId);
        }

        _balances[from] -= amount;
        _balances[to] += amount;
    }

    function _mintBatch(address to, uint256[] calldata tokenIds) internal virtual {
        require(to != address(0), "MINT_TO_ADDRESS_0");
        uint256 amount = tokenIds.length;
        require(amount > 0, "INVALID_AMOUNT");

        _beforeTokenBatchTransfer(address(0), to, tokenIds);
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = tokenIds[i];
            require(!_exists(tokenId), "ALREADY_MINTED");

            _owners[tokenId] = to;
            emit Transfer(address(0), to, tokenId);
        }
        _balances[to] += amount;
    }

    function _beforeTokenBatchTransfer(
        address from,
        address to,
        uint256[] calldata tokenIds
    ) internal virtual {
        if (from == address(0)) {
            _totalSupply += tokenIds.length;
        }
        if (to == address(0)) {
            _totalSupply -= tokenIds.length;
        }

        require(!paused(), "ERC721G: token transfer while paused");
    }
}