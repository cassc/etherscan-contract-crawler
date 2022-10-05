// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


/// @title Interface of the mintng contract
/// @author Martin Wawrusch
interface IMintDirect {
  function mintDirect(address to, uint256 quantity) external;

  function balanceOf(address owner) external  view returns (uint256);
  function totalSupply() external view returns (uint256);
}


/// @title Paid Minter
/// @author Martin Wawrusch
/// @notice This contract allows any allowlisted address to mint maxMintPerAddress number of 
/// @custom:security-contact [email protected]
contract Minter is Ownable, Pausable {
    using ECDSA for bytes32;
    using SafeMath for uint256;

    // The key used to sign allowlist signatures.
    // We will check to ensure that the key that signed the signature
    // is this one that we expect.
    address allowlistSigningAddress = address(0);

    uint256 public price;
    uint256 public availableSupply;

    mapping(address => bool) public claimedNFTs;
    address public nftContract;

    uint256 public maxMintPerAddress = 1;


    // Domain Separator is the EIP-712 defined structure that defines what contract
    // and chain these signatures can be used for.  This ensures people can't take
    // a signature used to mint on one contract and use it for another, or a signature
    // from testnet to replay on mainnet.
    // It has to be created in the constructor so we can dynamically grab the chainId.
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-domainseparator
    bytes32 public DOMAIN_SEPARATOR;

    // The typehash for the data type specified in the structured data
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#rationale-for-typehash
    // This should match whats in the client side allowlist signing code
    // https://github.com/msfeldstein/EIP712-allowlisting/blob/main/test/signWhitelist.ts#L22
    bytes32 public constant MINTER_TYPEHASH =
        keccak256("Minter(address wallet)");

    constructor(uint256 price_,
                uint256 maxMintPerAddress_,
                uint256 availableSupply_,
                address nftContract_,
                string memory domainVerifierAppName_,
                string memory domainVerifierAppVersion_,
                address allowlistSigningAddress_) {

        // This should match whats in the client side allowlist signing code
        // https://github.com/msfeldstein/EIP712-allowlisting/blob/main/test/signWhitelist.ts#L12
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                // This should match the domain you set in your client side signing.
                keccak256(bytes(domainVerifierAppName_)), // "WhitelistToken"
                keccak256(bytes(domainVerifierAppVersion_)), // "1"
                block.chainid,
                address(this)
            )
        );

        nftContract = nftContract_;
        allowlistSigningAddress = allowlistSigningAddress_;
        availableSupply = availableSupply_;
        price = price_;        
        maxMintPerAddress = maxMintPerAddress_;
    }


    /// @notice Mints numberOfTokens amount of tokens to address.
    function mint( bytes calldata signature) external payable requiresAllowlist(signature) whenNotPaused() {
      require(nftContract != address(0), "nftContract is null");
      require(!claimedNFTs[msg.sender], "Already claimed");
      require(msg.value >= price, "Insufficient payment");
      require(availableSupply > 0, "Not enough tokens left");
      //will never underflow
      unchecked {
        --availableSupply;
      }
      claimedNFTs[msg.sender] = true;
      IMintDirect(nftContract).mintDirect(msg.sender, 1);
   }


    function setAllowlistSigningAddress(address newSigningAddress) public onlyOwner {
        allowlistSigningAddress = newSigningAddress;
    }

    modifier requiresAllowlist(bytes calldata signature) {
        require(allowlistSigningAddress != address(0), "allowlist not enabled");
        // Verify EIP-712 signature by recreating the data structure
        // that we signed on the client side, and then using that to recover
        // the address that signed the signature for this data.
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(MINTER_TYPEHASH, msg.sender))
            )
        );
        // Use the recover method to see what address was used to create
        // the signature on this data.
        // Note that if the digest doesn't exactly match what was signed we'll
        // get a random recovered address.
        address recoveredAddress = digest.recover(signature);
        require(recoveredAddress == allowlistSigningAddress, "Invalid Signature");
        _;
    }


    /// @notice Pass-Through to not have to modify the minting client
    function totalSupply() public view virtual returns (uint256) {
        return IMintDirect(nftContract).totalSupply();
    }

    /// @notice Pass-Through to not have to modify the minting client
    function balanceOf(address owner) public view virtual returns (uint256) {
        return IMintDirect(nftContract).balanceOf(owner);
    }

    /// @notice sets the price in gwai for a single nft sale. 
    function setPrice(uint256 price_) public onlyOwner {
        price = price_;
    }

    /// @notice sets the availableSupply. 
    function setAvailableSupply(uint256 availableSupply_) public onlyOwner {
        availableSupply = availableSupply_;
    }


    /// @notice sets the maxMintPerAddress. 
    function setMaxMintPerAddress(uint256 maxMintPerAddress_) public onlyOwner {
        maxMintPerAddress = maxMintPerAddress_;
    }

    /// @notice Fund withdrawal for owner.
    function withdraw() public onlyOwner {
      payable(msg.sender).transfer(address(this).balance); 
    }
     
    /// @notice Pauses this contract
    /// Requires owner privileges
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses this contract
    /// Requires owner privileges
    function unpause() public onlyOwner {
        _unpause();
    }


    /// @notice Pass-Through to not have to modify the minting client
    function tokenClaimed(address owner) public view virtual returns (bool) {
        return claimedNFTs[owner];
    }

}