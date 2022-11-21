// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Address.sol';


contract Payable is ReentrancyGuard, Ownable {

    enum PaymentTypes {
        ERC721,
        ERC1155,
        ERC20,
        DEFAULT
    }

    event NewPayment(
        address from,
        address to,
        address currency,
        uint256[] ids,
        uint256[] amounts,
        PaymentTypes paymentType
    );

	function pay(
		address from,
        address to,
        address currency,
        uint256[] memory ids, // for batch transfers
        uint256[] memory amounts, // for batch transfers
        PaymentTypes paymentType
	) 
		public 
		payable 
		nonReentrant 
		onlyOwner 
	{

		if ( paymentType == PaymentTypes.ERC721 ) {

			IERC721(currency).safeTransferFrom(from, to, ids[0]);

		} else if ( paymentType == PaymentTypes.ERC1155 ) {

			IERC1155(currency).safeBatchTransferFrom(from, to, ids, amounts, "");

		} else if ( paymentType == PaymentTypes.ERC20 ) {

			if ( from != address(this) ) {
				require(IERC20(currency).transferFrom(from, to, amounts[0]));
			} else {
				require(IERC20(currency).transfer(to, amounts[0]));
			}

		} else if ( paymentType == PaymentTypes.DEFAULT ) {

			if ( Address.isContract(to) ) {
				(bool success, )= to.call{ value: amounts[0] }("");
				require(success);
			} else {
				require(payable(to).send(amounts[0]));
			}

		}

		emit NewPayment(
			from,
			to,
			currency,
			ids,
			amounts,
			paymentType
		);

	}

}