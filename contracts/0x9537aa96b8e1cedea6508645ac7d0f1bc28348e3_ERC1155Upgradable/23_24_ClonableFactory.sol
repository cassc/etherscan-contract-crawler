// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMath.sol";
import "./Clonable.sol";
abstract contract ClonableFactory is OwnableUpgradeable {

    using SafeMath for uint256;

    struct ImplementationsRecord {
        uint256 version;
        address implementation;
        uint256 contractVersion;
    }

    address public CurrentImplementation;
    ImplementationsRecord[] public AllImplementations;

    event CloneCreated(address indexed newThingAddress, address indexed libraryAddress);
    address[] internal Clones;
    string[] private Names;
    string public factoryType;

    function initialize() public virtual onlyOwner {
        updateImplementation();
    }

    function version() public view virtual returns (uint256) {
        return 1;
    }

    function versions() public view returns (uint256 _version) {
        return AllImplementations.length;
    }

    function updateImplementation() public onlyOwner {
        CurrentImplementation = implement();
        IClonable(CurrentImplementation).initialize();
        AllImplementations.push(ImplementationsRecord(AllImplementations.length.add(1), address(CurrentImplementation), IClonable(CurrentImplementation).version()));
    }

    function implement() internal virtual returns(address);
    function afterClone(address,address) internal virtual;

    function getClones() public view returns (address[] memory) {
        return Clones;
    }
    function createClone(address _newOwner) public onlyOwner {
        address clone = ClonesUpgradeable.clone(CurrentImplementation);
        handleClone(clone, _newOwner);
    }

    function createCloneAtVersion(address _newOwner, uint256 _version) public onlyOwner {
        address clone = ClonesUpgradeable.clone(AllImplementations[_version.sub(1)].implementation);
        handleClone(clone, _newOwner);
    }

    function handleClone(address clone, address _newOwner) internal {
        IClonable(clone).initialize();
        Clones.push(clone);
        emit CloneCreated(clone, CurrentImplementation);
        afterClone(_newOwner, clone);
    }

    function transferCloneOwnership(address clone, address newOwner) public onlyOwner {
        OwnableUpgradeable(clone).transferOwnership(newOwner);
    }

}