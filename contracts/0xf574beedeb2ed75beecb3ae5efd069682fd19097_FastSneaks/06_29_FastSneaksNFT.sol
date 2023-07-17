// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

import '../common/ERC721Tradable.sol';

contract FastSneaksNFT is ERC721Tradable, ERC721Burnable, ERC721Pausable, DefaultOperatorFilterer {
	uint public currentTokenId = 0;

	mapping(address => bool) public operators;
	
	string internal _baseTokenURI;

	constructor(
		address _proxyRegistryAddress,
		string memory _name,
		string memory _symbol,
		string memory __baseTokenURI,
		address[] memory _operators
	) ERC721Tradable(_name, _symbol, _proxyRegistryAddress)
	{
		_baseTokenURI = __baseTokenURI;

		for(uint i = 0; i < _operators.length; i++) {
			operators[_operators[i]] = true;
		}
	}

    /*
     * @dev function to update base URI for NFT marketplaces
     * @param __baseURI The new base URI 
     */
    function updateBaseURI(string memory __baseURI) public onlyOwner {
    	_baseTokenURI = __baseURI;
    }
    
    /*
     * @dev set operator status
     * @param _operatorAddress The address to which the changes will be applied 
     * @param _status Enabled or disabled (true/false)
     */
	function updateOperator(address _operatorAddress, bool _status) public onlyOwner {
		operators[_operatorAddress] = _status;
	}
    
    

    function pause () public {
        require(operators[msg.sender], "only operators");
        _pause();
    }

    function unpause () public {
        require(operators[msg.sender], "only operators");
        _unpause();
    }
    
   
	function baseTokenURI() public view override returns(string memory) {
        return _baseTokenURI;
	}

	function _baseURI() internal view override returns(string memory) {
        return _baseTokenURI;
    }

	/**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override (Context, ERC721Tradable)
        view
        returns (address sender)
    {
        return ERC721Tradable._msgSender();
    }

	function isApprovedForAll(address owner, address operator)
        override (ERC721Tradable, ERC721)
        public
        view
        returns (bool)
    {
        return super.isApprovedForAll(owner, operator);
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 _tokenId) 
        override (ERC721, ERC721Tradable)
        public 
        view 
        returns (string memory) 
    {
        return super.tokenURI(_tokenId);
    }

     function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

    }

    // DefaultOperatorFilterer

    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}