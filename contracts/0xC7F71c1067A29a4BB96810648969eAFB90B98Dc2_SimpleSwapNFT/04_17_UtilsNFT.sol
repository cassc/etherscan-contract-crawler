pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

library UtilsNFT {
    struct ToTokenNFTDetails {
        uint256 toToken;
        uint256 toTokenID;
        uint256 toAmount;
    }

    struct SimpleBuyNFTData {
        address fromToken;
        ToTokenNFTDetails[] toTokenDetails;
        uint256 fromAmount;
        uint256 expectedAmount;
        address[] callees;
        bytes exchangeData;
        uint256[] startIndexes;
        uint256[] values;
        address payable beneficiary;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    function transferTokens1155(
        address token,
        address payable destination,
        uint256 id,
        uint256 amount
    ) internal {
        IERC1155(token).safeTransferFrom(address(this), destination, id, amount, bytes(""));
    }

    function transferTokens721(
        address token,
        address payable destination,
        uint256 id
    ) internal {
        IERC721(token).safeTransferFrom(address(this), destination, id);
    }
}