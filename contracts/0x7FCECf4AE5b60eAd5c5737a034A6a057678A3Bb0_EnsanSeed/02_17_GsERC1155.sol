// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

/*
* @notice this class leverages standard practices to enable a safe and controllable ERC1155 token
*         in the current version, royalties are global for all token IDs
*/
contract GsERC1155 is ERC1155Supply, ERC1155Burnable, Ownable, Pausable, IERC2981 {
    
    string public name_;
    string public symbol_;   
    
    address private _recipient;
    uint256 private _royaltyShare;

    bool public _isPublicSale = false;
    bool public _isBurnable = false;
 
    constructor(string memory _name, string memory _symbol, string memory _baseURI, address recipient, uint256 royaltyShare) ERC1155(_baseURI) {
        name_ = _name;
        symbol_ = _symbol;
        _recipient = recipient;
        _royaltyShare = royaltyShare;
    }

    function name() public view returns (string memory) {
        return name_;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
    }  

    modifier whenPublicSaleIsActive() {
        require(
            _isPublicSale, "Public sale is closed"
        );
        _;
    } 
    
    modifier whenBurnIsActive() {
        require(
            _isBurnable, "Token is not burnable"
        );
        _;
    } 

    /*
    * @notice define modifiers
    */
    function setModifier(uint32 _type, bool _value) external onlyOwner {
        if (_type == 1) {
            _isPublicSale = _value;
        } else if (_type == 2) {
            _isBurnable = _value;
        } else {
            revert("Unknown modifier type");
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }

    function royaltyInfo(uint256 , uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        return (_recipient, (_salePrice * _royaltyShare) / 10000);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
        return (interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId));
    }

    function setRoyalties(address newRecipient, uint256 newShare) external onlyOwner {
        require(newRecipient != address(0), "Royalties: new recipient is the zero address");
        require(newShare > 0 && newShare < 10000, "Royalties: new share should be between 1 and 9999 basis points");
        _recipient = newRecipient;
        _royaltyShare = newShare;
    }

    /** 
    * @notice Override ERC1155Burnable burn method to let the contract define the burnability of tokens
    * 
    * @param account the address to burn from 
    * @param id the id of the token to burn
    * @param amount the amount of tokens to burn
    */
    function burn(address account, uint256 id, uint256 amount) public whenNotPaused whenBurnIsActive override(ERC1155Burnable){
        super.burn(account, id, amount);
    }

    /** 
    * @notice Override ERC1155Burnable burnBatch method to let the contract define the burnability of tokens
    * 
    * @param account the address to burn from 
    * @param ids an array of ids of tokens to burn
    * @param amounts an array of amounts of tokens to burn
    * 
    * ids and amounts must be of the same length
    */
    function burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) public whenNotPaused whenBurnIsActive override(ERC1155Burnable){
        super.burnBatch(account, ids, amounts);
    } 

    /// Allow the owner to withdraw funds from the contract to the owner's wallet
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool succ,) = payable(msg.sender).call{
            value: balance
        }("");
        require(succ, "transfer failed");
    }       

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal whenNotPaused virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    } 

    /**
    * @notice returns the metadata uri for a given id
    * 
    * @param _id the card id to return metadata for
    */
    function uri(uint256 _id) public view override returns (string memory) {
            require(exists(_id), "URI: nonexistent token");
            
            return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    } 
}