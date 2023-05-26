// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ContextMixin.sol";



contract ERC1155Astronauts is ContextMixin, ERC1155Burnable, ERC1155Pausable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using SafeMath for uint256;

    uint256 internal _tokenIdTracker = 0;
    mapping (uint256 => string) customUri;
    mapping (address => bool) operators;

    bool public public_mint_open = true;
    uint256 public mint_price = 80000000000000000;
    uint256 public max_mint_allowed = 100;

    string public name;
    string public symbol;

    modifier onlyOwnerOrOperator() {
        require(owner() == _msgSender() || isContractOperator(_msgSender()), "Ownable: caller is not the owner");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;
    }


    function mintToken(address _to, uint256 _quantity) public payable nonReentrant {
        require(_quantity > 0);
        if(owner() != _msgSender() || !isContractOperator(_msgSender())){
        require(public_mint_open);
        require(_quantity <= max_mint_allowed);
        require(mint_price.mul(_quantity) <= msg.value);
        }

        if(_quantity == 1){
        _mint(_to, _tokenIdTracker, 1, "");
        _tokenIdTracker += 1;
        }
        else
        {
            uint256[] memory _ids = new uint256[](_quantity);
            uint256[] memory _qty = new uint256[](_quantity);

            for(uint256 i = 0; i < _quantity; i++){
                _ids[i] = _tokenIdTracker + i;
                _qty[i] = 1;
            }

            _mintBatch(_to, _ids, _qty, "");
            _tokenIdTracker += _quantity;
        }

    }

    function mint(address _to, uint256 _id, uint256 _quantity, uint256 inc_counter) public onlyOwnerOrOperator {
        _mint(_to, _id, _quantity, "");

        if(inc_counter > 0){
        _tokenIdTracker += inc_counter;
        }
        

    }

    function mintBatchToken(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256 inc_counter
    ) public virtual onlyOwnerOrOperator {

        _mintBatch(to, ids, amounts, "");
        if(inc_counter > 0){
        _tokenIdTracker += inc_counter;
        }
    }

    function setSettings(bool _public_mint_open,uint256 _mint_price, uint256 _max_mint_allowed) public onlyOwnerOrOperator {
                        
        public_mint_open = _public_mint_open;
        mint_price = _mint_price;
        max_mint_allowed = _max_mint_allowed;
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual onlyOwnerOrOperator {
        _pause();
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdTracker;
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual onlyOwnerOrOperator {
        _unpause();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }


    function setURI(string memory _newURI) public onlyOwnerOrOperator {
        _setURI(_newURI);
    }

    function setCustomURI(
        uint256 _tokenId,
        string memory _newURI) public onlyOwnerOrOperator {
        customUri[_tokenId] = _newURI;
    }

    function resetCounter(
        uint256 _count) public onlyOwnerOrOperator {
        _tokenIdTracker = _count;
    }

    function setContractOperator(
        address _to, bool is_operator) public onlyOwnerOrOperator {
        operators[_to] = is_operator;
    }

    function isContractOperator(
        address _acc) public view returns(bool) {
        return operators[_acc];
    }




    function uri(uint256 token_) public view virtual override returns (string memory) {

        if (bytes(customUri[token_]).length > 0) {
            return customUri[token_];
        } else {
            if(token_ > (_tokenIdTracker - 1)){
                return "";
            }
            else
            {
            return bytes(ERC1155.uri(token_)).length > 0 ? string(abi.encodePacked(ERC1155.uri(token_), token_.toString())): "";
            }
        }
        
    }

    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}