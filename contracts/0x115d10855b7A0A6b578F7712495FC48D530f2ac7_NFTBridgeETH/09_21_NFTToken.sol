// SPDX-License-Identifier: none

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import { AccessControlled, IAuthority } from ".././Authority.sol";
import { IProxyRegistry } from "./ProxyRegistry.sol";

interface INFTToken is IERC721Upgradeable {
	function mint(address to, uint256 tokenId) external;
	function burn(uint256 tokenId) external;
	function exists(uint256 tokenId) external view returns (bool);
}

contract NFTToken is ERC721EnumerableUpgradeable, ERC721BurnableUpgradeable, AccessControlled {	
	using StringsUpgradeable for uint256;

	IProxyRegistry public proxyRegistry;
			
	string public contractUri;
	string public baseUri;
		
	function initialize(
        string memory _name, 
		string memory _symbol,
		string memory _baseUri,
		address authority_
    ) public virtual initializer {
        __ERC721_init(_name, _symbol);
		__AccessControlled_init(IAuthority(authority_));		
		setBaseURI(_baseUri);		
    }

	function contractData() public view returns (
		string memory _name,
		string memory _symbol,
		string memory _contractUri,
		string memory _baseUri,		
		uint256 _totalSupply
	) {
		_name = name();
		_symbol = symbol();
		_contractUri = contractURI();
		_baseUri = baseURI();		
		_totalSupply = totalSupply();				
	}

	function accountData(address account) public view returns (
		uint256 _total,
		uint256[] memory _tokens		
	) {
		_total = balanceOf(account);
        if (_total != 0) {
            _tokens = new uint256[](_total);
            for (uint256 index = 0; index < _total; index++) {
                _tokens[index] = tokenOfOwnerByIndex(account, index);
            }
        }
	}

	function mint(address to, uint256 tokenId) public onlyNftMinter {
		_mint(to, tokenId);
	}
		
	function setContractURI(string memory uri) public onlyOperator {		
		contractUri = uri;
		emit SetContractURI(uri);
	}

	function contractURI() public view returns (string memory uri) {
		if (bytes(contractUri).length > 0) {
            uri = contractUri;
        }
		uri = baseUri;
	}

	function setBaseURI(string memory uri) public onlyOperator {
		baseUri = uri;
		emit SetBaseURI(uri);
	}

	function baseURI() public view returns (string memory) {
		return baseUri;
	}

	function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable) returns (string memory) {
		require(_exists(tokenId), "URI query for nonexistent token");		
		return string(abi.encodePacked(baseUri, tokenId.toString()));			
	}
		
	function setProxyRegistry(address _proxyRegistry) public onlyOperator {
		proxyRegistry = IProxyRegistry(_proxyRegistry);
		emit SetProxyRegistry(_proxyRegistry);
	}	

	function isApprovedForAll(address owner, address operator) public view virtual override(IERC721Upgradeable, ERC721Upgradeable) returns (bool) {
		// allow transfers for proxy contracts (marketplaces)
		if (address(proxyRegistry) != address(0) && proxyRegistry.proxies(owner) == operator) {
			return true;
		}	
		if (authority.nftMinters(operator)) {
			return true;
		}	
		return super.isApprovedForAll(owner, operator);
	}

	function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

	function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

	function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721EnumerableUpgradeable, ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
	
	event SetMinter(address minter, bool state);
	event SetProxyRegistry(address proxyRegistry);	
	event SetContractURI(string uri);
	event SetBaseURI(string uri);	
	
}