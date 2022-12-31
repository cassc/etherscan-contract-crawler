// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../tokens/erc-721/ERC721VCG.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev This contract is for creating proxy to access ERC721VCG token.
 *
 * The beacon should be initialized before call ERC721VCGFactoryC1 constructor.
 *
 */
contract ERC721VCGFactoryC1 is Ownable {
    address public beacon;
    bool public isNeedWhitelist = false;

    mapping(address => bool) whiteListAddress; // address => isWhitelisted
    mapping(address => bool) blacklistAddress; // address => isBlacklisted

    event Create721VCGProxy(address proxy);

    constructor(address _beacon) {
        beacon = _beacon;
    }

    modifier checkRule() {
        require(!blacklistAddress[msg.sender], "Your Blacklisted");
        if (isNeedWhitelist) {
            require(whiteListAddress[msg.sender], "Your Not Whitelisted");
        }
        _;
    }

    //Only Owner Setup Function
    function flipWhiteList() external {
        isNeedWhitelist = !isNeedWhitelist;
    }

    function setWhitelist(address[] memory _addresses, bool isWhitelisted)
        external
        onlyOwner
    {
        for (uint i = 0; i < _addresses.length; i++) {
            if (isWhitelisted) {
                require(
                    !blacklistAddress[_addresses[i]],
                    "address already blacklisted"
                );
            }
            whiteListAddress[_addresses[i]] = isWhitelisted;
        }
    }

    function setBlacklist(address[] memory _addresses, bool isBlacklisted)
        external
        onlyOwner
    {
        for (uint i = 0; i < _addresses.length; i++) {
            if (isBlacklisted) {
                require(
                    !whiteListAddress[_addresses[i]],
                    "address already whitelisted"
                );
            }
            blacklistAddress[_addresses[i]] = isBlacklisted;
        }
    }

    function createToken(
        string memory _name,
        string memory _symbol,
        string memory contractURI,
        uint256 salt
    ) external checkRule {
        address beaconProxy = deployProxy(
            getData(_name, _symbol, contractURI),
            salt
        );
        ERC721VCG token = ERC721VCG(address(beaconProxy));
        token.transferOwnership(_msgSender());
        emit Create721VCGProxy(beaconProxy);
    }

    //deploying BeaconProxy contract with create2
    function deployProxy(bytes memory data, uint256 salt)
        internal
        returns (address proxy)
    {
        bytes memory bytecode = getCreationBytecode(data);
        assembly {
            proxy := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(proxy)) {
                revert(0, 0)
            }
        }
    }

    //adding constructor arguments to BeaconProxy bytecode
    function getCreationBytecode(bytes memory _data)
        internal
        view
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                type(BeaconProxy).creationCode,
                abi.encode(beacon, _data)
            );
    }

    //returns address that contract with such arguments will be deployed on
    function getAddress(
        string memory _name,
        string memory _symbol,
        string memory contractURI,
        uint256 _salt
    ) public view returns (address) {
        bytes memory bytecode = getCreationBytecode(
            getData(_name, _symbol, contractURI)
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                _salt,
                keccak256(bytecode)
            )
        );

        return address(uint160(uint256(hash)));
    }

    function getData(
        string memory _name,
        string memory _symbol,
        string memory contractURI
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                ERC721VCG.__ERC721VCG_init.selector,
                _name,
                _symbol,
                contractURI
            );
    }
}