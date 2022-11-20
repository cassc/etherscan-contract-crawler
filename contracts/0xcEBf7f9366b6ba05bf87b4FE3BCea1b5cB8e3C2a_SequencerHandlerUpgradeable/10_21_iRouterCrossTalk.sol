// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface iRouterCrossTalk {

    event Linkevent( uint8 indexed ChainID , address indexed linkedContract );

    event Unlinkevent( uint8 indexed ChainID , address indexed linkedContract );

    event CrossTalkSend(uint8 indexed sourceChain , uint8 indexed destChain , address sourceAddress , address destinationAddress ,bytes4 indexed _interface, bytes _data , bytes32 _hash );

    event CrossTalkReceive(uint8 indexed sourceChain , uint8 indexed destChain , address sourceAddress , address destinationAddress ,bytes4 indexed _interface, bytes _data , bytes32 _hash );

    function routerSync(uint8 srcChainID , address srcAddress , bytes4 _interface , bytes calldata _data , bytes32 hash ) external returns ( bool , bytes memory );

    function Link(uint8 _chainID , address _linkedContract) external;

    function Unlink(uint8 _chainID ) external;

    function fetchLinkSetter( ) external view returns( address);

    function fetchLink( uint8 _chainID ) external view returns( address);

    function fetchBridge( ) external view returns ( address );

    function fetchHandler( ) external view returns ( address );

}