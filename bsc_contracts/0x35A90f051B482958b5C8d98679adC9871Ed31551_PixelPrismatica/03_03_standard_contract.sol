// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

// import "@openzeppelin/contracts/utils/Base64.sol";
library Base64 {
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    function encode(bytes memory data) internal pure returns (string memory) {
        if(data.length == 0) return "";
        string memory table = _TABLE;
        string memory result = new string(4 * ((data.length + 2) / 3));
        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {
            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }
        return result;
    }
}

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
interface IERC777 {
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function granularity() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function send(address recipient, uint256 amount, bytes calldata data) external;
    function burn(uint256 amount, bytes calldata data) external;
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);
    function authorizeOperator(address operator) external;
    function revokeOperator(address operator) external;
    function defaultOperators() external view returns (address[] memory);
    function operatorSend(address sender, address recipient, uint256 amount, bytes calldata data, bytes calldata operatorData) external;
    function operatorBurn(address account, uint256 amount, bytes calldata data, bytes calldata operatorData) external;
    event Sent(address indexed operator, address indexed from, address indexed to, uint256 amount, bytes data, bytes operatorData);
}

// import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
interface IERC777Recipient {
    function tokensReceived(address operator, address from, address to, uint256 amount, bytes calldata userData, bytes calldata operatorData) external;
}

// import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
interface IERC777Sender {
    function tokensToSend(address operator, address from, address to, uint256 amount, bytes calldata userData, bytes calldata operatorData) external;
}

// import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
interface IERC1155 is IERC165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
interface IERC1155Receiver is IERC165 {
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external returns (bytes4);
    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external returns (bytes4);
}

// import "@openzeppelin/contracts/utils/introspection/IERC1820Implementer.sol";
interface IERC1820Implementer {
    function canImplementInterfaceForAddress(bytes32 interfaceHash, address account) external view returns (bytes32);
}

// import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
interface IERC1820Registry {
    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);
    event ManagerChanged(address indexed account, address indexed newManager);
    function setManager(address account, address newManager) external;
    function getManager(address account) external view returns (address);
    function setInterfaceImplementer(address account, bytes32 _interfaceHash, address implementer) external;
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);
    function updateERC165Cache(address account, bytes4 interfaceId) external;
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);
}

contract StandardContract is IERC721Receiver, IERC777Recipient, IERC777Sender, IERC1155Receiver, IERC1820Implementer {
    /*
    *
    *
        Errors
    *
    *
    */

    /// @notice The calling address is not the owner.
    error NotOwnerError(address _address, address ownerAddress);

    /// @notice The calling address is not the owner successor.
    error NotOwnerSuccessorError(address _address, address ownerSuccessorAddress);

    /*
    *
    *
        Events
    *
    *
    */

    /// @notice A record of the owner address changing.
    event OwnerChanged(address indexed oldOwnerAddress, address indexed newOwnerAddress);

    /*
    *
    *
        Constants
    *
    *
    */

    IERC1820Registry internal constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    bytes32 internal constant _ERC1820_ACCEPT_MAGIC = keccak256("ERC1820_ACCEPT_MAGIC");
    bytes32 internal constant _TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    bytes32 internal constant _TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");

    /*
    *
    *
        Internal Variables
    *
    *
    */

    /*
        Contract Variables
    */

    address internal ownerAddress;
    address internal ownerSuccessorAddress;

    bool internal lockFlag;

    /*
    *
    *
        Contract Functions
    *
    *
    */

    /*
        Built-In Functions
    */

    constructor() payable {
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), _TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), _TOKENS_SENDER_INTERFACE_HASH, address(this));

        setOwnerAddress(msg.sender);
        setOwnerSuccessorAddress(msg.sender);
    }

    /*
        Implementation Functions
    */

    // IERC165 Implementation
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IERC721Receiver).interfaceId
            || interfaceId == type(IERC777Recipient).interfaceId
            || interfaceId == type(IERC777Sender).interfaceId
            || interfaceId == type(IERC1155Receiver).interfaceId
            || interfaceId == type(IERC1820Implementer).interfaceId;
    }

    // IERC721Receiver Implementation
    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // IERC777Recipient Implementation
    function tokensReceived(address operator, address from, address to, uint256 amount, bytes calldata userData, bytes calldata operatorData) external {}

    // IERC777Sender Implementation
    function tokensToSend(address operator, address from, address to, uint256 amount, bytes calldata userData, bytes calldata operatorData) external {}

    // IERC1155Receiver Implementation
    function onERC1155Received(address, address, uint256, uint256, bytes memory) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    // IERC1820Implementer Implementation
    function canImplementInterfaceForAddress(bytes32 interfaceHash, address account) external view returns (bytes32) {
        if(account == address(this) && (interfaceHash == _TOKENS_RECIPIENT_INTERFACE_HASH || interfaceHash == _TOKENS_SENDER_INTERFACE_HASH)) {
            return _ERC1820_ACCEPT_MAGIC;
        }
        else {
            return bytes32(0x0);
        }
    }

    /*
        Action Functions
    */

    function claimOwnerRole(address _address) internal {
        setOwnerAddress(_address);
    }

    function offerOwnerRole(address _address) internal {
        setOwnerSuccessorAddress(_address);
    }

    /*
        Withdraw Functions
    */

    function withdrawCoins(address _address, uint256 _value) internal {
        payable(_address).transfer(_value);
    }

    function withdrawERC20Tokens(address _tokenAddress, address _address, uint256 _value) internal {
        // Take extra care to account for tokens that don't revert on failure or that don't return a value.
        // A return value is optional, but if it is present then it must be true.
        if(_tokenAddress.code.length == 0) {
            revert("ERC20TokenContractError");
        }

        bytes memory callData = abi.encodeWithSelector(IERC20(_tokenAddress).transfer.selector, _address, _value);
        (bool success, bytes memory returnData) = _tokenAddress.call(callData);

        if(!success || (returnData.length != 0 && !abi.decode(returnData, (bool)))) {
            revert("ERC20TokenTransferError");
        }
    }

    function withdrawERC721Tokens(address _tokenAddress, uint256 _id, address _address) internal {
        // Take extra care to account for tokens that don't revert on failure or that don't return a value.
        // A return value is optional, but if it is present then it must be true.
        if(_tokenAddress.code.length == 0) {
            revert("ERC721TokenContractError");
        }

        bytes memory callData = abi.encodeWithSelector(IERC721(_tokenAddress).transferFrom.selector, address(this), _address, _id);
        (bool success, bytes memory returnData) = _tokenAddress.call(callData);

        if(!success || (returnData.length != 0 && !abi.decode(returnData, (bool)))) {
            revert("ERC721TokenTransferError");
        }
    }

    function withdrawERC777Tokens(address _tokenAddress, address _address, uint256 _value, bytes memory _data) internal {
        // Take extra care to account for tokens that don't revert on failure or that don't return a value.
        // A return value is optional, but if it is present then it must be true.
        if(_tokenAddress.code.length == 0) {
            revert("ERC777TokenContractError");
        }

        bytes memory callData = abi.encodeWithSelector(IERC777(_tokenAddress).send.selector, _address, _value, _data);
        (bool success, bytes memory returnData) = _tokenAddress.call(callData);

        if(!success || (returnData.length != 0 && !abi.decode(returnData, (bool)))) {
            revert("ERC777TokenTransferError");
        }
    }

    function withdrawERC1155Tokens(address _tokenAddress, uint256 _id, address _address, uint256 _value, bytes memory _data) internal {
        // Take extra care to account for tokens that don't revert on failure or that don't return a value.
        // A return value is optional, but if it is present then it must be true.
        if(_tokenAddress.code.length == 0) {
            revert("ERC1155TokenContractError");
        }

        bytes memory callData = abi.encodeWithSelector(IERC1155(_tokenAddress).safeTransferFrom.selector, address(this), _address, _id, _value, _data);
        (bool success, bytes memory returnData) = _tokenAddress.call(callData);

        if(!success || (returnData.length != 0 && !abi.decode(returnData, (bool)))) {
            revert("ERC1155TokenTransferError");
        }
    }

    /*
        Query Functions
    */

    function isLocked() internal view returns (bool) {
        return lockFlag;
    }

    function isOwnerAddress(address _address) internal view returns (bool) {
        return _address == getOwnerAddress();
    }

    function isOwnerSuccessorAddress(address _address) internal view returns (bool) {
        return _address == getOwnerSuccessorAddress();
    }

    /*
        Require Functions
    */

    function requireOwnerAddress(address _address) internal view {
        if(!isOwnerAddress(_address)) {
            revert NotOwnerError(_address, getOwnerAddress());
        }
    }

    function requireOwnerSuccessorAddress(address _address) internal view {
        if(!isOwnerSuccessorAddress(_address)) {
            revert NotOwnerSuccessorError(_address, getOwnerSuccessorAddress());
        }
    }

    /*
        Get Functions
    */

    function getOwnerAddress() internal view returns (address) {
        return ownerAddress;
    }

    function getOwnerSuccessorAddress() internal view returns (address) {
        return ownerSuccessorAddress;
    }

    /*
        Set Functions
    */

    function setLocked(bool _isLocked) internal {
        lockFlag = _isLocked;
    }
    
    function setOwnerAddress(address _address) internal {
        if(_address != ownerAddress) {
            emit OwnerChanged(ownerAddress, _address);
            ownerAddress = _address;
        }
    }

    function setOwnerSuccessorAddress(address _address) internal {
        ownerSuccessorAddress = _address;
    }

    /*
        Reentrancy Functions
    */

    function lock() internal {
        // Call this at the start of each external function that can change state to protect against reentrancy.
        if(isLocked()) {
            punish();
        }
        setLocked(true);
    }

    function unlock() internal {
        // Call this at the end of each external function.
        setLocked(false);
    }

    /*
        Utility Functions
    */

    function addressToString(address _address) internal pure returns(string memory) {
        // Convert the address to a checksum address string.
        return getChecksum(_address);
    }

    function punish() internal pure {
        // This operation will cause a revert but also consume all the gas. This will punish those who are trying to attack the contract.
        assembly("memory-safe") { invalid() }
    }

    function uint256ToString(uint256 _i) internal pure returns (string memory) {
        if(_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while(j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while(_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /*
        Address Checksum Functions
    */

    function getChecksum(address account) internal pure returns (string memory accountChecksum) {
        return _toChecksumString(account);
    }

    function _toChecksumString(address account) private pure returns (string memory asciiString) {
        // convert the account argument from address to bytes.
        bytes20 data = bytes20(account);

        // create an in-memory fixed-size bytes array.
        bytes memory asciiBytes = new bytes(40);

        // declare variable types.
        uint8 b;
        uint8 leftNibble;
        uint8 rightNibble;
        bool leftCaps;
        bool rightCaps;
        uint8 asciiOffset;

        // get the capitalized characters in the actual checksum.
        bool[40] memory caps = _toChecksumCapsFlags(account);

        // iterate over bytes, processing left and right nibble in each iteration.
        for(uint256 i = 0; i < data.length; i++) {
            // locate the byte and extract each nibble.
            b = uint8(uint160(data) / (2**(8*(19 - i))));
            leftNibble = b / 16;
            rightNibble = b - 16 * leftNibble;

            // locate and extract each capitalization status.
            leftCaps = caps[2*i];
            rightCaps = caps[2*i + 1];

            // get the offset from nibble value to ascii character for left nibble.
            asciiOffset = _getAsciiOffset(leftNibble, leftCaps);

            // add the converted character to the byte array.
            asciiBytes[2 * i] = bytes1(leftNibble + asciiOffset);

            // get the offset from nibble value to ascii character for right nibble.
            asciiOffset = _getAsciiOffset(rightNibble, rightCaps);

            // add the converted character to the byte array.
            asciiBytes[2 * i + 1] = bytes1(rightNibble + asciiOffset);
        }

        return string.concat("0x", string(asciiBytes));
    }

    function _toChecksumCapsFlags(address account) private pure returns (bool[40] memory characterCapitalized) {
        // convert the address to bytes.
        bytes20 a = bytes20(account);

        // hash the address (used to calculate checksum).
        bytes32 b = keccak256(abi.encodePacked(_toAsciiString(a)));

        // declare variable types.
        uint8 leftNibbleAddress;
        uint8 rightNibbleAddress;
        uint8 leftNibbleHash;
        uint8 rightNibbleHash;

        // iterate over bytes, processing left and right nibble in each iteration.
        for(uint256 i; i < a.length; i++) {
            // locate the byte and extract each nibble for the address and the hash.
            rightNibbleAddress = uint8(a[i]) % 16;
            leftNibbleAddress = (uint8(a[i]) - rightNibbleAddress) / 16;
            rightNibbleHash = uint8(b[i]) % 16;
            leftNibbleHash = (uint8(b[i]) - rightNibbleHash) / 16;

            characterCapitalized[2 * i] = (leftNibbleAddress > 9 && leftNibbleHash > 7);
            characterCapitalized[2 * i + 1] = (rightNibbleAddress > 9 && rightNibbleHash > 7);
        }
    }

    function _getAsciiOffset(uint8 nibble, bool caps) private pure returns (uint8 offset) {
        // to convert to ascii characters, add 48 to 0-9, 55 to A-F, & 87 to a-f.
        if(nibble < 10) {
            offset = 48;
        }
        else if(caps) {
            offset = 55;
        }
        else {
            offset = 87;
        }
    }

    // based on https://ethereum.stackexchange.com/a/56499/48410
    function _toAsciiString(bytes20 data) private pure returns (string memory asciiString) {
        // create an in-memory fixed-size bytes array.
        bytes memory asciiBytes = new bytes(40);

        // declare variable types.
        uint8 b;
        uint8 leftNibble;
        uint8 rightNibble;

        // iterate over bytes, processing left and right nibble in each iteration.
        for(uint256 i = 0; i < data.length; i++) {
            // locate the byte and extract each nibble.
            b = uint8(uint160(data) / (2 ** (8 * (19 - i))));
            leftNibble = b / 16;
            rightNibble = b - 16 * leftNibble;

            // to convert to ascii characters, add 48 to 0-9 and 87 to a-f.
            asciiBytes[2 * i] = bytes1(leftNibble + (leftNibble < 10 ? 48 : 87));
            asciiBytes[2 * i + 1] = bytes1(rightNibble + (rightNibble < 10 ? 48 : 87));
        }

        return string(asciiBytes);
    }

    /*
    *
    *
        External Functions
    *
    *
    */

    /*
        Action Functions
    */

    /// @notice The owner successor can claim the owner role.
    function action_claimOwnerRole() external {
        lock();

        requireOwnerSuccessorAddress(msg.sender);

        claimOwnerRole(msg.sender);

        unlock();
    }

    /// @notice The owner can offer the owner role to a successor address.
    /// @param _address The owner successor address.
    function action_offerOwnerRole(address _address) external {
        lock();

        requireOwnerAddress(msg.sender);

        offerOwnerRole(_address);

        unlock();
    }

    /*
        Withdraw Functions
    */

    /// @notice The owner can withdraw any amount of coins.
    /// @param _value The amount of coins to withdraw.
    function withdraw_coins(uint256 _value) external {
        lock();

        requireOwnerAddress(msg.sender);

        withdrawCoins(msg.sender, _value);

        unlock();
    }

    /// @notice The owner can withdraw any amount of one kind of ERC20 token.
    /// @param _tokenAddress The address where the ERC20 token's contract lives.
    /// @param _value The amount of ERC20 tokens to withdraw.
    function withdraw_erc20Tokens(address _tokenAddress, uint256 _value) external {
        lock();

        requireOwnerAddress(msg.sender);

        withdrawERC20Tokens(_tokenAddress, msg.sender, _value);

        unlock();
    }

    /// @notice The owner can withdraw an ERC721 token.
    /// @param _tokenAddress The address where the ERC721 token's contract lives.
    /// @param _id The ID of the ERC721 token.
    function withdraw_erc721Tokens(address _tokenAddress, uint256 _id) external {
        lock();

        requireOwnerAddress(msg.sender);

        withdrawERC721Tokens(_tokenAddress, _id, msg.sender);

        unlock();
    }

    /// @notice The owner can withdraw any amount of one kind of ERC777 token.
    /// @param _tokenAddress The address where the ERC777 token's contract lives.
    /// @param _value The amount of ERC777 tokens to withdraw.
    /// @param _data Additional data with no specified format.
    function withdraw_erc777Tokens(address _tokenAddress, uint256 _value, bytes memory _data) external {
        lock();

        requireOwnerAddress(msg.sender);

        withdrawERC777Tokens(_tokenAddress, msg.sender, _value, _data);

        unlock();
    }

    /// @notice The owner can withdraw any amount of one kind of ERC1155 token.
    /// @param _tokenAddress The address where the ERC1155 token's contract lives.
    /// @param _id The ID of the ERC1155 token.
    /// @param _value The amount of ERC1155 tokens to withdraw.
    /// @param _data Additional data with no specified format.
    function withdraw_erc1155Tokens(address _tokenAddress, uint256 _id, uint256 _value, bytes memory _data) external {
        lock();

        requireOwnerAddress(msg.sender);

        withdrawERC1155Tokens(_tokenAddress, _id, msg.sender, _value, _data);

        unlock();
    }

    /*
        Query Functions
    */

    /// @notice Returns whether the contract is currently locked.
    /// @return Whether the contract is currently locked.
    function query_isLocked() external view returns (bool) {
        return isLocked();
    }

    /// @notice Returns whether the address is the owner address.
    /// @param _address The address that we are checking.
    /// @return Whether the address is the owner address.
    function query_isOwnerAddress(address _address) external view returns (bool) {
        return isOwnerAddress(_address);
    }

    /// @notice Returns whether the address is the owner successor address.
    /// @param _address The address that we are checking.
    /// @return Whether the address is the owner successor address.
    function query_isOwnerSuccessorAddress(address _address) external view returns (bool) {
        return isOwnerSuccessorAddress(_address);
    }

    /*
        Get Functions
    */

    /// @notice Returns the owner address.
    /// @return The owner address.
    function get_ownerAddress() external view returns (address) {
        return getOwnerAddress();
    }

    /// @notice Returns the owner successor address.
    /// @return The owner successor address.
    function get_ownerSuccessorAddress() external view returns (address) {
        return getOwnerSuccessorAddress();
    }

    /*
        Fail-Safe Functions
    */

    /// @notice The owner can unlock the contract.
    function failsafe_unlock() external {
        requireOwnerAddress(msg.sender);

        setLocked(false);
    }

    /*
        Donate Functions
    */

    /// @notice Anyone can call this to donate funds to the contract.
    function donate() external payable {}
}