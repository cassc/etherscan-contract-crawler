// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;

interface ERC721Enumerable {

  /**
   * @dev Returns a count of valid NFTs tracked by this contract, where each one of them has an
   * assigned and queryable owner not equal to the zero address.
   * @return Total supply of NFTs.
   */
  function totalSupply()
    external
    view
    returns (uint256);

  /**
   * @dev Returns the token identifier for the `_index`th NFT. Sort order is not specified.
   * @param _index A counter less than `totalSupply()`.
   * @return Token id.
   */
  function tokenByIndex(
    uint256 _index
  )
    external
    view
    returns (uint256);

  /**
   * @dev Returns the token identifier for the `_index`th NFT assigned to `_owner`. Sort order is
   * not specified. It throws if `_index` >= `balanceOf(_owner)` or if `_owner` is the zero address,
   * representing invalid NFTs.
   * @param _owner An address where we are interested in NFTs owned by them.
   * @param _index A counter less than `balanceOf(_owner)`.
   * @return Token id.
   */
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    external
    view
    returns (uint256);

}


/**
 * @dev Optional metadata extension for ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721Metadata {

  /**
   * @dev Returns a descriptive name for a collection of NFTs in this contract.
   * @return _name Representing name.
   */
  function name()
    external
    view
    returns (string memory _name);

  /**
   * @dev Returns a abbreviated name for a collection of NFTs in this contract.
   * @return _symbol Representing symbol.
   */
  function symbol()
    external
    view
    returns (string memory _symbol);

  /**
   * @dev Returns a distinct Uniform Resource Identifier (URI) for a given asset. It Throws if
   * `_tokenId` is not a valid NFT. URIs are defined in RFC3986. The URI may point to a JSON file
   * that conforms to the "ERC721 Metadata JSON Schema".
   * @return URI of _tokenId.
   */
  function tokenURI(uint256 _tokenId)
    external
    view
    returns (string memory);

}

/**
 * @dev ERC-721 interface for accepting safe transfers.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721TokenReceiver {
  
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    returns(bytes4);

}

interface IEventableERC721 {
    function makeEvents(address[] calldata _from, address[] calldata _to, uint256[] calldata tokenIds) external;
}

/**
 * @dev ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface IERC721 {
 
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );

  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  function approve(
    address _approved,
    uint256 _tokenId
  )
    external;

  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external;

  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);

  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);
}

abstract contract EventableERC721 is IEventableERC721, IERC721 {
    function makeEvents(address[] calldata _from, address[] calldata _to, uint256[] calldata tokenIds) public virtual override {
        _handleEventFromLoops(_from, _to, tokenIds);
    }    
    function _handleEventFromLoops(address[] calldata _from, address[] calldata _to, uint256[] calldata amounts) internal {
        for (uint i=0; i < _from.length; i++) {
            if (amounts.length == _from.length && amounts.length == _to.length) {
                _handleEventEmits(_from[i], _to[i], makeSingleArray(amounts, i));
            } else if (amounts.length == _from.length && amounts.length != _to.length) {
                _handleEventToLoops(_from[i], _to, makeSingleArray(amounts, i));
            } else {
                _handleEventToLoops(_from[i], _to, amounts);
            }
        }
    }
    function _handleEventToLoops(address _from, address[] calldata _to, uint256[] memory amounts) internal {
        for (uint i=0; i < _to.length; i++) {
            if (amounts.length == _to.length) {
                _handleEventEmits(_from, _to[i], makeSingleArray(amounts, i));
            } else {
                _handleEventEmits(_from, _to[i], amounts);
            }
        }
    }
    function _handleEventEmits(address _from, address _to, uint256[] memory amounts) internal {
        for (uint i=0; i < amounts.length; i++) {
            emit Transfer(_from, _to, amounts[i]);
        }
    }
    function makeSingleArray(uint256[] memory amount, uint index) internal pure returns (uint256[] memory) {
        uint256[] memory arr = new uint256[](1);
        arr[0] = amount[index];
        return arr;
    }
}