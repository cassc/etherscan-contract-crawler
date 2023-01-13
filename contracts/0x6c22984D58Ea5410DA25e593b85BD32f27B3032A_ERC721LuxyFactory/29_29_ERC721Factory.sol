//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../ERC721/ERC721Luxy.sol";

contract ERC721LuxyFactory is Ownable {
    event Create721LuxyContract(address erc721);

    constructor() {}

    function createToken(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        bool _isChangeable,
        uint256 _maxSupply,
        uint256 _salt
    ) external {
        address luxy721Token = deployProxy(
            getData(_name, _symbol, _baseURI, _isChangeable,_maxSupply),
            _salt
        );

        ERC721Luxy token = ERC721Luxy(luxy721Token);
        token.__ERC721Luxy_init(_name, _symbol, _baseURI, _isChangeable,_maxSupply);
        token.transferOwnership(_msgSender());
        emit Create721LuxyContract(luxy721Token);
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
            abi.encodePacked(type(ERC721Luxy).creationCode, abi.encode(_data));
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
                ERC721Luxy.__ERC721Luxy_init.selector,
                _name,
                _symbol,
                _baseURI,
                _isChangeable,
                _maxSupply
            );
    }
}