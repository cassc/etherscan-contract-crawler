// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// Version: 1.1
contract DropKitERC721A is ERC721A, Ownable {

  uint256 private immutable _collectionSize;
  /**
    * @dev the optimal number for balancing mint to transfer is 8
    * https://github.com/chiru-labs/ERC721A/issues/145
    */ 
  uint256 private immutable _maxBatchSize;
  string private _baseURIextended;
  address payable private immutable _royaltyReceiver;
  uint256 private immutable _royaltyBPS;

  constructor(
    string memory contractName,
    string memory tokenSymbol,
    uint256 maxBatchSize_,
    uint256 collectionSize_,
    string memory baseURI_,
    address payable royaltyReceiver_,
    uint256 royaltyBPS_
  ) ERC721A(contractName, tokenSymbol) {
    require(
      collectionSize_ > 0,
      "ERC721A: collection must have a nonzero supply"
    );
    require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");

    require(maxBatchSize_ < collectionSize_, "ERC721A: max batch size must be lower than collection size");
    require(royaltyBPS_ >= 0, "ERC721A: Royalties cannot be lower than 0");
    
    _baseURIextended = baseURI_;
    _maxBatchSize = maxBatchSize_;
    _collectionSize = collectionSize_;
    _royaltyReceiver = royaltyReceiver_;
    _royaltyBPS = royaltyBPS_;
  }

  function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

  function mint(uint256 quantity, address buyer) external onlyOwner {
    require(
      totalSupply() + quantity <= _collectionSize,
      "Mint quantity exceeds collection size"
    );

    require(
         quantity <= _maxBatchSize,
          "Mint quantity exceeds max batch size"
        );

    _safeMint(buyer, quantity);
  }

  function burn(uint256 tokenId) external {
    _burn(tokenId, true);
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseURIextended;
  }

  // ROYALTIES

  /**
     *  @dev Rarible: RoyaltiesV1
     *
     *  bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *  bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     *
     *  => 0xb9c4d9fb ^ 0x0ebd4c7f = 0xb7799584
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    /**
     *  @dev Foundation
     *
     *  bytes4(keccak256('getFees(uint256)')) == 0xd5a06d4c
     *
     *  => 0xd5a06d4c = 0xd5a06d4c
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_FOUNDATION = 0xd5a06d4c;

    /**
     *  @dev EIP-2981
     *
     * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     *
     * => 0x2a55205a = 0x2a55205a
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;

    /**
     * @dev 3rd party Marketplace Royalty Support
     */

    /**
     * @dev IFoundation
     */
    function getFees(uint256 tokenId)
        external
        view
        virtual
        returns (address payable[] memory, uint256[] memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        address payable[] memory receivers = new address payable[](1);
        uint256[] memory bps = new uint256[](1);
        receivers[0] = _getReceiver();
        bps[0] = _getBps();
        return (receivers, bps);
    }

    /**
     * @dev IRaribleV1
     */
    function getFeeRecipients(uint256 tokenId)
        external
        view
        virtual
        returns (address payable[] memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        address payable[] memory receivers = new address payable[](1);
        receivers[0] = _getReceiver();
        return receivers;
    }

    function getFeeBps(uint256 tokenId)
        external
        view
        virtual
        returns (uint256[] memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        uint256[] memory bps = new uint256[](1);
        bps[0] = _getBps();
        return bps;
    }

    /**
     * @dev EIP-2981
     * Returns primary receiver i.e. receivers[0]
     */
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        virtual
        returns (address, uint256)
    {
        require(_exists(tokenId), "Nonexistent token");
        return _getRoyaltyInfo(value);
    }

    function _getRoyaltyInfo(uint256 value)
        internal
        view
        returns (address receiver, uint256 amount)
    {
        address _receiver = _getReceiver();
        uint256 _bps = _getBps();
        return (_receiver, (_bps * value) / 10000);
    }

    function _getBps() internal view returns (uint256) {
        return _royaltyBPS;
    }

    function _getReceiver()
        internal
        view
        returns (address payable)
    {
        return _royaltyReceiver;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            _supportsRoyaltyInterfaces(interfaceId);
    }

    function _supportsRoyaltyInterfaces(bytes4 interfaceId)
        private
        pure
        returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE ||
            interfaceId == _INTERFACE_ID_ROYALTIES_FOUNDATION ||
            interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981;
    }
}