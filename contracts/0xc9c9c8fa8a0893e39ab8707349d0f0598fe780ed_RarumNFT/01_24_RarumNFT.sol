//SPDX-License-Identifier: none

pragma solidity ^0.8.0;

import "./RarumNFT_Permit.sol";

contract RarumNFT is ERC1155PresetMinterPauserUpgradeable, RarumNFT_Permit {

    string public name;
    string public symbol;
    string public description;

    mapping (uint256 => string) private _tokenURIs;
    uint256[] public tokenIds; // list of token ids - order is not important

    /**
     * @dev Grants `OPERATOR_ROLE` to the account that deploys the contract.
     */
    function initialize(
        string calldata _uri,
        string calldata _name,
        string calldata _symbol,
        string calldata _description
    )
        public
        initializer
    {
        __ERC1155PresetMinterPauser_init(_uri);
        __EIP712_init("https://rarum.io", "1");

        _setupRole(BURNER_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, _msgSender());

        name = _name;
        symbol = _symbol;
        description = _description;
    }

    function registerToken(
        uint256 id,
        string calldata cid
    )
        external
        onlyMinter
    {
        require(bytes(_tokenURIs[id]).length == 0, "RarumNFT: token already registered");

        tokenIds.push(id);

        _setTokenURI(id, cid);
    }

    function batchRegisterToken(
        uint256[] calldata ids,
        string[] calldata cids
    )
        external
        onlyMinter
    {
        require(ids.length == cids.length, "RarumNFT: ids and cids length mismatch");

        for (uint i = 0; i < ids.length; i++) {
            require(bytes(_tokenURIs[ids[i]]).length == 0, "RarumNFT: token already registered");
            tokenIds.push(ids[i]);
            _setTokenURI(ids[i], cids[i]);
        }
    }

    function isRegistered(
        uint256 id
    ) external view returns (bool) {
        return bytes(_tokenURIs[id]).length != 0;
    }

    function getRegisteredTokens()
        external view returns (uint256[] memory) {
        return tokenIds;
    }

    function balancesOf(
        address wallet
    ) external view returns (uint256[] memory tokens, uint256[] memory balances) {
        uint256[] memory tokens = tokenIds;
        uint256[] memory balances = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; ++i) {
            balances[i] = balanceOf(wallet, tokens[i]);
        }

        return (tokens, balances);
    }

     /**
     * @dev Creates `amount` new tokens for `to`, of token type `id` and adds a default operator
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    )
        public
        override
    {
        require(bytes(_tokenURIs[id]).length != 0, "RarumNFT: token is not registered");

        super.mint(to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint} and adds a default operator.
     */
    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    )
        public
        override
    {
        for (uint i = 0; i < ids.length; i++) {
            require(bytes(_tokenURIs[ids[i]]).length != 0, "RarumNFT: token is not registered");
        }

        super.mintBatch(to, ids, amounts, data);
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    )
        public
        override
        onlyBurner
    {
        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] calldata ids,
        uint256[] calldata values
    )
        public
        override
        onlyBurner
    {
        _burnBatch(account, ids, values);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return _tokenURI(_id);
    }

    /**
     * @dev Returns an URI for a given token ID. If tokenId is 0, returns _uri
     * @param tokenId uint256 ID of the token to query
     */
    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        if (tokenId == 0) return _uri;

        return _tokenURIs[tokenId];
    }

    /**
     * @dev Internal function to set the token cid for a given token.
     * @param tokenId uint256 ID of the token to set its URI
     * @param cid string ipfs cid to assign
     */
    function _setTokenURI(uint256 tokenId, string memory cid) internal {
        _tokenURIs[tokenId] = string(abi.encodePacked(_uri, cid));

        emit URI(_tokenURIs[tokenId], tokenId);
    }
}