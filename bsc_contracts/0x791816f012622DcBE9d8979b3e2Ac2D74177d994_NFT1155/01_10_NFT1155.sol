// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";

contract NFT1155 is
    Ownable,
    IERC165,
    IERC1155,
    IERC1155MetadataURI,
    ReentrancyGuard
{
    using Address for address;
    using Strings for uint256;
    string public name;
    string public symbol;
    string public baseURI;
    address public platform;
    uint256 public maxSupply;
    uint256 public totalSupply;
    uint256 public perIdMaxSupply;
    mapping(uint256 => uint256) private perIdMintMap;
    // true：unlimited，false：limited
    bool public unlimitedSupply;
    bool public unlimitedPerIdSupply;
    mapping(uint256 => bool) public tokenIds;
    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor() {
        name = "NFT1155";
        symbol = "NFT1155";
        maxSupply = 10000;
        unlimitedSupply = false;
        unlimitedPerIdSupply = false;
        totalSupply = 0;
        perIdMaxSupply = 10;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            account != address(0),
            "ERC1155: address zero is not a valid owner"
        );
        return _balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "ERC1155: accounts and ids length mismatch"
        );
        uint256[] memory batchBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }
        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(
            msg.sender != operator,
            "ERC1155: setting approval status for self"
        );
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        address operator = msg.sender;
        require(
            from == operator || isApprovedForAll(from, operator),
            "ERC1155: caller is not token owner nor approved"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");
        uint256 fromBalance = _balances[id][from];
        require(
            fromBalance >= amount,
            "ERC1155: insufficient balance for transfer"
        );
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;
        emit TransferSingle(operator, from, to, id, amount);
        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        address operator = msg.sender;
        require(
            from == operator || isApprovedForAll(from, operator),
            "ERC1155: caller is not token owner nor approved"
        );
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155: insufficient balance for transfer"
            );
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }
        emit TransferBatch(operator, from, to, ids, amounts);
        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    function _checkOnERC1155Received(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            return
                IERC1155Receiver(to).onERC1155Received(
                    msg.sender,
                    from,
                    tokenId,
                    amount,
                    _data
                ) == IERC1155Receiver.onERC1155Received.selector;
        } else {
            return true;
        }
    }

    function safeMint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner {
        _safeMint(to, tokenId, amount);
    }

    function _safeMint(
        address to,
        uint256 id,
        uint256 amount
    ) internal virtual {
        _safeMint(to, id, amount, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId, amount, "");
        require(
            _checkOnERC1155Received(address(0), to, tokenId, amount, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function isExistTokenId(uint256 tokenId) public view returns (bool) {
        return tokenIds[tokenId];
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        if (!isExistTokenId(id)) {
            tokenIds[id] = true;
            if (unlimitedSupply) {
                require(
                    maxSupply >= totalSupply + 1,
                    "ERC1155: maximum supply exceeded"
                );
            }
        }
        if (unlimitedPerIdSupply) {
            require(
                perIdMaxSupply >= perIdMintMap[id] + amount,
                "ERC1155: maximum per id supply exceeded"
            );
        }
        address operator = msg.sender;
        _balances[id][to] += amount;
        perIdMintMap[id] += amount;
        totalSupply += 1;
        emit TransferSingle(operator, address(0), to, id, amount);
        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            id,
            amount,
            data
        );
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, id.toString()))
                : "";
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        return uri(_tokenId);
    }

    function _setBaseURI(string memory baseURI_) internal virtual {
        baseURI = baseURI_;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        _setBaseURI(_baseURI);
    }

    function _setPlatform(address _platform) internal virtual {
        platform = _platform;
    }

    function setPlatform(address _platform) external onlyOwner {
        _setPlatform(_platform);
    }

    function _isLaunchpadPlatform(address spender)
        internal
        view
        virtual
        returns (bool)
    {
        return (spender == platform);
    }

    function setBaseURIByLaunchpadPlatform(string calldata _baseURI)
        external
        nonReentrant
    {
        if (_isLaunchpadPlatform(_msgSender())) {
            _setBaseURI(_baseURI);
        }
    }

    function mintByLaunchpadPlatform(
        address to,
        uint256 tokenId,
        uint256 quantity
    ) external nonReentrant {
        if (_isLaunchpadPlatform(_msgSender())) {
            _safeMint(to, tokenId, quantity);
        }
    }
}