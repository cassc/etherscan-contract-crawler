pragma solidity =0.5.16;

import "./libraries/Address.sol";
import "./libraries/SafeMath.sol";
import "./interfaces/IERC1155TokenReceiver.sol";
import "./Minter.sol";

contract MonetCardToken is Minter {
    using Address for address;
    using SafeMath for uint256;

    bytes4 private constant ERC1155_RECEIVED_VALUE = 0xf23a6e61;
    bytes4 private constant ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;
    bytes4 private constant ERC1155_INTERFACE_ID = 0xd9b67a26;

    mapping(address => mapping(uint256 => uint256)) internal _balances;
    mapping(address => mapping(address => bool)) internal _operators;
    mapping(uint256 => uint256) internal _totalSupplies;

    // VIEW

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return _operators[_owner][_operator];
    }

    function totalSupply(uint256 _id) public view returns (uint256) {
        return _totalSupplies[_id];
    }

    function balanceOf(address _owner, uint256 _id) external view returns (uint256) {
        return _balances[_owner][_id];
    }

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory) {
        require(_owners.length == _ids.length, "INVALID_ARRAY_LENGTH");

        uint256[] memory batchBalances = new uint256[](_owners.length);
        for (uint256 i = 0; i < _owners.length; i++) {
            batchBalances[i] = _balances[_owners[i]][_ids[i]];
        }
        return batchBalances;
    }

    function cardsNumOf(address _owner, uint256 _level,uint256 _carry) public view returns (uint256 nums) {
        for (uint256 i = 0; i < 4; i++) {
            uint256 num = _balances[_owner][_level.mul(10).add(i)];
            nums = nums.add((_carry**(3 - i)).mul(num));
        }
        return nums;
    }

    function cardsNumOfAll(address _owner, uint256 _carry) public view returns (uint256[10] memory nums) {
        uint256 levelMax = 10;
        for (uint256 i = 0; i < levelMax; i++) {
            nums[i] = cardsNumOf(_owner, levelMax.sub(i), _carry);
        }
    }

    function cardsTotalSupply() public view returns (uint256[40] memory nums) {
        uint256 idx;
        for (uint256 i = 10; i > 0; i--) {
            for (uint256 j = 0; j < 4; j++) {
                nums[idx++] = _totalSupplies[i.mul(10).add(j)];
            }
        }
    }

    function supportsInterface(bytes4 _interfaceID) external pure returns (bool) {
        return _interfaceID == ERC1155_INTERFACE_ID;
    }

    // PRIVATE
    function _mintBatch(address _to, uint256[] memory _ids, uint256[] memory _values) private {
        require(_to != address(0), "INVALID_RECIPIENT");

        uint256 size = _ids.length;
        for (uint256 i = 0; i < size; i++) {
            _totalSupplies[_ids[i]] = _totalSupplies[_ids[i]].add(_values[i]);
            _balances[_to][_ids[i]] = _balances[_to][_ids[i]].add(_values[i]);
        }
        emit TransferBatch(msg.sender, address(0), _to, _ids, _values);
    }

    function _safeBatchBurnFrom(address _from, uint256[] memory _ids, uint256[] memory _values ) private {
        require(_ids.length == _values.length, "INVALID_ARRAYS_LENGTH");

        uint256 size = _ids.length;
        for (uint256 i = 0; i < size; i++) {
            _balances[_from][_ids[i]] = _balances[_from][_ids[i]].sub(
                _values[i]
            );
            _totalSupplies[_ids[i]] = _totalSupplies[_ids[i]].sub(_values[i]);
        }

        emit TransferBatch(msg.sender, _from, address(0), _ids, _values);
    }

    function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount) private {
        _balances[_from][_id] = _balances[_from][_id].sub(_amount); // Subtract amount
        _balances[_to][_id] = _balances[_to][_id].add(_amount); // Add amount

        emit TransferSingle(msg.sender, _from, _to, _id, _amount);
    }

    function _safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) private {
        require(_ids.length == _amounts.length, "INVALID_ARRAYS_LENGTH");

        uint256 size = _ids.length;
        for (uint256 i = 0; i < size; i++) {
            _balances[_from][_ids[i]] = _balances[_from][_ids[i]].sub(
                _amounts[i]
            );
            _balances[_to][_ids[i]] = _balances[_to][_ids[i]].add(_amounts[i]);
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
    }

    function _callonERC1155Received(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data) private {
        if (_to.isContract()) {
            bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received(msg.sender, _from, _id, _amount, _data);
            require(retval == ERC1155_RECEIVED_VALUE, "INVALID_ON_RECEIVE_MESSAGE");
        }
    }

    function _callonERC1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) private {
        if (_to.isContract()) {
            bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived(msg.sender, _from, _ids, _amounts, _data );
            require(retval == ERC1155_BATCH_RECEIVED_VALUE, "INVALID_ON_RECEIVE_MESSAGE");
        }
    }

    // EXTERNAL
    function safeBatchMint(address _to, uint256[] calldata _ids, uint256[] calldata _values) external onlyMinter {
        require(_ids.length == _values.length, "INVALID_ARRAYS_LENGTH");
        _mintBatch(_to, _ids, _values);
    }

    function safeBatchBurnFrom(address _from, uint256[] calldata _ids, uint256[] calldata _amounts) external {
        require((msg.sender == _from) || isApprovedForAll(_from, msg.sender));

        _safeBatchBurnFrom(_from, _ids, _amounts);
    }

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external {
        require((msg.sender == _from) || isApprovedForAll(_from, msg.sender));
        require(_to != address(0), "INVALID_RECIPIENT");

        _safeTransferFrom(_from, _to, _id, _amount);
        _callonERC1155Received(_from, _to, _id, _amount, _data);
    }

    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external {
        require((msg.sender == _from) || isApprovedForAll(_from, msg.sender));
        require(_to != address(0), "INVALID_RECIPIENT");

        _safeBatchTransferFrom(_from, _to, _ids, _amounts);
        _callonERC1155BatchReceived(_from, _to, _ids, _amounts, _data);
    }

    function cardsBatchMint(address _to, uint256[] calldata _cards) external onlyMinter {
        uint256[] memory _ids = new uint256[](_cards.length);
        uint256[] memory _values = new uint256[](_cards.length);
        for (uint256 i = 0; i < _cards.length; i++) {
            _ids[i] = _cards[i] % 1000;
            _values[i] = _cards[i] / 1000;
        }
        _mintBatch(_to, _ids, _values);
    }

    function cardsBatchBurnFrom(address _from, uint256[] calldata _cards) external {
        require((msg.sender == _from) || isApprovedForAll(_from, msg.sender));

        uint256[] memory _ids = new uint256[](_cards.length);
        uint256[] memory _values = new uint256[](_cards.length);
        for (uint256 i = 0; i < _cards.length; i++) {
            _ids[i] = _cards[i] % 1000;
            _values[i] = _cards[i] / 1000;
        }

        _safeBatchBurnFrom(_from, _ids, _values);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        _operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    // EVENT
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _amount, uint256 indexed _id);
}