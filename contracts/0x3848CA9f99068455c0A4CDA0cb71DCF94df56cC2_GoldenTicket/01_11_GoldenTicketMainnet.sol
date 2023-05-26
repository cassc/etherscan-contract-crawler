pragma solidity ^0.8.2;

import "ERC1155.sol";
import "Ownable.sol";
import "IERC1155Burnable.sol";

contract GoldenTicket is ERC1155(""), Ownable {

	address constant public PREDICATE = 0x2d641867411650cd05dB93B59964536b1ED5b1B7;
	mapping(uint256 => string) public uris;
	mapping(address => bool) public authorisedCallers;

	modifier authorised() {
		require(authorisedCallers[msg.sender] || msg.sender == owner(), "KongArmory: Not authorised caller");
		_;
	}

	function uri(uint256 _id) public override view returns (string memory) {
		if (bytes(uris[_id]).length == 0)
			return string(abi.encodePacked(_uri, toString(_id)));
        return uris[_id];
    }

	function setCaller(address _caller, bool _value) external onlyOwner {
		authorisedCallers[_caller] = _value;
	}

	function updateBaseUri(string memory _uri_) external authorised {
		_uri = _uri_;
	}

	function setUri(uint256 _id, string memory _uri_) external authorised {
		uris[_id] = _uri_;
	}

	function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external {
		require(msg.sender == PREDICATE);
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external {
		require(msg.sender == PREDICATE);
        _mintBatch(to, ids, amounts, data);
    }


	function burnFor(address _user, uint256 _tokenId, uint256 _amount) external {
		require(isApprovedForAll(_user, msg.sender));
		_burn(_user, _tokenId, _amount);
	}

	function toString(uint256 value) internal pure returns (string memory) {
		// Inspired by OraclizeAPI's implementation - MIT licence
		// https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

		if (value == 0) {
			return "0";
		}
		uint256 temp = value;
		uint256 digits;
		while (temp != 0) {
			digits++;
			temp /= 10;
		}
		bytes memory buffer = new bytes(digits);
		uint256 index = digits - 1;
		temp = value;
		while (temp != 0) {
			buffer[index--] = bytes1(uint8(48 + temp % 10));
			temp /= 10;
		}
		return string(buffer);
	}
}