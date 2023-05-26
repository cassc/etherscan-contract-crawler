// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/finance/PaymentSplitter.sol';

interface IERC721 {
	function ownerOf(uint256 tokenId) external view returns (address owner);
}

/*

OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
OOOO                                                                        OOOO
OOOO   OOOOO                                                        OOOOO   OOOO
OOOO  OOOO                                                            OOOO  OOOO
OOOO  OOOO                                                            OOOO  OOOO
OOOO  OOOOOOO                                                      OOOOOOO  OOOO
OOOO  OOOOOOOOOOOOOOOOOOOO                            OOOOOOOOOOOOOOOOOOOO  OOOO
OOOO  OOOOOOOOOOOOOOOOOOOOOOOOO                  OOOOOOOOOOOOOOOOOOOOOOOOO  OOOO
OOOO  OOOOOOOOOOOOOOOOOOOOOOOOOOO              OOOOOOOOOOOOOOOOOOOOOOOOOOO  OOOO
OOOO  OOOOOOOOOOOOOOOOOOOOOOOOOOOO            OOOOOOOOOOOOOOOOOOOOOOOOOOOO  OOOO
OOOO  OOOOOOOOOOOOOOOOOOOOOOOOOOOOO          OOOOOOOOOOOOOOOOOOOOOOOOOOOOO  OOOO
BBBB  BBBBBBBBBBB BBBBB   BBBBBBBBBB        BBBBBBBBBB   BBBBB BBBBBBBBBBB  BBBB
BBBB  BBBBBBBBBB         BBBBBBBBBBB        BBBBBBBBBBB        BBBBBBBBBBB  BBBB
BBBB  BBBBBBBBBBBBB BBBBBBBBBBBBBBBB        BBBBBBBBBBBBBBBB BBBBBBBBBBBBB  BBBB
BBBB  BBBBBBBBBB      BBBBBB   BBBBB        BBBBB   BBBBBB      BBBBBBBBBB  BBBB
BBBB      BBBBB      BBBBB    BBBBB          BBBBB    BBBBB      BBBBB      BBBB
BBBB              BBBBBB     BBBBB            BBBBB     BBBBBB              BBBB
BBBB                       BBBBBB              BBBBBB                       BBBB
BBBB                     BBBBBB                  BBBBBB                     BBBB
BBBB                    BBBBB                      BBBBB                    BBBB
BBBB                   BBBBB  BBBBBBB      BBBBBBB  BBBBB                   BBBB
BBBB                    BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB                    BBBB
BBBB                      BBBBBBB     BBBB     BBBBBBB                      BBBB
EEEE                                                                        EEEE
EEEE                EEEE                               EEEEE                EEEE
EEEE               EEEEEE                              EEEEEE               EEEE
EEEE              EEEEEEE                              EEEEEEE              EEEE
EEEE            EEEEE            EEE        EEE            EEEEE            EEEE
EEEE            EE          EEEEEEEEEEEEEEEEEEEEEEEE          EE            EEEE
EEEE                   EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE                   EEEE
EEEE                  EEEEEEEE       EEEEEE       EEEEEEEE                  EEEE
EEEE  EE                EEEEEEEE                EEEEEEEE                EE  EEEE
EEEE  EE                    EEEEEEEEE      EEEEEEEE                     EE  EEEE
EEEE  EEE                         EEEEEEEEEEEE                         EEE  EEEE
EEEE  EEEE                           EEEEEE                           EEEE  EEEE
YYYY                                                                        YYYY
YYYY            YY                                            YY            YYYY
YYYY            YYYYY                                      YYYYY            YYYY
YYYY  YYY        YYYYYYYY                              YYYYYYYY        YYY  YYYY
YYYY  YYYYY       YYYYYYYY                            YYYYYYYY       YYYYY  YYYY
YYYY  YYYYYYYY   YYYYYYYYYY                          YYYYYYYYYY   YYYYYYYY  YYYY
YYYY  YYYYYYYYYYYYYYYYYYYYYYYYY                  YYYYYYYYYYYYYYYYYYYYYYYYY  YYYY
YYYY   YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY   YYYY
YYYY                                                                        YYYY
YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY

 */
contract ArtNotWar is ERC1155, PaymentSplitter {
	string public constant name = 'Obey Make Art Not War Ukraine';
	string public constant symbol = 'MANWU';
	uint256 public constant MAX_SUPPLY = 8900;
	uint256 public constant MAX_FREE_CLAIM = 7400;
	uint256 public constant CLAIM_START = 1646672400;
	uint256 public constant PUBLIC_START = 1646758800;
	uint256 public constant PRICE = 0.05 ether;
	IERC721 private constant OBEYDG = IERC721(0x7828c811636CCf051993C1EC3157b0B732e55B23); // ObeyDG contract address
	uint256 public _totalSupply;
	mapping(uint256 => bool) private usedTokens;

	constructor(address[] memory _payees, uint256[] memory _shares)
		ERC1155('ipfs://QmVWTiQBASgy4zjL9cNdwLPBfQcTC9h8ZVLJmWdb8m5o34')
		PaymentSplitter(_payees, _shares)
	{
		// Mint for OBEY
		_totalSupply += 100;
		_mint(0xcA31e53AA808fe22Bf0A0100D6b2fe5e12250CaC, 1, 100, '');
	}

	function freeClaim(uint256 claimTokenId) public {
		require(_totalSupply + 1 <= MAX_FREE_CLAIM, 'All free tokens claimed');
		require(CLAIM_START <= block.timestamp, "Free claim hasn't started yet");
		require(PUBLIC_START > block.timestamp, 'Free claim is over');
		address owner = OBEYDG.ownerOf(claimTokenId);
		require(msg.sender == owner, 'You do not own this NFT');
		require(usedTokens[claimTokenId] == false, 'token already claimed');
		usedTokens[claimTokenId] = true;
		_totalSupply++;
		_mint(msg.sender, 1, 1, '');
	}

	function mint() public payable {
		require(_totalSupply + 1 <= MAX_SUPPLY, 'All tokens have been minted');
		require(PUBLIC_START < block.timestamp, "Sale hasn't started");
		require(msg.value == PRICE, 'Incorrect Payment');
		_totalSupply++;
		_mint(msg.sender, 1, 1, '');
	}

	function tokenURI(uint256 tokenId) public view returns (string memory) {
		require(exists(tokenId), 'Token does not exist');
		return uri(tokenId);
	}

	function totalSupply(uint256 tokenId) public view returns (uint256) {
		require(exists(tokenId), 'Token does not exist');
		return _totalSupply;
	}

	function withdraw(address payable account) external virtual {
		release(account);
	}

	function withdrawERC20(IERC20 token, address account) external virtual {
		release(token, account);
	}

	function exists(uint256 id) public pure returns (bool) {
		return id == 1;
	}
}