// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.13;
import "./SafeMath.sol";
import "./IERC1155.sol";
import "./ERC165.sol";
import "./IHandlerCallback.sol";
import "./IsSerializedUpgradable.sol";
import "./Clonable.sol";
// import "./Stream.sol";
// import "./EventableERC1155.sol";
import "./ERC2981Royalties.sol";
import "./UpgradableERC1155.sol";
import "operator-filter-registry/src/upgradeable/OperatorFiltererUpgradeable.sol";

contract ERC1155Upgradable is ERC165, IERC1155MetadataURI, IsSerializedUpgradable, Clonable, ERC2981Royalties, UpgradableERC1155, OperatorFiltererUpgradeable {
    using SafeMath for uint256;
    address payable public streamAddress;

    mapping (uint256 => mapping(address => uint256)) private _balances;
    mapping (address => mapping(address => bool)) private _operatorApprovals;
    mapping (uint256 => bool) private usedTokenId;
    // uint256[] public tokenIds;

    string private name;
    string private symbol;

    string private _uri;

    mapping (address => mapping (uint => bool)) seenInBlock;

    mapping(uint256 => mapping(address => uint256[])) internal tokenIdToOwnerToSerialNumbers;

    address private serialManagerAddress;
    uint private managerUpgradeBlock;

    constructor () {
        // __Ownable_init();
    }

    function initialize() public override initializer {
        __Ownable_init();
        _registerInterface(0xd9b67a26); //_INTERFACE_ID_ERC1155
        _registerInterface(0x0e89341c); //_INTERFACE_ID_ERC1155_METADATA_URI
        initializeERC165();
        _registerInterface(0x2a55205a); // ERC2981
        __OperatorFilterer_init(0x9dC5EE2D52d014f8b81D662FA8f4CA525F27cD6b, true);
        _uri = "https://api.emblemvault.io/s:evmetadata/meta/"; 
        serialized = true;
        overloadSerial = true;
        isClaimable = true;
    }

    // function fireEvent( address _to, uint256 _tokenId, uint256 _amount) public onlyOwner {
    //     emit TransferSingle(_msgSender(), address(0), _to, _tokenId, _amount);
    // }

    // function fireEvents(address[] memory _to, uint256[] memory _tokenIds, uint256[] memory _amounts) public onlyOwner {
    //     for (uint i = 0; i < _tokenIds.length; i++) {
    //         emit TransferSingle(_msgSender(), address(0), _to[i], _tokenIds[i], _amounts[i]);
    //     }
    // }

    // function initSerialManager(address _address) public onlyOwner {
    //     require(serialManagerAddress == address(0), "Already initialized");
    //     serialManagerAddress = _address;
    //     managerUpgradeBlock = block.number;
    // }

    // function updateSerialManagerBlock(uint _block) public onlyOwner {
    //     managerUpgradeBlock = _block;
    // }

    function version() public pure override returns(uint256) {
        return 12;
    }

    function changeName(string calldata _name, string calldata _symbol) public onlyOwner {
      name = _name;
      symbol = _symbol;
    }

    function mint(address _to, uint256 _tokenId, uint256 _amount) public onlyOwner {
        bytes memory empty = abi.encodePacked(uint256(0));        
        mintWithSerial(_to, _tokenId, _amount, empty);
    }

    function mintWithSerial(address _to, uint256 _tokenId, uint256 _amount, bytes memory serialNumber) public onlyOwner {
        _mint(_to, _tokenId, _amount, serialNumber);
    }

    function migrationMint(uint256 serialNumber, address account, uint256 tokenId) public onlyOwner {
        tokenIdToSerials[tokenId].push(serialNumber);
        serialToTokenId[serialNumber] = tokenId;
        serialToOwner[serialNumber] = account;
        tokenIdToOwnerToSerialNumbers[tokenId][account].push(serialNumber);
        // _balances[tokenId][account] = _balances[tokenId][account].add(1);
        emit TransferSingle(_msgSender(), address(0), account, tokenId, 1);
    }

    function migrationMintMany(uint256[] memory serialNumber, address[] memory account, uint256[] memory tokenId) public onlyOwner {
        for (uint i = 0; i < serialNumber.length; i++) { 
            tokenIdToSerials[tokenId[i]].push(serialNumber[i]);
            serialToTokenId[serialNumber[i]] = tokenId[i];
            serialToOwner[serialNumber[i]] = account[i];
            tokenIdToOwnerToSerialNumbers[tokenId[i]][account[i]].push(serialNumber[i]);
            // _balances[tokenId[i]][account[i]] = _balances[tokenId[i]][account[i]].add(1);
            emit TransferSingle(_msgSender(), address(0), account[i], tokenId[i], 1);
        }
    }

    function mintBatch(address[] memory to, uint256[] memory ids, uint256[] memory amounts, bytes[] memory serialNumbers) public onlyOwner {
        _mintBatch(to, ids, amounts, serialNumbers);
    }

    function burn(address _from, uint256 _tokenId, uint256 _amount) public {
        require(_from == _msgSender() || isApprovedForAll(_from, _msgSender()) || canBypass(), 'Not Approved to burn');
        _burn(_from, _tokenId, _amount);
    }

    function setURI(string memory newuri) public onlyOwner {
        _uri = newuri;
    }
    
    function uri(uint256 _tokenId) external view override returns (string memory) {
        return string(abi.encodePacked(_uri, toString(_tokenId)));
    }

    function toString(uint256 value) internal pure returns (string memory) {

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function balanceOf(address account, uint256 tokenId) public view returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return tokenIdToOwnerToSerialNumbers[tokenId][account].length;
        // return _balances[id][account];
    }
    
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) public view returns (uint256[] memory) {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            require(accounts[i] != address(0), "ERC1155: batch balance query for the zero address");
            // batchBalances[i] = _balances[ids[i]][accounts[i]];
            batchBalances[i] = tokenIdToOwnerToSerialNumbers[ids[i]][accounts[i]].length;
        }
        return batchBalances;
    }
    
    function setApprovalForAll(address operator, bool approved) public virtual onlyAllowedOperatorApproval(operator) {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }
    
    function isApprovedForAll(address account, address operator) public view returns (bool) {
        return _operatorApprovals[account][operator];
    }
    
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory) public virtual onlyAllowedOperatorApproval(from) {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()) || canBypassForTokenId(id), "ERC1155: caller is not owner nor approved nor bypasser");

        address operator = _msgSender();

        // _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        // _balances[id][to] = _balances[id][to].add(amount);

        if (isSerialized()) {
            for (uint i = 0; i < amount; i++) {            
                uint256 serialNumber = getFirstSerialByOwner(from, id);
                if (serialNumber != 0 ) {
                    transferSerial(serialNumber, from, to);
                }
            }
        }

        emit TransferSingle(operator, from, to, id, amount);
        if (registeredOfType[3].length > 0 && registeredOfType[3][0] != address(0)) {
            for (uint i = 0; i < amount; i++) {
                IHandlerCallback(registeredOfType[3][0]).executeCallbacks(from, to, id, IHandlerCallback.CallbackType.TRANSFER);
            }
        }
    }

    function safeBatchTransferIdFrom(address from, address[] calldata tos, uint256 id, uint256 amount, bytes memory data) public virtual onlyAllowedOperator(from) {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        for (uint256 i = 0; i < tos.length; ++i) {
            address to = tos[i];
            require(to != address(0), "ERC1155: transfer to the zero address");
            safeTransferFrom(from, to, id, amount, data);
        }
    }
    
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual onlyAllowedOperator(from) {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            safeTransferFrom(from, to, id, amount, data);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

    }

    function _mint(address account, uint256 id, uint256 amount, bytes memory serialNumber) internal virtual {
        address operator = _msgSender();
        if (isSerialized()) {
            for (uint i = 0; i < amount; i++) {
                if (overloadSerial){
                    require(toUint256(serialNumber, 0) != 0, "Must provide serial number");
                    uint256 _serialNumber = amount > 1?  decodeUintArray(abi.encodePacked(serialNumber))[i]: decodeSingle(abi.encodePacked(serialNumber));
                    mintSerial(_serialNumber, account, id);
                } else {
                    mintSerial(id, account);
                }
            }            
        }
        if (registeredOfType[3].length > 0 && registeredOfType[3][0] == _msgSender()) {
            for (uint i = 0; i < amount; i++) {
                IHandlerCallback(_msgSender()).executeCallbacks(address(0), account, id, IHandlerCallback.CallbackType.MINT);
            }
        }
        // _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);
    }

    function _mintBatch(address[] memory to, uint256[] memory ids, uint256[] memory amounts, bytes[] memory serialNumbers) internal virtual {
        
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        for (uint i = 0; i < ids.length; i++) {
            // If a particular id entry has multiple amounts, pack the serial numbers into a byte array
            // If there is only one amount, use the serial number as is
            // Example using web3.js:
            // let serialNumbers = [123, 456, 789];
            // let packedSerialNumbers = web3.eth.abi.encodeParameter('uint256[]', serialNumbers);
            bytes memory _serialNumber = amounts[i] > 1? abi.encode(decodeUintArray(serialNumbers[i])) : serialNumbers[i];
            _mint(to[i], ids[i], amounts[i], _serialNumber);
        }        
    }

    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        // _balances[id][account] = _balances[id][account].sub(
        //     amount,
        //     "ERC1155: burn amount exceeds balance"
        // );

        if (isSerialized()) {
            uint256 serialNumber = getFirstSerialByOwner(account, id);
            if (serialNumber != 0 ) {
                burnSerial(serialNumber);
            }
        }
        if (registeredOfType[3].length > 0 && registeredOfType[3][0] != address(0)) {
            IHandlerCallback(registeredOfType[3][0]).executeCallbacks(account, address(0), id, IHandlerCallback.CallbackType.BURN);
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    function isSerialized() public view returns (bool) {
        return serialized;
    }

    function isOverloadSerial() public view returns (bool) {
        return overloadSerial;
    }

    function toggleSerialization() public onlyOwner {
        require(!hasSerialized, "Already has serialized items");
        serialized = !serialized;
    }

    function toggleOverloadSerial() public onlyOwner {
        overloadSerial = !overloadSerial;
    }

    function mintSerial(uint256 tokenId, address _owner) internal onlyOwner {
        uint256 serialNumber = uint256(keccak256(abi.encode(tokenId, _owner, serialCount)));
        _mintSerial(serialNumber, _owner, tokenId);
    }

    function mintSerial(uint256 serialNumber, address _owner, uint256 tokenId) internal onlyOwner {
        _mintSerial(serialNumber, _owner, tokenId);
    }

    function _mintSerial(uint256 serialNumber, address _owner, uint256 tokenId)internal onlyOwner {
        require(serialToTokenId[serialNumber] == 0 && serialToOwner[serialNumber] == address(0), "Serial number already used");
        tokenIdToSerials[tokenId].push(serialNumber);
        serialToTokenId[serialNumber] = tokenId;
        serialToOwner[serialNumber] = _owner;
        tokenIdToOwnerToSerialNumbers[tokenId][_owner].push(serialNumber);
        if (!hasSerialized) {
            hasSerialized = true;
        }
        serialCount++;
    }
    
    function transferSerial(uint256 serialNumber, address from, address to) internal {
        require(serialToOwner[serialNumber] == from, 'Not correct owner of serialnumber');
        uint256 tokenId = serialToTokenId[serialNumber];
        serialToOwner[serialNumber] = to;
        uint256[] storage serialNumbersTo = tokenIdToOwnerToSerialNumbers[tokenId][to];
        uint256[] storage serialNumbersFrom = tokenIdToOwnerToSerialNumbers[tokenId][from];
        for(uint i=0; i<serialNumbersFrom.length; i++) {
            if (serialNumbersFrom[i] == serialNumber) {
                serialNumbersFrom[i] = serialNumbersFrom[serialNumbersFrom.length-1];
                serialNumbersFrom.pop();
                serialNumbersTo.push(serialNumber);
                break;
            }
        }
    }

    function burnSerial(uint256 serialNumber) internal {
        uint256[] storage serialNumbersFrom = tokenIdToOwnerToSerialNumbers[serialToTokenId[serialNumber]][serialToOwner[serialNumber]];
        uint256 tokenId = serialToTokenId[serialNumber];
        serialToOwner[serialNumber] = address(0);
        for(uint i=0; i<serialNumbersFrom.length; i++) {
            if (serialNumbersFrom[i] == serialNumber) {
                serialNumbersFrom[i] = serialNumbersFrom[serialNumbersFrom.length-1];
                serialNumbersFrom.pop();
                break;
            }
        }
        for(uint i=0; i<tokenIdToSerials[tokenId].length; i++) {
            if (tokenIdToSerials[tokenId][i] == serialNumber) {
                tokenIdToSerials[tokenId][i] = tokenIdToSerials[tokenId][tokenIdToSerials[tokenId].length - 1];
                tokenIdToSerials[tokenId].pop();
                break;
            }
        }
    }


    function getSerial(uint256 tokenId, uint256 index) public view returns (uint256) {
        return tokenIdToSerials[tokenId][index];
    }

    function getFirstSerialByOwner(address _owner, uint256 tokenId) public view returns (uint256) {
        return tokenIdToOwnerToSerialNumbers[tokenId][_owner].length == 0? 0: tokenIdToOwnerToSerialNumbers[tokenId][_owner][0];
    }

    function getSerialByOwnerAtIndex(address _owner, uint256 tokenId, uint256 index) public view returns (uint256) {
        return (tokenIdToOwnerToSerialNumbers[tokenId][_owner].length == 0 || index > tokenIdToOwnerToSerialNumbers[tokenId][_owner].length-1) ? 0: tokenIdToOwnerToSerialNumbers[tokenId][_owner][index];
    }

    function getOwnerOfSerial(uint256 serialNumber) public view returns (address) {
        return serialToOwner[serialNumber];
    }

    function getTokenIdForSerialNumber(uint256 serialNumber) public view returns (uint256) {
        return serialToTokenId[serialNumber];
    }

    function decodeUintArray(bytes memory encoded) internal pure returns(uint256[] memory ids){
        ids = abi.decode(encoded, (uint256[]));
    }

    // To pack the value using web3.js, you can use the following code:
    // let value = 123;
    // let packedValue = web3.eth.abi.encodeParameter('uint256', value);     
    function decodeSingle(bytes memory encoded) internal pure returns(uint256 id) {
        id = abi.decode(encoded, (uint256));
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    function toUint256(bytes memory _bytes, uint256 _start) private pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }
}