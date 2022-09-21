// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
pragma abicoder v2;

import "./ERC721/ERC721.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev This contract is for creating proxy to access ERC721 token.
 *
 * The beacon should be initialized before call CollectionsFactory constructor.
 *
 */
contract CollectionsFactory721 is Ownable {
    address public beacon;

    event CreateERC721UserProxy(address proxy);

    constructor(address _beacon) {
        beacon = _beacon;
    }

    function createToken(
        string memory _name,
        string memory _symbol,
        string memory baseURI,
        string memory contractURI,
        address[] memory operators
    ) external {
        BeaconProxy beaconProxy = new BeaconProxy(
            beacon,
            getData(_name, _symbol, baseURI, contractURI, operators)
        );
        GenericERC721 token = GenericERC721(address(beaconProxy));
        token.transferOwnership(_msgSender());
        emit CreateERC721UserProxy(address(beaconProxy));
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

    //returns address that private contract with such arguments will be deployed on
    function getAddress(
        string memory _name,
        string memory _symbol,
        string memory baseURI,
        string memory contractURI,
        address[] memory operators,
        uint256 _salt
    ) public view returns (address) {
        bytes memory bytecode = getCreationBytecode(
            getData(_name, _symbol, baseURI, contractURI, operators)
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
        string memory baseURI,
        string memory contractURI,
        address[] memory operators
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                GenericERC721.__GenericERC721_initialize_User.selector,
                _name,
                _symbol,
                baseURI,
                contractURI,
                operators
            );
    }
}