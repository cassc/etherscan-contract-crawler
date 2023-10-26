// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

struct SetConfigParam {
    uint32 configType;
    bytes config;
}

interface IMessageLibManager {
    struct Timeout {
        address lib;
        uint expiry;
    }

    event LibraryRegistered(address newLib);
    event DefaultSendLibrarySet(uint32 eid, address newLib);
    event DefaultReceiveLibrarySet(uint32 eid, address oldLib, address newLib);
    event DefaultReceiveLibraryTimeoutSet(uint32 eid, address oldLib, uint expiry);
    event SendLibrarySet(address sender, uint32 eid, address newLib);
    event ReceiveLibrarySet(address receiver, uint32 eid, address oldLib, address newLib);
    event ReceiveLibraryTimoutSet(address receiver, uint32 eid, address oldLib, uint timeout);

    function registerLibrary(address _lib) external;

    function isRegisteredLibrary(address _lib) external view returns (bool);

    function getRegisteredLibraries() external view returns (address[] memory);

    function setDefaultSendLibrary(uint32 _eid, address _newLib) external;

    function defaultSendLibrary(uint32 _eid) external view returns (address);

    function setDefaultReceiveLibrary(uint32 _eid, address _newLib, uint _timeout) external;

    function defaultReceiveLibrary(uint32 _eid) external view returns (address);

    function setDefaultReceiveLibraryTimeout(uint32 _eid, address _lib, uint _expiry) external;

    function defaultReceiveLibraryTimeout(uint32 _eid) external view returns (address lib, uint expiry);

    function defaultConfig(address _lib, uint32 _eid, uint32 _configType) external view returns (bytes memory);

    function isSupportedEid(uint32 _eid) external view returns (bool);

    /// ------------------- OApp interfaces -------------------
    function setSendLibrary(uint32 _eid, address _newLib) external;

    function getSendLibrary(address _sender, uint32 _eid) external view returns (address lib);

    function isDefaultSendLibrary(address _sender, uint32 _eid) external view returns (bool);

    function setReceiveLibrary(uint32 _eid, address _newLib, uint _gracePeriod) external;

    function getReceiveLibrary(address _receiver, uint32 _eid) external view returns (address lib, bool isDefault);

    function setReceiveLibraryTimeout(uint32 _eid, address _lib, uint _gracePeriod) external;

    function receiveLibraryTimeout(address _receiver, uint32 _eid) external view returns (address lib, uint expiry);

    function setConfig(address _lib, uint32 _eid, SetConfigParam[] calldata _params) external;

    function getConfig(
        address _oapp,
        address _lib,
        uint32 _eid,
        uint32 _configType
    ) external view returns (bytes memory config, bool isDefault);

    function snapshotConfig(address _lib, uint32[] calldata _eids) external;

    function resetConfig(address _lib, uint32[] calldata _eids) external;
}