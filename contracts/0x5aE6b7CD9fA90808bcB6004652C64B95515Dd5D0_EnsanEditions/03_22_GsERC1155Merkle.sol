// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./GsERC1155.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

error WrongRoot();
error InactiveWhitelist();
error InvalidProof();

/// @notice This contract adds a Merkle Tree based Whitelist to the GsERC1155 contract.
/// Multiple whitelists can exist for a given token ID
/// @author www.geeks.solutions
/// @dev You can use this contract as a parent for your collection and you can use
/// https://sections.geeks.solutions to get a ready frontend solution to run
/// your mint page that connects seamlessly to this contract
contract GsERC1155Merkle is GsERC1155 {
    struct WhitelistData {
        bytes32 merkle_root;
        uint128 token_price;
        uint8 max_per_wallet;
        bool active;
        bool use_dynamic_price;
    }

    // whitelist_datas[token_id][whitelist_index]
    mapping(uint256 => WhitelistData[]) internal whitelist_datas;

    /// @notice Builds a collection that can be whitelist gated
    constructor(string memory _name, string memory _symbol, string memory _contractURI, address _recipient, uint16 _royaltyShare) 
    GsERC1155(_name, _symbol, _contractURI, _recipient, _royaltyShare){}

    modifier whitelistExist(uint256 whitelistIndex, uint256 tokenId) {
        _whiteListExist(whitelistIndex, tokenId);
        _;
    }

    function _whiteListExist(uint256 whitelistIndex, uint256 tokenId) internal view virtual {
        if(whitelistIndex >= whitelist_datas[tokenId].length) revert IndexOutOfRange();
    }

    /// @notice Adds a new whitelist for a given token ID. The token must be defined. Whitelist index starts at 0
    /// 
    /// @param _token_id The Id of the token to create a whitelist for
    /// @param _wl_price_in_wei The price in GWEI (https://eth-converter.com/) of the token when minting with this whitelist
    /// @param _merkle_root The merkle root to grant access to the whitelist
    /// @param _wl_max_per_wallet The maximum amount of tokens one can hold to mint using this whitelist
    /// @param _active Whether or not this whitelist is active and can be used to mint the token
    /// @param _use_dynamic_price a boolean to indicate if we should use the dynamic price or not
    /// @return whitelist_index
    function addNewWhitelist(uint256 _token_id, uint128 _wl_price_in_wei, bytes32 _merkle_root, 
        uint8 _wl_max_per_wallet, bool _active, bool _use_dynamic_price) external editors tokenExist(_token_id)
    returns(uint256){
        whitelist_datas[_token_id].push(
            WhitelistData({
                token_price: _wl_price_in_wei,
                active: _active,
                merkle_root: _merkle_root,
                max_per_wallet: _wl_max_per_wallet,
                use_dynamic_price: _use_dynamic_price
            }));
        return whitelist_datas[_token_id].length - 1;
    }

    /// @notice Fully edit the whitelist for a token id at a given index
    /// 
    /// @param _token_id The id of the token to update the whitelist for
    /// @param _whitelist_index The index of the whitelist to edit
    /// @param _merkle_root The new merkle root to store for this whitelist
    /// @param _active  Whether or not this whitelist is active and can be used to mint the token
    /// @param _wl_price_in_wei the price in GWEI (https://eth-converter.com/)
    /// @param _wl_max_per_wallet The maximum amount of tokens one can hold to mint using this whitelist
    /// @param _use_dynamic_price a boolean to indicate if we should use the dynamic price or not
    function editWhitelistFull(uint256 _whitelist_index, uint256 _token_id, uint128 _wl_price_in_wei, bytes32 _merkle_root, 
        uint8 _wl_max_per_wallet, bool _active, bool _use_dynamic_price) external editors whitelistExist(_whitelist_index, _token_id) {
        editWhitelist(whitelist_datas[_token_id][_whitelist_index], _token_id, _whitelist_index, _merkle_root, _active, _wl_price_in_wei, _wl_max_per_wallet, _use_dynamic_price);
        
    }

    /// @notice Partially edit the whitelist for a token id at a given index
    /// 
    /// @param _token_id The id of the token to edit the whitelist for
    /// @param _whitelist_index the index of the whitelist to edit
    /// @param _merkle_root the new merkle root to store for this whitelist
    /// @param _active  Whether or not this whitelist is active and can be used to mint the token
    /// @param _use_dynamic_price Whether or not to use dynamic price for the whitelist
    function editWhitelistPartial(uint256 _whitelist_index, uint256 _token_id, bytes32 _merkle_root, bool _active, bool _use_dynamic_price) external editors whitelistExist(_whitelist_index, _token_id) {
        WhitelistData memory whitelist = whitelist_datas[_token_id][_whitelist_index];
        editWhitelist(whitelist, _token_id, _whitelist_index, _merkle_root, _active, whitelist.token_price, whitelist.max_per_wallet, _use_dynamic_price);
    }

    function editWhitelist(WhitelistData memory _whitelist, uint256 _token_id, uint256 _whitelist_index, bytes32 _merkle_root, bool _active,
        uint128 _wl_price, uint8 _wl_max_per_wallet, bool _use_dynamic_price) internal {            
        if(_merkle_root == "") revert WrongRoot();

        _whitelist.merkle_root = _merkle_root;
        _whitelist.active = _active;
        _whitelist.token_price = _wl_price;
        _whitelist.max_per_wallet = _wl_max_per_wallet;
        _whitelist.use_dynamic_price = _use_dynamic_price;

        whitelist_datas[_token_id][_whitelist_index] = _whitelist;
    }

    /// @notice Gets a white for token id at a specific index
    /// 
    /// @param _token_id the id of the token to get the whitelist for
    /// @param _whitelist_index the index of the whitelist to get
    /// @return whitelist
    function getWhiteListAtIndex(uint256 _token_id, uint256 _whitelist_index) public view whitelistExist(_whitelist_index, _token_id)
    returns(WhitelistData memory) {
        return whitelist_datas[_token_id][_whitelist_index];
    }

    /// @notice Returns the number of whitelists defined for a given token id
    /// 
    /// @param _token_id The id of the token to get the count for
    /// @return length
    function getWhiteListLengthForToken(uint256 _token_id) external view returns(uint256) {
        return whitelist_datas[_token_id].length;
    }

    /// @notice Returns the total price for a mint based on a token ID the amount of token, 
    /// the whitelist and the wallet requesting it. Price can be dynamic or static,
    /// whitelist can be set to override dynamic pricing
    /// 
    /// @param account the address to compute the price for
    /// @param token_id the token id to get the price for
    /// @param whitelist_index the whitelist to check the price for
    /// @param amount the amount of token to compute the price for
    ///
    /// @return price
    function getMintTotalPrice(address account, uint256 token_id, uint256 whitelist_index, uint256 amount) external view whitelistExist(whitelist_index, token_id) 
    returns(uint256 price) {
        WhitelistData memory _whitelist = getWhiteListAtIndex(token_id, whitelist_index); 
        if (_whitelist.use_dynamic_price) {
            return super.extractTotalPrice(token_id, _whitelist.token_price, token_datas[token_id].total_supply, token_datas[token_id].mints_count[account], amount);
        }
        return _whitelist.token_price * amount;
    }

    function initFront(address account, uint256 token_id, uint256 whitelist_index) public view whitelistExist(whitelist_index, token_id)
     returns(ReturnData memory rd){
       rd = super.initFront(account, token_id);
        // whitelist overriding
        WhitelistData memory wl = getWhiteListAtIndex(token_id, whitelist_index);
       rd.max_per_wallet = wl.max_per_wallet;
       rd.base_price = wl.token_price;
       rd.active = wl.active;
       rd.use_dynamic_price = wl.use_dynamic_price;
    }

    //************ SUPPORT FUNCTIONS ************//
    /**
     * @notice This function checks for the elligibility for a user to mint a given amount of token id based on the proof
     * of a given whitelist index
     * @param _amount the amount of token to check mint elligibility for
     * @param _token_id the token id to check
     * @param _whitelist_index the whitelist index to check for
     * @param _merkleProof the proof of the Merkle tree provided by the user
     * @return total
     */
    function elligible_claim(uint256 _amount, uint256 _token_id, uint256 _whitelist_index, bytes32[] calldata _merkleProof) view internal 
    returns(uint256 total) {
        WhitelistData storage whitelist = whitelist_datas[_token_id][_whitelist_index];
        if(!whitelist.active) revert InactiveWhitelist();
        if(!MerkleProof.verifyCalldata(_merkleProof, whitelist.merkle_root, keccak256(abi.encodePacked(msg.sender)))) revert InvalidProof();
        return super.elligible_mint(_token_id, _amount, whitelist.use_dynamic_price, whitelist.max_per_wallet, whitelist.token_price);
    }

}