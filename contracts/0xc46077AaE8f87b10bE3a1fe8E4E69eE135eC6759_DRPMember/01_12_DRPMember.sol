// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { TokenHolder } from "./DRPLibraries.sol";

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
//     DRP + Pellar 2022
//     DRP Member Token

contract DRPMember is ERC1155Supply, Ownable {
	using TokenHolder for TokenHolder.Holders;

	struct TokenConfig {
		uint16 MAX_SUPPLY;
		uint16 MAX_PUBLIC_SALE;
		uint16 MAX_PER_WALLET;
		uint16 MAX_PER_TXN;
		uint256 PRICE;
	}

	struct Token {
		bool salesActive;
		bool whitelistSalesActive;
		bool teamClaimed;

		TokenConfig config;

		address[] drops;
		string uri;
	}

	uint16 public nDrops;
	string public constant name = "DRPMember";
  string public constant symbol = "DRPM";

	mapping(uint16 => bool) public enableTrading;
	mapping(uint16 => mapping(address => uint16)) public tokenWhitelist;
	mapping(uint16 => Token) public tokens;
	mapping(uint16 => TokenHolder.Holders) holders;

	constructor () ERC1155 ("") {}

	/** User */
	function claim(uint16 _tokenId, uint16 _amount) public payable {
		Token memory token = tokens[_tokenId];
		TokenConfig memory config = token.config;
		uint256 balance = IERC1155(0xb09e99F8bFc11f6C311E7d63EFc42F26c51017A6).balanceOf(msg.sender, _tokenId);
		require(token.salesActive, "Not active");
		require(eligibleToMint(_tokenId), "Need prerequisite token");
		require(config.MAX_PER_WALLET == 0 || balance + balanceOf(msg.sender, _tokenId) + _amount <= config.MAX_PER_WALLET, "Exceed wallet");
		require(config.MAX_PER_TXN == 0 || _amount <= config.MAX_PER_TXN, "Exceed txn");
		require(totalSupply(_tokenId) + _amount <= config.MAX_PUBLIC_SALE, "Exceed max");
		require(msg.value >= config.PRICE * _amount, "Incorrect ETH value");
		_mint(msg.sender, _tokenId, _amount, "");
	}

	function whitelistClaim(uint16 _tokenId, uint16 _amount) public payable {
		Token memory token = tokens[_tokenId];
		TokenConfig memory config = token.config;
		uint256 balance = IERC1155(0xb09e99F8bFc11f6C311E7d63EFc42F26c51017A6).balanceOf(msg.sender, _tokenId);
		require(token.whitelistSalesActive, "Not active");
		require(tokenWhitelist[_tokenId][msg.sender] >= _amount, "Exceed allocated");
		require(config.MAX_PER_WALLET == 0 || balance + balanceOf(msg.sender, _tokenId) + _amount <= config.MAX_PER_WALLET, "Exceed wallet");
		require(config.MAX_PER_TXN == 0 || _amount <= config.MAX_PER_TXN, "Exceed txn");
		require(totalSupply(_tokenId) + _amount <= config.MAX_PUBLIC_SALE, "Exceed max");
		require(msg.value >= config.PRICE * _amount, "Incorrect ETH value");

		tokenWhitelist[_tokenId][msg.sender] -= _amount;
		_mint(msg.sender, _tokenId, _amount, "");
	}

	/** View */
  function getHoldersLength(uint16 _tokenId) public view returns (uint256) {
    return holders[_tokenId].accounts.length;
  }

  function getHolders(uint16 _tokenId, uint256 _start, uint256 _end) public view returns (address[] memory, uint256[] memory) {
    uint256 maxSize = getHoldersLength(_tokenId);
    _end = _end > maxSize ? maxSize : _end;

    uint256 size = _end - _start;
    address[] memory accounts = new address[](size);
    uint256[] memory balances = new uint256[](size);
    for (uint256 i = 0; i < size; i++) {
      address holder = holders[_tokenId].accounts[_start + i];
      accounts[i] = holder;
      balances[i] = balanceOf(holder, _tokenId);
    }
    return (accounts, balances);
  }

	function getTokenPrerequisiteDropAddresses(uint16 _tokenId) public view returns (address[] memory) {
		Token memory token = tokens[_tokenId];
		return token.drops;
	}

	function eligibleToMint(uint16 _tokenId) public view returns (bool) {
		Token memory token = tokens[_tokenId];
		address[] memory drops = token.drops;
		if (drops.length == 0) {
			return true;
		}
		for (uint256 i = 0; i < drops.length; i++) {
			uint256 _amount = ERC721(drops[i]).balanceOf(msg.sender);
			if (_amount > 0) {
				return true;
			}
		}
		return false;
	}

	function uri(uint256 _tokenId) public view override returns (string memory)  {
		require(exists(_tokenId), "Non exists token");
		return tokens[uint16(_tokenId)].uri;
	}

	/** Admin */
	function setToken(
		uint16 _tokenId,
		uint16 _maxSupply,
		uint16 _maxPublicSale,
		uint16 _maxPerWallet,
		uint16 _maxPerClaim,
		uint256 _price
	) public onlyOwner {
		TokenConfig storage config = tokens[_tokenId].config;
		config.MAX_SUPPLY = _maxSupply;
		config.MAX_PUBLIC_SALE = _maxPublicSale;
		config.MAX_PER_WALLET = _maxPerWallet;
		config.MAX_PER_TXN = _maxPerClaim;
		config.PRICE = _price;
	}

	function toggleSalesActive(uint16[] calldata _tokenIds, bool _status) external onlyOwner{
		for (uint16 i = 0; i < _tokenIds.length; i++) {
			require(tokens[_tokenIds[i]].config.MAX_SUPPLY > 0, "Non exists config");
		}
		for (uint16 i = 0; i < _tokenIds.length; i++) {
			tokens[_tokenIds[i]].salesActive = _status;
		}
	}

	function toggleWhitelistSalesActive(uint16[] calldata _tokenIds, bool _status) external onlyOwner {
		for (uint16 i = 0; i < _tokenIds.length; i++) {
			require(tokens[_tokenIds[i]].config.MAX_SUPPLY > 0, "Non exists config");
		}
		for (uint16 i = 0; i < _tokenIds.length; i++) {
			tokens[_tokenIds[i]].whitelistSalesActive = _status;
		}
	}

	function toggleTrading(uint16[] calldata _tokenIds, bool _status) external onlyOwner {
		for (uint256 i = 0; i < _tokenIds.length; i++) {
			enableTrading[_tokenIds[i]] = _status;
		}
	}

	function setWalletWhitelist(uint16 _tokenId, address[] calldata _whitelist, uint16[] calldata _amount) external onlyOwner {
		for (uint16 i = 0; i < _whitelist.length; i++) {
			tokenWhitelist[_tokenId][_whitelist[i]] = _amount[i];
		}
	}

	function addDrops(uint16 _tokenId, address[] calldata drops) external onlyOwner {
		for (uint16 i = 0; i < drops.length; i++) {
			tokens[_tokenId].drops.push(drops[i]);
		}
	}

	function setDrops(
		uint16 tokenId, 
		address[] calldata drops
	) external onlyOwner {
		Token storage token = tokens[tokenId];
		token.drops = drops;
	}

	function teamClaim(uint16 _tokenId) external onlyOwner {
		Token storage token = tokens[_tokenId];
		require(!token.teamClaimed, "Already claimed");
		_mint(msg.sender, _tokenId, token.config.MAX_SUPPLY - token.config.MAX_PUBLIC_SALE, "");
		token.teamClaimed = true;
	}

	function setURI(uint16[] calldata _tokenIds, string[] calldata _uri) external onlyOwner {
		require(_tokenIds.length == _uri.length, "Input mismatch");
		for (uint16 i = 0; i < _tokenIds.length; i++) {
			require(tokens[_tokenIds[i]].config.MAX_SUPPLY > 0, "Non exists config");
		}
		for (uint16 i = 0; i < _tokenIds.length; i++) {
			tokens[_tokenIds[i]].uri = _uri[i];
		}
	}

	function withdraw() external onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
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
			require(from == address(0) || enableTrading[tokenId], "Token paused");
			if (amounts[i] == 0) continue;

      if (from != address(0) && balanceOf(from, tokenId) == amounts[i]) {
        holders[tokenId].removeHolder(from);
      }

      if (to != address(0)) {
        holders[tokenId].addHolder(to);
      }
		}
	}
}

interface ERC721 {
	function balanceOf(address owner) external view returns (uint256);
}