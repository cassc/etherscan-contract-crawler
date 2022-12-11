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

//import 'erc721a/contracts/ERC721A.sol';
//import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./ERC721AntiScam/ERC721AntiScam.sol";
//import "contract-allow-list/contracts/ERC721AntiScam/ERC721AntiScam.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract IGUQUEST_COLLECTION is DefaultOperatorFilterer, ERC2981, ERC721AntiScam, AccessControl{

	address public withdrawAddress;
	string baseURI;
	string public baseExtension = ".json";
	uint256 public pub_cost = 0.005 ether;  //★
	uint256 public maxSupply = 2000;    //★
	bool public revealed = false;
	string public notRevealedUri;

	enum em_saleStage{
		Pause,		//0 : consruct paused
		WLSale,		//1 : WL Sale
		PubSale,	//2 : Public Sale
		BMSale		//3 : BurnMint Sale
	}
	em_saleStage public saleStage = em_saleStage.Pause; //現在のセール内容
					
	uint256 public maxPubSaleMintAmount = 1;
	mapping(address => uint256) public publicMintedAmount;

	uint8 public wlSaleCount = 0;               //1回目のセールが0
	struct WLSaleInfo{
		bytes32 WLMearkleRoot;										//wlSaleCountに応じたMearkleRoot
		mapping(address => uint8) WLMintedAmount;	//アドレスに対してwlSaleCountに応じたmint枚数を格納
	}
	WLSaleInfo[] public fmWlSaleData;
	WLSaleInfo[] public wlSaleData;

	uint256 public maxBmSupply = 500;  //★BMで何体出すか
	uint256 public totalBmSupply = 0;  //BMで何体出たか

	constructor() ERC721A('IGUQUEST COLLECTION', 'IGU') {
		//Role initialization
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

		setNotRevealedURI("http://igunft.heteml.net/nft/data/veal/reveal_gif.gif");
		setBaseURI("http://igunft.heteml.net/nft/data/json/");
		setWithdrawAddress(0xC877DF9fB131Df3a7AD13C370A081528A99A9384);

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

	// public
	function mint(uint256 _mintAmount) public payable {
		uint256 supply = totalSupply();
		require(_mintAmount > 0, "need to mint at least 1 NFT");
		require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

		// Owner also can mint.
		if (msg.sender != owner()) {
			require(saleStage == em_saleStage.PubSale, "the contract is not Public Sale");
			require(_mintAmount <= maxPubSaleMintAmount, "max mint amount per session exceeded");
			require(publicMintedAmount[msg.sender] + _mintAmount <= maxPubSaleMintAmount, "max NFT per mint amount exceeded");
			require(msg.value >= pub_cost * _mintAmount, "insufficient funds");
			publicMintedAmount[msg.sender] += _mintAmount;
		}
		_safeMint(msg.sender, _mintAmount);
	}

	function wl_mint(uint8 _mintAmount, uint8 _wlMaxMintAmount, uint8 _mintCost, bytes32[] calldata _merkleProof, bool _bFreemint) public payable {
		uint256 supply = totalSupply();
		uint256 cost = 1000000000000000 * _mintCost;
		require(_mintAmount > 0, "need to mint at least 1 NFT");
		require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
		
		if (msg.sender != owner()) {
			require(saleStage == em_saleStage.WLSale, "the contract is not WL Sale");
			require(_mintAmount <= _wlMaxMintAmount, "max mint amount per session exceeded");
			require(isWhitelisted(msg.sender, _wlMaxMintAmount, _mintCost, _merkleProof, _bFreemint), "You don't have WL.");
			require(msg.value >= cost * _mintAmount, "insufficient funds. : Wl mint");
			if(_bFreemint){
				require(fmWlSaleData[wlSaleCount].WLMintedAmount[msg.sender] + _mintAmount <= _wlMaxMintAmount, "max NFT per address exceeded");	
				fmWlSaleData[wlSaleCount].WLMintedAmount[msg.sender] += _mintAmount;
			}else{
				require(wlSaleData[wlSaleCount].WLMintedAmount[msg.sender] + _mintAmount <= _wlMaxMintAmount, "max NFT per address exceeded");
				wlSaleData[wlSaleCount].WLMintedAmount[msg.sender] += _mintAmount;
			}
		}
		_safeMint(msg.sender, _mintAmount);
	}

	function burnMint(uint256[] memory _burnTokenIds, uint8 _wlMaxMintAmount, uint8 _mintCost, bytes32[] calldata _merkleProof, bool _bFreemint) external payable {
		uint256 cost = 1000000000000000 * _mintCost;
		require(_burnTokenIds.length > 0, "need to burn-mint at least 1 NFT");
		require(totalBmSupply + _burnTokenIds.length <= maxBmSupply, "Max Burn mint Supply over!");

		if (msg.sender != owner()) {
			require(saleStage == em_saleStage.BMSale, "the contract is not BurnMint Sale");
			require(_burnTokenIds.length <= _wlMaxMintAmount, "max burn mint amount per session exceeded");
			require(isWhitelisted(msg.sender, _wlMaxMintAmount, _mintCost, _merkleProof, _bFreemint), "You don't have BMWL.");
			require(msg.value >= cost * _burnTokenIds.length, "insufficient funds. : BM");
			if(_bFreemint){
				require(fmWlSaleData[wlSaleCount].WLMintedAmount[msg.sender] + _burnTokenIds.length <= _wlMaxMintAmount, "max BM per address exceeded.");
				fmWlSaleData[wlSaleCount].WLMintedAmount[msg.sender] += (uint8)(_burnTokenIds.length);
			}else{
				require(wlSaleData[wlSaleCount].WLMintedAmount[msg.sender] + _burnTokenIds.length <= _wlMaxMintAmount, "max BM per address exceeded.");
				wlSaleData[wlSaleCount].WLMintedAmount[msg.sender] += (uint8)(_burnTokenIds.length);
			}
		}
		for(uint256 i = 0; i < _burnTokenIds.length; i++) {
			uint256 tokenId = _burnTokenIds[i];
			require(_msgSender() == ownerOf(tokenId), "you are not owner.");
			totalBmSupply++;
			_burn(tokenId);
		}
		_safeMint(msg.sender, _burnTokenIds.length);
	}

	function airdropMint(address[] calldata _airdropAddresses , uint256[] memory _UserMintAmount) public onlyRole(DEFAULT_ADMIN_ROLE){
		uint256 supply = totalSupply();
		uint256 totalmintAmount = 0;
		for (uint256 i = 0; i < _UserMintAmount.length; i++) {
			totalmintAmount += _UserMintAmount[i];
		}
		require(totalmintAmount > 0, "need to mint at least 1 NFT");
		require(supply + totalmintAmount <= maxSupply, "max NFT limit exceeded");

		for (uint256 i = 0; i < _UserMintAmount.length; i++) {
			_safeMint(_airdropAddresses[i], _UserMintAmount[i] );
		}
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
		if(revealed == false) {
			return notRevealedUri;
		}else{
			return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
		}
	}

	function isWhitelisted(address _user, uint8 _wlMaxMintAmount, uint8 _mintCost, bytes32[] calldata _merkleProof, bool _bFreemint) public view returns (bool) {
		bytes32 leaf = keccak256(abi.encodePacked(_user, _wlMaxMintAmount, _mintCost));
		if(_bFreemint){
			return MerkleProof.verify(_merkleProof, fmWlSaleData[wlSaleCount].WLMearkleRoot, leaf);			
		}else{
			return MerkleProof.verify(_merkleProof, wlSaleData[wlSaleCount].WLMearkleRoot, leaf);
		}
	}

	function getWLMintedAmount(address _user, uint8 _wlSaleCount, bool _bFreemint)public view returns(uint8){
		if(_bFreemint){
			require(_wlSaleCount < fmWlSaleData.length, "FM WL Sale count over!");
			return fmWlSaleData[_wlSaleCount].WLMintedAmount[_user];
		}else{
			require(_wlSaleCount < wlSaleData.length, "WL Sale count over!");
			return wlSaleData[_wlSaleCount].WLMintedAmount[_user];
		}

	}

	function getWLMearkleRoot(uint8 _wlSaleCount, bool _bFreemint)public view returns(bytes32){
		if(_bFreemint){
			require(_wlSaleCount < fmWlSaleData.length, "FM WL Sale count over!");
			return fmWlSaleData[_wlSaleCount].WLMearkleRoot;
		}else{
			require(_wlSaleCount < wlSaleData.length, "WL Sale count over!");
			return wlSaleData[_wlSaleCount].WLMearkleRoot;
		}
	}
	//only owner  
	function reveal() public onlyRole(DEFAULT_ADMIN_ROLE) {
		revealed = true;
	}

	function setPubCost(uint256 _newCost) public onlyRole(DEFAULT_ADMIN_ROLE) {
		pub_cost = _newCost;
	}

	function setMaxSupply(uint256 _maxSupply) public onlyRole(DEFAULT_ADMIN_ROLE) {
		maxSupply = _maxSupply;
	}    

	function setmaxPubSaleMintAmount(uint256 _newmaxPubSaleMintAmount) public onlyRole(DEFAULT_ADMIN_ROLE) {
		maxPubSaleMintAmount = _newmaxPubSaleMintAmount;
	}

	function setNotRevealedURI(string memory _notRevealedURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
		notRevealedUri = _notRevealedURI;
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

	//WL
	function setWLMearkleRoot(uint256 _wlSaleCount, bytes32 _wlMearkleRoot, bool _bFreemint) public onlyRole(DEFAULT_ADMIN_ROLE){
		if(_bFreemint){
			require(_wlSaleCount < fmWlSaleData.length, "FM WL Sale count over!");
			fmWlSaleData[_wlSaleCount].WLMearkleRoot = _wlMearkleRoot;
		}else{
			require(_wlSaleCount < wlSaleData.length, "WL Sale count over!");
			wlSaleData[_wlSaleCount].WLMearkleRoot = _wlMearkleRoot;
		}
	}

	function setWlSaleCount(uint8 _wlSaleCount) public onlyRole(DEFAULT_ADMIN_ROLE){
		require(_wlSaleCount < wlSaleData.length, "WL Sale count over!");
		wlSaleCount = _wlSaleCount;
	}

	function addNewWLSale() public onlyRole(DEFAULT_ADMIN_ROLE) returns (uint){
		wlSaleData.push();
		fmWlSaleData.push();
		return wlSaleData.length;
	}

	function wlSaleDataLength() view public returns (uint){
		return wlSaleData.length;
	}

	//Burn-Mint
	function setMaxBmSupply(uint256 _maxBmSupply) public onlyRole(DEFAULT_ADMIN_ROLE) {
		maxBmSupply = _maxBmSupply;
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