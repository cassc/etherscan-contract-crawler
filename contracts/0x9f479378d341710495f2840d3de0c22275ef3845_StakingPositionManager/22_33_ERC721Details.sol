// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';

import "./IERC721Details.sol";

abstract contract ERC721Details is IERC721Details, ERC721 {
    using Strings for uint256;
    using Strings for address;

    uint256 private $sellerFee;
    address private $feeReceiver;
    ContractDetails private $details;

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721Details).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function contractURI() external view virtual override returns (string memory) {
        return _generateURI(details(), sellerFee(), feeReceiver());
    }

    function feeReceiver() public view virtual override returns (address) {
        return $feeReceiver;
    }

    function details() public view virtual override returns (ContractDetails memory) {
        return $details;
    }

    // 100 = 1%
    function sellerFee() public view virtual override returns (uint256) {
        return $sellerFee;
    }

    // 100 == 1%
    function _updateSellerFee(uint256 newSellerFee) internal virtual {
        require(newSellerFee < 1000, 'ERC721Details: MAX_SELL_FEE');
        emit SellerFeeUpdate($sellerFee, newSellerFee, _msgSender());
        $sellerFee = newSellerFee;
    }

    function _updateDetails(ContractDetails calldata newContractDetails) internal virtual {
        emit ContractDetailsUpdate($details, newContractDetails, _msgSender());
        $details = newContractDetails;
    }

    function _updateFeeReceiver(address newFeeReceiver) internal virtual {
        emit FeeReceiverUpdate($feeReceiver, newFeeReceiver, _msgSender());
        $feeReceiver = newFeeReceiver;
    }

    function _generateURI(
        ContractDetails memory details_,
        uint256 sellFee,
        address feeRecipient
    ) private pure returns (string memory uri) {
        bytes memory buffer = abi.encodePacked("{"
            '"name":"', details_.name, '",'
            '"description":"', details_.description, '",'
            '"image":"', details_.image, '",'
            '"external_link":"', details_.link, '",'
            '"seller_fee_basis_points":', sellFee.toString(), ','
            '"fee_recipient":"', feeRecipient.toHexString(), '"'
        "}");

        return string(abi.encodePacked(
            'data:application/json;base64,',
            Base64.encode(buffer)
        ));
    }
}