/**
 *Submitted for verification at Etherscan.io on 2020-01-26
*/

// Copyright (c) 2018-2020 double jump.tokyo inc.
pragma solidity 0.5.12;

interface IERC721Metadata /* is ERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface IERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    )
        external
        returns(bytes4);
}

library Uint32 {

    function add(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
        require(a >= b, "subtraction overflow");
        return a - b;
    }

    function mul(uint32 a, uint32 b) internal pure returns (uint32) {
        if (a == 0) {
            return 0;
        }
        uint32 c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }

    function div(uint32 a, uint32 b) internal pure returns (uint32) {
        require(b != 0, "division by 0");
        return a / b;
    }

    function mod(uint32 a, uint32 b) internal pure returns (uint32) {
        require(b != 0, "modulo by 0");
        return a % b;
    }

}

library String {

    function compare(string memory _a, string memory _b) public pure returns (bool) {
        return (keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b)));
    }

    function cut(string memory _s, uint256 _from, uint256 _range) public pure returns (string memory) {
        bytes memory s = bytes(_s);
        require(s.length >= _from + _range, "_s length must be longer than _from + _range");
        bytes memory ret = new bytes(_range);

        for (uint256 i = 0; i < _range; i++) {
            ret[i] = s[_from+i];
        }
        return string(ret);
    }

    function concat(string memory _a, string memory _b) internal pure returns (string memory) {
        return string(abi.encodePacked(_a, _b));
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function toHex(address account) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(account));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }
}
interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/// @title ERC-165 Standard Interface Detection
/// @dev See https://eips.ethereum.org/EIPS/eip-165
contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

interface IApprovalProxy {
  function setApprovalForAll(address _owner, address _spender, bool _approved) external;
  function isApprovedForAll(address _owner, address _spender, bool _original) external view returns (bool);
}
library Uint256 {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "division by 0");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "modulo by 0");
        return a % b;
    }

    function toString(uint256 a) internal pure returns (string memory) {
        bytes32 retBytes32;
        uint256 len = 0;
        if (a == 0) {
            retBytes32 = "0";
            len++;
        } else {
            uint256 value = a;
            while (value > 0) {
                retBytes32 = bytes32(uint256(retBytes32) / (2 ** 8));
                retBytes32 |= bytes32(((value % 10) + 48) * 2 ** (8 * 31));
                value /= 10;
                len++;
            }
        }

        bytes memory ret = new bytes(len);
        uint256 i;

        for (i = 0; i < len; i++) {
            ret[i] = retBytes32[i];
        }
        return string(ret);
    }
}

interface IERC721 /* is ERC165 */ {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    function add(Role storage role, address account) internal {
        require(!has(role, account), "role already has the account");
        role.bearer[account] = true;
    }

    function remove(Role storage role, address account) internal {
        require(has(role, account), "role dosen't have the account");
        role.bearer[account] = false;
    }

    function has(Role storage role, address account) internal view returns (bool) {
        return role.bearer[account];
    }
}

contract ERC721 is IERC721, ERC165 {
    using Uint256 for uint256;
    using Address for address;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;

    mapping (uint256 => address) private _tokenOwner;
    mapping (address => uint256) private _balance;
    mapping (uint256 => address) private _tokenApproved;
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    constructor () public {
        _registerInterface(_InterfaceId_ERC721);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return _balance[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        require(_exist(_tokenId),
                "`_tokenId` is not a valid NFT.");
        return _tokenOwner[_tokenId];
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public payable {
        require(_data.length == 0, "data is not implemented");
        safeTransferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable {
        require(_checkOnERC721Received(_from, _to, _tokenId, ""),
                "`_to` is a smart contract and onERC721Received is invalid");
        transferFrom(_from, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public payable {
        require(_transferable(msg.sender, _tokenId),
                "Unless `msg.sender` is the current owner, an authorized operator, or the approved address for this NFT."); // solhint-disable-line
        require(ownerOf(_tokenId) == _from,
                "`_from` is not the current owner.");
        require(_to != address(0),
                "`_to` is the zero address.");
        require(_exist(_tokenId),
                "`_tokenId` is not a valid NFT.");
        _transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) public payable {
        address owner = ownerOf(_tokenId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
                "Unless `msg.sender` is the current NFT owner, or an authorized operator of the current owner.");

        _tokenApproved[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        _setApprovalForAll(msg.sender, _operator, _approved);
    }

    function _setApprovalForAll(address _owner, address _operator, bool _approved) internal {
        _operatorApprovals[_owner][_operator] = _approved;
        emit ApprovalForAll(_owner, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        require(_exist(_tokenId),
                "`_tokenId` is not a valid NFT.");
        return _tokenApproved[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return _isApprovedForAll(_owner, _operator);
    }
    
    function _isApprovedForAll(address _owner, address _operator) internal view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    function _transferable(address _spender, uint256 _tokenId) internal view returns (bool){
        address owner = ownerOf(_tokenId);
        return (_spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender));
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        _clearApproval(_tokenId);
        _tokenOwner[_tokenId] = _to;
        _balance[_from] = _balance[_from].sub(1);
        _balance[_to] = _balance[_to].add(1);
        emit Transfer(_from, _to, _tokenId);
    }
  
    function _mint(address _to, uint256 _tokenId) internal {
        require(!_exist(_tokenId), "mint token already exists");
        _tokenOwner[_tokenId] = _to;
        _balance[_to] = _balance[_to].add(1);
        emit Transfer(address(0), _to, _tokenId);
    }
  
    function _burn(uint256 _tokenId) internal {
        require(_exist(_tokenId), "burn token does not already exists");
        address owner = ownerOf(_tokenId);
        _clearApproval(_tokenId);
        _tokenOwner[_tokenId] = address(0);
        _balance[owner] = _balance[owner].sub(1);
        emit Transfer(owner, address(0), _tokenId);
    }

    function _exist(uint256 _tokenId) internal view returns (bool) {
        address owner = _tokenOwner[_tokenId];
        return owner != address(0);
    }

    function _checkOnERC721Received(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) 
        internal
        returns (bool) 
    {
        if (!_to.isContract()) {
            return true;
        }
        bytes4 retval = IERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    function _clearApproval(uint256 tokenId) internal {
        if (_tokenApproved[tokenId] != address(0)) {
            _tokenApproved[tokenId] = address(0);
        }
    }
}

interface IERC173 /* is ERC165 */ {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return The address of the owner.
    function owner() external view returns (address);

    /// @notice Set the address of the new owner of the contract
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

contract ERC173 is IERC173, ERC165  {
    address private _owner;

    constructor() public {
        _registerInterface(0x7f5828d0);
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner(), "Must be owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address _newOwner) public onlyOwner() {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        address previousOwner = owner();
	_owner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }
}

contract Operatable is ERC173 {
    using Roles for Roles.Role;

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;
    Roles.Role private operators;

    constructor() public {
        operators.add(msg.sender);
        _paused = false;
    }

    modifier onlyOperator() {
        require(isOperator(msg.sender), "Must be operator");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOperator() {
        _transferOwnership(_newOwner);
    }

    function isOperator(address account) public view returns (bool) {
        return operators.has(account);
    }

    function addOperator(address account) public onlyOperator() {
        operators.add(account);
        emit OperatorAdded(account);
    }

    function removeOperator(address account) public onlyOperator() {
        operators.remove(account);
        emit OperatorRemoved(account);
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    function pause() public onlyOperator() whenNotPaused() {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyOperator() whenPaused() {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    function withdrawEther() public onlyOperator() {
        msg.sender.transfer(address(this).balance);
    }

}

contract ERC721Metadata is IERC721Metadata, ERC721, Operatable {
    using Uint256 for uint256;
    using String for string;

    event UpdateTokenURIPrefix(
        string tokenUriPrefix
    );

    // Metadata
    string private __name;
    string private __symbol;
    string private __tokenUriPrefix;

    constructor(string memory _name,
                string memory _symbol,
                string memory _tokenUriPrefix) public {
        // ERC721Metadata
        __name = _name;
        __symbol = _symbol;
        setTokenURIPrefix(_tokenUriPrefix);
    }

    function setTokenURIPrefix(string memory _tokenUriPrefix) public onlyOperator() {
        __tokenUriPrefix = _tokenUriPrefix;
        emit UpdateTokenURIPrefix(_tokenUriPrefix);
    }

    function name() public view returns (string memory) {
        return __name;
    }

    function symbol() public view returns (string memory) {
        return __symbol;
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        return __tokenUriPrefix.concat(_tokenId.toString());
    }
}

contract ERC721TokenPausable is ERC721,Operatable {
    using Roles for Roles.Role;
    Roles.Role private tokenPauser;

    event TokenPauserAdded(address indexed account);
    event TokenPauserRemoved(address indexed account);

    event TokenPaused(uint256 indexed tokenId);
    event TokenUnpaused(uint256 indexed tokenId);

    mapping (uint256 => bool) private _tokenPaused;

    constructor() public {
        tokenPauser.add(msg.sender);
    }

    modifier onlyTokenPauser() {
        require(isTokenPauser(msg.sender), "Only token pauser can call this method");
        _;
    }

    modifier whenNotTokenPaused(uint256 _tokenId) {
        require(!isTokenPaused(_tokenId), "TokenPausable: paused");
        _;
    }

    modifier whenTokenPaused(uint256 _tokenId) {
        require(isTokenPaused(_tokenId), "TokenPausable: not paused");
        _;
    }

    function pauseToken(uint256 _tokenId) public onlyTokenPauser() {
        require(!isTokenPaused(_tokenId), "Token is already paused");
        _tokenPaused[_tokenId] = true;
        emit TokenPaused(_tokenId);
    }

    function unpauseToken(uint256 _tokenId) public onlyTokenPauser() {
        require(isTokenPaused(_tokenId), "Token is not paused");
        _tokenPaused[_tokenId] = false;
        emit TokenUnpaused(_tokenId);
    }

    function isTokenPaused(uint256 _tokenId) public view returns (bool) {
        return _tokenPaused[_tokenId];
    }

    function isTokenPauser(address account) public view returns (bool) {
        return tokenPauser.has(account);
    }

    function addTokenPauser(address account) public onlyOperator() {
        tokenPauser.add(account);
        emit TokenPauserAdded(account);
    }

    function removeTokenPauser(address account) public onlyOperator() {
        tokenPauser.remove(account);
        emit TokenPauserRemoved(account);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public payable
                            whenNotPaused() whenNotTokenPaused(_tokenId) {
        super.safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable
                            whenNotPaused() whenNotTokenPaused(_tokenId) {
        super.safeTransferFrom(_from, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public payable
                            whenNotPaused() whenNotTokenPaused(_tokenId) {
        super.transferFrom(_from, _to, _tokenId);
    }
}

interface IERC721Mintable {
    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);
    function exist(uint256 _tokenId) external view returns (bool);
    function mint(address _to, uint256 _tokenId) external;
    function isMinter(address account) external view returns (bool);
    function addMinter(address account) external;
    function removeMinter(address account) external;
}

contract ERC721Mintable is ERC721, IERC721Mintable, Operatable {
    using Roles for Roles.Role;
    Roles.Role private minters;

    constructor() public {
        addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "Must be minter");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return minters.has(account);
    }

    function addMinter(address account) public onlyOperator() {
        minters.add(account);
        emit MinterAdded(account);
    }

    function removeMinter(address account) public onlyOperator() {
        minters.remove(account);
        emit MinterRemoved(account);
    }
    
    function exist(uint256 tokenId) public view returns (bool) {
        return _exist(tokenId);
    }

    function mint(address to, uint256 tokenId) public onlyMinter() {
        _mint(to, tokenId);
    }
}
interface IERC721CappedSupply /* IERC721Mintable, IERC721 */ {
    event SetUnitCap(uint32 _assetType, uint32 _unitCap);
    event SetTypeCap(uint256 _typeCap);
    function totalSupply() external view returns (uint256);
    function getTypeOffset() external view returns (uint256);
    function getTypeCap() external view returns (uint256);
    function setTypeCap(uint32 _newTypeCap) external;
    function getTypeCount() external view returns (uint256);
    function existingType(uint32 _assetType) external view returns (bool);
    function getUnitCap(uint32 _assetType) external view returns (uint32);
    function setUnitCap(uint32 _assetType, uint32 _newUnitCap) external;
    function mint(address _to, uint256 _tokenId) external;
}

/// @title ERC-721 Capped Supply
/// @author double jump.tokyo inc.
/// @dev see https://medium.com/@makzent/ca1008866871
contract ERC721CappedSupply is IERC721CappedSupply, ERC721Mintable {
    using Uint256 for uint256;
    using Uint32 for uint32;

    uint32 private assetTypeOffset;
    mapping(uint32 => uint32) private unitCap;
    mapping(uint32 => uint32) private unitCount;
    mapping(uint32 => bool) private unitCapIsSet;
    uint256 private assetTypeCap = 2**256-1;
    uint256 private assetTypeCount = 0;
    uint256 private totalCount = 0;

    constructor(uint32 _assetTypeOffset) public {
        setTypeOffset(_assetTypeOffset);
    }

    function isValidOffset(uint32 _offset) private pure returns (bool) {
        for (uint32 i = _offset; i > 0; i = i.div(10)) {
            if (i == 10) {
                return true;
            }
            if (i.mod(10) != 0) {
                return false;
            }
        }
        return false;
    }

    function totalSupply() public view returns (uint256) {
        return totalCount;
    }

    function setTypeOffset(uint32 _assetTypeOffset) private {
        require(isValidOffset(_assetTypeOffset),  "Offset is invalid");
        assetTypeCap = assetTypeCap / _assetTypeOffset;
        assetTypeOffset = _assetTypeOffset;
    }

    function getTypeOffset() public view returns (uint256) {
        return assetTypeOffset;
    }

    function setTypeCap(uint32 _newTypeCap) public onlyMinter() {
        require(_newTypeCap < assetTypeCap, "New type cap cannot be less than existing type cap");
        require(_newTypeCap >= assetTypeCount, "New type cap must be more than current type count");
        assetTypeCap = _newTypeCap;
        emit SetTypeCap(_newTypeCap);
    }

    function getTypeCap() public view returns (uint256) {
        return assetTypeCap;
    }

    function getTypeCount() public view returns (uint256) {
        return assetTypeCount;
    }

    function existingType(uint32 _assetType) public view returns (bool) {
        return unitCapIsSet[_assetType];
    }

    function setUnitCap(uint32 _assetType, uint32 _newUnitCap) public onlyMinter() {
        require(_assetType != 0, "Asset Type must not be 0");
        require(_newUnitCap < assetTypeOffset, "New unit cap must be less than asset type offset");

        if (!existingType(_assetType)) {
            unitCapIsSet[_assetType] = true;
            assetTypeCount = assetTypeCount.add(1);
            require(assetTypeCount <= assetTypeCap, "Asset type cap is exceeded");
        } else {
            require(_newUnitCap < getUnitCap(_assetType), "New unit cap must be less than previous unit cap");
            require(_newUnitCap >= getUnitCount(_assetType), "New unit cap must be more than current unit count");
        }

        unitCap[_assetType] = _newUnitCap;
        emit SetUnitCap(_assetType, _newUnitCap);
    }

    function getUnitCap(uint32 _assetType) public view returns (uint32) {
        require(existingType(_assetType), "Asset type does not exist");
        return unitCap[_assetType];
    }

    function getUnitCount(uint32 _assetType) public view returns (uint32) {
        return unitCount[_assetType];
    }

    function mint(address _to, uint256 _tokenId) public onlyMinter() {
        require(_tokenId.mod(assetTypeOffset) != 0, "Index must not be 0");
        uint32 assetType = uint32(_tokenId.div(assetTypeOffset));
        unitCount[assetType] = unitCount[assetType].add(1);
        totalCount = totalCount.add(1);
        require(unitCount[assetType] <= getUnitCap(assetType), "Asset unit cap is exceed");
        super.mint(_to, _tokenId);
    }
}

contract BFHUnit is
                    ERC721TokenPausable,
                    ERC721CappedSupply(10000),
                    ERC721Metadata("BFH:Unit", "BFHU", "https://bravefrontierheroes.com/metadata/units/")
                    {

    event UpdateApprovalProxy(address _newProxyContract);
    IApprovalProxy public approvalProxy;
    constructor(address _approvalProxy) public {
        setApprovalProxy(_approvalProxy);
    }

    function setApprovalProxy(address _new) public onlyOperator() {
        approvalProxy = IApprovalProxy(_new);
        emit UpdateApprovalProxy(_new);
    }

    function setApprovalForAll(address _spender, bool _approved) public {
        if (address(approvalProxy) != address(0x0) && _spender.isContract()) {
            approvalProxy.setApprovalForAll(msg.sender, _spender, _approved);
        }
        super.setApprovalForAll(_spender, _approved);
    }

    function isApprovedForAll(address _owner, address _spender) public view returns (bool) {
        bool original = super.isApprovedForAll(_owner, _spender);
        if (address(approvalProxy) != address(0x0)) {
            return approvalProxy.isApprovedForAll(_owner, _spender, original);
        }
        return original;
    }
}