pragma solidity ^0.8.2;

import "Ownable.sol";
import "ERC721.sol";
import "IERC721.sol";

contract GenesisBadge is ERC721("NFTBox","[BADGE]"), Ownable {

	uint256 public constant MAX = 500;
	address public constant BOX_NFT = 0x6d4530149e5B4483d2F7E60449C02570531A0751;

	uint256 counter;

	function airdrop(uint256 _amount) external onlyOwner {
		uint256 _counter = counter;
		_amount = _amount > (MAX - _counter) ? (MAX - _counter) : _amount;
		for (uint i = 0; i < _amount; i++) {
			uint256 actualToken = (_counter + i) * 10 + 8;
			address owner = IERC721(BOX_NFT).ownerOf(actualToken);
			_mint(owner ,_counter + i + 1);
		}
		counter += _amount;
	}

	function tokenURI(uint256 _tokenId) public view override returns(string memory) {
		return string(
			abi.encodePacked(
				bytes('data:application/json;utf8,{"name":"'),
				_getName(_tokenId),
				bytes('","description":"'),
				"A new Genesis Badge for a new era.",
				bytes('","external_url":"'),
				_getExternalUrl(),
				bytes('","image":"'),
				_getImageCache(),bytes('"}')
			)
		);
	}

	function _getName(uint256 _tokenId) internal view returns(string memory) {
		return string(abi.encodePacked("Genesis Badge 2.0 #", _uint2str(_tokenId)));
	}

	function _getExternalUrl() internal view returns(string memory) {
		return string(abi.encodePacked("https://www.nftboxes.io/"));
	}

	function _getImageCache() internal view returns(string memory) {
		return string(abi.encodePacked("https://g5an5qiqoiypmd544fk6vmzaikjr43bpelndy332xwcbxoru.arweave.net/N0D_ewRByMP-YPvO-FV6rMgQpMebC8i2jxver2EG7o0"));
	}

	function _uint2str(uint _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint j = _i;
		uint len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint k = len;
		while (_i != 0) {
			k = k-1;
			uint8 temp = (48 + uint8(_i - _i / 10 * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}
}