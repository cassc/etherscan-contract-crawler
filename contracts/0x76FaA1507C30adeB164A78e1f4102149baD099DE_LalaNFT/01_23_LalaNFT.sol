// SPDX-License-Identifier: MIT
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol'; // signatures
import '@openzeppelin/contracts/access/AccessControl.sol'; // roles
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol'; // a standard for royalties that may in the future be widely supported
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol';
import './lib/LibPart.sol';
import './lib/LibRoyaltiesV2.sol';
import './lib/RoyaltiesV2.sol';
import './lib/ILalaRevenue.sol';

pragma solidity ^0.8.9;

contract LalaNFT is
  ERC721Pausable,
  EIP712,
  AccessControl,
  IERC2981,
  RoyaltiesV2,
  ILalaRevenue
{
  using ECDSA for bytes32;
  using Strings for uint256;
  using Address for address payable;
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  string private _URI; // base URI
  bytes private _encyptedURI; // encypted base URI
  string private _contractURI; // Contract-level metadata
  uint256 private _totalShares; // how many holders we have in the shares array
  Share[] private _shares; // array of shares per token
  uint16 public _soldShares; // 0-100*100, when 100*100 no more tokens can be issued anymore

  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE'); // role responsible for giving out the vouchers
  bytes32 public constant MAINTAINER_ROLE = keccak256('MAINTAINER_ROLE'); // role responsible for updating contract data

  address payable _merchant; // the address receiving the funds flying into this contract

  mapping(uint256 => LibPart.Part[]) internal _royalties; // map from token -> royalties
  mapping(address => address) internal _royaltyOverride; // map from compromised wallet -> new wallet

  event ContractURIChanged(string contractURI);
  event RoyaltyOverrideChanged(address oldAccount, address newAccount);
  event RoyaltyOverrideRemoved(address account);

  constructor(
    address minter,
    address payable merchant,
    string memory uri, // base URI
    bytes memory encypted_uri, // encypted base URI
    string memory contract_uri, // Contract-level metadata
    string memory name, // name of the pool
    string memory symbol_name, // what the ERC721 token will be called
    string memory version // e.g. "1"
  ) ERC721(name, symbol_name) EIP712(name, version) {
    _merchant = merchant;
    _URI = uri;
    _encyptedURI = encypted_uri;
    _contractURI = contract_uri;
    _totalShares = 0;
    _soldShares = 0;

    _setupRole(MINTER_ROLE, minter);
    _setupRole(MAINTAINER_ROLE, minter);
    _setupRole(MAINTAINER_ROLE, _msgSender());
  }

  // represents an un-minted NFT, which has not yet been recorded into the blockchain.
  // a signed voucher can be redeemed for a real NFT using the redeem function.
  struct NFTVoucher {
    uint256 tokenId; // must be unique - if another token with this ID already exists, the redeem function will revert
    uint256 price;
    uint16 share; // 0-100 %, scaled up to 0/10000
    address buyer; // the wallet that this voucher is for
    LibPart.Part[] royalties; // array of associated royalties ({account, value}[])
  }

  // represents a bought share of the total revenue stream
  struct Share {
    uint16 share; // from 0-100 %, scaled to 0/10000
    uint256 tokenId;
  }

  // Returns the Uniform Resource Identifier (URI) for `tokenId` token
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), 'ERC721: invalid token ID');

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), '.json'))
        : '';
  }

  // Returns the Uniform Resource Identifier (URI) for computing {tokenURI}
  function _baseURI() internal view virtual override returns (string memory) {
    return _URI;
  }

  // Returns a URL for the storefront-level metadata for your contract.
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string memory contractURI_)
    public
    onlyRole(MAINTAINER_ROLE)
  {
    _contractURI = contractURI_;

    emit ContractURIChanged(contractURI_);
  }

  // Redeems an NFTVoucher for an actual NFT, creating it in the process.
  function redeem(
    NFTVoucher calldata voucher, // an NFTVoucher that describes the NFT to be redeemed.
    bytes memory signature // an EIP712 signature of the voucher, produced by the NFT creator.
  ) public payable returns (uint256) {
    // make sure signature is valid and get the address of the signer
    address signer = _verify(voucher, signature);

    require(voucher.share + _soldShares <= 10000, 'No more shares available');

    // make sure that the signer is authorized to mint NFTs
    require(hasRole(MINTER_ROLE, signer), 'Signature invalid or unauthorized');

    // make sure that the redeemer is paying enough to cover the buyer's cost
    require(msg.value >= voucher.price, 'Insufficient funds to redeem');

    // make sure the voucher was created for sender's wallet
    require(
      msg.sender == voucher.buyer,
      'Voucher is issued for a different wallet'
    );

    // add share to total share sum
    _soldShares = _soldShares + voucher.share;
    Share memory share = Share(voucher.share, voucher.tokenId);
    _shares.push(share);
    _totalShares = _totalShares + 1;

    // handle royalties
    uint16 royaltiesSum = 0;
    LibPart.Part[] storage tokenRoyalties = _royalties[voucher.tokenId];
    uint8 royaltiesLength = uint8(voucher.royalties.length);

    for (uint8 i = 0; i < royaltiesLength; ++i) {
      tokenRoyalties.push(voucher.royalties[i]);
      royaltiesSum += uint16(voucher.royalties[i].value);

      // update royalty overrides
      if (royaltyOverrideOf(tokenRoyalties[i].account) != address(0)) {
        tokenRoyalties[i].account = payable(
          royaltyOverrideOf(tokenRoyalties[i].account)
        );
      }
    }
    require(royaltiesSum <= 10000, 'Royalties cannot be more than 100%');

    // first assign the token to the merchant, to establish provenance on-chain
    _mint(_merchant, voucher.tokenId);

    for (uint8 i = 0; i < royaltiesLength; ++i) {
      // transfer all royalties first
      uint256 royaltyAmount = (msg.value * voucher.royalties[i].value) / 10000;
      address payable royaltyAccount = payable(voucher.royalties[i].account);
      royaltyAccount.transfer(royaltyAmount);
    }

    // transfer the token to the redeemer
    _transfer(_merchant, msg.sender, voucher.tokenId);

    // transfer payment to merchant, everything except the royalties
    uint256 remainingAmount = ((10000 - royaltiesSum) * msg.value) / 10000;
    _merchant.transfer(remainingAmount);

    return voucher.tokenId;
  }

  // Verifies the signature for a given NFTVoucher, returning the address of the signer.
  // Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
  function _verify(
    NFTVoucher calldata voucher, // an NFTVoucher describing an unminted NFT.
    bytes memory signature // an EIP712 signature of the given voucher.
  ) private view returns (address) {
    bytes32 digest = _hash(voucher);
    return digest.toEthSignedMessageHash().recover(signature);
  }

  // Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
  function _hash(NFTVoucher calldata voucher) private view returns (bytes32) {
    bytes32[] memory royaltyHashArray = new bytes32[](voucher.royalties.length);

    for (uint256 i = 0; i < voucher.royalties.length; i++) {
      royaltyHashArray[i] = LibPart.hash(voucher.royalties[i]);
    }

    return
      _hashTypedDataV4(
        keccak256(
          abi.encode(
            keccak256(
              'NFTVoucher(uint256 tokenId,uint256 price,uint16 share,address buyer,Part[] royalties)Part(address account,uint96 value)'
            ),
            voucher.tokenId,
            voucher.price,
            voucher.share,
            voucher.buyer,
            keccak256(abi.encodePacked(royaltyHashArray))
          )
        )
      );
  }

  // -------------------- Revenue distribution -------------------- //

  // Returns the revenue distribution for a given amount of revenue. The returned array contains the addresses of the shareholders and the amount of revenue to be distributed to each shareholder.
  // The amount of revenue to be distributed to each shareholder is calculated by multiplying the total amount of revenue by the share of each shareholder.
  // ammount parameter is in USDC (6 decimals) i.e. 1000000 = 1 USDC
  function getDistribution(uint256 amount)
    external
    view
    returns (DistributionShare[] memory)
  {
    DistributionShare[] memory values = new DistributionShare[](_totalShares);
    for (uint256 i = 0; i < _totalShares; i++) {
      Share memory share = _shares[i];
      // tokens are sold, so we need to call ownerOf
      address shareholder = ownerOf(share.tokenId);
      uint256 shareAmount = (amount * share.share) / 10000;

      values[i] = DistributionShare(shareholder, shareAmount);
    }
    return values;
  }

  // -------------------- Delayed drop reveal -------------------- //

  // Lets an account with `MAINTAINER_ROLE` role reveal the NFT drop
  function reveal(bytes calldata key)
    external
    onlyRole(MAINTAINER_ROLE)
    returns (string memory)
  {
    require(_encyptedURI.length > 0, 'Encrypted URI is not set');

    _URI = string(encryptDecrypt(_encyptedURI, key));

    return _URI;
  }

  // See: https://ethereum.stackexchange.com/questions/69825/decrypt-message-on-chain
  function encryptDecrypt(bytes memory data, bytes calldata key)
    private
    pure
    returns (bytes memory result)
  {
    // Store data length on stack for later use
    uint256 length = data.length;

    assembly {
      // Set result to free memory pointer
      result := mload(0x40)
      // Increase free memory pointer by lenght + 32
      mstore(0x40, add(add(result, length), 32))
      // Set result length
      mstore(result, length)
    }

    // Iterate over the data stepping by 32 bytes
    for (uint256 i = 0; i < length; i += 32) {
      // Generate hash of the key and offset
      bytes32 hash = keccak256(abi.encodePacked(key, i));

      bytes32 chunk;
      assembly {
        // Read 32-bytes data chunk
        chunk := mload(add(data, add(i, 32)))
      }
      // XOR the chunk with hash
      chunk ^= hash;
      assembly {
        // Write 32-byte encrypted chunk
        mstore(add(result, add(i, 32)), chunk)
      }
    }
  }

  // -------------------- Resell royalties -------------------- //

  // necessary override
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControl, ERC721, IERC165)
    returns (bool)
  {
    if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
      return true;
    }
    if (interfaceId == _INTERFACE_ID_ERC2981) {
      return true;
    }
    return super.supportsInterface(interfaceId);
  }

  // Returns token royalties with royalty overrides
  function getRoyalties(uint256 tokenId)
    public
    view
    returns (LibPart.Part[] memory)
  {
    LibPart.Part[] memory tokenRoyalties = _royalties[tokenId];

    // check royalty overrides
    for (uint256 i = 0; i < tokenRoyalties.length; ++i) {
      if (royaltyOverrideOf(tokenRoyalties[i].account) != address(0)) {
        tokenRoyalties[i].account = payable(
          royaltyOverrideOf(tokenRoyalties[i].account)
        );
      }
    }

    return tokenRoyalties;
  }

  // really the only function IERC2981 standard defines;
  // only supports one royalty per token
  function royaltyInfo(
    uint256 tokenId,
    uint256 salePrice // whatever the unit, we just return the percentage of royalty
  ) external view override returns (address receiver, uint256 royaltyAmount) {
    LibPart.Part[] memory tokenRoyalties = getRoyalties(tokenId);

    // if there are no royalties
    if (tokenRoyalties.length == 0) {
      // no receiver and no amount
      return (address(0), 0);
    }

    uint256 royalties;
    for (uint256 i = 0; i < tokenRoyalties.length; ++i) {
      // calculate royalties via the percentages
      royalties += (salePrice * tokenRoyalties[i].value) / 10000;
    }

    return (tokenRoyalties[0].account, royalties);
  }

  // special function for rarible royalties - the only one their contract needs;
  // supports multiple royalties per token
  function getRaribleV2Royalties(uint256 tokenId)
    external
    view
    override
    returns (LibPart.Part[] memory)
  {
    return getRoyalties(tokenId);
  }

  // Return royalty override for an account
  function royaltyOverrideOf(address account) public view returns (address) {
    address overrideAddress = _royaltyOverride[account];

    while (_royaltyOverride[overrideAddress] != address(0)) {
      overrideAddress = _royaltyOverride[overrideAddress];
    }

    return overrideAddress;
  }

  // Lets an account with `MAINTAINER_ROLE` set the royalty override
  function setRoyaltyOverride(address oldAccount, address newAccount)
    external
    onlyRole(MAINTAINER_ROLE)
  {
    require(
      _royaltyOverride[newAccount] == address(0),
      'Royalty override for new address already exists.'
    );

    _royaltyOverride[oldAccount] = newAccount;

    emit RoyaltyOverrideChanged(oldAccount, newAccount);
  }

  // Lets an account with `MAINTAINER_ROLE` remove the royalty override
  function removeRoyaltyOverride(address account)
    external
    onlyRole(MAINTAINER_ROLE)
  {
    delete _royaltyOverride[account];

    emit RoyaltyOverrideRemoved(account);
  }

  // -------------------- Pausable token transfers -------------------- //

  // Lets an account with `MAINTAINER_ROLE` pauses all token transfers.
  function pause() public virtual onlyRole(MAINTAINER_ROLE) {
    _pause();
  }

  // Lets an account with `MAINTAINER_ROLE` unpauses all token transfers.
  function unpause() public virtual onlyRole(MAINTAINER_ROLE) {
    _unpause();
  }
}