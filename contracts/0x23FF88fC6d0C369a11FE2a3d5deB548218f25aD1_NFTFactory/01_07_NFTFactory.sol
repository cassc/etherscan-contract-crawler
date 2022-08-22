// NFT Factory Contract
// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

interface IMintedTunesNFT {
	function initialize(string memory _name, string memory _uri, address creator, address _feeAddress, bool bPublic) external;
}

contract NFTFactory is OwnableUpgradeable {
    using SafeMath for uint256;

    address[] public collections;	
	address private nftImplementation;
	address public feeAddress;
    uint256 public createFee;
    uint256 private mintFee;
	
	/** Events */
    event CollectionCreated(address collection_address, address owner, string name, string uri, bool isPublic);

	function initialize(
		address _nftImplementation,
		address _feeAddress
	) public initializer {
        __Ownable_init();
        nftImplementation = _nftImplementation;
		feeAddress = _feeAddress;
        createFee = 0;
        mintFee = 1000000000000000; // 0.001 ETH
    }

	function updateNFTImplementation(address _nftImplementation)
        external
        onlyOwner
    {
        nftImplementation = _nftImplementation;
    }
    function viewNFTImplementation() external view returns (address) {
        return nftImplementation;
    }

	function setFeeAddress(address _feeAddress) external onlyOwner {		
        feeAddress = _feeAddress;		
    }

    function setCreateFee(uint256 _createFee) external onlyOwner {
       	createFee = _createFee;
    }

    function setMintFee(uint256 _mintFee) external onlyOwner {
       	mintFee = _mintFee;
    }
    function getMintFee() external view returns (uint256) {
        return mintFee;
    }

	function createCollection(string memory _name, string memory _uri, bool bPublic) external payable returns(address collection) {
        require(msg.value >= createFee, "insufficient fee");
        if (createFee > 0) {
            payable(feeAddress).transfer(createFee);
        }
		if(bPublic){
			require(owner() == msg.sender, "Only owner can create public collection");	
		}		
		collection = ClonesUpgradeable.clone(nftImplementation);

        IMintedTunesNFT(collection).initialize(_name, _uri, msg.sender, feeAddress, bPublic);
		collections.push(collection);		
		emit CollectionCreated(collection, msg.sender, _name, _uri, bPublic);
	}

    function withdrawBNB() external onlyOwner {
		uint balance = address(this).balance;
		require(balance > 0, "insufficient balance");
		payable(msg.sender).transfer(balance);
	}

	/**
     * @dev To receive ETH
     */
    receive() external payable {}
}