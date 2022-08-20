// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ERC721Stashable {
    /// @dev The Stashing base contract is implemented with the diamond storage pattern to prevent
    /// data overlapping, so it can be added and removed during upgrades without affecting other data.
    bytes32 private constant storagePosition =
        keccak256("diamond.storage.ERC721Stashable");

    error AlreadyInStashing();
    error NotInStashing();
    error StashingDisabled();
    error NotAllowed();
    error NotAuthorized();

    struct ERC721StashableStorage {
        mapping(uint256 => TokenParameter) tokenParam;
        bool enableStashing;
        mapping(address => bool) operatorAddress;
    }

    /// @dev pack token related parameters into a single storage slot to reduce gas consumption.
    struct TokenParameter {
        uint64 StashingStartTime;
        uint64 totalStashingTime;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        if (IERC721(address(this)).ownerOf(tokenId) != msg.sender) {
            revert NotAuthorized();
        }
        _;
    }

    modifier onlyTokensOwner(uint256[] memory tokenId) {
        for (uint256 i; i < tokenId.length; i++) {
            if (IERC721(address(this)).ownerOf(tokenId[i]) != msg.sender) {
                revert NotAuthorized();
            }
        }
        _;
    }

    modifier onlyOperator() {
        if (_retriveOperator(msg.sender) != true) {
            revert NotAuthorized();
        }
        _;
    }

    function _retriveERC721Storage()
        private
        pure
        returns (ERC721StashableStorage storage ds)
    {
        bytes32 storagePosition_ = storagePosition;
        assembly {
            ds.slot := storagePosition_
        }
    }

    function _retriveTokenParam(uint256 tokenId)
        private
        view
        returns (TokenParameter storage)
    {
        return _retriveERC721Storage().tokenParam[tokenId];
    }

    function _retriveOperator(address operator) private view returns (bool) {
        return _retriveERC721Storage().operatorAddress[operator];
    }

    function isStashing(uint256 tokenId) public view returns (bool) {
        return _retriveTokenParam(tokenId).StashingStartTime > 0;
    }

    function StashingTime(uint256 tokenId) public view returns (uint256 t) {
        t = _retriveTokenParam(tokenId).totalStashingTime;
        if (isStashing(tokenId)) {
            t +=
                uint64(block.timestamp) -
                _retriveTokenParam(tokenId).StashingStartTime;
        }
    }

    function enterStashing(uint256 tokenId) external onlyTokenOwner(tokenId) {
        _enterStashing(tokenId);
    }

    function exitStashing(uint256 tokenId) external onlyTokenOwner(tokenId) {
        _exitStashing(tokenId);
    }

    function enterStashingMulti(uint256[] calldata tokenId)
        external
        onlyTokensOwner(tokenId)
    {
        for (uint256 i; i < tokenId.length; i++) {
            _enterStashing(tokenId[i]);
        }
    }

    function exitStashingMulti(uint256[] calldata tokenId)
        external
        onlyTokensOwner(tokenId)
    {
        for (uint256 i; i < tokenId.length; i++) {
            _exitStashing(tokenId[i]);
        }
    }

    function _enterStashing(uint256 tokenId) internal {
        if (isStashing(tokenId)) {
            revert AlreadyInStashing();
        }

        if (!_retriveERC721Storage().enableStashing) {
            revert StashingDisabled();
        }

        _retriveTokenParam(tokenId).StashingStartTime = uint64(
            block.timestamp
        );
    }

    function _exitStashing(uint256 tokenId) internal {
        if (!isStashing(tokenId)) {
            revert NotInStashing();
        }

        _retriveTokenParam(tokenId).totalStashingTime +=
            uint64(block.timestamp) -
            _retriveTokenParam(tokenId).StashingStartTime;
        _retriveTokenParam(tokenId).StashingStartTime = 0;
    }

    function _setStashingEnable(bool enableStashing) internal {
        _retriveERC721Storage().enableStashing = enableStashing;
    }

    function _swapOperator(address operator) internal {
        _retriveERC721Storage().operatorAddress[
            operator
        ] = !_retriveERC721Storage().operatorAddress[operator];
    }

    function _kickStashing(uint256 tokenId) internal onlyOperator {
        _exitStashing(tokenId);
    }

    function isStashingEnabled() public view returns (bool) {
        return _retriveERC721Storage().enableStashing;
    }

    /// @dev Insert this fuctions to the token transfer hook
    function _transferCheck(uint256 tokenId) internal view {
        if (isStashing(tokenId)) {
            revert NotAllowed();
        }
    }
}