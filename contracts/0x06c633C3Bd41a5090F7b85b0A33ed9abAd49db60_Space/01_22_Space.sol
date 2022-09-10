// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./ISpace.sol";
import "./ISoulbound.sol";


contract Space is ISpace, Initializable, OwnableUpgradeable {
    using AddressUpgradeable for address;

    IUniswapV2Router02 private _uniswapV2Router;
    ISoulbound private _soulbound;
    address public _token;
    uint256 _mintFee;
    string public _uriSuffix;
    address _marketingWallet;

    string public _name;
    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => uint256) private _costs;
    mapping(uint256 => uint256) private _supplies;
    mapping(uint256 => uint256) private _minted;
    mapping(uint256 => string) private _attributes;
    mapping(uint256 => mapping(address => mapping(address => bool))) private _endorsements;
    uint256 private _attributeId;

    mapping(uint256 => mapping(address => bool)) private _links;
    mapping(uint256 => mapping(address => uint256)) private _power;

    string private _uri;

    function initialize(string memory uri_, string memory name_, address soulboundContract) public initializer {
        super.__Ownable_init();
        _token = 0x79A06aCb8bdd138BEEECcE0f1605971f3AC7c09B;
        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _mintFee = 0;
        _uriSuffix = ".json";
        _soulbound = ISoulbound(soulboundContract);
        _setURI(uri_);
        _name = name_;
        _attributeId = 1;
        emit SpaceCreated(_name, string(abi.encodePacked(_uri, "space", _uriSuffix)), _msgSender());
    }

    function endorse(uint256 attributeId, address to) external override onlySoulboundOwner {
        require(_balances[attributeId][to] >= 1, "Recipient has no attribute");
        require(_links[attributeId][to], "Attribute must be linked");
        require(!_endorsements[attributeId][to][_msgSender()], "Already endorsed");
        _power[attributeId][to] += 1;
        _endorsements[attributeId][to][_msgSender()] = true;
        emit AttributeEndorsed(_msgSender(), to, attributeId);
    }

    function endorsed(address from, address to, uint256 id) external view returns (bool) {
        require(from != address(0) && to != address(0), "Address must be non-zero");
        return _endorsements[id][to][_msgSender()];
    }

    function addAttribute(string memory name, uint256 cost, uint256 supply) external override onlyOwner {
        _attributes[_attributeId] = name;
        _costs[_attributeId] = cost;
        _supplies[_attributeId] = supply;
        emit AttributeAdded(_attributeId, name, cost, supply);
        _attributeId += 1;
    }

    function getAttribute(uint256 attributeId) external view override returns (string memory name, uint256 cost, uint256 supply) {
        name = _attributes[attributeId];
        cost = _costs[attributeId];
        supply = _supplies[attributeId];
    }

    function getSpaceName() external view returns (string memory)  {
        return _name;
    }

    function mint(uint256 attributeId) external override payable onlySoulboundOwner {
        require(attributeId < _attributeId, "Attribute does not exist");
        require(msg.value >= _costs[attributeId], "Insufficient amount");

        uint256 balance = _balances[attributeId][msg.sender];
        require(balance < 1, "Already minted");
        _swapEthForTokens();
        _mint(msg.sender, attributeId, 1, "");
        emit AttributeMinted(msg.sender, attributeId);
    }

    function link(uint256 attributeId) external override onlySoulboundOwner {
        require(_balances[attributeId][msg.sender] >= 1, "Sender has no attributes");
        require(!_links[attributeId][msg.sender], "Already Linked");
        _links[attributeId][msg.sender] = true;
        emit AttributeLinked(msg.sender, attributeId);
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC1155).interfaceId || interfaceId == type(IERC1155MetadataURI).interfaceId ||
        interfaceId == type(ISpace).interfaceId;
    }

    function uri(uint256 attributeId) public view override returns (string memory) {
        return string(abi.encodePacked(_uri, attributeId, _uriSuffix));
    }

    function setUriSuffix(string memory uriSuffix) public onlyOwner {
        _uriSuffix = uriSuffix;
    }

    function balanceOf(address account, uint256 id) public view override returns (uint256) {
        require(account != address(0), "Address must be non-zero");
        return _balances[id][account];
    }

    function isLinked(address account, uint256 id) external view returns (bool) {
        require(account != address(0), "Address must be non-zero");
        return _links[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) public view override returns (uint256[] memory){
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved) public override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "Caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "Transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "Transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "Insufficient balance for transfer");
        uint256 toBalance = _balances[id][to];
        require(amount == 1);
        require(toBalance == 0);
        require(!_links[id][from]);

    unchecked {
        _balances[id][from] = fromBalance - amount;
    }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "Ids and amounts length mismatch");
        require(to != address(0), "Transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            uint256 toBalance = _balances[id][to];
            require(amount == 1);
            require(fromBalance >= amount, "Insufficient balance for transfer");
            require(toBalance == 0);
            require(!_links[id][from]);

        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    function _setURI(string memory newuri) internal {
        _uri = newuri;
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "Mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;

        require((_supplies[id]) == 0 || (_minted[id] + amount <= _supplies[id]), "Supply exceeded");
        _minted[id] += amount;

        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "Mint to the zero address");
        require(ids.length == amounts.length, "Ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];

            require((_supplies[ids[i]] == 0) || (_minted[ids[i]] + amounts[i] <= _supplies[ids[i]]), "Supply exceeded");
            _minted[ids[i]] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "Setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("Transfer to non ERC1155Receiver implementer");
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
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("Transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    function _swapEthForTokens() private {
        address[] memory path = new address[](3);
        path[0] = _uniswapV2Router.WETH();
        path[1] = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        path[2] = _token;

        uint eth = msg.value;
        if (_mintFee != 0) {
            uint fees = eth * _mintFee / 100;
            payable(_marketingWallet).transfer(fees);
            eth -= fees;
        }

        _uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value : eth}(
            0,
            path,
            address(this),
            block.timestamp
        );

        ERC20(_token).transfer(address(0xdead), ERC20(_token).balanceOf(address(this)));
    }

    function setToken(address token) external onlyOwner {
        _token = token;
    }

    function setMintFee(uint256 mintFee) external onlyOwner {
        _mintFee = mintFee;
    }

    modifier onlySoulboundOwner() {
        require(_soulbound.id(_msgSender()) != 0, "Should own soulbound token");
        _;
    }

    function mintTo(
        address [] calldata to,
        uint256 attributeId
    ) external onlyOwner {
        require(attributeId < _attributeId, "Nonexisting attribute");

        for (uint256 i = 0; i < to.length; i++) {
            uint256 balance = _balances[attributeId][to[i]];
            require(balance < 1, "Already minted");
            _mint(msg.sender, attributeId, 1, "");
            emit AttributeMinted(to[i], attributeId);
        }
    }
}