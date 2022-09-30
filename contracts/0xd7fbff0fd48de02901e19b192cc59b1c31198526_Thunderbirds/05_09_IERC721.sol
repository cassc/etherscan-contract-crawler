// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @author Prashant Prabhakar Singh [[email protected]]
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
interface IERC721 {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    function balanceOf(address _owner) external view returns (uint256 _balance);

    function ownerOf(uint256 _tokenId) external view returns (address _owner);

    function exists(uint256 _tokenId) external view returns (bool _exists);

    function approve(address _to, uint256 _tokenId) external;

    function getApproved(uint256 _tokenId)
        external
        view
        returns (address _operator);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) external;

    function name() external view returns (string memory _name);

    function symbol() external view returns (string memory _symbol);

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256 _tokenId);

    function tokenByIndex(uint256 _index) external view returns (uint256);

    function supportsInterface(bytes4 _interfaceId)
        external
        view
        returns (bool);
}
