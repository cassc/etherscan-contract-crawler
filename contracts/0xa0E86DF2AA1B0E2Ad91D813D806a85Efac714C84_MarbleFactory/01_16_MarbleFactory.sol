// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "MirariMarbleCollection.sol";

contract MarbleFactory is Ownable {
	
	function deployMainCollection() public onlyOwner returns (address) {
		MirariMarbleCollection collection = new MirariMarbleCollection("Mirari Marble", "MM");
		collection.mintNewMarble(
			msg.sender,
			"https://arweave.net/8avbVHlVIp5iS2pbCvDFhIZiSRPJnA4rt0YWINU0Jvo/MirariMarbleOG00.json"
		);
		collection.mintNewMarble(
			msg.sender,
			"https://arweave.net/8avbVHlVIp5iS2pbCvDFhIZiSRPJnA4rt0YWINU0Jvo/MirariMarbleOG01.json"
		);
		collection.mintNewMarble(
			msg.sender,
			"https://arweave.net/8avbVHlVIp5iS2pbCvDFhIZiSRPJnA4rt0YWINU0Jvo/MirariMarbleOG02.json"
		);
		collection.mintNewMarble(
			msg.sender,
			"https://arweave.net/8avbVHlVIp5iS2pbCvDFhIZiSRPJnA4rt0YWINU0Jvo/MirariMarbleOG03.json"
		);
		collection.mintNewMarble(
			msg.sender,
			"https://arweave.net/8avbVHlVIp5iS2pbCvDFhIZiSRPJnA4rt0YWINU0Jvo/MirariMarbleOG04.json"
		);
		collection.mintNewMarble(
			msg.sender,
			"https://arweave.net/8avbVHlVIp5iS2pbCvDFhIZiSRPJnA4rt0YWINU0Jvo/MirariMarbleOG05.json"
		);
		collection.mintNewMarble(
			msg.sender,
			"https://arweave.net/8avbVHlVIp5iS2pbCvDFhIZiSRPJnA4rt0YWINU0Jvo/MirariMarbleOG06.json"
		);
		collection.mintNewMarble(
			msg.sender,
			"https://arweave.net/8avbVHlVIp5iS2pbCvDFhIZiSRPJnA4rt0YWINU0Jvo/MirariMarbleOG07.json"
		);
		collection.mintNewMarble(
			msg.sender,
			"https://arweave.net/8avbVHlVIp5iS2pbCvDFhIZiSRPJnA4rt0YWINU0Jvo/MirariMarbleOG08.json"
		);
		collection.mintNewMarble(
			msg.sender,
			"https://arweave.net/8avbVHlVIp5iS2pbCvDFhIZiSRPJnA4rt0YWINU0Jvo/MirariMarbleOG09.json"
		);
		collection.transferOwnership(msg.sender);
		return address(collection);
	}

	function deployExtraCollection(string memory name, string memory symbol) 
		public 
		onlyOwner 
		returns (address) 
	{
		MirariMarbleCollection collection = new MirariMarbleCollection(name, symbol);
		collection.transferOwnership(msg.sender);
		return address(collection);
	}

}