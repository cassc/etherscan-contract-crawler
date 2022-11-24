// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./Common.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SpiderTanks is IERC1155, ERC165, Pausable, CommonConstants, Ownable, IERC1155MetadataURI  {
    using Address for address;
    uint256 constant TYPE_MASK = uint256(type(uint128).max) << 128;
    uint256 public constant NF_INDEX_MASK = type(uint128).max;
    uint256 constant TYPE_NF_BIT = 1 << 255;
    uint256 nonce;

    string public client;

    mapping(uint256 => mapping(address => uint256)) internal balances; // id => (owner => balance)
    mapping(address => mapping(address => bool)) internal operatorApproval; // owner => (operator => approved)
    mapping(uint256 => address) public nfOwners;
    mapping(uint256 => bool) public nfExists;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(address => bool) internal creators;
    //URI mapping
    string private baseContractURI = "";
    string private baseURI = "";

    event Client(string _clientName);

    event Creator(address _creator, bool _authorized);

    event BaseURI(string baseURI);

    event ContractURI(string contractURI);

    constructor(string memory _client) {
        require(bytes(_client).length > 0, "Contract client name is required!");
        creators[msg.sender] = true;
        client = _client;
        emit Client(_client);
    }

    modifier creatorOnly() {
        require(creators[msg.sender], "Creator permission required");
        _;
    }

    function create(bool _isNF) external whenNotPaused creatorOnly returns (uint256 _type) {
        _type = (++nonce << 128);

        if (_isNF) {
            _type = _type | TYPE_NF_BIT;
            nfExists[_type] = true;
        }

        emit TransferSingle(msg.sender, address(0x0), address(0x0), _type, 0);

        broadcastURIEvent(_type);

        return _type;
    }

    function mintNonFungible(
        uint256[] calldata _ids,
        address[] calldata _to,
        bytes calldata _data
    ) external whenNotPaused creatorOnly {
        require(_ids.length == _to.length, "IDs and recipients must be of same length");
        for (uint256 i = 0; i < _to.length; ++i) {
            uint256 tokenType = getNonFungibleBaseType(_ids[i]);

            require(nfExists[tokenType], "NF token must exist");

            require(isNonFungible(tokenType), "TokenType not non-fungible");

            require(_to[i] != address(0x0), "Cannot mint to zero address");

            require(nfOwners[_ids[i]] == address(0x0), "Token already owned");

            address distributeTo = _to[i];

            nfOwners[_ids[i]] = distributeTo;

            tokenSupply[tokenType] = tokenSupply[tokenType] + 1;
            balances[tokenType][distributeTo] = balances[tokenType][distributeTo] + 1;

            emit TransferSingle(msg.sender, address(0x0), distributeTo, _ids[i], 1);

            broadcastURIEvent(_ids[i]);

            if (distributeTo.isContract()) {
                _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, distributeTo, _ids[i], 1, _data);
            }
        }
    }

    function mintFungible(
        uint256 _id,
        address[] calldata _to,
        uint256[] calldata _quantities,
        bytes calldata _data
    ) external whenNotPaused creatorOnly {
        require(isFungible(_id), "ID must be a non-fungible ID");
        require(_to.length == _quantities.length, "Address and quantity length mismatch");
        for (uint256 i = 0; i < _to.length; ++i) {
            require(_to[i] != address(0x0), "Recipient address cannot be zero");
            balances[_id][_to[i]] = _quantities[i] + balances[_id][_to[i]];
            tokenSupply[_id] = tokenSupply[_id] + _quantities[i];

            emit TransferSingle(msg.sender, address(0x0), _to[i], _id, _quantities[i]);

            broadcastURIEvent(_id);

            if (_to[i].isContract()) {
                _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, _to[i], _id, _quantities[i], _data);
            }
        }
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external override whenNotPaused {
        require(_to != address(0x0), "cannot send to zero address");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers");

        if (isNonFungible(_id)) {
            require(nfOwners[_id] == _from, "Invalid owner");
            require(_value > 0, "quantity must be greater than zero");
            nfOwners[_id] = _to;
            // You could keep balance of NF type in base type id like so:
            uint256 baseType = getNonFungibleBaseType(_id);
            balances[baseType][_from] = balances[baseType][_from] - _value;
            balances[baseType][_to] = balances[baseType][_to] + _value;
        } else {
            balances[_id][_from] = balances[_id][_from] - _value;
            balances[_id][_to] = balances[_id][_to] + _value;
        }

        emit TransferSingle(msg.sender, _from, _to, _id, _value);

        if (_to.isContract()) {
            _doSafeTransferAcceptanceCheck(msg.sender, _from, _to, _id, _value, _data);
        }
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external override whenNotPaused {
        require(_to != address(0x0), "Cannot send to zero address");
        require(_ids.length == _values.length, "Array length must match");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers");

        for (uint256 i = 0; i < _ids.length; ++i) {
            if (isNonFungible(_ids[i])) {
                require(nfOwners[_ids[i]] == _from, "Invalid owner");
                require(_values[i] > 0, "quantity must be greater than zero");
                nfOwners[_ids[i]] = _to;
                balances[getNonFungibleBaseType(_ids[i])][_from] = balances[getNonFungibleBaseType(_ids[i])][_from] - _values[i];
                balances[getNonFungibleBaseType(_ids[i])][_to] = balances[getNonFungibleBaseType(_ids[i])][_to] + _values[i];
            } else {
                balances[_ids[i]][_from] = balances[_ids[i]][_from] - _values[i];
                balances[_ids[i]][_to] = _values[i] + balances[_ids[i]][_to];
            }
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _values);

        if (_to.isContract()) {
            _doSafeBatchTransferAcceptanceCheck(msg.sender, _from, _to, _ids, _values, _data);
        }
    }

    function balanceOf(address _owner, uint256 _id) external view override returns (uint256) {
        if (isNonFungibleItem(_id)) return nfOwners[_id] == _owner ? 1 : 0;
        return balances[_id][_owner];
    }

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view override returns (uint256[] memory) {
        require(_owners.length == _ids.length, "Owners and ids length mismatch");
        uint256[] memory balances_ = new uint256[](_owners.length);
        for (uint256 i = 0; i < _owners.length; ++i) {
            uint256 id = _ids[i];
            if (isNonFungibleItem(id)) {
                balances_[i] = nfOwners[id] == _owners[i] ? 1 : 0;
            } else {
                balances_[i] = balances[id][_owners[i]];
            }
        }

        return balances_;
    }

    function setApprovalForAll(address _operator, bool _approved) external override whenNotPaused {
        require(msg.sender != _operator, "ERC1155: setting approval status for self");
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) external view override returns (bool) {
        return operatorApproval[_owner][_operator];
    }

    function isNonFungible(uint256 _id) public pure returns (bool) {
        return _id & TYPE_NF_BIT == TYPE_NF_BIT;
    }

    function isFungible(uint256 _id) public pure returns (bool) {
        return _id & TYPE_NF_BIT == 0;
    }

    function getNonFungibleIndex(uint256 _id) public pure returns (uint256) {
        return _id & NF_INDEX_MASK;
    }

    function getNonFungibleBaseType(uint256 _id) public pure returns (uint256) {
        return _id & TYPE_MASK;
    }

    function isNonFungibleBaseType(uint256 _id) external pure returns (bool) {
        // A base type has the NF bit but does not have an index.
        return (_id & TYPE_NF_BIT == TYPE_NF_BIT) && (_id & NF_INDEX_MASK == 0);
    }

    function isNonFungibleItem(uint256 _id) public pure returns (bool) {
        // A base type has the NF bit but does has an index.
        return (_id & TYPE_NF_BIT == TYPE_NF_BIT) && (_id & NF_INDEX_MASK != 0);
    }

    function ownerOf(uint256 _id) external view returns (address) {
        return nfOwners[_id];
    }

    function _doSafeTransferAcceptanceCheck(
        address _operator,
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes memory _data
    ) internal {
        require(
            ERC1155Receiver(_to).onERC1155Received(_operator, _from, _id, _value, _data) == ERC1155_ACCEPTED,
            "contract returned an unknown value from onERC1155Received"
        );
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address _operator,
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _values,
        bytes memory _data
    ) internal {
        require(
            ERC1155Receiver(_to).onERC1155BatchReceived(_operator, _from, _ids, _values, _data) == ERC1155_BATCH_ACCEPTED,
            "contract returned an unknown value from onERC1155BatchReceived"
        );
    }

    function batchAuthorizeCreators(address[] calldata _addresses) external whenNotPaused onlyOwner {
        for (uint256 i = 0; i < _addresses.length; ++i) {
            emit Creator(_addresses[i], true);
            creators[_addresses[i]] = true;
        }
    }

    function batchDeauthorizeCreators(address[] calldata _addresses) external whenNotPaused onlyOwner {
        for (uint256 i = 0; i < _addresses.length; ++i) {
            delete creators[_addresses[i]];
            emit Creator(_addresses[i], false);
        }
    }

    function burn(
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values
    ) external whenNotPaused {
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party burn");
        require(_ids.length > 0 && _ids.length == _values.length, "Ids and values mismatch");
        for (uint256 i = 0; i < _ids.length; i++) {
            if (isFungible(_ids[i])) {
                require(balances[_ids[i]][_from] >= _values[i],"balance must be greater than value");
                balances[_ids[i]][_from] = balances[_ids[i]][_from] - _values[i];
                tokenSupply[_ids[i]] = tokenSupply[_ids[i]] - _values[i];
            } else {
                require(isNonFungible(_ids[i]), "Id must be non fungible");
                require(_values[i] == 1,"value must be 1");
                uint256 baseType = getNonFungibleBaseType(_ids[i]);
                balances[baseType][_from] = balances[baseType][_from] - 1;
                tokenSupply[baseType] = tokenSupply[baseType] - _values[i];
                delete nfOwners[_ids[i]];
            }
            emit TransferSingle(msg.sender, _from, address(0x0), _ids[i], _values[i]);
        }
    }

    function uri(uint256 _tokenId) public override view returns (string memory) {
        if (isNonFungible(_tokenId)) {
            uint256 baseType = getNonFungibleBaseType(_tokenId);
            uint256 instanceId = getNonFungibleIndex(_tokenId);
            return string(abi.encodePacked(baseURI, Strings.toString(baseType), "/", Strings.toString(instanceId)));
        } else {
            return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
        }
    }

    function broadcastURIEvent(uint256 _tokenId) public creatorOnly {
        string memory uri = uri(_tokenId);
        emit URI(uri, _tokenId);
    }

    function setBaseURI(string memory _baseURI) external creatorOnly {
        baseURI = _baseURI;
        emit BaseURI(baseURI);
    }

    function contractURI() external view returns (string memory) {
        return baseContractURI;
    }

    function setContractURI(string memory _contractUri) external onlyOwner {
        baseContractURI = _contractUri;
        emit ContractURI(baseContractURI);
    }

    function updateClientName(string calldata _newClientName) external whenNotPaused onlyOwner {
        require(bytes(_newClientName).length > 0, "Client name cannot be empty");
        client = _newClientName;
        emit Client(_newClientName);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return _interfaceId == type(IERC1155).interfaceId || _interfaceId == type(IERC1155MetadataURI).interfaceId ||super.supportsInterface(_interfaceId);
    }
}