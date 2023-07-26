// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./@rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "./@rarible/royalties/contracts/LibPart.sol";
import "./@rarible/royalties/contracts/LibRoyaltiesV2.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //
//  ██████╗  ██████╗  ██████╗ ██████╗     ██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ █████╗     ████████╗ ██████╗ ██╗  ██╗███████╗███╗   ██╗  //
// ██╔════╝ ██╔═══██╗██╔═══██╗██╔══██╗    ██║ ██╔╝██╔══██╗██╔══██╗████╗ ████║██╔══██╗    ╚══██╔══╝██╔═══██╗██║ ██╔╝██╔════╝████╗  ██║  //
// ██║  ███╗██║   ██║██║   ██║██║  ██║    █████╔╝ ███████║██████╔╝██╔████╔██║███████║       ██║   ██║   ██║█████╔╝ █████╗  ██╔██╗ ██║  //
// ██║   ██║██║   ██║██║   ██║██║  ██║    ██╔═██╗ ██╔══██║██╔══██╗██║╚██╔╝██║██╔══██║       ██║   ██║   ██║██╔═██╗ ██╔══╝  ██║╚██╗██║  //
// ╚██████╔╝╚██████╔╝╚██████╔╝██████╔╝    ██║  ██╗██║  ██║██║  ██║██║ ╚═╝ ██║██║  ██║       ██║   ╚██████╔╝██║  ██╗███████╗██║ ╚████║  //
//  ╚═════╝  ╚═════╝  ╚═════╝ ╚═════╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝       ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝  //
// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //

contract GoodKarmaToken is ERC1155, RoyaltiesV2Impl, Ownable, ReentrancyGuard {
	using Strings for uint256;
	using Address for address;
	uint8 public constant GoodKarmaTokenID = 0; // default is zero
	uint96 public constant royaltyBasisPoints = 9900;
	bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
	uint256 public MAX_SUPPLY = 2347;
	string public tokenUri = "ipfs://QmZhUoNHxkaJNaUtiMNtSSxxEG9Sj2vEXAFJ6mRso6h58D";
	string public name = "Good Karma Token";
	address private VandalzContract;

	constructor() ERC1155(tokenUri) {
		_mint(msg.sender, GoodKarmaTokenID, MAX_SUPPLY, "");
		_setRoyalties(payable(msg.sender));
	}

	function uri(uint256) public view override returns (string memory) {
		return tokenUri;
	}

	function setTokenUri(string memory _newUri) external onlyOwner {
		tokenUri = _newUri;
	}

	function mintEmergencySupply(uint256 _numNewTokens) external onlyOwner {
		MAX_SUPPLY += _numNewTokens;
		_mint(msg.sender, GoodKarmaTokenID, _numNewTokens, "");
	}

	function withdraw() external onlyOwner {
		uint256 _balance = address(this).balance;
		require(_balance > 0, "No amount to withdraw");
		Address.sendValue(payable(owner()),_balance);
	}

	function setVandalzContract(address _vandalzAddress) external onlyOwner {
		require(address(_vandalzAddress) != address(0) && _vandalzAddress.isContract(), "Invalid Address");
		VandalzContract = _vandalzAddress;
	}

	function burnTokenForVandal(address holderAddress) external {
		require(msg.sender == VandalzContract, "Invalid Burn Caller");
		_burn(holderAddress, GoodKarmaTokenID, 1);
	}

	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
		if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
			return true;
		}
		if (interfaceId == _INTERFACE_ID_ERC2981) {
			return true;
		}
		return super.supportsInterface(interfaceId);
	}

	// Adding 99% royalty on sales via Rariable and 2981;
	function _setRoyalties(address payable _royaltyRecipient) internal nonReentrant {
		LibPart.Part[] memory _royalties = new LibPart.Part[](1);
		_royalties[0].value = royaltyBasisPoints;
		_royalties[0].account = _royaltyRecipient;
		_saveRoyalties(GoodKarmaTokenID, _royalties);
	}

	function royaltyInfo(uint256 id, uint256 _salePrice)
		public
		view
		virtual
		override(RoyaltiesV2Impl)
		returns (address receiver, uint256 royaltyAmount)
	{
		if (id != GoodKarmaTokenID) {
			// if the tokenID checked is invalid return a 0 royalty
			return (address(owner()), 0);
		}

		return super.royaltyInfo(id, _salePrice);
	}
}