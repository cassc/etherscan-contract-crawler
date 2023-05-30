// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.0;
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IFerrumDeployer.sol";
import "./IVersioned.sol";

contract FerrumDeployer is IFerrumDeployer, IVersioned {
	string constant public override VERSION = "0.0.1";
    uint256 constant EXTERNAL_HASH = 0x0ddafcd8600839ce553cacb17e362c83ea42ccfd1e8c8b3cb4d075124196dfc0;
    uint256 constant INTERNAL_HASH = 0x27fd0863a54f729686099446389b11108e6e34e7364d1f8e38a43e1661a07f3a;
    bytes public override initData;
    event Deployed(address);
    event DeployedWithData(address conAddr, address owner);

    function deploy(bytes32 salt, bytes calldata bytecode)
    public returns (address) {
        bytes32 _data = keccak256(abi.encode(salt, INTERNAL_HASH, msg.sender));
        address deployed = Create2.deploy(0, _data, bytecode);
        emit Deployed(deployed);
        return deployed;
    }

    function deployOwnable(bytes32 salt, address owner, bytes calldata data, bytes calldata bytecode)
    external returns (address) {
        // Contract should get the date using IFerrumDeployer(this).initData();
        initData = data;
        bytes32 _data = keccak256(abi.encode(salt, EXTERNAL_HASH, owner, data));
        address addr = Create2.deploy(0, _data, bytecode);
        if (owner != address(0)) {
            Ownable(addr).transferOwnership(owner);
        }
        emit DeployedWithData(addr, owner);
        delete initData;
        return addr;
    }

    function computeAddressOwnable(bytes32 salt, address owner, bytes calldata data, bytes32 bytecodeHash)
    external view returns (address) {
        bytes32 _data = keccak256(abi.encode(salt, EXTERNAL_HASH, owner, data));
        return Create2.computeAddress(_data, bytecodeHash);
    }

    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer)
    external view returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(salt, INTERNAL_HASH, deployer)
        );
        return Create2.computeAddress(_data, bytecodeHash);
    }
}