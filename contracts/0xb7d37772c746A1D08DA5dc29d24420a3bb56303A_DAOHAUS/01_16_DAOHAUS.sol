// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./DAOHAUSMinter.sol";

contract DAOHAUS is DAOHAUSMinter {
    // ====== STATE VARIABLES ======

    string internal _baseTokenURISegmentBefore;
    string internal _baseTokenURISegmentAfter;
    address internal _teamWalletAddress;

    // ====== CONSTRUCTOR ======

    constructor(
        uint256 maxMintSupply,
        string memory baseTokenURISegmentBefore,
        string memory baseTokenURISegmentAfter,
        address teamWalletAddress_
    ) DAOHAUSMinter("DAOHAUS", "DAOHAUS", maxMintSupply) {
        _baseTokenURISegmentBefore = baseTokenURISegmentBefore;
        _baseTokenURISegmentAfter = baseTokenURISegmentAfter;
        _teamWalletAddress = teamWalletAddress_;
    }

    // ====== OVERRIDES ======

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURISegmentBefore;
    }

    /**
     * @dev Returns the URI of a DAOHAUS with the given token ID.
     *
     * Throws if the given token ID is not a valid (i.e. it does not point to a
     * minted DAOHAUS).
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        require(_exists(tokenId), "DH_NONEXISTENT_TOKEN");
        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    _toString(tokenId),
                    _baseTokenURISegmentAfter
                )
            );
    }

    // ====== EXTERNAL FUNCTIONS ======

    /**
     * @dev Returns the address of the contract's owner.
     *
     * This function is required by OpenSea. Normally, you'd inherit from
     * `Ownable` and get the owner from there, but since we're using
     * `AccessControl`, we'll return the only user with `DEFAULT_ADMIN_ROLE`.
     */
    function owner() external view virtual returns (address) {
        return _admin;
    }

    // ====== ONLY-OPERATOR FUNCTIONS ======

    /**
     * @dev Returns the address that will be used to withdraw the contract's
     * balance to.
     *
     * You must have at least the OPERATOR role to call this function.
     */
    function teamWalletAddress() external view onlyOperator returns (address) {
        return _teamWalletAddress;
    }

    /**
     * @dev Returns a tuple of before and after segments that will sandwich the
     * token ID when querying the token URI for a specific minted token.
     *
     * You must have at least the OPERATOR role to call this function.
     */
    function baseTokenURISegments()
        external
        view
        onlyOperator
        returns (string memory segmentBefore, string memory segmentAfter)
    {
        return (_baseTokenURISegmentBefore, _baseTokenURISegmentAfter);
    }

    /**
     * @dev Update the segments that will sandwich the token ID when querying
     * the token ID for a specific minted token.
     */
    function setBaseTokenURISegments(
        string memory newSegmentBefore,
        string memory newSegmentAfter
    ) external onlyOperator {
        _baseTokenURISegmentBefore = newSegmentBefore;
        _baseTokenURISegmentAfter = newSegmentAfter;
    }

    // ====== ONLY-WITHDRAWER FUNCTIONS ======

    /**
     * @dev Transfers any pending balance available in the contract to the
     * designated team wallet address.
     *
     * You must have at least the WITHDRAWER role to call this function.
     */
    function withdraw() external onlyWithdrawer {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(_teamWalletAddress).call{value: balance}("");
        require(success, "HH_TRANSFER_FAILURE");
    }
}