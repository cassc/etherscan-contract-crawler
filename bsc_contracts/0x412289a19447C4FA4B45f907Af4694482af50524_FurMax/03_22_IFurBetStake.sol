// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFurBetStake {
    function addressBook (  ) external view returns ( address );
    function approve ( address to, uint256 tokenId ) external;
    function balanceOf ( address owner ) external view returns ( uint256 );
    function getApproved ( uint256 tokenId ) external view returns ( address );
    function initialize (  ) external;
    function isApprovedForAll ( address owner, address operator ) external view returns ( bool );
    function name (  ) external view returns ( string memory );
    function owner (  ) external view returns ( address );
    function ownerOf ( uint256 tokenId ) external view returns ( address );
    function pause (  ) external;
    function paused (  ) external view returns ( bool );
    function proxiableUUID (  ) external view returns ( bytes32 );
    function renounceOwnership (  ) external;
    function safeTransferFrom ( address from, address to, uint256 tokenId ) external;
    function safeTransferFrom ( address from, address to, uint256 tokenId, bytes memory _data ) external;
    function setAddressBook ( address address_ ) external;
    function setApprovalForAll ( address operator, bool approved ) external;
    function setup (  ) external;
    function stake ( uint256 period_, uint256 amount_ ) external;
    function stakeFor ( address participant_, uint256 period_, uint256 amount_ ) external;
    function stakeMax ( address participant_, uint256 amount_ ) external;
    function staked ( address participant_ ) external view returns ( uint256 );
    function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
    function symbol (  ) external view returns ( string memory );
    function tokenURI ( uint256 tokenId_ ) external view returns ( string memory );
    function transferFrom ( address from, address to, uint256 tokenId ) external;
    function transferOwnership ( address newOwner ) external;
    function unpause (  ) external;
    function upgradeTo ( address newImplementation ) external;
    function upgradeToAndCall ( address newImplementation, bytes memory data ) external;
}