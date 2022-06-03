//SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

abstract contract IToken {
    function ownerOf(uint256 tokenId) external view virtual returns (address);

    function mint(address _owner, uint256 _tokenId) external virtual;

    function mintBatch(address _owner, uint16[] calldata _tokenIds) external virtual;

    function burn(uint256 _tokenId) external virtual;

    function exists(uint256 _tokenId) external view virtual returns (bool);

    function tokensOfOwner(address _owner) external view virtual returns (uint256[] memory);

    function MAX_SUPPLY() external view virtual returns (uint256);
}