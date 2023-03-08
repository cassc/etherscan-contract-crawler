// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import "./libraries/GsDynamicPrice.sol";

error UnknownModifier();
error Unauthorized(address user);
error TokenNotFound();
error Unburnable();
error SaleClosed();
error ExistingToken();
error TokenLockedBySupply();
error IndexOutOfRange();
error ListFull();
error InvalidRoyaltyShare();
error TransferFailed();
error ContractMint();
error MaxSupply();
error MaxCount();
error ZeroAddress();
error NotTokenOwnerOrAuthorised();

// For convenience to inheriting contracts
error InsufficentFunds();

/// @title A base class to create token IDs within an ERC1155 collection
/// @author www.geeks.solutions
/// @notice Each token definition carries a price, a max supply and certain mint rules
/// You can define as many tokens as you want. Once a token has been supplied the supply levels
/// and base prices are locked for this token ID.
/// You can also define pricing rules per token to have dynamic prices apply to tokens. 
/// pricing rules are based on ascending triggering values and can be based on 
/// token SUPPLY or wallet MINTS or a combination of both
/// @dev You can define default values that will be used when creating new tokens
/// You can use this contract as a parent for your collection and you can use
/// https://sections.geeks.solutions to get a ready frontend solution to run
/// your mint page that connects seamlessly to this contract
contract GsERC1155 is ERC1155, Ownable, Pausable, IERC2981 {
    
    enum PriceCondition{SUPPLY, MINTS}

    string public name;
    string public symbol;
    string public contractURI;  

    TokenData internal _default;
    PriceCondition[2] public price_condition_priority; 

    struct ReturnData {
        uint128 base_price;
        uint16 royalty_share;
        bool active;
        bool burnable;
        bool use_dynamic_price;
        bool isPaused;
        uint32 max_supply;
        uint32 total_supply;
        uint16 max_per_wallet;
        address royalty_recipient;
        string uri;
        uint256 mints_count;
    }

    struct TokenData {
        mapping(address => uint256) mints_count;
        uint128 base_price;
        uint16 royalty_share;
        bool public_sale;
        bool burnable;
        uint32 max_supply;
        uint32 total_supply;
        uint16 max_per_wallet;
        bool exist;
        bool use_dynamic_price;
        address royalty_recipient;
        string uri;
    }
    mapping(address => bool) private _editors;
    mapping(uint256 => TokenData) internal token_datas;
    mapping(uint256 => GsDynamicPrice.PriceRule[][]) internal price_conditions;

    /// @notice constructor to instantiate GsERC1155 contract
    /// @dev The params provided to this function will define the default Token Data to use for Tokens creation
    //
    /// @param _name the name of this collection
    /// @param _symbol the symbol to use for this collection
    /// @param _contractURI the URI pointing to the metadata describing your contract/collection (https://docs.opensea.io/docs/contract-level-metadata)
    /// @param _recipient the default royalty recipient for tokens to be created
    /// @param _royaltyShare the share of each sale (1% = 100) to distribute to the royalty recipient
    constructor(string memory _name, string memory _symbol, string memory _contractURI, address _recipient, uint16 _royaltyShare) ERC1155("https://geeks.solutions") {
        _default.base_price = 0.05 ether;
        _default.royalty_share = _royaltyShare;
        _default.public_sale = true;
        //_default.burnable = false;
        _default.max_supply = 1000;
        _default.max_per_wallet = 1;
        _default.exist = true;
        _default.royalty_recipient = _recipient;
        //_default.use_dynamic_price = false;

        name = _name;
        symbol = _symbol;
        contractURI = _contractURI;

        price_condition_priority[0] = PriceCondition.SUPPLY;
        price_condition_priority[1] = PriceCondition.MINTS;
    }

    /// @notice Convenience function to update the URI of the contract metadata
    /// 
    /// @param _contractURI the new URI to set for your contract/collection metadata file
    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    /// @notice This function is used to update a specific modifier for a given token id 
    /// @dev can only be called by the owner or editors
    //
    /// @param _token_id The token ID to edit the modifier for
    /// @param _type the modifier to edit (1=public_sale, 2=burnable, 3=use_dynamic_price)
    /// @param _value the new modifier value
    function setModifier(uint256 _token_id, uint32 _type, bool _value) external editors tokenExist(_token_id) {
        if (_type == 1) {
            token_datas[_token_id].public_sale = _value;
        } else if (_type == 2) {
            token_datas[_token_id].burnable = _value;
        } else if (_type == 3) {
            token_datas[_token_id].use_dynamic_price = _value;
        } else {
            revert UnknownModifier();
        }
    }

    modifier whenPublicSaleIsActive(uint256 _token_id) {
       if(!token_datas[_token_id].public_sale) revert SaleClosed();
        _;
    } 

    modifier tokenExist(uint256 tokenId) {
        _tokenExist(tokenId);
        _;
    }

    function _tokenExist(uint256 tokenId) internal view virtual {
        if (!token_datas[tokenId].exist) revert TokenNotFound();
    }

    modifier editors() {
        _checkEditors();
        _;
    }

    function _checkEditors() internal view virtual {
        if (!((owner() == _msgSender()) || _editors[_msgSender()])) revert Unauthorized(_msgSender());
    }

    function enableEditor(address editor) external onlyOwner {
        _editors[editor] = true;
    }

    function disableEditor(address editor) external onlyOwner {
        _editors[editor] = false;
    }

    /**
     * @dev Total amount of tokens minted with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint32) {
        return token_datas[id].total_supply;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
    * @notice returns the metadata uri for a given id
    * 
    * @param _token_id the token id to return metadata for
    */
    function uri(uint256 _token_id) public view override tokenExist(_token_id) returns (string memory) {
        return token_datas[_token_id].uri;
    } 

    /// @notice Updates the URI of a given token, can be called at any time (for simple reveals)
    /// 
    /// @param _token_id The id of the token to update
    /// @param _tokenURI The new URI to use for the token metadata (returned as is)
    function setURI(uint256 _token_id, string memory _tokenURI) external editors tokenExist(_token_id) {
        token_datas[_token_id].uri = _tokenURI;
    }

    function getDefaultTokenData() external view returns(ReturnData memory) {
        return ReturnData({
            base_price: _default.base_price, 
            royalty_share: _default.royalty_share,
            royalty_recipient: _default.royalty_recipient,
            active: _default.public_sale, 
            burnable: _default.burnable,
            max_supply: _default.max_supply,
            total_supply: _default.total_supply,
            max_per_wallet: _default.max_per_wallet,
            use_dynamic_price: _default.use_dynamic_price,
            uri: _default.uri,
            mints_count: 0,
            isPaused: super.paused()
        });
    }

    function setDefaultRoyalties(address _recipient, uint16 _share) public onlyOwner {
        _default.royalty_recipient = _recipient;
        _default.royalty_share = _share;
    }

    /// @notice this function updates the modifiers for the default values to use when creating new tokens
    //
    /// @param _publicSale the value to set for the public sale modifier
    /// @param _burnable the value to set for the burnable modifier
    function setDefaultModifiers(bool _publicSale, bool _burnable, bool _use_dynamic_price) public onlyOwner {
        _default.public_sale = _publicSale;
        _default.burnable = _burnable;
        _default.use_dynamic_price = _use_dynamic_price;
    }

    function setDefaultTokenMeta(uint32 _maxSupply, uint8 _maxPerWallet, uint128 _price_in_wei) public onlyOwner {
        _default.max_supply = _maxSupply;
        _default.max_per_wallet = _maxPerWallet;
        _default.base_price = _price_in_wei;
    }

    /// @notice updates the default values to use when creating new tokens
    /// @dev can only be called by the owner 
    //
    /// @param _recipient the recipient address to receive royalties
    /// @param _share the share of royalties to distribute on each sale (1% = 100)
    /// @param _publicSale Enable public sale for new tokens as soon as they are defined
    /// @param _burnable Allow the tokens to be burned as soon as they are defined
    /// @param _maxSupply The maximum Supply for new token creations
    /// @param _maxMintsPerWallet The maximum number of token a given wallet can mint
    /// @param _price_in_wei The token price in WEI (check https://eth-converter.com/ for help)
    function setDefaults(address _recipient, uint16 _share,
        bool _publicSale, bool _burnable, bool _use_dynamic_price,
        uint32 _maxSupply, uint8 _maxMintsPerWallet, uint128 _price_in_wei) external onlyOwner {
            setDefaultRoyalties(_recipient, _share);
            setDefaultModifiers(_publicSale, _burnable, _use_dynamic_price);
            setDefaultTokenMeta(_maxSupply, _maxMintsPerWallet, _price_in_wei);
    }

    function getTokenData(uint256 id) public view tokenExist(id)
      returns(ReturnData memory) {
        TokenData storage td = token_datas[id];
        return ReturnData({
            base_price: td.base_price, 
            royalty_share: td.royalty_share,
            active: td.public_sale, 
            burnable: td.burnable, 
            max_supply: td.max_supply,
            total_supply: td.total_supply,
            max_per_wallet: td.max_per_wallet, 
            use_dynamic_price: td.use_dynamic_price,
            royalty_recipient: td.royalty_recipient,
            uri: td.uri,
            isPaused: super.paused(),
            mints_count: 0
        }
        );
    }

    /// @notice Adds a new token without reading default token values
    /// Updates the token if it's been declared but not yet supplied. Rejects if the token id has been supplied already
    /// @dev can only be called by the owner.
    //
    /// @param _tokenId The ID to use for the new token to create
    /// @param _tokenUri The URI to use for the token metadata (returned as is)
    /// @param _tokenPublicSale Allow the token to be publicly minted
    /// @param _tokenBurnable Allow the token to be burned by its holder
    /// @param _tokenMaxSupply The maximum Supply for this token
    /// @param _tokenMaxMintsPerWallet The maximum amount of token a wallet can hold to mint more
    /// @param price_in_wei The price of the token in wei (https://eth-converter.com/)
    /// @param _tokenRoyaltyShare The share of royalty to send to the recipient on each sale (1% = 100)
    /// @param _tokenRoyaltyRecipient The recipient address to receive royalties on each sale
    function addNewToken(uint256 _tokenId, 
        string calldata _tokenUri, 
        bool _tokenPublicSale, 
        bool _tokenBurnable,
        uint32 _tokenMaxSupply,
        uint16 _tokenMaxMintsPerWallet,
        uint128 price_in_wei,
        uint16 _tokenRoyaltyShare,
        address _tokenRoyaltyRecipient,
        bool _use_dynamic_price) external editors {
            addToken(_tokenId, _tokenUri, _tokenPublicSale, _tokenBurnable, _tokenMaxSupply, 
            _tokenMaxMintsPerWallet, price_in_wei, _tokenRoyaltyShare, _tokenRoyaltyRecipient, _use_dynamic_price);
    }

    /// @notice Adds a new token by using default token values
    /// Updates the token if it's been declared but not yet supplied. Rejects if the token id has been supplied already
    /// @dev Can only be called by the owner
    //
    /// @param _tokenId the ID to use for this token
    /// @param _tokenUri The URI for this token metadata (returned as is)
    function addNewTokenLight(uint256 _tokenId, string calldata _tokenUri) external editors {
            addToken(_tokenId, _tokenUri, _default.public_sale, _default.burnable, _default.max_supply, _default.max_per_wallet, 
            _default.base_price, _default.royalty_share, _default.royalty_recipient, _default.use_dynamic_price);
    }

    function addToken(uint256 _tokenId, 
        string calldata _tokenUri, 
        bool _tokenPublicSale, 
        bool _tokenBurnable,
        uint32 _tokenMaxSupply,
        uint16 _tokenMaxPerWallet,
        uint128 _tokenPrice,
        uint16 _tokenRoyaltyShare,
        address _tokenRoyaltyRecipient,
        bool _use_dynamic_price) internal {
            if(token_datas[_tokenId].total_supply > 0) revert ExistingToken();
            TokenData storage td = token_datas[_tokenId];
            td.base_price = _tokenPrice;
            td.royalty_share = _tokenRoyaltyShare;
            td.public_sale = _tokenPublicSale;
            td.burnable = _tokenBurnable;
            td.max_supply = _tokenMaxSupply;
            td.max_per_wallet = _tokenMaxPerWallet;
            td.exist = true;
            td.royalty_recipient = _tokenRoyaltyRecipient;
            td.uri = _tokenUri;
            td.use_dynamic_price = _use_dynamic_price;
    }

    /// @notice Updates a given token Supply and price only if it hasn't been supplied
    //
    /// @param _tokenId The token ID to update
    /// @param _maxSupply The new maximum Supply to define for this token
    /// @param _maxPerWallet The maximum number of token a wallet can mint
    /// @param _price_in_wei The new price in GWEI (https://eth-converter.com/)
    function editTokenMeta(uint256 _tokenId, uint32 _maxSupply, uint16 _maxPerWallet, uint128 _price_in_wei) external editors {
        if(token_datas[_tokenId].total_supply > 0) revert TokenLockedBySupply();
        token_datas[_tokenId].max_supply = _maxSupply;
        token_datas[_tokenId].max_per_wallet = _maxPerWallet;
        token_datas[_tokenId].base_price = _price_in_wei;
    }

    function getMintTotalPrice(address account, uint256 token_id, uint256 amount) external view tokenExist(token_id) 
    returns(uint256 price) {
        TokenData storage td = token_datas[token_id];
        if (td.use_dynamic_price) {
            return extractTotalPrice(token_id, td.base_price, td.total_supply, td.mints_count[account], amount);
        }
        return td.base_price * amount;
    }

    function initFront(address account, uint256 token_id) public view virtual tokenExist(token_id)
    returns(ReturnData memory) {
        TokenData storage td = token_datas[token_id];
        return ReturnData({
            base_price: td.base_price, 
            royalty_share: td.royalty_share,
            active: td.public_sale, 
            burnable: td.burnable, 
            max_supply: td.max_supply,
            total_supply: td.total_supply,
            max_per_wallet: td.max_per_wallet, 
            use_dynamic_price: td.use_dynamic_price,
            royalty_recipient: td.royalty_recipient,
            uri: td.uri,
            isPaused: super.paused(),
            mints_count: td.mints_count[account]
        });
    }

    /// @notice Returns the Price condition type at priority index and the price rules associated for this token
    /// 
    /// @param _token_id the token id to get the price rules for
    /// @param _priority_index the priority index to return rules for
    function getPriceRules(uint256 _token_id, uint8 _priority_index) external view
     returns(PriceCondition, GsDynamicPrice.PriceRule[] memory){
        if(_priority_index >= price_conditions[_token_id].length) revert IndexOutOfRange();
        return (price_condition_priority[_priority_index], price_conditions[_token_id][_priority_index]);
    }

    /// @notice Reverse the order of priority between `SUPPLY` and `BALANCE`
    /// @dev this does not change the entries in the `price_conditions` map it only reassigns the value they compare against
    function reversePriceConditionPriority() external onlyOwner {
        PriceCondition[2] memory tmp = price_condition_priority;

        price_condition_priority[0] = tmp[1];
        price_condition_priority[1] = tmp[0];
    }

    /// @notice Add a list of price rules in the `price_conditions` map
    /// @dev the `price_conditions` map is as follows `price_conditions[uint256][priority_index][]`
    /// the list of price rules should contain a tuple for the trigger and the price value
    /// [[{trigger},{price in wei}],...] ie [[10,20000000000000000],[15,25000000000000000]]
    /// we need to iterate over the calldata array to manually convert to storage as calldata[] to storage conversion
    /// is not supported
    /// 
    /// @param _token_id the token id to add a price rule list for
    /// @param _ordered_rules the list of rules to add, has to be correctly formatted and in the right order
    function addPriceRules(uint256 _token_id, GsDynamicPrice.PriceRule[] calldata _ordered_rules) external editors tokenExist(_token_id) {
        if(!GsDynamicPrice.checkValidRulesList(_ordered_rules)) revert GsDynamicPrice.InvalidRule();
       
        uint256 new_index = price_conditions[_token_id].length;
        if(new_index >= price_condition_priority.length) revert ListFull();

        price_conditions[_token_id].push();
        for(uint8 i = 0; i < _ordered_rules.length; i++) {
            price_conditions[_token_id][new_index].push(_ordered_rules[i]);
        }
    }

    /// @notice Update an existing price rule list
    /// @dev see `addPriceRules` for more details
    /// 
    /// @param _token_id the token id to update the price rules list for
    /// @param _priority_index the price rule index to update
    /// @param _ordered_rules the price rules list
    function updatePriceRules(uint256 _token_id, uint8 _priority_index, GsDynamicPrice.PriceRule[] calldata _ordered_rules) external editors tokenExist(_token_id) {
        if(_priority_index >= price_conditions[_token_id].length) revert IndexOutOfRange();
        if(!GsDynamicPrice.checkValidRulesList(_ordered_rules)) revert GsDynamicPrice.InvalidRule();

        delete price_conditions[_token_id][_priority_index];
        
        for(uint8 i = 0; i < _ordered_rules.length; i++) {
            price_conditions[_token_id][_priority_index].push(_ordered_rules[i]);
        }
    }

    /// @notice Calculates the amount of royalty to send to the recipient based on the sale price
    /// 
    /// @param _token_id the Id of the token to compute royalty for
    /// @param _salePrice the price the token was sold for
    /// @return receiver
    /// @return royaltyAmount 
    function royaltyInfo(uint256 _token_id, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        return (token_datas[_token_id].royalty_recipient, (_salePrice * token_datas[_token_id].royalty_share) / 10000);
    }

    /// @notice Updates the Royalty parameters for a given token
    /// 
    /// @param _token_id the id of the token to update royalty param for
    /// @param _newRecipient the new recipient address
    /// @param _newShare the new share to take from each sale (1% = 100) should be between 1 and 9999 basis points
    function setRoyalties(uint256 _token_id, address _newRecipient, uint8 _newShare) external onlyOwner tokenExist(_token_id) {
        if(_newRecipient == address(0)) revert ZeroAddress();
        if(_newShare > 9999) revert InvalidRoyaltyShare();
        token_datas[_token_id].royalty_recipient = _newRecipient;
        token_datas[_token_id].royalty_share = _newShare;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
        return (interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId));
    }

    /** 
    * @notice Taken from ERC1155Burnable burn method to let the contract define the burnability of tokens
    * 
    * @param account the address to burn from 
    * @param id the id of the token to burn
    * @param amount the amount of tokens to burn
    */
    function burn(address account, uint256 id, uint256 amount) public virtual whenNotPaused{
        if (!token_datas[id].burnable) revert Unburnable();
        if (!(account == _msgSender() || isApprovedForAll(account, _msgSender()))) revert NotTokenOwnerOrAuthorised();

        _burn(account, id, amount);
    }

    /** 
    * @notice Taken from ERC1155Burnable burnBatch method to let the contract define the burnability of tokens
    * 
    * @param account the address to burn from 
    * @param ids an array of ids of tokens to burn
    * @param amounts an array of amounts of tokens to burn
    * 
    * ids and amounts must be of the same length
    */
    function burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) public virtual whenNotPaused{
        for(uint i = 0; i < ids.length; i++) {
            if(!token_datas[ids[i]].burnable) revert Unburnable();            
        }
        if (!(account == _msgSender() || isApprovedForAll(account, _msgSender()))) revert NotTokenOwnerOrAuthorised();
        _burnBatch(account, ids, amounts);
    } 

    /// @notice Allow the owner to withdraw funds from the contract to the owner's wallet
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool succ,) = payable(msg.sender).call{
            value: balance
        }("");
        if(!succ) revert TransferFailed();
    }       

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal whenNotPaused virtual override(ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        
        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                unchecked{
                    token_datas[ids[i]].mints_count[to] += amounts[i];
                    // MaxSupply is uint32 so this cast is safe
                    token_datas[ids[i]].total_supply += uint32(amounts[i]);
                }
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint32 amount = uint32(amounts[i]);
                uint32 supply = token_datas[id].total_supply;
                if(amount > supply) revert MaxSupply();
                unchecked {
                    token_datas[id].total_supply = supply - amount;
                }
            }
        }
    } 

    //************ SUPPORT FUNCTIONS ************//

    function elligible_mint(uint256 id, uint256 amount) view internal 
    returns(uint256 dynamicPrice) {
        TokenData storage td = token_datas[id];
        return elligible_mint(td, id, amount, td.use_dynamic_price, td.max_per_wallet, td.base_price);
    }

    function elligible_mint(uint256 _token_id, uint256 _amount, bool _load_dynamic_price, uint _wallet_max, uint _default_price) view internal 
    returns(uint256 dynamicPrice) {
        TokenData storage td =  token_datas[_token_id];  
        return elligible_mint(td, _token_id, _amount, _load_dynamic_price, _wallet_max, _default_price);
    }

    /// @notice Verifies the elligibility for a mint by a given wallet
    /// 
    /// @param td the inital token data
    /// @param _token_id The id of the token to mint
    /// @param _amount The amount of tokens to mint
    /// @param _load_dynamic_price whether or not it is necessary to compute a dynamic price or simply return the standard price
    /// @param _wallet_max the max_per_wallet condition to check (could come from a whitelist entry)
    /// @param _default_price the price to apply in case no dynamic price were found or it is disabled
    function elligible_mint(TokenData storage td, uint256 _token_id, uint256 _amount, bool _load_dynamic_price, uint _wallet_max, uint _default_price) view private tokenExist(_token_id)
    returns(uint256 dynamicPrice) {    
        uint32 _totalSupply = td.total_supply;
        if(_totalSupply + _amount > td.max_supply) revert MaxSupply();
        
        uint256 mintsCount = td.mints_count[_msgSender()];
        if(mintsCount + _amount > _wallet_max) revert MaxCount();

        if(tx.origin != _msgSender()) revert ContractMint();
        
        if (_load_dynamic_price) {
            return extractTotalPrice(_token_id, _default_price, _totalSupply, mintsCount, _amount);
        } else {
            return _default_price * _amount;
        }
    }

    function extractTotalPrice(uint256 _token_id, uint256 _base_price, uint32 total_supply, uint256 mintsCount, uint256 amount) view internal 
    returns(uint256) {
        uint256 value;
        for(uint i = 0; i < price_conditions[_token_id].length; i++) {
            if (price_condition_priority[i] == PriceCondition.SUPPLY) {
                value = total_supply;
            } else {
                value = mintsCount;
            }
            (bool triggered, uint256 price) = GsDynamicPrice.extractPrice(price_conditions[_token_id][i], value, _base_price, amount);
            if (triggered) return price;
        }

        return _base_price * amount;
    }
}