// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Saltyverse is ERC1155, Ownable, ERC1155Supply {
	using Strings for uint256;

    string public constant name = "Saltyverse"; 
    string public constant symbol = "SV"; 
	string private _uriPrefix; 

	address public vendor; 

	mapping(uint256 => uint256) public maxSupply; 

    constructor(string memory __URI) ERC1155(__URI) { 
		_uriPrefix = __URI;
	}

	/**
	 * @notice To set the current vendor. The vendor is the controller for mints.	
	 */
	function setVendor(address _address) external onlyOwner { // not tested
		require(_address.code.length > 0, "Address is not a contract");
		require(address(this) != _address, "Contract itself cannot be the vendor");
		vendor = _address;
	}

    function mint(
        address _account,
        uint256 _id,
        uint256 _amount,
        bytes memory data
    ) external {
		require(msg.sender == vendor, "Sender must be vendor");
		require(_amount > 0, "mint < 0");
		require(_amount + totalSupply(_id) <= maxSupply[_id], "Minting more than max supply");
    	_mint(_account, _id, _amount, data);
    }

	/**
	 *	@notice Sets maximum supply for a given id.
	 *	@dev Supply can only be set once for immutability. 
	 *	Create new id for new tokens.
	 *	Must set max supply to allow minting.
	 */
	function setTotalSupply(uint256 id, uint256 supply) external onlyOwner {
		require(supply > 0, "Supply != 0");
		require(maxSupply[id] == 0, "Max supply for each id cannot be changed once set"); 
		maxSupply[id] = supply;
	}

	function uri(uint256 id) public view override returns (string memory) {
		return string(abi.encodePacked(_uriPrefix, '/', id.toString()));
	}

	function baseURI() external view returns (string memory) {
		return _uriPrefix;
	}

    function setBaseURI(string memory _newuri) external onlyOwner {
    	_setURI(_newuri);
		_uriPrefix = _newuri;
    }

    function airdrop(address _account, uint256 _id, uint256 _amount, bytes memory _data)
        external
        onlyOwner
    {
        _mint(_account, _id, _amount, _data);
    }

    function mintBatch(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
        external
        onlyOwner
    {
        _mintBatch(_to, _ids, _amounts, _data);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}