// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ERC721Retreatable {
    /// @dev The Retreating base contract is implemented with the diamond storage pattern to prevent
    /// data overlapping, so it can be added and removed during upgrades without affecting other data.
    bytes32 private constant storagePosition =
        keccak256("diamond.storage.ERC721Retreatable");

    error AlreadyInRetreating();
    error NotInRetreating();
    error RetreatingDisabled();
    error NotAllowed();
    error NotAuthorized();

    struct ERC721RetreatableStorage {
        mapping(uint256 => TokenParameter) tokenParam;
        bool enableRetreating;
        mapping(address => bool) operatorAddress;
    }

    /// @dev pack token related parameters into a single storage slot to reduce gas consumption.
    struct TokenParameter {
        uint64 retreatingStartTime;
        uint64 totalRetreatingTime;
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
        returns (ERC721RetreatableStorage storage ds)
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

    function isRetreating(uint256 tokenId) public view returns (bool) {
        return _retriveTokenParam(tokenId).retreatingStartTime > 0;
    }

    function retreatingTime(uint256 tokenId) public view returns (uint256 t) {
        t = _retriveTokenParam(tokenId).totalRetreatingTime;
        if (isRetreating(tokenId)) {
            t +=
                uint64(block.timestamp) -
                _retriveTokenParam(tokenId).retreatingStartTime;
        }
    }

    function enterRetreating(uint256 tokenId) external onlyTokenOwner(tokenId) {
        _enterRetreating(tokenId);
    }

    function exitRetreating(uint256 tokenId) external onlyTokenOwner(tokenId) {
        _exitRetreating(tokenId);
    }

    function enterRetreatingMulti(uint256[] calldata tokenId)
        external
        onlyTokensOwner(tokenId)
    {
        for (uint256 i; i < tokenId.length; i++) {
            _enterRetreating(tokenId[i]);
        }
    }

    function exitRetreatingMulti(uint256[] calldata tokenId)
        external
        onlyTokensOwner(tokenId)
    {
        for (uint256 i; i < tokenId.length; i++) {
            _exitRetreating(tokenId[i]);
        }
    }

    function _enterRetreating(uint256 tokenId) internal {
        if (isRetreating(tokenId)) {
            revert AlreadyInRetreating();
        }

        if (!_retriveERC721Storage().enableRetreating) {
            revert RetreatingDisabled();
        }

        _retriveTokenParam(tokenId).retreatingStartTime = uint64(
            block.timestamp
        );
    }

    function _exitRetreating(uint256 tokenId) internal {
        if (!isRetreating(tokenId)) {
            revert NotInRetreating();
        }

        _retriveTokenParam(tokenId).totalRetreatingTime +=
            uint64(block.timestamp) -
            _retriveTokenParam(tokenId).retreatingStartTime;
        _retriveTokenParam(tokenId).retreatingStartTime = 0;
    }

    function _setRetreatingEnable(bool enableRetreating) internal {
        _retriveERC721Storage().enableRetreating = enableRetreating;
    }

    function _swapOperator(address operator) internal {
        _retriveERC721Storage().operatorAddress[
            operator
        ] = !_retriveERC721Storage().operatorAddress[operator];
    }

    function _kickRetreating(uint256 tokenId) internal onlyOperator {
        _exitRetreating(tokenId);
    }

    function isRetreatingEnabled() public view returns (bool) {
        return _retriveERC721Storage().enableRetreating;
    }

    /// @dev Insert this fuctions to the token transfer hook
    function _transferCheck(uint256 tokenId) internal view {
        if (isRetreating(tokenId)) {
            revert NotAllowed();
        }
    }
}