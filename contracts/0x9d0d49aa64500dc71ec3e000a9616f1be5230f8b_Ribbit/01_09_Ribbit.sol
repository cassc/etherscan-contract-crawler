//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract Ribbit is Context, Ownable, ERC20 {
    IERC721Enumerable public frogContract;

    uint256 public ribbitPerTokenId = 10000 * (10**decimals());
    uint256 public tokenIdStart = 0;
    uint256 public tokenIdEnd = 9999;

    mapping(uint256 => bool) public ribbitClaimedByTokenId;

    constructor(address frogContractAddress) Ownable() ERC20("Ribbit", "RBT") {
        frogContract = IERC721Enumerable(frogContractAddress);
    }

    function claimById(uint256 tokenId) external {
        require(
            _msgSender() == frogContract.ownerOf(tokenId),
            "MUST_OWN_TOKEN_ID"
        );
        _claim(tokenId, _msgSender());
    }

    function claimAllForOwner() external {
        uint256 tokenBalanceOwner = frogContract.balanceOf(_msgSender());

        require(tokenBalanceOwner > 0, "NO_FROGS_OWNED");

        for (uint256 i = 0; i < tokenBalanceOwner; i++) {
            _claim(
                frogContract.tokenOfOwnerByIndex(_msgSender(), i),
                _msgSender()
            );
        }
    }

    function claimRangeForOwner(uint256 ownerIndexStart, uint256 ownerIndexEnd)
        external
    {
        uint256 tokenBalanceOwner = frogContract.balanceOf(_msgSender());

        require(tokenBalanceOwner > 0, "NO_FROGS_OWNED");

        require(
            ownerIndexStart >= 0 && ownerIndexEnd < tokenBalanceOwner,
            "INDEX_OUT_OF_RANGE"
        );

        for (uint256 i = ownerIndexStart; i <= ownerIndexEnd; i++) {
            _claim(
                frogContract.tokenOfOwnerByIndex(_msgSender(), i),
                _msgSender()
            );
        }
    }

    function _claim(uint256 tokenId, address tokenOwner) internal {
        require(
            tokenId >= tokenIdStart && tokenId <= tokenIdEnd,
            "TOKEN_ID_OUT_OF_RANGE"
        );

        require(
            !ribbitClaimedByTokenId[tokenId],
            "RIBBIT_CLAIMED_FOR_TOKEN_ID"
        );

        ribbitClaimedByTokenId[tokenId] = true;

        _mint(tokenOwner, ribbitPerTokenId);
    }
}