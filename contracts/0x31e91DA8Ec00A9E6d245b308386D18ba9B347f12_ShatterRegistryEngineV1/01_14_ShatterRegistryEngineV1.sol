// SPDX-License-Identifier: GPL-3.0-or-later

/// @title Shatter Registry Engine V1
/// @author transientlabs.xyz

/*
   _____ __          __  __               ____             _      __                ______            _               _    _____
  / ___// /_  ____ _/ /_/ /____  _____   / __ \___  ____ _(_)____/ /________  __   / ____/___  ____ _(_)___  ___     | |  / <  /
  \__ \/ __ \/ __ `/ __/ __/ _ \/ ___/  / /_/ / _ \/ __ `/ / ___/ __/ ___/ / / /  / __/ / __ \/ __ `/ / __ \/ _ \    | | / // / 
 ___/ / / / / /_/ / /_/ /_/  __/ /     / _, _/  __/ /_/ / (__  ) /_/ /  / /_/ /  / /___/ / / / /_/ / / / / /  __/    | |/ // /  
/____/_/ /_/\__,_/\__/\__/\___/_/     /_/ |_|\___/\__, /_/____/\__/_/   \__, /  /_____/_/ /_/\__, /_/_/ /_/\___/     |___//_/   
                                                 /____/                /____/               /____/                              
*/

pragma solidity ^0.8.9;

import "ERC165.sol";
import "ECDSA.sol";
import "OwnableUpgradeable.sol";
import "UUPSUpgradeable.sol";

contract ShatterRegistryEngineV1 is ERC165, OwnableUpgradeable, UUPSUpgradeable {

    address public signer;
    mapping(address => uint256) internal version;
    mapping(address => bool) internal isShatterContract;
    mapping(address => mapping(bytes32 => bool)) internal nonceUsed;

    event Register(address indexed _deployer, address indexed _contract, uint256 indexed _version);

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    /// @notice function to set the trusted signer
    /// @dev requires owner of the contract
    /// @param _signer is the new trusted signer address
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    /// @notice function to register official shatter contracts based on a trusted signer
    /// @dev nonce is used so signatures can't be copied
    /// @dev meant to be called during contract deployment
    /// @param _deployer is the user deploying the shatter contract
    /// @param _version is the shatter version
    /// @param _nonce is a number used to create unique signatures
    /// @param _sig is the actual signature to check
    function register(address _deployer, uint256 _version, bytes32 _nonce, bytes memory _sig) external virtual {
        require(!isShatterContract[msg.sender], "Already registered");
        require(!nonceUsed[_deployer][_nonce], "Nonce already has been used");
        bytes32 msgHash = _generateMessageHash(_deployer, _version, _nonce);
        require(ECDSA.recover(msgHash, _sig) == signer, "Invalid signature supplied");
        version[msg.sender] = _version;
        isShatterContract[msg.sender] = true;
        nonceUsed[_deployer][_nonce] = true;
        emit Register(_deployer, msg.sender, _version);
    }

    /// @notice function to manually add shatter contracts
    /// @dev requires ownership of this contract
    /// @param _deployer is the user that deployed the shatter contract
    /// @param _contract is the shatter contract address
    /// @param _version is the shatter contract version
    function manuallyRegister(address _deployer, address _contract, uint256 _version) external virtual onlyOwner {
        require(!isShatterContract[_contract], "Already registered");
        version[_contract] = _version;
        isShatterContract[_contract] = true;
        emit Register(_deployer, _contract, _version);
    }

    /// @notice function to lookup if a contract is a shattter contract
    /// @param _contract is the contract address to lookup
    /// @return tf boolean indicating if a shatter contract
    /// @return v uint256 with the version. 0 is returned if the contract is not a shatter contract
    function lookup(address _contract) external virtual view returns(bool tf, uint256 v) {
        if (isShatterContract[_contract]) {
            return (true, version[_contract]);
        } else {
            return (false, 0);
        }
    }

    /// @notice function to create hash for signature checking
    function _generateMessageHash(address _sender, uint256 _v, bytes32 _n) internal virtual pure returns(bytes32) {
        return (
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n84", _sender, _v, _n))
        );
    }

    /// @notice override _authorizeUpgrade function from UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}
}