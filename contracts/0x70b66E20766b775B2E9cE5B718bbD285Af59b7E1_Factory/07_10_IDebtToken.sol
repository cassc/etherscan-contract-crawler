// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDebtToken {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload, bytes _reason);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ReceiveFromChain(uint16 indexed _srcChainId, address indexed _to, uint256 _amount);
    event RetryMessageSuccess(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes32 _payloadHash);
    event SendToChain(uint16 indexed _dstChainId, address indexed _from, bytes _toAddress, uint256 _amount);
    event SetMinDstGas(uint16 _dstChainId, uint16 _type, uint256 _minDstGas);
    event SetPrecrime(address precrime);
    event SetTrustedRemote(uint16 _remoteChainId, bytes _path);
    event SetTrustedRemoteAddress(uint16 _remoteChainId, bytes _remoteAddress);
    event SetUseCustomAdapterParams(bool _useCustomAdapterParams);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function approve(address spender, uint256 amount) external returns (bool);

    function burn(address _account, uint256 _amount) external;

    function burnWithGasCompensation(address _account, uint256 _amount) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function enableTroveManager(address _troveManager) external;

    function flashLoan(address receiver, address token, uint256 amount, bytes calldata data) external returns (bool);

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;

    function mint(address _account, uint256 _amount) external;

    function mintWithGasCompensation(address _account, uint256 _amount) external returns (bool);

    function nonblockingLzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external;

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function renounceOwnership() external;

    function returnFromPool(address _poolAddress, address _receiver, uint256 _amount) external;

    function sendToSP(address _sender, uint256 _amount) external;

    function setConfig(uint16 _version, uint16 _chainId, uint256 _configType, bytes calldata _config) external;

    function setMinDstGas(uint16 _dstChainId, uint16 _packetType, uint256 _minGas) external;

    function setPayloadSizeLimit(uint16 _dstChainId, uint256 _size) external;

    function setPrecrime(address _precrime) external;

    function setReceiveVersion(uint16 _version) external;

    function setSendVersion(uint16 _version) external;

    function setTrustedRemote(uint16 _srcChainId, bytes calldata _path) external;

    function setTrustedRemoteAddress(uint16 _remoteChainId, bytes calldata _remoteAddress) external;

    function setUseCustomAdapterParams(bool _useCustomAdapterParams) external;

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function transferOwnership(address newOwner) external;

    function retryMessage(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external payable;

    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _amount,
        address _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    function DEBT_GAS_COMPENSATION() external view returns (uint256);

    function DEFAULT_PAYLOAD_SIZE_LIMIT() external view returns (uint256);

    function FLASH_LOAN_FEE() external view returns (uint256);

    function NO_EXTRA_GAS() external view returns (uint256);

    function PT_SEND() external view returns (uint16);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function borrowerOperationsAddress() external view returns (address);

    function circulatingSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function domainSeparator() external view returns (bytes32);

    function estimateSendFee(
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _amount,
        bool _useZro,
        bytes calldata _adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    function factory() external view returns (address);

    function failedMessages(uint16, bytes calldata, uint64) external view returns (bytes32);

    function flashFee(address token, uint256 amount) external view returns (uint256);

    function gasPool() external view returns (address);

    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address,
        uint256 _configType
    ) external view returns (bytes memory);

    function getTrustedRemoteAddress(uint16 _remoteChainId) external view returns (bytes memory);

    function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    function lzEndpoint() external view returns (address);

    function maxFlashLoan(address token) external view returns (uint256);

    function minDstGasLookup(uint16, uint16) external view returns (uint256);

    function name() external view returns (string memory);

    function nonces(address owner) external view returns (uint256);

    function owner() external view returns (address);

    function payloadSizeLimitLookup(uint16) external view returns (uint256);

    function permitTypeHash() external view returns (bytes32);

    function precrime() external view returns (address);

    function stabilityPoolAddress() external view returns (address);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function token() external view returns (address);

    function totalSupply() external view returns (uint256);

    function troveManager(address) external view returns (bool);

    function trustedRemoteLookup(uint16) external view returns (bytes memory);

    function useCustomAdapterParams() external view returns (bool);

    function version() external view returns (string memory);
}