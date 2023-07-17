// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

//
//
//
//
//            .                         ,(/..,,##,,             %% ,%&%%
//           &%%%%#.                  /,,,,,((*....**            %%%%%%
//           %%&%%%#                #%&&&&&#(((%&%&&%%%,        %&%&.
//              %&&&%%,          %%%&%@@@@@@@@@@@@&@&&%%%#   .%%%%%
//                 &&%%&*      %%%%%&&%&%%%%%%%%%%%%%%%%%%* %%%%%
//                   #%%&%/    %%&&%%&&&&&&&%&&%&%%%%%%&&%%%%%%
//                     %&&%%%,   /&%%&%%%&&&%&%%%%%%&&&%%%%&%
//                        %&%&&&%%%&%%%%%%%&&%%%&%&%%&&&%%%
//                          %%%&%&&&&&%&&&&%&&&&%&%%%&&&%%
//                            %&&&&%&%%%%%&%%%%%%%%%%%%%%%
//
//
//     DRP + Pellar 2022
//     Drop 3 - VR002


contract DRPToken is ERC721Enumerable, Ownable {
	struct TokenInfo {
		uint8 claimed;
		uint8 MAX_SALE_SUPPLY;
		uint8 MAX_SUPPLY;
		uint8 PADDING;
		uint8 PRE_TOKENS;
	}

	TokenInfo[4] public tokens;
	ERC721Lushsux public Lushsux_io = ERC721Lushsux(0x0b15727723690295a7981F12CF49b706A3EB555F);
	address public burnerWallet = 0x39A715308a23e04Efe5D23c3000A141fE2ad02aE;
	uint256 public constant MINT_PRICE = 0.001 ether;
	string public parentURI = 'ipfs://bafybeigpzjkmdwupr5icxqkxxdwegav3t7som2mq4uzsqmhbxb2cof73wi';
	bool public salesActive;

	mapping(address => bool)[3] public whitelists;

	constructor () ERC721("DRPToken", "DRP") {
		tokens[0] = TokenInfo(0, 50, 60, 0, 1);
		tokens[1] = TokenInfo(0, 25, 30, 60, 5);
		tokens[2] = TokenInfo(0, 10, 12, 90, 10);
		tokens[3] = TokenInfo(0, 50, 60, 102, 0);
	}

	function getTokenId(uint8 _tokenNo) internal pure returns(uint8) {
		return _tokenNo - 1;
	}

	// convert tokenId to token number
	function getTokenNoFromId(uint8 tokenId) external view returns (uint8) {
		require(_exists(tokenId));
		if (tokenId < (tokens[0].MAX_SUPPLY + tokens[0].PADDING)) { // token 1
			return 1;
		}
		else if (tokenId < (tokens[1].MAX_SUPPLY + tokens[1].PADDING)) { // token 2
			return 2;
		}
		else if (tokenId < (tokens[2].MAX_SUPPLY + tokens[2].PADDING)) { // token 3
			return 3;
		}
		else { // token 4
			return 4;
		}

	}

	// check for token 4
	function getToken4Supply() external view returns (uint8) {
		return tokens[3].claimed;
	}

	function setTokenWhitelist(uint8 _tokenId, address[] calldata _addresses, bool _state) external onlyOwner {
		uint8 tokenId = getTokenId(_tokenId);
		require(tokenId <= 3, "Invalid token");
		for (uint16 i = 0; i < _addresses.length; i++) {
			whitelists[tokenId][_addresses[i]] = _state;
		}
	}

	function toggleSalesActive() external onlyOwner {
		salesActive = !salesActive;
	}

	// 0.001 ETH
	function mintToken(uint8 _tokenNo) external payable {
		uint8 tokenId = getTokenId(_tokenNo);
		require(salesActive, "Claim is not active");
    require(tx.origin == msg.sender, "Claim cannot be made from a contract");
		require(tokens[tokenId].claimed < tokens[tokenId].MAX_SALE_SUPPLY, "Claim: Sorry we have sold out");
		require(whitelists[tokenId][msg.sender], "Claim: Not whitelisted");
		require(Lushsux_io.balanceOf(msg.sender) >= tokens[tokenId].PRE_TOKENS, "Claim: Must own eligible Lushsux.io tokens");
		require(msg.value >= MINT_PRICE, "Claim: Ether value incorrect");

		_safeMint(msg.sender, tokens[tokenId].PADDING + tokens[tokenId].claimed);
		tokens[tokenId].claimed++;
		whitelists[tokenId][msg.sender] = false;
	}

	// have to pre-approve on the minting page first before using (free)
	function mintToken4(uint16 burnToken1, uint16 burnToken2, uint16 burnToken3) external payable {
		uint8 tokenId = getTokenId(4);
		require(salesActive, "Claim is not active");
    require(tx.origin == msg.sender, "Claim cannot be made from a contract");
		require(tokens[tokenId].claimed < tokens[tokenId].MAX_SALE_SUPPLY, "Claim: Sorry we have sold out");
		require(Lushsux_io.ownerOf(burnToken1) == msg.sender
						&& Lushsux_io.ownerOf(burnToken2) == msg.sender
						&& Lushsux_io.ownerOf(burnToken3) == msg.sender, "You do not own token");
		Lushsux_io.safeTransferFrom(msg.sender, burnerWallet, burnToken1);
		Lushsux_io.safeTransferFrom(msg.sender, burnerWallet, burnToken2);
		Lushsux_io.safeTransferFrom(msg.sender, burnerWallet, burnToken3);

		_safeMint(msg.sender, tokens[tokenId].PADDING + tokens[tokenId].claimed);
		tokens[tokenId].claimed++;
	}

	function teamClaim() external onlyOwner {
		for (uint8 i = 0; i < tokens.length; i++) {
			TokenInfo memory token = tokens[i];
			for (uint8 j = token.MAX_SALE_SUPPLY; j < token.MAX_SUPPLY; j++) {
				_safeMint(msg.sender, token.PADDING + j);
			}
		}
	}

	function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
		require(_exists(_tokenId), "URI query for non existent token");

		if (_tokenId < (tokens[0].MAX_SUPPLY + tokens[0].PADDING)) { // token 1
			return string(abi.encodePacked(parentURI, "/1"));
		}
		else if (_tokenId < (tokens[1].MAX_SUPPLY + tokens[1].PADDING)) { // token 2
			return string(abi.encodePacked(parentURI, "/2"));
		}
		else if (_tokenId < (tokens[2].MAX_SUPPLY + tokens[2].PADDING)) { // token 3
			return string(abi.encodePacked(parentURI, "/3"));
		}
		else { // token 4
			return string(abi.encodePacked(parentURI, "/4"));
		}
	}

	function setTokenURI(string calldata _newURI) external onlyOwner {
		parentURI = _newURI;
	}

	function withdraw() public onlyOwner {
		uint balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}
}

interface ERC721Lushsux {
	function balanceOf(address) external view returns (uint256);
	function ownerOf(uint256) external view returns (address);
	function safeTransferFrom(address, address, uint256) external;
	function getApproved(uint256 tokenId) external view returns (address);
}