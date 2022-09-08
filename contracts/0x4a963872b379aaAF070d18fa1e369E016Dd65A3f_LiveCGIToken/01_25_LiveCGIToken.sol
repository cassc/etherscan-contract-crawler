// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface MessageProxy {
    function postOutgoingMessage(
        bytes32 targetChainHash,
        address targetContract,
        bytes calldata data
    ) external;
}

contract LiveCGIToken is
    ERC1155PresetMinterPauser,
    ERC1155Supply,
    ERC1155Holder,
    ERC2981,
    Ownable
{
    using Strings for uint256;

    string internal _baseUri;
    MessageProxy public messageProxy;
    bytes32 public targetChainHash;
    address public targetContract;
    uint96 public royaltyfeeNumerator;

    mapping(address => bool) public isBlacklisted;

    constructor(
        string memory uri_,
        address _messageProxy,
        bytes32 _targetChainHash,
        uint96 _royaltyfeeNumerator
    ) ERC1155PresetMinterPauser(uri_) {
        require(
            _royaltyfeeNumerator <= _feeDenominator(),
            "LiveCGIToken: royalty fee will exceed salePrice"
        );

        _baseUri = uri_;
        messageProxy = MessageProxy(_messageProxy);
        targetChainHash = _targetChainHash;
        royaltyfeeNumerator = _royaltyfeeNumerator;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "LiveCGIToken: must have admin role"
        );
        _;
    }

    function uri(uint256 _id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(_baseUri, _id.toString()));
    }

    function bridge(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(from, id, amount);

        bytes memory bridgedData = abi.encode(to, id, amount, data);

        messageProxy.postOutgoingMessage(
            targetChainHash,
            targetContract,
            bridgedData
        );
    }

    function postMessage(
        bytes32 schainHash,
        address sender,
        bytes calldata bridgedData
    ) external returns (address) {
        require(
            address(messageProxy) == _msgSender(),
            "ERC1155Token: Invalid Message Proxy"
        );
        require(
            schainHash == targetChainHash,
            "ERC1155Token: Invalid source chain"
        );

        (address to, uint256 id, uint256 amount, bytes memory data) = abi
            .decode(bridgedData, (address, uint256, uint256, bytes));

        _mint(to, id, amount, data);

        return sender;
    }

    function setURI(string memory newuri) external onlyAdmin {
        _setURI(newuri);
        _baseUri = newuri;
    }

    function addBlacklist(address _user) external onlyAdmin {
        isBlacklisted[_user] = true;
    }

    function removeBlacklist(address _user) external onlyAdmin {
        isBlacklisted[_user] = false;
    }

    function setMessageProxy(address _messageProxy) external onlyAdmin {
        messageProxy = MessageProxy(_messageProxy);
    }

    function setTargetChainHash(bytes32 _targetChainHash) external onlyAdmin {
        targetChainHash = _targetChainHash;
    }

    function setTargetContract(address _targetContract) external onlyAdmin {
        targetContract = _targetContract;
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyAdmin {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) external onlyAdmin {
        _resetTokenRoyalty(tokenId);
    }

    function setRoyaltyfeeNumerator(uint96 _royaltyfeeNumerator)
        external
        onlyAdmin
    {
        require(
            _royaltyfeeNumerator <= _feeDenominator(),
            "LiveCGIToken: royalty fee will exceed salePrice"
        );
        royaltyfeeNumerator = _royaltyfeeNumerator;
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        if (!exists(id)) _setTokenRoyalty(id, to, royaltyfeeNumerator);

        super._mint(to, id, amount, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        for (uint256 i = 0; i < ids.length; i++) {
            if (!exists(ids[i]))
                _setTokenRoyalty(ids[i], to, royaltyfeeNumerator);
        }

        super._mintBatch(to, ids, amounts, data);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual override {
        super._burn(from, id, amount);

        if (!exists(id)) _resetTokenRoyalty(id);
    }

    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override {
        super._burnBatch(from, ids, amounts);

        for (uint256 i = 0; i < ids.length; i++) {
            if (!exists(ids[i])) _resetTokenRoyalty(ids[i]);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC1155PresetMinterPauser, ERC1155Receiver, ERC2981)
        returns (bool)
    {
        return
            ERC1155.supportsInterface(interfaceId) ||
            ERC1155PresetMinterPauser.supportsInterface(interfaceId) ||
            ERC1155Receiver.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
        override(ERC1155PresetMinterPauser, ERC1155Supply)
        whenNotPaused
    {
        require(!isBlacklisted[from], "Sender is Blacklisted!");
        require(!isBlacklisted[to], "Receiver is Blacklisted!");
        require(!isBlacklisted[operator], "Operator is Blacklisted!");

        ERC1155Supply._beforeTokenTransfer(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }
}