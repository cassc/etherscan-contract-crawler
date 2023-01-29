// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Kenchiro.
// Source code forked from Keisuke OHNO.

/*

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "contract-allow-list/contracts/ERC721AntiScam/ERC721AntiScam.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract NFT_Test is DefaultOperatorFilterer, ERC2981, ERC721AntiScam, AccessControl{

	address public withdrawAddress;
	string baseURI;
	string public baseExtension = ".json";
	uint256 public cost = 0.082 ether;  //★
	uint256 public maxSupply = 24182;    //★

	enum em_saleStage{
		Pause,		//0 : consruct paused
		PubSale,	//1 : Public Sale
		BMSale		//2 : BurnMint Sale
	}
	em_saleStage public saleStage = em_saleStage.Pause; //現在のセール内容
					
	uint256[] public saleImageID;					// 販売対象のImageID
	uint256 public saleAmount;						// 売り出す数
	uint256[] public imageIDarry = [0];		// TokenIDに対応するImageID

  bytes32 public constant SWITCHER_ROLE = keccak256("SWITCHER_ROLE");

	constructor() ERC721A('GPJMaskedCollection', 'GPJM') {
		//Role initialization
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_setupRole(DEFAULT_ADMIN_ROLE, 0x68B99B08f7d1FF4A3931A1804EFf5687A27087BD);
		setBaseURI("https://nft.gpjmaskedcollection.com/nft/data/json/");
		setWithdrawAddress(0x68B99B08f7d1FF4A3931A1804EFf5687A27087BD);
		//Royality initialization
		_setDefaultRoyalty(withdrawAddress, 1000);

		//CAL initialization
		_setCAL(0xdbaa28cBe70aF04EbFB166b1A3E8F8034e5B9FC7);//Ethereum mainnet proxy
		//_setCAL(0xb506d7BbE23576b8AAf22477cd9A7FDF08002211);//Goerli testnet proxy

	}

	// internal
	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	function publicSaleMint(uint256 _imageID)external payable{
		require(_imageID > 0, "imageID is 0.");
		require(saleStage == em_saleStage.PubSale, "the contract is not Sale");
		require(saleAmount > 0, "Sales quantity reached.");
		require(msg.value >= cost, "insufficient funds. : publicSaleMint");

		uint256 i;
		bool hitFlg = false;
		for(i = 0; i < saleImageID.length; i++){
			if(saleImageID[i] == _imageID){
				hitFlg = true;
				break;
			}
		}
		require(hitFlg != false, "Not sale imageID.");
		delete saleImageID[i];
		imageIDarry.push(_imageID);
		saleAmount--;
		
		_safeMint(msg.sender, 1);
	} 

	function airdropMint(address _airdropAddresses , uint256 _UserMintAmount, uint256[] calldata _imageIDs) public onlyRole(DEFAULT_ADMIN_ROLE){
		require(_UserMintAmount > 0, "need to mint at least 1 NFT");
		require(totalSupply() + _UserMintAmount <= maxSupply, "max NFT limit exceeded");
		require(_imageIDs.length == _UserMintAmount, "imageIDs array invalid.");

		_safeMint(_airdropAddresses, _UserMintAmount);
		for(uint256 i = 0; i < _imageIDs.length; i++){
			imageIDarry.push(_imageIDs[i]);
		}
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
		if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
		
		uint timeId = ((((block.timestamp / 3600) % 24) + 9) / 3) + 1;
		return string(abi.encodePacked(_baseURI(),_toString(imageIDarry[tokenId]), "/", _toString(timeId), baseExtension));
	}

	function getSaleImageID() public view returns(string memory){
		string memory returnValue;
		for(uint256 i = 0; i < saleImageID.length; i++){
			returnValue = string(abi.encodePacked(returnValue, _toString(saleImageID[i]) , ","));
		}
		return returnValue;
	}

	function setTokenImageID(uint256 _tokenID, uint256 _ImageID) public {
		require((hasRole(SWITCHER_ROLE, msg.sender)) || (hasRole(DEFAULT_ADMIN_ROLE, msg.sender)), "Caller is not qualified");
		imageIDarry[_tokenID] = _ImageID;
	}
	
	//only owner  
	function setCost(uint256 _newCost) public onlyRole(DEFAULT_ADMIN_ROLE) {
		cost = _newCost;
	}

	function setMaxSupply(uint256 _maxSupply) public onlyRole(DEFAULT_ADMIN_ROLE) {
		maxSupply = _maxSupply;
	}    

	function setBaseURI(string memory _newBaseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
		baseURI = _newBaseURI;
	}

	function setBaseExtension(string memory _newBaseExtension) public onlyRole(DEFAULT_ADMIN_ROLE) {
		baseExtension = _newBaseExtension;
	}

	function setSaleStage(em_saleStage _saleStage) public onlyRole(DEFAULT_ADMIN_ROLE) {
		saleStage = _saleStage;
	}

	function setWithdrawAddress(address _withdrawAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
		withdrawAddress = _withdrawAddress;
	}

	function setSaleImageID(uint256[] memory _saleImageID) public onlyRole(DEFAULT_ADMIN_ROLE){
		saleImageID = _saleImageID;
	}

	function getTokenImageID(uint256 _tokenID) view public onlyRole(DEFAULT_ADMIN_ROLE) returns(uint256){
		return imageIDarry[_tokenID];
	}
	
	function setSaleAmount(uint256 _saleAmount) public onlyRole(DEFAULT_ADMIN_ROLE){
		saleAmount = _saleAmount;
	}
	//Other
	function withdraw() public payable onlyRole(DEFAULT_ADMIN_ROLE) {
		require(withdrawAddress != address(0), "The payment address is 0.");
		(bool os, ) = payable(withdrawAddress).call{value: address(this).balance}("");
		require(os);
	}

	//ERC2981 Royalty Data.
	function setRoyaltyFee(uint96 _feeNumerator) public onlyRole(DEFAULT_ADMIN_ROLE) {
		_setDefaultRoyalty(withdrawAddress, _feeNumerator);
	}

	/*―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
		OVERRIDES operator-filter-registry
	―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――*/

	function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator){
		super.setApprovalForAll(operator, approved);
	}

	function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator){
		super.approve(operator, tokenId);
	}

	function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from){
		super.transferFrom(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from){
		super.safeTransferFrom(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from){
		super.safeTransferFrom(from, to, tokenId, data);
	}

	/*―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
		OVERRIDES ERC721Lockable
	―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――*/
	function setTokenLock(uint256[] calldata tokenIds, LockStatus lockStatus)external override{
		for (uint256 i = 0; i < tokenIds.length; i++) {
				require(msg.sender == ownerOf(tokenIds[i]), "not owner.");
		}
		_setTokenLock(tokenIds, lockStatus);
	}

	function setWalletLock(address to, LockStatus lockStatus)external override{
		require(to == msg.sender, "not yourself.");
		_setWalletLock(to, lockStatus);
	}

	function setContractLock(LockStatus lockStatus)external override onlyRole(DEFAULT_ADMIN_ROLE){
		_setContractLock(lockStatus);
	}

	/*―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
		OVERRIDES ERC721RestrictApprove
	―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――*/
	function addLocalContractAllowList(address transferer) external override onlyRole(DEFAULT_ADMIN_ROLE){
		_addLocalContractAllowList(transferer);
	}

	function removeLocalContractAllowList(address transferer) external override onlyRole(DEFAULT_ADMIN_ROLE){
		_removeLocalContractAllowList(transferer);
	}

	function setCALLevel(uint256 level) external override onlyRole(DEFAULT_ADMIN_ROLE){
		CALLevel = level;
	}

	function setCAL(address calAddress) external onlyRole(DEFAULT_ADMIN_ROLE){
		_setCAL(calAddress);
	}

	/*―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
		OVERRIDES ERC721AntiScam
	―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――*/
	//for ERC2981,ERC721AntiScam.AccessControl
	function supportsInterface(bytes4 interfaceId) public view override(ERC721AntiScam , AccessControl, ERC2981) returns (bool) {
		return(
				ERC721AntiScam.supportsInterface(interfaceId) || 
				AccessControl.supportsInterface(interfaceId) ||
				ERC2981.supportsInterface(interfaceId) ||
				super.supportsInterface(interfaceId)
		);
	}
	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}    
}