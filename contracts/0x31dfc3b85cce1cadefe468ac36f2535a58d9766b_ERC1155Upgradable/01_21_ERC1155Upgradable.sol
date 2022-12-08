// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;
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
    

    constructor () {
        // __Ownable_init();
    }

    modifier oncePerBlock(address to) {
        require(!seenInBlock[to][block.number], 'already seen this block');
        _;
    }

    function upgradeFrom(address oldContract) public onlyOwner virtual override {
       UpgradableERC1155.upgradeFrom(oldContract);
    }

    // function  makeEvents(address[] calldata operators, uint256[] calldata tokenIds, address[] calldata _from, address[] calldata _to, uint256[] calldata amounts) public onlyOwner override {
    //     EventableERC1155.makeEvents(operators, tokenIds, _from, _to, amounts);
    // }

    function initialize() public override initializer {
        __Ownable_init();
        _registerInterface(0xd9b67a26); //_INTERFACE_ID_ERC1155
        _registerInterface(0x0e89341c); //_INTERFACE_ID_ERC1155_METADATA_URI
        initializeERC165();
        _registerInterface(0x2a55205a); // ERC2981
        _uri = "https://api.emblemvault.io/s:evmetadata/meta/"; 
        serialized = true;
        overloadSerial = false;
        isClaimable = true;
        // initStream();
    }

    // function initStream() private onlyOwner {
    //     streamAddress = payable(address(new Stream()));
    //     Stream(streamAddress).initialize();
    //     OwnableUpgradeable(streamAddress).transferOwnership(_msgSender());
    //     Stream(streamAddress).addMember(Stream.Member(owner(), 1, 1)); // add owner as stream recipient
    //     IERC2981Royalties(this).setTokenRoyalty(0, streamAddress, 10000); // set contract wide royalties to stream
    // }

    function version() public pure override returns(uint256) {
        return 5;
    }

    function changeName(string calldata _name, string calldata _symbol) public onlyOwner {
      name = _name;
      symbol = _symbol;
    }

    function mint(address _to, uint256 _tokenId, uint256 _amount) public onlyOwner oncePerBlock(_to) {
        bytes memory empty = abi.encodePacked(uint256(0));
        
        mintWithSerial(_to, _tokenId, _amount, empty);
    }

    function mintWithSerial(address _to, uint256 _tokenId, uint256 _amount, bytes memory serialNumber) public onlyOwner oncePerBlock(_to) {
        _mint(_to, _tokenId, _amount, serialNumber);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes[] memory serialNumbers) public onlyOwner oncePerBlock(to) {
        _mintBatch(to, ids, amounts, serialNumbers);
    }

    function burn(address _from, uint256 _tokenId, uint256 _amount) public {
        require(_from == _msgSender() || isApprovedForAll(_from, _msgSender()), 'Not Approved to burn');
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

    function balanceOf(address account, uint256 id) public view returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return UpgradableERC1155.balanceOfHook(account, id, _balances);
    }
    
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) public view returns (uint256[] memory) {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            require(accounts[i] != address(0), "ERC1155: batch balance query for the zero address");
            batchBalances[i] = UpgradableERC1155.balanceOfHook(accounts[i], ids[i], _balances);
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
        bool _canBypass = canBypassForTokenId(id);
        uint256 pastSenderBalance = 0;
        uint256 pastRecipientBalance = 0;
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()) || _canBypass, "ERC1155: caller is not owner nor approved nor bypasser");

        address operator = _msgSender();

        // _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);
        (pastSenderBalance, pastRecipientBalance) = UpgradableERC1155.transferHook(from, to, id, _balances);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        if (isSerialized()) {
            for (uint i = 0; i < amount; i++) {            
                uint256 serialNumber = getFirstSerialByOwner(from, id);
                if (serialNumber != 0 ) {
                    transferSerial(serialNumber, from, to);
                }
            }
        }

        emit TransferSingle(operator, from, to, id, amount);
        UpgradableERC1155.transferEventHook(operator, from, to, id, pastSenderBalance, pastRecipientBalance);

        // _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
        if (registeredOfType[3].length > 0 && registeredOfType[3][0] != address(0)) {
            for (uint i = 0; i < amount; i++) {
                IHandlerCallback(registeredOfType[3][0]).executeCallbacks(from, to, id, IHandlerCallback.CallbackType.TRANSFER);
            }
        }
    }
    
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        // _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            safeTransferFrom(from, to, id, amount, data);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        // _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    function _mint(address account, uint256 id, uint256 amount, bytes memory serialNumber) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");
        address operator = _msgSender();
        amount = UpgradableERC1155.mintHook(account, id, amount);
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
        // usedTokenId[id] = true;
        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);
    }

    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes[] memory serialNumbers) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        for (uint i = 0; i < ids.length; i++) {
            bytes memory _serialNumber = amounts[i] > 1? abi.encode(decodeUintArray(serialNumbers[i])) : serialNumbers[i];
            _mint(to, ids[i], amounts[i], _serialNumber);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);
    }

    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

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

    // fallback (bytes calldata input) external returns (bytes memory) {
    //     // should allow registration of fallback functions
    // }
}