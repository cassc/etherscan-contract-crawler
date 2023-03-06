// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract VersionRepo is UUPSUpgradeable, OwnableUpgradeable {

    event CreateContract(string name);
    event DelContract(string name);
    event AddVersion(string name, string version, address insAddress);
    event DelVersion(string name, string version);
    event SetCurrentVersion(string name, string version);

    modifier checkContract(string memory name) {
        require(hasContract(name), "Contract is nonexistent");
        _;
    }

    modifier checkVersion(string memory name, string memory version) {
        require(hasVersion(name, version), "Version is nonexistent");
        _;
    }

    struct Version {
        string ver;
        address ins;
    }

    struct Contract {
        string name;
        string current;
        string[] versionList;
        mapping(string => Version) versionMap;
    }

    string[] contractList;
    mapping(string => Contract) contractMap;

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override {}

    function createContract(string memory name)
    onlyOwner
    external {
        require(!hasContract(name), "Duplicated contract name");
        contractList.push(name);
        contractMap[name].name = name;
        emit CreateContract(name);
    }

    function getContractList()
    view external returns (string [] memory) {
        return contractList;
    }

    function getAddress(string memory name)
    view external returns (address) {
        string memory version = contractMap[name].current;
        return contractMap[name].versionMap[version].ins;
    }

    function getAddressByVersion(string memory name, string memory version)
    view external returns (address) {
        Version memory obj = contractMap[name].versionMap[version];
        return obj.ins;
    }

    function hasContract(string memory name)
    view public returns (bool) {
        return bytes(contractMap[name].name).length != 0;
    }

    function hasVersion(string memory name, string memory version)
    view public returns (bool) {
        return bytes(contractMap[name].versionMap[version].ver).length != 0;
    }

    function addVersion(string memory name, string memory version, address insAddress)
    onlyOwner
    checkContract(name)
    external {
        require(!hasVersion(name, version), "Duplicated version");
        Contract storage obj = contractMap[name];
        obj.versionList.push(version);
        obj.versionMap[version].ver = version;
        obj.versionMap[version].ins = insAddress;
        emit AddVersion(name, version, insAddress);
    }

    function setCurrentVersion(string memory name, string memory version)
    onlyOwner
    checkContract(name)
    checkVersion(name, version)
    external {
        Contract storage contractObj = contractMap[name];
        Version memory verObj = contractObj.versionMap[version];
        contractObj.current = verObj.ver;
        emit SetCurrentVersion(name, version);
    }

    function getCurrentVersion(string memory name)
    checkContract(name)
    view external returns (string memory) {
        Contract storage contractObj = contractMap[name];
        return contractObj.current;
    }

    function searchIndexOfList(string[] memory list, string memory text) pure private returns (uint) {
        uint i;
        for (i = 0; i < list.length; i++) {
            string memory element = list[i];
            if (bytes(element).length == bytes(text).length) {
                if (keccak256(abi.encodePacked(element)) == keccak256(abi.encodePacked(text))) {
                    return i;
                }
            }
        }
        return i;
    }

    function delAllVersions(string memory name) private {
        mapping(string => Version) storage versionMap = contractMap[name].versionMap;
        string[] storage versionList = contractMap[name].versionList;
        for (uint i = 0; i < versionList.length; i++) {
            string memory version = versionList[i];
            delete versionMap[version];
            delete versionList[i];
        }
    }

    function delContract(string memory name)
    onlyOwner
    checkContract(name)
    external {
        delAllVersions(name);
        uint iContract = searchIndexOfList(contractList, name);
        contractList[iContract] = contractList[contractList.length - 1];
        contractList.pop();
        delete contractMap[name];
        emit DelContract(name);
    }

    function getVersionList(string memory name) view external returns (string [] memory) {
        return contractMap[name].versionList;
    }

    function delVersion(string memory name, string memory version)
    onlyOwner
    checkContract(name)
    checkVersion(name, version)
    external {
        mapping(string => Version) storage versionMap = contractMap[name].versionMap;
        string[] storage versionList = contractMap[name].versionList;
        uint iVersion = searchIndexOfList(versionList, version);
        versionList[iVersion] = versionList[versionList.length - 1];
        versionList.pop();
        delete versionMap[version];
        emit DelVersion(name, version);
    }
}