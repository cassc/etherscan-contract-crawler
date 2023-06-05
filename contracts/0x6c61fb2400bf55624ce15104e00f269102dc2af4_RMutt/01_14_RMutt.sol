// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


/**
 * Used to delegate ownership of a contract to another address,
 * to save on unneeded transactions to approve contract use for users
 */
contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract RMutt is ERC721A, Ownable {
    using SafeMath for uint256;

    enum MintPhase {
        RESERVED_PUBLIC, // 1 - public can mint, but some supply reserved for holders
        PUBLIC           // 2 - no requirements, public can mint, including reserves
    }

    mapping(address => bool) public proxyApproved;       // proxy accounts for easy listing
    mapping(address => uint256) public publicBalance;    // owned amounts for public mint
    mapping(address => uint256) public reserveBalance;   // owned amounts for reserve mint

    bytes32 public merkleRoot;                     // root merkle proof hash
    bool public merkleSet = false;                 // if contract merkle setup
    bool public mintingIsActive = false;           // control if mints can proceed
    bool public reservedTokens = false;            // if team has minted tokens already
    uint256 public constant maxSupply = 2048;      // total supply
    uint256 public constant maxMint = 5;           // max per mint (non-holders)
    uint256 public constant maxWallet = 5;         // max per wallet (non-holders)
    uint256 public constant teamReserve = 48;      // amount to mint to the team
    uint256 public reservedSupply;                 // supply to be reserved temporarily for holders
    uint256 public reserveMinted;                  // track amounts minted from reserves
    uint256 public publicMinted;                   // track amounts minted from public
    uint256 public startTime;                      // timestamp when minting begins to track hours between phases
    uint256 public reserveTime;                    // timestamp when reserves allowed to be minted
    address public immutable proxyRegistryAddress; // primary proxy address (opensea)
    string public baseURI;                         // base URI of hosted IPFS assets
    string public _contractURI;                    // contract URI for details

    constructor(
        address _proxyRegistryAddress
    ) ERC721A("RMutt", "MUT") {
        proxyRegistryAddress = _proxyRegistryAddress;
        reserveTokens();            // reserve tokens for team
    }

    // Show contract URI
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    // Return number of seconds since we started the initial timer (startTime)
    function getTimeElapsed() public view returns (uint256 ts) {
        if (startTime > 0) {
            return block.timestamp - startTime;
        }
        return 0;
    }

    // Return number of seconds until next phase of minting begins
    function getTimeUntilNextPhase() public view returns (uint256 ts) {
        if (block.timestamp < reserveTime) {
            return reserveTime - block.timestamp;
        }
        return 0;
    }

    // Get mint phase based upon time elapsed
    function getMintPhase() public view returns (MintPhase phase) {
        if (startTime > 0) {
            if (block.timestamp < reserveTime) {
                return MintPhase.RESERVED_PUBLIC;
            } else {
                return MintPhase.PUBLIC;
            }
        }
        return MintPhase.RESERVED_PUBLIC;
    }

    // Withdraw contract balance to creator (mnemonic seed address 0)
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Flip the minting from active or paused
    function toggleMinting() external onlyOwner {
        if (startTime == 0) {
            // Update phase times when we first toggle minting
            startTime = block.timestamp;
            reserveTime = startTime + 48 hours;
        }
        mintingIsActive = !mintingIsActive;
    }

    // Flip the proxy approval state for a given address
    function toggleProxyState(address proxyAddress) external onlyOwner {
        proxyApproved[proxyAddress] = !proxyApproved[proxyAddress];
    }

    // Specify a new IPFS URI for token metadata
    function setBaseURI(string memory URI) external onlyOwner {
        baseURI = URI;
    }

    // Specify a new contract URI
    function setContractURI(string memory URI) external onlyOwner {
        _contractURI = URI;
    }

    // Specify the reserved supply
    function setReservedSupply(uint256 s) external onlyOwner {
        reservedSupply = s;
    }

    // Specify a merkle root hash from the gathered k/v dictionary of
    // addresses and their claimable amount of tokens - thanks Kiwi!
    // https://github.com/0xKiwi/go-merkle-distributor
    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
        merkleSet = true;
    }

    // Reserve some tokens for giveaways
    function reserveTokens() public onlyOwner {
        // Only allow one-time reservation of tokens
        if (!reservedTokens) {
            _mintTokens(teamReserve, false);
            reservedTokens = true;
        }
    }

    // Internal mint function
    function _mintTokens(uint256 numberOfTokens, bool isReserve) private {
        require(numberOfTokens > 0, "Must mint at least 1 token.");

        // Mint number of tokens requested
        _safeMint(msg.sender, numberOfTokens);

        if (isReserve) {
          reserveMinted = reserveMinted.add(numberOfTokens);
        } else {
          publicMinted = publicMinted.add(numberOfTokens);
        }

        // Disable minting if max supply of tokens is reached
        if (totalSupply() == maxSupply) {
            mintingIsActive = false;
        }
    }

    // Mint public
    function mintPublic(uint256 numberOfTokens) external payable {
        require(mintingIsActive, "Minting is not active.");
        require(reservedSupply > 0, "Reserved supply must be set by contract owner");
        require(numberOfTokens <= maxMint, "Cannot mint more than 5 during mint.");
        require(publicBalance[msg.sender].add(numberOfTokens) <= maxWallet, "Cannot mint more than 5 per wallet.");

        if (getMintPhase() == MintPhase.PUBLIC) {
            require(totalSupply().add(numberOfTokens) <= maxSupply, "Minting would exceed max supply.");
        } else {
            uint256 publicSupply = maxSupply.sub(reservedSupply);
            require(publicMinted.add(numberOfTokens) <= publicSupply, "Minting would exceed public supply.");
        }

        _mintTokens(numberOfTokens, false);

        // Track token balances during public
        publicBalance[msg.sender] = publicBalance[msg.sender].add(numberOfTokens);
    }

    // Mint reserve
    function mintReserve(
      uint256 index,
      address account,
      uint256 whitelistedAmount,
      bytes32[] calldata merkleProof,
      uint256 numberOfTokens
    ) external payable {
        require(mintingIsActive, "Minting is not active.");
        require(reservedSupply > 0, "Reserved supply must be set by contract owner");
        require(totalSupply().add(numberOfTokens) <= maxSupply, "Minting would exceed max supply.");
        require(getMintPhase() == MintPhase.RESERVED_PUBLIC, "Can only mint reserved tokens during first 48 hours.");
        require(reserveMinted.add(numberOfTokens) <= reservedSupply, "Minting would exceed reserved supply.");
        require(reserveBalance[msg.sender].add(numberOfTokens) <= whitelistedAmount, "Cannot mint more than the amount whitelisted for.");

        // Merkle checks
        require(merkleSet, "Merkle root not set by contract owner.");
        require(msg.sender == account, "Can only be claimed by the whitelisted address.");
        bytes32 node = keccak256(abi.encodePacked(index, account, whitelistedAmount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "Invalid merkle proof.");

        _mintTokens(numberOfTokens, true);

        // Track token balances during reserve
        reserveBalance[msg.sender] = reserveBalance[msg.sender].add(numberOfTokens);
    }

    /*
     * Override the below functions from parent contracts
     */

    // Always return tokenURI, even if token doesn't exist yet
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    // Whitelist proxy contracts for easy trading on platforms (Opensea is default)
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override(ERC721A)
        returns (bool isOperator)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator || proxyApproved[_operator]) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }
}