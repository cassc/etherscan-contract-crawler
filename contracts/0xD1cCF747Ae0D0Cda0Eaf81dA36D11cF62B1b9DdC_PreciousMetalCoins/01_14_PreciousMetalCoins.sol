// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PreciousMetalCoins is ERC1155, ERC2981, Ownable, ERC1155Burnable, ERC1155Supply {
    mapping (uint256 => string) private _uris;
    mapping (uint256 => bool) private _frozen;
    
    constructor() ERC1155("")
    {
    	_setDefaultRoyalty(_msgSender(), 1000);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
    	require(! exists(id), "PreciousMetalCoins: token has already been minted");
        _mint(account, id, amount, data);
        _uris[id] = string(data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
    
    function uri(uint256 id)
        override
        public
        view
        returns (string memory)
    {
        return(_uris[id]);
    }

    function frozenURI(uint256 id)
        public
        view
        returns (bool)
    {
        return(_frozen[id]);
    }

	function setTokenURI(uint256 id, string memory newuri)
	    public
	    onlyOwner
	{
		require(exists(id), "PreciousMetalCoins: token does not exist");
		require(! frozenURI(id), "PreciousMetalCoins: uri is frozen");
		_uris[id] = newuri;    
        emit URI(_uris[id], id);
    }
    
    function freezeURI(uint256 id)
	    public
	    onlyOwner
	{
		require(exists(id), "PreciousMetalCoins: token does not exist");
		require(! frozenURI(id), "PreciousMetalCoins: uri is already frozen");
		_frozen[id] = true;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function setDefaultRoyalty(address receiver, uint96 amount)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, amount);
    }

    function clearDefaultRoyalty()
        public
        onlyOwner
    {
        _deleteDefaultRoyalty();
    }
    
    function setTokenRoyalty(uint256 id, address receiver, uint96 amount)
	    public
	    onlyOwner
	{
		require(exists(id), "PreciousMetalCoins: token does not exist");
		_setTokenRoyalty(id, receiver, amount);
    }

    function clearTokenRoyalty(uint256 id)
    	public
	    onlyOwner
	{
		require(exists(id), "PreciousMetalCoins: token does not exist");
		_resetTokenRoyalty(id);
    }
}