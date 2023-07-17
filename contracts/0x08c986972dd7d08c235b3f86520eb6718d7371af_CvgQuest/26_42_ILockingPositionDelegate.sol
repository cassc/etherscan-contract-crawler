// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILockingPositionDelegate {
    struct OwnedAndDelegated {
        uint256[] owneds;
        uint256[] mgDelegateds;
        uint256[] veDelegateds;
    }

    function delegatedYsCvg(uint256 tokenId) external view returns (address);

    function getMgDelegateeInfoPerTokenAndAddress(
        uint256 _tokenId,
        address _to
    ) external view returns (uint256, uint256, uint256);

    function getVeCvgIndexForDelegatee(address _delegatee, uint256 _tokenId) external view returns (uint256);

    function getMgCvgIndexForDelegatee(address _delegatee, uint256 _tokenId) external view returns (uint256);

    function delegateVeCvg(uint256 _tokenId, address _to) external;

    function delegateYsCvg(uint256 _tokenId, address _to, bool _status) external;

    function delegateMgCvg(uint256 _tokenId, address _to, uint256 _percentage) external;

    function delegatedVeCvg(uint256 tokenId) external view returns (address);

    function getVeCvgDelegatees(address account) external view returns (uint256[] memory);

    function getMgCvgDelegatees(address account) external view returns (uint256[] memory);

    function getTokenOwnedAndDelegated(address _addr) external view returns (OwnedAndDelegated[] memory);

    function getTokenMgOwnedAndDelegated(address _addr) external view returns (uint256[] memory, uint256[] memory);

    function getTokenVeOwnedAndDelegated(address _addr) external view returns (uint256[] memory, uint256[] memory);

    function addTokenAtMint(uint256 _tokenId, address minter) external;
}