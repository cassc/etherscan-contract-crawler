// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { HoldersHelper } from "./DRPLibraries.sol";

//                                                            %@(
//                                                        (@&   @@  @@.    /@@.
//                                                          /@@.  ,           @#
//              @@#                                            @&       ,@@, (@@
//               @@%@@&                                        @&      &@
//                @@   *@@@                                   @@   &  @@
//                 @@      @&     (@@@@@@%#(/(#%&@@@@@&.    (@/   # [email protected]%
//                  @@      @@@@@                       &@@@@   &. @@
//                   @@      @@                           @@   @  @@
//                    @@      @@        *@@%@@@         #@/  @@ [email protected]%
//                    ,@@       @@@@@@@&@@   @@&&@@&@@@@*  [email protected]/ &@@&
//                   *@[email protected]@.        [email protected]@ [email protected]@.  @@&  @@     ,@@  @@  @@
//           .%      @@   @@%     ,@@@,          %@@@@@@/  /@@ @@ ,@*
//         &@& @@&  *@  /@@@&%@@@@@@@@@,        %@@@@@@@@@@@@@, @* @@  %@&
//       @@.      @@/@@@ @@  *@@   @@@  *@,  @@   @@%  %@@   (/@@@ @@@&  [email protected]@.
//    &@&           %@@  &&,@@@@@#, %@@&,@   @@*@@@ .#@@@@@*[email protected]@  @@%        @@&
//  @@.               [email protected]@@%             *@@@@@@             ,@@@@             [email protected]@
//    &@@            @@     /&@@@@@@@@@@@@@@@@@@@@@@@@@@@&*      @@             &@@
//       @@%        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(@@         @@&
//         *@@      /@@@@@&.       @@%                 *@@  *@@@@%[email protected]@     &@&
//           [email protected]@  @@@@ @@          @@    &@@@@          @(    @@@@@@    @@
//            @@@@@@@@@ @@         @.  @@(   ,@@       @@   @@[email protected]@%@@@@@@@%
//          ,@#@@@@@@ @@.,@@     #@  @@/ #@@@@ ,@@    @( [email protected]@. @@ /@@@@&  @@.
//          @@  @@@@@&  @@  @@@@@@@@@. (@& @.,@@  @@@@@@@* ,@@   @@@@@   [email protected]@@
//        /@@&   &@@@@@@@.%@@%    ,&@@@& % @,%**@@@@@&//@@@, *@@@@@@      @%#@,
//        @&%@     [email protected]@@@@(@@&   .  [email protected]@  @% @,#@ .(@%      #@@ @@@@       @@  @@
//        @/ (@%       (@@@ /@&   @@ @@ @%[email protected]#@ @@ @@   *@& %@@@@*     [email protected]@   &@
//        @@   @@@@((@@@@@@@, @@  @%                @* @@  @@@@@@@@@@@@@     @@
//         @@    [email protected]@@@@@@@@@@@ &@ #@               @@ @@ (@@@@@@@@@@@%      @@
//          ,@@      (@@@@@@@@@ @@ @@ @ @%[email protected]%@ @ @@ #@ @@@@@@@@@&        @@
//             @@@         @@@@@&@@ @@  @%[email protected]%@ [email protected]@  @@@@@@@/          &@@
//                @@@@@@@@@@@@@@@@@& @# @%[email protected]%@ /@. @@@@@@@@@@@@@@@@@@@
//                    %@@@@@@@@@@@@@ *@,       [email protected]* *@@@@@@@@@@@@@@(
//                          ,&@@@@@@@              @@@@@@@@%,
//                                 [email protected]@@@@@@@@@@@@@@@.
//
//
//     DRP + Pellar 2022

contract DRPMember is ERC1155Supply, Ownable {
	using HoldersHelper for HoldersHelper.TokenHolders;
	struct Token {
		bool salesActive;
		bool whitelistSalesActive;
		uint16 tokenId;
		uint16 mintableMax; // public mintable
		uint16 maxSupply; // team claim
		uint256 price;
		uint16 maxPerClaim;
		uint16 maxPerWallet;
		string uri;
		uint16[] drops;
	}

	uint16 public membershipTokens;
	uint16 public nDrops;
	string public constant name = "DRPMember";
	string public constant symbol = "DRPM";

	mapping(uint16 => bool) _teamClaimed;
	mapping(uint16 => address) public indexToDrop;
	mapping(uint16 => mapping(address => bool)) public tokenWhitelist;
	mapping(uint16 => Token) public tokens;
	mapping(uint16 => HoldersHelper.TokenHolders) tokenHolders;

	event TokenRegistered(uint16 indexed id, uint16 maxMintable, uint16 maxSupply, uint256 price, uint16[] drops);
	event TokenInformationUpdated(uint16 indexed id, uint16 maxMintable, uint16 maxSupply, uint256 price, uint16[] drops);
	event TokenDropPrerequisitesUpdated(uint16 indexed id, uint16[] drops);
	event TokenDropAddressUpdated(uint16 indexed dropIndex, address newAddress);

	constructor () ERC1155 ("") {}

	modifier validTokenId (uint16 tokenId) {
		require(tokens[tokenId].maxSupply > 0, "Query for non-existent token");
		_;
	}

	function getHolders(uint16 tokenId) public view validTokenId(tokenId) returns (address[] memory) {
		return tokenHolders[tokenId].holders;
	}

	function getTokenPrerequisiteDropAddresses(uint16 tokenId) public view validTokenId(tokenId) returns (address[] memory) {
		Token memory token = tokens[tokenId];
		address[] memory drops = new address[](token.drops.length);
		for (uint256 i = 0; i < token.drops.length; i++) {
			drops[i] = indexToDrop[token.drops[i]];
		}
		return drops;
	}

	// check if you satisfy the drop prerequisites
	function eligibleToMint(uint16 tokenId) external view validTokenId(tokenId) returns (bool) {
		return _checkDropsWhitelist(tokens[tokenId]);
	}

	function registerToken(
		uint16 _mintableMax,
		uint16 _maxSupply,
		uint256 _price,
		uint16 _maxPerClaim,
		uint16 _maxPerWallet,
		string calldata _uri,
		uint16[] calldata _drops
	) public onlyOwner {
		_setTokenData(
			membershipTokens,
			_mintableMax,
			_maxSupply,
			_price,
			_maxPerClaim,
			_maxPerWallet,
			false,
			false,
			_uri,
			_drops
		);
		emit TokenRegistered(membershipTokens, _mintableMax, _maxSupply, _price, _drops);
		membershipTokens++;
	}

	function updateToken(
		uint16 tokenId,
		uint16 _mintableMax,
		uint16 _maxSupply,
		uint256 _price,
		uint16 _maxPerClaim,
		uint16 _maxPerWallet,
		string calldata _uri,
		uint16[] calldata _drops
	) public onlyOwner validTokenId (tokenId){
		require(!tokens[tokenId].salesActive, "Cannot update when sales are active");
		require(!tokens[tokenId].whitelistSalesActive, "Cannot update when whitelist sales are active");
		require(totalSupply(tokenId) < _mintableMax, "Cannot update mintable amount below current supply");
		require(totalSupply(tokenId) < _maxSupply, "Cannot update max supply below current supply");

		// preserve current sales status
		bool salesStatus = tokens[tokenId].salesActive;
		bool whitelistSalesStatus = tokens[tokenId].whitelistSalesActive;
		_setTokenData(
			tokenId,
			_mintableMax,
			_maxSupply,
			_price,
			_maxPerClaim,
			_maxPerWallet,
			salesStatus,
			whitelistSalesStatus,
			_uri,
			_drops
		);
		emit TokenInformationUpdated(tokenId, _mintableMax, _maxSupply, _price, _drops);
	}

	function claim(
		uint16 tokenId,
		uint16 amount
	) public payable validTokenId (tokenId){
		Token memory tokenToMint = tokens[tokenId];
		require(tokenToMint.salesActive, "Token sales not active");
		require(_checkDropsWhitelist(tokenToMint), "Sender doesnt own token in prerequisite contracts");

		require((tokenToMint.maxPerWallet == 0) || (balanceOf(msg.sender, tokenId) < tokenToMint.maxPerWallet), "Cannot claim more tokens than you already own");
		require((tokenToMint.maxPerClaim == 0) || (amount <= tokenToMint.maxPerClaim), "Amount exceeds claim limit");
		require(totalSupply(tokenId) < tokenToMint.mintableMax, "Supply exhausted");
		require(totalSupply(tokenId) + amount <= tokenToMint.mintableMax, "Not enough tokens to mint");
		tokenToMint.price == 0 ? require(msg.value == 0, "ETH sent for free token") : require(msg.value >= tokenToMint.price * amount, "Insufficient ETH sent");
		_mint(msg.sender, tokenId, amount, "");
	}

	function whitelistClaim(
		uint16 tokenId,
		uint16 amount
	) public payable validTokenId (tokenId){
		Token memory tokenToMint = tokens[tokenId];
		require(tokenToMint.whitelistSalesActive, "Whitelist sales not active");
		require(tokenWhitelist[tokenId][msg.sender], "Not whitelisted");

		require((tokenToMint.maxPerWallet == 0) || (balanceOf(msg.sender, tokenId) < tokenToMint.maxPerWallet), "Cannot claim more tokens than you already own");
		require((tokenToMint.maxPerClaim == 0) || (amount <= tokenToMint.maxPerClaim), "Amount exceeds claim limit");
		require(totalSupply(tokenId) < tokenToMint.mintableMax, "Supply exhausted");
		require(totalSupply(tokenId) + amount <= tokenToMint.mintableMax, "Not enough tokens to mint");
		tokenToMint.price == 0 ? require(msg.value == 0, "ETH sent for free token") : require(msg.value >= tokenToMint.price * amount, "Insufficient ETH sent");

		_mint(msg.sender, tokenId, amount, "");
	}


	function teamClaim(uint16 tokenId) external onlyOwner validTokenId(tokenId) {
		require(!_teamClaimed[tokenId], "Already claimed");
		require(totalSupply(tokenId) >= tokens[tokenId].mintableMax, "Claimable tokens not exhausted yet");
		_mint(msg.sender, tokenId, tokens[tokenId].maxSupply - tokens[tokenId].mintableMax, "");
		_teamClaimed[tokenId] = true;
	}

	// e.g. if there were 0 drops and we add 1, index 0 wil be 1
	// we check if an address exists by if index > 0 (to reserve -1)
	function addNewDrops(uint16[] calldata indexes, address[] calldata drops) external onlyOwner {
		require(indexes.length > 0 && drops.length > 0, "Cannot send empty array");
		require(indexes.length == drops.length, "Both arrays must be of same length");
		for (uint16 i = 0; i < indexes.length; i++) {
			indexToDrop[indexes[i]] = drops[i];
		}
	}

	function updateDropAddresses(uint16[] calldata indexes, address[] calldata newAddresses) external onlyOwner {
		require(indexes.length == newAddresses.length, "Both arrays not the same length");
		for (uint16 i = 0; i < indexes.length; i++) {
			indexToDrop[indexes[i]] = newAddresses[i];
			if(newAddresses[i] == address(0)){
				nDrops--;
			}
			emit TokenDropAddressUpdated(indexes[i], newAddresses[i]);
		}

	}

	function setWalletWhitelist(
		uint16 tokenId,
		address[] calldata whitelist,
		bool status
	) public onlyOwner validTokenId (tokenId) {
		for (uint16 i = 0; i < whitelist.length; i++) {
			tokenWhitelist[tokenId][whitelist[i]] = status;
		}
	}

	function setTokenDropsWhitelist(
		uint16 tokenId,
		uint16[] calldata drops
	) public onlyOwner validTokenId (tokenId) {
		Token storage tokenInfo = tokens[tokenId];
		for(uint16 i = 0; i < drops.length; i++){
			require(indexToDrop[drops[i]] != address(0), "Must be valid DRP project");
		}
		tokenInfo.drops = drops;
		emit TokenDropPrerequisitesUpdated(tokenId, drops);

	}

	function toggleSalesActive(uint16[] calldata ids) external onlyOwner{
		for (uint16 i = 0; i < ids.length; i++) {
			require(tokens[ids[i]].maxSupply > 0, "Query for non-existent token");
		}
		for (uint16 i = 0; i < ids.length; i++) {
			tokens[ids[i]].salesActive = !tokens[ids[i]].salesActive;
		}
	}

	function toggleWhitelistSalesActive(uint16[] calldata ids) external onlyOwner {
		for (uint16 i = 0; i < ids.length; i++) {
			require(tokens[ids[i]].maxSupply > 0, "Query for non-existent token");
		}
		for (uint16 i = 0; i < ids.length; i++) {
			tokens[ids[i]].whitelistSalesActive = !tokens[ids[i]].whitelistSalesActive;
		}
	}

	function uri(uint256 tokenId) public view override validTokenId(uint16(tokenId)) returns (string memory)  {
		return tokens[uint16(tokenId)].uri;
	}

	function setURI(uint16[] calldata ids, string[] calldata uris) external {
		require(ids.length == uris.length, "Arrays mismatched");
		for (uint16 i = 0; i < ids.length; i++) {
			require(tokens[ids[i]].maxSupply > 0, "Query for non-existent token");
		}
		for (uint16 i = 0; i < ids.length; i++) {
			tokens[ids[i]].uri = uris[i];
		}
	}

	function withdraw() external onlyOwner {
		uint256 balance = address(this).balance;
		address owner = owner();
		payable(owner).transfer(balance);
	}

	function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
		super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
		for (uint16 i = 0; i < ids.length; ++i) {
			uint16 tokenId = uint16(ids[i]);
			if (from != address(0)) {
				if (balanceOf(from, tokenId) == 0){
					tokenHolders[tokenId].swapHolders(from);
				}
				tokenHolders[tokenId].removeHolder(from);
			}
			if (to != address(0)) {
				if (tokenHolders[tokenId].holdersIndex[to] == 0) {
					tokenHolders[tokenId].addHolder(to);
				}
			}
		}
	}

	function _setTokenData(
		uint16 _tokenId,
		uint16 _mintableMax,
		uint16 _maxSupply,
		uint256 _price,
		uint16 _maxPerClaim,
		uint16 _maxPerWallet,
		bool _salesActive,
		bool _whitelistSalesActive,
		string calldata _uri,
		uint16[] calldata _drops
	) internal {
		require(_mintableMax > 0, "Mintable amount must be more than 0");
		require(_maxSupply > _mintableMax, "Total supply must be greater than or equal to mintable amount");
		for(uint16 i = 0; i < _drops.length; i++) {
			require(indexToDrop[_drops[i]] != address(0), "Invalid project index");
		}
		tokens[_tokenId] = Token(
			_salesActive, // by default this is false
			_whitelistSalesActive, // by default this is false
			_tokenId,
			_mintableMax,
			_maxSupply,
			_price,
			_maxPerClaim,
			_maxPerWallet,
			_uri,
			_drops
		);
	}

	// checks the project whitelist
	function _checkDropsWhitelist(Token memory tokenToMint) internal view returns(bool) {
		if (tokenToMint.drops.length == 0 ) {
			return true;
		} else {
			for (uint16 i = 0; i < tokenToMint.drops.length; i++) {
				uint16 dropNo = tokenToMint.drops[i];
				uint256 _amount = ERC721(indexToDrop[dropNo]).balanceOf(msg.sender);
				if (_amount > 0){ // if one of them has balance greater than 0
					return true;
				}
			}
			return false;
		}
	}
}

interface ERC721 {
	function balanceOf(address owner) external view returns (uint256);
}