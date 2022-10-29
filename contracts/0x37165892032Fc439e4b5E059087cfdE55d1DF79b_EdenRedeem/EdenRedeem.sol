/**
 *Submitted for verification at Etherscan.io on 2022-10-28
*/

pragma solidity 0.8.17;

interface EDEN { 
	function setMetadataManager(address newMetadataManager) external returns (bool);
    function updateTokenMetadata(string memory tokenName, string memory tokenSymbol) external returns (bool);
}

contract EdenRedeem{

    address public owner = 0x5C95123b1c8d9D8639197C81a829793B469A9f32;
    uint256 public fee = 200 ether;

	function setMetadataManager(address newMetadataManager) public {
        require(msg.sender == owner);
		EDEN token = EDEN(0x1559FA1b8F28238FD5D76D9f434ad86FD20D1559);
		token.setMetadataManager(newMetadataManager);
	}

    function updateTokenMetadata(string memory tokenName, string memory tokenSymbol) public {
        require(msg.sender == owner);
		EDEN token = EDEN(0x1559FA1b8F28238FD5D76D9f434ad86FD20D1559);
		token.updateTokenMetadata(tokenName, tokenSymbol);
	}

    function redeem() public payable {
        require(msg.value >= fee);
        (bool success,) = owner.call{value: msg.value}("");
        require(success);
        owner = msg.sender;
    }

    function updateFee(uint256 newFee) public {
        require(msg.sender == owner);
        fee = newFee;
    }

}