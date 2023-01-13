//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../ERC1155/ERC1155Luxy.sol";

contract ERC1155LuxyFactory is Ownable {
    event Create1155LuxyContract(address erc1155);
    event Create1155LuxyPrivateContract(address erc1155);

    constructor() {}

    function createToken(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        bool _isChangeable,
        uint256 _maxSupply,
        uint256 _salt
    ) external {
        address luxy1155Token = deployProxy(
            getData(_name, _symbol, _baseURI, _isChangeable,_maxSupply),
            _salt
        );

        ERC1155Luxy token = ERC1155Luxy(luxy1155Token);
        token.__ERC1155Luxy_init(_name, _symbol, _baseURI, _isChangeable,_maxSupply);
        token.transferOwnership(_msgSender());
        emit Create1155LuxyContract(luxy1155Token);
    }

    //deploying Luxy1155 contract with create2
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

    //adding  unnecessary constructor arguments to Luxy1155 bytecode, to get less change for collision on contract address
    function getCreationBytecode(bytes memory _data)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(type(ERC1155Luxy).creationCode, abi.encode(_data));
    }

    //returns address that contract with such arguments will be deployed on
    function getAddress(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        bool _isChangeable,
        uint256 _maxSupply,
        uint256 _salt
    ) public view returns (address) {
        bytes memory bytecode = getCreationBytecode(
            getData(_name, _symbol, _baseURI, _isChangeable,_maxSupply)
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
        string memory _baseURI,
        bool _isChangeable,
        uint256 _maxSupply
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                ERC1155Luxy.__ERC1155Luxy_init.selector,
                _name,
                _symbol,
                _baseURI,
                _isChangeable,
                _maxSupply
            );
    }
}