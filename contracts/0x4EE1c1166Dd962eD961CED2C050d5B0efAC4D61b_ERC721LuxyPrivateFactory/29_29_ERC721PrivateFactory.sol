//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../ERC721/ERC721LuxyPrivate.sol";

contract ERC721LuxyPrivateFactory is Ownable {
    event Create721LuxyContract(address erc721);

    constructor() {}

    function createToken(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address[] memory _minters,
        bool _ischangeable,
        uint256 _maxSupply,
        uint _salt
    ) external {
        address luxy721PrivateToken = deployProxy(
            getData(_name, _symbol, _baseURI, _minters, _ischangeable,_maxSupply),
            _salt
        );
        ERC721LuxyPrivate token = ERC721LuxyPrivate(luxy721PrivateToken);
        token.__ERC721LuxyPrivate_init(_name, _symbol, _baseURI, _minters,_ischangeable,_maxSupply);
        token.transferOwnership(_msgSender());
        emit Create721LuxyContract(luxy721PrivateToken);
    }

    //deploying Luxy1155 contract with create2
    function deployProxy(bytes memory data, uint salt)
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
            abi.encodePacked(
                type(ERC721LuxyPrivate).creationCode,
                abi.encode(_data)
            );
    }

    //returns address that contract with such arguments will be deployed on
    function getAddress(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address[] memory _minters,
        bool _ischangeable,
        uint256 _maxSupply,
        uint _salt
    ) public view returns (address) {
        bytes memory bytecode;
        bytecode = getCreationBytecode(
            getData(_name, _symbol, _baseURI, _minters,_ischangeable,_maxSupply)
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
        address[] memory _minters,
        bool _ischangeable,
        uint256 _maxSupply
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                ERC721LuxyPrivate.__ERC721LuxyPrivate_init.selector,
                _name,
                _symbol,
                _baseURI,
                _minters,
                _ischangeable,
                _maxSupply
            );
    }
}