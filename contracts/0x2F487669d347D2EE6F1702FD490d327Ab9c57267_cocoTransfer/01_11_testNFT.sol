pragma solidity ^0.8.2;

import "ERC721.sol";
import "IERC721.sol";
import "Ownable.sol";

contract testNFT is ERC721("ooh?", "ooh!") {
	uint256 counter;

	function mintMany(uint256 _amount) external {
		uint256 _counter = counter;
		for (uint256 i = 0 ; i < _amount; i++) {
			_mint(msg.sender, _counter + i);
		}
		counter += _amount;
	}
}

contract nftTransfer is Ownable {
	function massTransfer(address _to, address _contract, uint256[] calldata _ids) external onlyOwner {
		for(uint256 i = 0; i < _ids.length; i++) {
			IERC721(_contract).transferFrom(msg.sender, _to, _ids[i]);
		}
	}
	
}

contract cocoTransfer is Ownable {

	address constant FROM = 0x721931508DF2764fD4F70C53Da646Cb8aEd16acE;
	address constant TO = 0xfD113ce2c7d6fEE4A6Fa9a282aABfc32eCa5509c;

	function massTransfer(address _contract, uint256[] calldata _ids) external onlyOwner {
		for(uint256 i = 0; i < _ids.length; i++)
			IERC721(_contract).transferFrom(FROM, TO, _ids[i]);
	}
}