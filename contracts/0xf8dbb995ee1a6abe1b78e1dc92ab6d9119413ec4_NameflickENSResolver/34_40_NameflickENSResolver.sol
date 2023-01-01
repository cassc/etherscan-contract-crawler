// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*

  _  _                               __     _       _              _     
 | \| |   __ _    _ __     ___      / _|   | |     (_)     __     | |__  
 | .` |  / _` |  | '  \   / -_)    |  _|   | |     | |    / _|    | / /  
 |_|\_|  \__,_|  |_|_|_|  \___|   _|_|_   _|_|_   _|_|_   \__|_   |_\_\  
_|"""""|_|"""""|_|"""""|_|"""""|_|"""""|_|"""""|_|"""""|_|"""""|_|"""""| 
"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'                                                 
*/

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/ABIResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/AddrResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/ContentHashResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/DNSResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/InterfaceResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/NameResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/PubkeyResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/TextResolver.sol";
import "erc721a/contracts/interfaces/IERC721AQueryable.sol";
import "hardhat/console.sol";

import "./SignatureVerifier.sol";
import "./StringLib.sol";
import "./BytesLib.sol";

interface IExtendedResolver {
  function resolve(
    bytes calldata name,
    bytes calldata data
  ) external view returns (bytes memory);
}

// sighash of addr(bytes32)
bytes4 constant ADDR_ETH_INTERFACE_ID = 0x3b3b57de;
// sighash of addr(bytes32,uint)
bytes4 constant ADDR_INTERFACE_ID = 0xf1cb7e06;

uint256 constant COIN_TYPE_ETH = 60;

/**
 * Implements an ENS resolver that directs all queries to a CCIP read gateway.
 * Callers must implement EIP 3668 and ENSIP 10.
 */
contract NameflickENSResolver is IExtendedResolver, ERC165, Ownable {
  using StringLib for string;
  using BytesLib for bytes;

  /**
   * @dev the list of URLS to query for offchain resolution. The first URL is the primary URL, and the rest are fallbacks.
   */
  string[] public urls;
  /**
   * @dev the list of signers that can sign offchain resolution requests.
   */
  mapping(address => bool) public signers;
  /**
   * @dev tracks what contract is supported by a given namehash.
   */
  mapping(bytes32 => address) public nfts;
  /**
   * @dev tracks what coins (chains) are supported by a given contract + ENS combo. The format of the bytes32 is keccak256(abi.encodePacked(namehash, address, coinId))
   * This is used to determine if a given contract supports a given coin. Every supported combo will automatically return the owner of the NFT when requesting a sub-domain
   */
  mapping(bytes32 => bool) public nftOnCoin;

  /**
   * @dev the ENS registry
   */
  ENS immutable ens;
  /**
   * @dev the parent contract that owns this resolver. If 0x0, then this resolver is owned by the ENS registry. Allows another contract to proxy this resolver
   */
  address public parentContract;

  /**
   * @dev New signers have been added to sign offchain resolution
   */
  event NewSigners(address[] signers);
  /**
   * @dev Signers have been removed from signing offchain resolution
   */
  event RemoveSigners(address[] signers);
  /**
   * @dev A new URL list has been set to the list of URLs to query for offchain resolution
   */
  event NewURLs(string[] url);
  /**
   * @dev A new contract + namehash has been enabled for resolution
   */
  event EnableContractResolution(bytes32 name, address contractAddress);
  /**
   * @dev A contract + namehash has been disabled for resolution
   */
  event DisableContractResolution(bytes32 name);
  /**
   * @dev A contract + namehash has been registered for a set of coins
   */
  event RegisterContractCoin(
    bytes32 name,
    address contractAddress,
    uint256[] coins
  );
  /**
   * @dev A contract + namehash has been unregistered for a set of coins
   */
  event UnregisterContractCoin(
    bytes32 name,
    address contractAddress,
    uint256[] coins
  );
  /**
   * @dev An offchain resolution request has been made
   */
  error OffchainLookup(
    address sender,
    string[] urls,
    bytes callData,
    bytes4 callbackFunction,
    bytes extraData
  );

  /**
   * @dev The resolver supports the following interfaces:
   * - ERC165
   * - EIP 3668
   * - ENSIP 10
   * - ENSIP 11
   * - ENSIP 12
   * - ENSIP 13 (via ExtededResolver/ENSIP-10 and EIP-3668)
   *
   * @param _ens the ENS registry
   * @param _parentContract the parent contract that owns this resolver. If 0x0, then this resolver is owned by the ENS registry. Allows another contract to proxy this resolver
   * @param _urls the list of URLs to query for offchain resolution. The first URL is the primary URL, and the rest are fallbacks.
   * @param _signers the list of signers that can sign offchain resolution requests.
   */
  constructor(
    ENS _ens,
    address _parentContract,
    string[] memory _urls,
    address[] memory _signers
  ) {
    ens = _ens;
    parentContract = _parentContract;
    urls = _urls;
    for (uint256 i = 0; i < _signers.length; i++) {
      signers[_signers[i]] = true;
    }
    emit NewSigners(_signers);
    emit NewURLs(_urls);
  }

  /**
   * @dev Adds a list of signers to the list of signers that can sign offchain resolution requests
   * @param _signers the list of signers to add
   */
  function addSigners(address[] memory _signers) external onlyOwner {
    for (uint256 i = 0; i < _signers.length; i++) {
      signers[_signers[i]] = true;
    }
    emit NewSigners(_signers);
  }

  /**
   * @dev Removes a list of signers from the list of signers that can sign offchain resolution requests
   * @param _signers the list of signers to remove
   */
  function removeSigners(address[] memory _signers) external onlyOwner {
    for (uint256 i = 0; i < _signers.length; i++) {
      signers[_signers[i]] = false;
    }
    emit RemoveSigners(_signers);
  }

  /**
   * @dev Sets the list of URLs to query for offchain resolution
   * @param _urls the list of URLs to query for offchain resolution
   */
  function setUrls(string[] memory _urls) external onlyOwner {
    urls = _urls;
    emit NewURLs(_urls);
  }

  /**
   * @dev Converts an address to a bytes array
   * @param a the address to convert
   * @return b the bytes array
   */
  function addressToBytes(address a) internal pure returns (bytes memory b) {
    b = new bytes(20);
    assembly {
      mstore(add(b, 32), mul(a, exp(256, 12)))
    }
  }

  /**
   * @dev Checks an NFT contract to see if the given address is the owner of the given token ID
   * @param tokenId the token ID to check
   * @param nftContract the NFT contract to check
   * @return success if the call was successful
   * @return owner the owner of the NFT
   */
  function ownerOfNft(
    uint256 tokenId,
    address nftContract
  ) internal view returns (bool success, address payable owner) {
    bytes memory result;
    (success, result) = address(nftContract).staticcall(
      abi.encodeWithSignature("ownerOf(uint256)", tokenId)
    );
    if (success) {
      owner = abi.decode(result, (address));
    }
  }

  /**
   * @dev Checks an NFT contract to see if the given address is the owner of the given token ID
   * @param namehash the namehash to check
   * @param nftContract the NFT contract to check
   * @param coinId the coin ID to check
   * @return success if the call was successful
   */
  function isCoinSupportedByNft(
    bytes32 namehash,
    address nftContract,
    uint256 coinId
  ) internal view returns (bool success) {
    success = nftOnCoin[keccak256(abi.encode(namehash, nftContract, coinId))];
  }

  /**
   * @dev Returns the current parent contract that owns this resolver. If 0x0, then this resolver is owned by the ENS registry. Allows another contract to proxy this resolver
   * @return proxiedParentContract parent contract that owns this resolver, or self
   */
  function getParentContract()
    public
    view
    returns (address proxiedParentContract)
  {
    proxiedParentContract = parentContract == address(0)
      ? address(this)
      : parentContract;
  }

  /**
   * @dev Sets the parent contract that owns this resolver. If 0x0, then this resolver is owned by the ENS registry. Allows another contract to proxy this resolver
   */
  function setParentContract(address _parentContract) external onlyOwner {
    parentContract = _parentContract;
  }

  /**
   * @dev signals that the client should use the offchain lookup
   * @param name the DNS-encoded name to query
   * @param data the data to pass to the resolver
   */
  function revertOffchainLookup(
    bytes calldata name,
    bytes calldata data
  ) internal view {
    bytes memory callData = abi.encodeWithSelector(
      IExtendedResolver.resolve.selector,
      name,
      data
    );
    revert OffchainLookup(
      getParentContract(),
      urls,
      callData,
      NameflickENSResolver.resolveWithProof.selector,
      callData
    );
  }

  /**
   * Returns the address associated with an ENS node.
   * @param coinId The coin type to query.
   * @param node The ENS node that owns the resolver.
   * @param name The DNS-encoded name to query.
   * @param data The data to pass to the resolver.
   * @param nft The NFT contract to query.
   * @return owner The associated address.
   */
  function addr(
    uint256 coinId,
    bytes32 node,
    bytes calldata name,
    bytes calldata data,
    address nft
  ) public view returns (address payable owner) {
    if (!isCoinSupportedByNft(node, nft, coinId)) {
      revertOffchainLookup(name, data);
    }
    // get the tokenID from the sub-domain label in name
    (bool success, uint256 tokenId) = name.getNodeString(0).toUint();
    if (!success) {
      revertOffchainLookup(name, data);
    }
    (success, owner) = ownerOfNft(tokenId, nft);
    if (!success) {
      revertOffchainLookup(name, data);
    }
  }

  /**
   * Resolves a name, as specified by ENSIP 10.
   * @param name The DNS-encoded name to resolve.
   * @param data The ABI encoded data for the underlying resolution function (Eg, addr(bytes32), text(bytes32,string), etc).
   * @return bytes return data, ABI encoded identically to the underlying function.
   */
  function resolve(
    bytes calldata name,
    bytes calldata data
  ) external view override returns (bytes memory) {
    // Get the parent node
    bytes32 parentNode = name.namehash(uint8(name[0]) + 1);
    if (nfts[parentNode] != address(0)) {
      address nft = nfts[parentNode];
      // First check if this is a request for addr(bytes32,uint) or addr(bytes32)
      // If it is, we can return the owner of the NFT
      bytes4 selector = data.getBytes4(0);
      bytes32 node = name.getENSDomainComponent(1).namehash(0);
      if (selector == ADDR_ETH_INTERFACE_ID) {
        address owner = addr(COIN_TYPE_ETH, node, name, data, nft);
        return addressToBytes(owner);
      } else if (selector == ADDR_INTERFACE_ID) {
        // When calling addr(bytes32,uint), the second parameter is the coin ID
        // So we only return the ownerOf if the
        uint256 coinId = uint256(data.getBytes32(36));
        address owner = addr(coinId, node, name, data, nft);
        return addressToBytes(owner);
      } else if (selector == TextResolver.text.selector) {
        (, string memory textRecord) = abi.decode(data[4:], (bytes32, string));
        if (textRecord.equals("avatar")) {
          // get the tokenID from the sub-domain label in name
          string memory subdomain = name.getNodeString(0);
          (bool success, uint256 tokenId) = subdomain.toUint();

          if (!success) {
            revertOffchainLookup(name, data);
          }
          address owner;
          // Checks if the NFT is valid...
          (success, owner) = ownerOfNft(tokenId, nft);
          if (!success) {
            revertOffchainLookup(name, data);
          }
          bytes memory record = abi.encodePacked(
            "eip155:1/erc721:",
            Strings.toHexString(uint256(uint160(nft))),
            "/",
            subdomain
          );
          return record;
        }
      }
    }
    revertOffchainLookup(name, data);
  }

  /**
   * @dev Callback used by CCIP read compatible clients to verify and parse the response.
   * @param response The response from the resolver.
   * @param extraData The extra data that was passed to the resolver.
   */
  function resolveWithProof(
    bytes calldata response,
    bytes calldata extraData
  ) external view returns (bytes memory) {
    (address signer, bytes memory result) = SignatureVerifier.verify(
      getParentContract(),
      extraData,
      response
    );
    require(signers[signer], "SignatureVerifier: Invalid sigature");
    return result;
  }

  /**
   * @dev EIP-165 interface support.
   */
  function supportsInterface(
    bytes4 interfaceID
  ) public view override returns (bool) {
    return
      interfaceID == type(IExtendedResolver).interfaceId ||
      super.supportsInterface(interfaceID);
  }

  /**
   * @dev Controls whether a contract must be registered by the owner of the contract.
   */
  bool public requireContractOwnershipToRegister = false;

  /**
   * @dev Controls whether a contract must be registered by the owner of the contract.
   * @param _requireContractOwnership Whether to require contract ownership.
   */
  function setRequireContractOwnershipToRegister(
    bool _requireContractOwnership
  ) external onlyOwner {
    requireContractOwnershipToRegister = _requireContractOwnership;
  }

  /**
   * @dev Registers a contract for a given namehash.
   * @param namehash The namehash of the node.
   * @param contractAddress The address of the contract.
   * @param supportedCoinsFromEth The supported coins from eth.
   */
  function registerContract(
    bytes32 namehash,
    address contractAddress,
    uint256[] calldata supportedCoinsFromEth
  ) external onlyNodeAuthorized(namehash) onlyOwnsContract(contractAddress) {
    nfts[namehash] = contractAddress;
    emit EnableContractResolution(namehash, contractAddress);
    for (uint256 i = 0; i < supportedCoinsFromEth.length; i++) {
      nftOnCoin[
        keccak256(
          abi.encode(namehash, contractAddress, supportedCoinsFromEth[i])
        )
      ] = true;
    }
    emit RegisterContractCoin(namehash, contractAddress, supportedCoinsFromEth);
  }

  /**
   * @dev Disables a contract for a given namehash.
   * @param namehash The namehash of the node.
   */
  function disableContract(
    bytes32 namehash
  ) external onlyNodeAuthorized(namehash) {
    nfts[namehash] = address(0);
    emit DisableContractResolution(namehash);
  }

  /**
   * @dev Disables a contract for a given namehash.
   * @param namehash The namehash of the node.
   * @param contractAddress The address of the contract.
   * @param coins The coins to disable.
   */
  function disableCoinForContract(
    bytes32 namehash,
    address contractAddress,
    uint256[] calldata coins
  ) external onlyNodeAuthorized(namehash) {
    for (uint256 i = 0; i < coins.length; i++) {
      delete nftOnCoin[
        keccak256(abi.encode(namehash, contractAddress, coins[i]))
      ];
    }
    emit UnregisterContractCoin(namehash, contractAddress, coins);
  }

  /**
   * @dev Reverts if the caller does not own the contract and requireContractOwnershipToRegister is true.
   * @param contractAddress The contract address.
   */
  modifier onlyOwnsContract(address contractAddress) {
    if (requireContractOwnershipToRegister) {
      require(
        Ownable(contractAddress).owner() == msg.sender,
        "Caller not owner of contract"
      );
    }
    _;
  }

  /**
   * @dev Reverts if the caller does not own the ENS node.
   * @param namehash The ENS node.
   */
  modifier onlyNodeAuthorized(bytes32 namehash) {
    require(
      ens.owner(namehash) == msg.sender ||
        ens.isApprovedForAll(ens.owner(namehash), msg.sender),
      "Caller does not own ENS node"
    );
    _;
  }
}