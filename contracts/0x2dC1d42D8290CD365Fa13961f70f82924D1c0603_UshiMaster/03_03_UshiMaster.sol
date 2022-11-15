// SPDX-License-Identifier: MIT
//@itsalexey
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

interface MyInterface {
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event CreatorChanged(uint256 indexed _id, address indexed _creator);
    event MetaTransactionExecuted(
        address userAddress,
        address relayerAddress,
        bytes functionSignature
    );
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event PermanentURI(string _value, uint256 indexed _id);
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event URI(string value, uint256 indexed id);
    event Unpaused(address account);

    function ERC712_VERSION() external view returns (string memory);

    function addSharedProxyAddress(address _address) external;

    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) external view returns (uint256[] memory);

    function batchBurn(address _from, uint256[] memory _ids, uint256[] memory _quantities) external;

    function batchMint(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data
    ) external;

    function burn(address _from, uint256 _id, uint256 _quantity) external;

    function creator(uint256 _id) external view returns (address);

    function disableMigrate() external;

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external payable returns (bytes memory);

    function exists(uint256 _id) external view returns (bool);

    function getChainId() external view returns (uint256);

    function getDomainSeperator() external view returns (bytes32);

    function getNonce(address user) external view returns (uint256 nonce);

    function isApprovedForAll(
        address _owner,
        address _operator
    ) external view returns (bool isOperator);

    function isPermanentURI(uint256 _id) external view returns (bool);

    function maxSupply(uint256 _id) external pure returns (uint256);

    function migrate(AssetContractShared.Ownership[] memory _ownerships) external;

    function migrationTarget() external view returns (address);

    function mint(address _to, uint256 _id, uint256 _quantity, bytes memory _data) external;

    function name() external view returns (string memory);

    function openSeaVersion() external pure returns (string memory);

    function owner() external view returns (address);

    function pause() external;

    function paused() external view returns (bool);

    function proxyRegistryAddress() external view returns (address);

    function removeSharedProxyAddress(address _address) external;

    function renounceOwnership() external;

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function setCreator(uint256 _id, address _to) external;

    function setPermanentURI(uint256 _id, string memory _uri) external;

    function setProxyRegistryAddress(address _address) external;

    function setTemplateURI(string memory _uri) external;

    function setURI(uint256 _id, string memory _uri) external;

    function sharedProxyAddresses(address) external view returns (bool);

    function supportsFactoryInterface() external pure returns (bool);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function templateURI() external view returns (string memory);

    function totalSupply(uint256 _id) external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function unpause() external;

    function uri(uint256 _id) external view returns (string memory);
}

interface AssetContractShared {
    struct Ownership {
        uint256 id;
        address owner;
    }
}

error UshiMaster__ReceiversArrayLengthNotEqualtoIDs();
error UshiMaster__TransferFailed();

contract UshiMaster is Ownable {
    constructor() Ownable() {}

    function bulkAirdrop(
        MyInterface _token,
        address[] calldata _to,
        uint256[] calldata _id,
        uint256[] calldata _amount
    ) public onlyOwner {
        if (_to.length != _id.length) {
            revert UshiMaster__ReceiversArrayLengthNotEqualtoIDs();
        }
        for (uint256 i = 0; i < _to.length; i++) {
            _token.safeTransferFrom(msg.sender, _to[i], _id[i], _amount[i], "");
        }
    }

    function setCreator(MyInterface _token, uint256 _id, address _to) external onlyOwner {
        _token.setCreator(_id, _to);
    }

    function getCreator(MyInterface _token, uint256 _id) external view returns (address) {
        return _token.creator(_id);
    }

    function getUri(MyInterface _token, uint256 _id) external view returns (string memory) {
        return _token.uri(_id);
    }

    function withdrawETH() public onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        if (!success) {
            revert UshiMaster__TransferFailed();
        }
    }

    receive() external payable {}

    fallback() external payable {}
}