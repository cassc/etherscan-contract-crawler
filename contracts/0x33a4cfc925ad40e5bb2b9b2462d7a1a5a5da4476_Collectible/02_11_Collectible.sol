pragma solidity ^0.5.0;

import "./ERC1155MixedFungible.sol";


contract Collectible is ERC1155MixedFungible {

    /**
     * Emits to denote the creation of a new collectible
     */
    event NewCollectible(address indexed _creator, uint256 indexed _type, uint256 _proofCount);
    event Generation(uint256 _type, uint256 _maxSubType, uint256 _generation, string _uriId);

    bytes4 constant private INTERFACE_SIGNATURE_URI = 0x0e89341c;
    address _owner;
    string internal baseMetadataURI;

    constructor() public {
      _owner = msg.sender;
  }

    /**
     * @dev needed for opensea storefront validation
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    function supportsInterface(bytes4 _interfaceId)
    public
    view
    returns (bool) {
        if (_interfaceId == INTERFACE_SIGNATURE_URI) {
            return true;
        } else {
            return super.supportsInterface(_interfaceId);
        }
    }



    uint256 public nonce;
    mapping (uint256 => address) public creators;
    mapping (uint256 => uint256) public maxIndex;
    mapping (uint256 => uint256) public proofs;
    mapping (uint256 => uint256) generations;
    mapping (uint256 => string) uris;

    modifier creatorOnly(uint256 _id) {
        require(creators[_id] == msg.sender, "CREATOR");
        _;
    }

    modifier onlyOwner {
        require(_owner == msg.sender, "OWNER");
        _;
    }

    modifier isNonFungibleType(uint256 _id) {
        // types all have a 128-bit zero-index value;
        // no token exists at these indices
        require((_id & TYPE_NF_BIT == TYPE_NF_BIT) && (_id & NF_INDEX_MASK == 0), "NOT_TYPE");
        _;
    }

    // provides unique URIs for each subtype
    // individual tokens ids do not have a specific URI
    function uri(
        uint256 _id
    ) public view returns (string memory) {
        require(exists(_id), "ERC721Tradable#uri: NONEXISTENT_TOKEN");
        require(bytes(uris[_id & SUBTYPE_MASK]).length != 0, "NONEXISTENT_URI");
        return string(abi.encodePacked(baseMetadataURI, uris[_id & SUBTYPE_MASK]));
    }

    function setBaseMetadataURI(
        string memory _newBaseMetadataURI
    ) public onlyOwner {
        baseMetadataURI = _newBaseMetadataURI;
    }

    // This function creates the type and mints artist proofs.
    function create(
        uint256 _artistProofs,
        string calldata _uri,
        bool   _isNF,
        address[] calldata _to
    )
    external onlyOwner returns(uint256 _type) {

        // Store the type in the upper 128 bits
        _type = (++nonce << 128);

        // Set a flag if this is an NFI.
        if (_isNF)
          _type = _type | TYPE_NF_BIT;

        // This will allow restricted access to creators.
        creators[_type] = msg.sender;

        // tokenId
        proofs[_type] = _artistProofs;
        uris[_type] = _uri;

        bool sendTokens; // false
        if (_to.length > 0) {
            require(_to.length == _artistProofs, "TO_PROOF_MISMATCH");
            sendTokens = true;
        }

        emit NewCollectible(msg.sender, _type, _artistProofs);

        string memory fullURI = string(abi.encodePacked(baseMetadataURI, _uri));
        emit URI(fullURI, _type);

        for (uint256 i = 1; i <= _artistProofs; ++i) {
            address dst = msg.sender;
            if (sendTokens) {
                dst = _to[i-1];
            }
            uint256 id  = _type | i;

            nfOwners[id] = dst;
            creators[id] = msg.sender;

            // You could use base-type id to store NF type balances if you wish.
            // balances[_type][dst] = quantity.add(balances[_type][dst]);

            emit TransferSingle(msg.sender, address(0x0), dst, id, 1);
            if (dst.isContract()) {
                _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, dst, id, 1, '');
            }
        }
        emit Generation(_type, _artistProofs, 0, _uri);
    }

    // mint a new generation of a type of tokens;
    // all tokens of the generation go to the owner of this contract
    // all metadata of a generation is the same, edition is read on-chain
    function mint(
        uint256 _type,
        uint256 _editions,
        string calldata _uriId,
        address[] calldata _to
    ) external
    isNonFungibleType(_type)
    creatorOnly(_type)
    {
        // make sure baseMetadataURI is already set
        require(bytes(baseMetadataURI).length != 0, "URI_BASE_UNSET");

        // check if _to is utilized
        bool sendTokens; // false
        if (_to.length > 0) {
            require(_to.length == _editions, "TO_EDITION_MISMATCH");
            sendTokens = true;
        }
        string memory fullURI = string(abi.encodePacked(baseMetadataURI, _uriId));
        // Index are 1-based.
        uint256 index = maxIndex[_type].add(1);
        maxIndex[_type] = _editions.add(maxIndex[_type]);
        uint256 subType;

        for (uint256 i = 0; i < _editions; ++i) {
            // subType is used to denote each new edition within a generation
            uint256 subTypeIdx = (index + i) << 64;
            subType = _type | subTypeIdx;
            creators[subType] = msg.sender;

            uint256 id = subType + 1;

            // sanity/bug check - can probably be removed for mainnet
            require(nfOwners[id] == address(0), "TOKEN_EXISTS");
            uris[subType] = _uriId;
            emit URI(fullURI, subType);

            address recipient = msg.sender;
            if (sendTokens) {
                recipient = _to[i];
            }
            nfOwners[id] = recipient;

            emit TransferSingle(msg.sender, address(0x0), recipient, id, 1);

            if (_owner.isContract()) {
                _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, recipient, id, 1, '');
            }
        }
        uint256 nextGen = generations[_type] + 1;
        emit Generation(_type, subType, nextGen, _uriId);
        generations[_type] = nextGen;
    }

    // for fungible Tokens
    function mintFungibles(uint256 _id, address[] calldata _to, uint256[] calldata _quantities) external creatorOnly(_id) {

        require(isFungible(_id));

        for (uint256 i = 0; i < _to.length; ++i) {

            address to = _to[i];
            uint256 quantity = _quantities[i];

            // Grant the items to the caller
            balances[_id][to] = quantity.add(balances[_id][to]);

            // Emit the Transfer/Mint event.
            // the 0x0 source address implies a mint
            // It will also provide the circulating supply info.
            emit TransferSingle(msg.sender, address(0x0), to, _id, quantity);

            if (to.isContract()) {
                _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, to, _id, quantity, '');
            }
        }
    }

    /**
     * @dev for non-fungibles `_id` should always be a subType
     *      _uriId should only contain the unique identifier (such as the IPFS CID)
     */
    function setURI(string calldata _uriId, uint256 _id) external creatorOnly(_id) {
        string memory fullURI = string(abi.encodePacked(baseMetadataURI, _uriId));
        uris[_id] = _uriId;
        emit URI(fullURI, _id);
    }

    function exists(uint256 _id) internal view returns (bool) {
        return nfOwners[_id] != address(0);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

}
