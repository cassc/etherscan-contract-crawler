import '../royalties/ERC2981.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../royalties/IRoyaltyEngineV1.sol';
pragma solidity ^0.8.0;

/**
 * @dev royalty Token Validation functions
 *
 
 */
library royalties {
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    using SafeERC20 for IERC20;

    function checkRoyalties(ERC2981 _contract) internal view returns (bool) {
        try _contract.supportsInterface(_INTERFACE_ID_ERC2981) returns (bool result) {
            return result;
        } catch {
            return false;
        }
    }

    function getRoyalty(
        ERC2981 tokenContract,
        uint256 tokenID,
        uint256 price
    ) internal returns (address, uint256) {
        try tokenContract.royaltyInfo(tokenID, price) returns (address receiver, uint256 royalty) {
            return (receiver, royalty);
        } catch {
            return (address(0), 0);
        }
    }

    function royaltyTransfer(
        address nft,
        address feeToken,
        uint256 price,
        uint256 tokenID
    ) internal returns (uint256 royalty) {
        (address recipient, uint256 _royalty) = getRoyalty(ERC2981(nft), tokenID, price);

        if (_royalty > 0 && recipient != address(0)) {
            IERC20(feeToken).safeTransfer(recipient, _royalty);
        }

        return _royalty;
    }

    function royaltyTransferFrom(
        address nft,
        address feeToken,
        address buyer,
        uint256 price,
        uint256 tokenID
    ) internal returns (uint256 royalty, bool success) {
        (address recipient, uint256 _royalty) = getRoyalty(ERC2981(nft), tokenID, price);

        if (_royalty > 0 && recipient != address(0)) {
            IERC20(feeToken).safeTransferFrom(buyer, recipient, _royalty);
            success = true;
        }

        return (_royalty, success);
    }

    struct registryInput {
        uint256 price;
        uint256 tokenID;
        address feeToken;
        address royaltyRegistry;
        address buyer;
    }

    function royaltyTransferFromRegistry(address nft, registryInput memory input)
        internal
        returns (uint256 royalty, bool success)
    {
        return
            queryRoyaltyEngine(
                nft,
                input.royaltyRegistry,
                input.feeToken,
                input.buyer,
                input.tokenID,
                input.price
            );
    }

    function queryRoyaltyEngine(
        address nft,
        address royaltyRegistry,
        address feeToken,
        address buyer,
        uint256 tokenID,
        uint256 price
    ) internal returns (uint256, bool) {
        uint256 royaltySum;
        (address payable[] memory recipients, uint256[] memory amounts) = IRoyaltyEngineV1(
            royaltyRegistry
        ).getRoyalty(nft, tokenID, price);
        for (uint256 i = 0; i < recipients.length; i++) {
            IERC20(feeToken).safeTransferFrom(buyer, recipients[i], amounts[i]);

            royaltySum += amounts[i];
        }

        return (royaltySum, true);
    }
}