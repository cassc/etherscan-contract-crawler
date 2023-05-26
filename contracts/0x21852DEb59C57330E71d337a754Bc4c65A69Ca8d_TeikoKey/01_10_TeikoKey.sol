// SPDX-License-Identifier: MIT

// @title Teiko Key for Teiko World
// @author TheV

//                                                                                                                       _________________________ 
// [... [......[........[..[..   [..      [....          [..        [..    [....     [.......    [..      [.....        ///      __       __      \
//      [..    [..      [..[..  [..     [..    [..       [..        [..  [..    [..  [..    [..  [..      [..   [..    |||      |  |     |  |      |
//      [..    [..      [..[.. [..    [..        [..     [..   [.   [..[..        [..[..    [..  [..      [..    [..   |||      |__|  _  |__|      |
//      [..    [......  [..[. [.      [..        [..     [..  [..   [..[..        [..[. [..      [..      [..    [..    \\\______    /_\     _____/
//      [..    [..      [..[..  [..   [..        [..     [.. [. [.. [..[..        [..[..  [..    [..      [..    [..           \\\__________/
//      [..    [..      [..[..   [..    [..     [..      [. [.    [....  [..     [.. [..    [..  [..      [..   [..            |||         |
//      [..    [........[..[..     [..    [....          [..        [..    [....     [..      [..[........[.....                \\\_______/

pragma solidity >=0.7.0;

import "https://github.com/chiru-labs/ERC721A/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator_filter/OperatorFilterer.sol";
import {CANONICAL_CORI_SUBSCRIPTION} from "operator_filter/lib/Constants.sol";


contract TeikoKey is ERC721A, Ownable, OperatorFilterer
{
    //////////////////////////////////////////////////////////////////
    // Library
    //////////////////////////////////////////////////////////////////
    
    using Counters for Counters.Counter;

    //////////////////////////////////////////////////////////////////
    // Enums
    //////////////////////////////////////////////////////////////////

    enum MintPhase
    {
        CLOSED,
        WHITELIST,
        ALLOWLIST,
        PUBLIC
    }

    enum KeyType
    {
        REGULAR,
        ROBOT,
        ZOMBIE,
        APE,
        SPIRIT,
        GOLD
    }

    //////////////////////////////////////////////////////////////////
    // Attributes
    //////////////////////////////////////////////////////////////////

    Counters.Counter private _tokenIds;
    MintPhase public currentMintPhase = MintPhase.CLOSED;
    uint256 public constant MAX_SUPPLY = 2008;
    bytes32 constant public whitelistRole = keccak256("whitelisted");
    bytes32 constant public allowlistRole = keccak256("allowlisted");
    uint8 public maxMintWhitelist = 2;
    uint8 public maxMintAllowlist = 1;
    uint8 public maxMintPublic = 1;
    address public mainAddress = 0x9Cc8C097251d71f68f674c0f4d2c86fB170e7BCD;
    address public signerAddress = 0x8fD261f08991619c2c0ad36B3a73E8f874BB5372;
    string public baseURI = "https://ipfs.io/ipns/k51qzi5uqu5djzdmli4l9utu46cvd35sn9plo3u50pkam7gtqw3ifq0crypp0p";
    uint256 public price = 0 ether;
    mapping (address => uint256) public mints;
    mapping (uint256 => uint8) public keyPercents;
    mapping(address => int8) public approvedCallers;
    mapping(uint256 => string) public tokenURIs;
    mapping(uint256 => KeyType) public keyTypes;
    mapping(KeyType => uint16) public maxCountKeyTypes;
    mapping(KeyType => uint8) public currentCountKeyTypes;

    //////////////////////////////////////////////////////////////////
    // Constructor
    //////////////////////////////////////////////////////////////////

    constructor() ERC721A("Teiko Key", "TEIKOKEY") OperatorFilterer(CANONICAL_CORI_SUBSCRIPTION, false)
    {
        maxCountKeyTypes[KeyType.REGULAR] = 1083;
        maxCountKeyTypes[KeyType.ROBOT] = 450;
        maxCountKeyTypes[KeyType.ZOMBIE] = 300;
        maxCountKeyTypes[KeyType.APE] = 120;
        maxCountKeyTypes[KeyType.SPIRIT] = 50;
        maxCountKeyTypes[KeyType.GOLD] = 5;
    }

    //////////////////////////////////////////////////////////////////
    // Modifiers
    //////////////////////////////////////////////////////////////////

    modifier onlyApprovedOrOwner(address addr)
    {
        require(approvedCallers[addr] == 1 || addr == owner(), "Caller is not approved nor owner");
        _;
    }

    modifier onlyOwnerOfOrApproved(address addr, uint256 tokenId)
    {
        require(ownerOf(tokenId) == addr || approvedCallers[addr] == 1, "Caller is not owner of that token id nor approved");
        _;
    }

    //////////////////////////////////////////////////////////////////
    // OperatorFilter functions
    //////////////////////////////////////////////////////////////////

    /**
     * @notice Registers self with the operator filter registry
    */
    function register()
        external onlyOwner
    {
        OPERATOR_FILTER_REGISTRY.register(address(this));
    }

    /**
     * @notice Unregisters self from the operator filter registry
    */
    function unregister()
        external onlyOwner
    {
        OPERATOR_FILTER_REGISTRY.unregister(address(this));
    }

    /**
     * @notice Registers self with the operator filter registry, and susbscribe to 
        the filtered operators of the given subscription 
    */
    function registerAndSubscribe(address subscription)
        external onlyOwner
    {
        OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscription);
    }

    /**
     * @notice Registers self with the operator filter registry, and copy
        the filtered operators of the given subscription 
    */
    function registerAndCopyEntries(address registrantToCopy)
        external onlyOwner
    {
        OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), registrantToCopy);
    }

    /**
     * @notice Update given operator address to filtered/unfiltered state
    */
    function updateOperator(address operator, bool filtered)
        external onlyOwner
    {
        OPERATOR_FILTER_REGISTRY.updateOperator(address(this), operator, filtered);
    }

    /**
     * @notice Update given operator smart contract code hash to filtered/unfiltered state
    */
    function updateCodeHash(bytes32 codeHash, bool filtered)
        external onlyOwner
    {
        OPERATOR_FILTER_REGISTRY.updateCodeHash(address(this), codeHash, filtered);
    }

    /**
     * @notice Batch function for updateOperator
    */
    function updateOperators(address[] calldata operators, bool filtered)
        external onlyOwner
    {
        OPERATOR_FILTER_REGISTRY.updateOperators(address(this), operators, filtered);
    }

    /**
     * @notice Batch function for updateCodeHash
    */
    function updateCodeHashes(bytes32[] calldata codeHashes, bool filtered)
        external onlyOwner
    {
        OPERATOR_FILTER_REGISTRY.updateCodeHashes(address(this), codeHashes, filtered);
    }

    /**
     * @notice Check if a given operator address is currently filtered
    */
    function isOperatorAllowed(address operator)
        external view
        returns (bool)
    {
        return OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator);
    }

    /**
     * @notice Subscribe to OperatorFilterRegistry contract : activate modifiers
    */
    function subscribe(address subscription)
        external onlyOwner
    {
        return OPERATOR_FILTER_REGISTRY.subscribe(address(this), subscription);
    }

    /**
     * @notice Unsubscribe to OperatorFilterRegistry contract : deactivate modifiers
    */
    function unsubscribe(bool copyExistingEntries)
        external onlyOwner
    {
        return OPERATOR_FILTER_REGISTRY.unsubscribe(address(this), copyExistingEntries);
    }

    /**
     * @notice Copy filtered operators of a given OperatorFilterRegistry
        registered smart contract
    */
    function copyEntriesOf(address registrantToCopy)
        external onlyOwner
    {
        return OPERATOR_FILTER_REGISTRY.copyEntriesOf(address(this), registrantToCopy);
    }

    /**
     * @notice Returns the list of filtered operators
    */
    function filteredOperators()
        external
        returns (address[] memory)
    {
        return OPERATOR_FILTER_REGISTRY.filteredOperators(address(this));
    }

    /**
    * @notice Overriding ERC721A.supportsInterface as advised for OperatorFilterRegistry 
        smart contract
    */
    function supportsInterface(bytes4 interfaceId)
        public view virtual 
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
    * @notice Overriding ERC721A.approve to integrate OperatorFilter modifier 
        onlyAllowedOperatorApproval
    */
    function approve(address operator, uint256 tokenId)
        public payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }
    
    /**
    * @notice Overriding ERC721A.setApprovalForAll to integrate OperatorFilter modifier 
        onlyAllowedOperatorApproval
    */
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /**
    * @notice Overriding ERC721A.safeTransferFrom to integrate
        OperatorFilter modifier onlyAllowedOperator
    */
    function safeTransferFrom(address from, address to, uint256 tokenId)
        public payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
    * @notice Overriding ERC721A.safeTransferFrom to integrate
        OperatorFilter modifier onlyAllowedOperator
    */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
    * @notice Overriding ERC721A.transferFrom to integrate
        OperatorFilter modifier onlyAllowedOperator
    */
    function transferFrom(address from, address to, uint256 tokenId)
        public payable
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    // Mint Functions
    ////////////////////

    /**
    * @notice Internal mint logic
    */
    function _mintNFT(uint256 nMint, address recipient)
        private
    {
        require(_tokenIds.current() + nMint <= MAX_SUPPLY, "No more NFT to mint");

        mints[recipient] += nMint;

        for (uint256 i = 0; i < nMint; i++)
        {
            _tokenIds.increment();
        }

        // Use _mint instead of _safeMint 
        // Because _mint is better when INDIVIDUALS are going to mint
        // While _safeMint is better when SMART CONTRACTS are going to mint
        _mint(recipient, nMint);
    }

    /**
    * @notice Main mint entry point
    */
    function mintNFT(uint256 nMint, uint8 v, bytes32 r, bytes32 s, string calldata nonce, uint256 deadline)
        external payable
    {
        require(currentMintPhase != MintPhase.CLOSED, "Mint period have not started yet");
        require(tx.origin == msg.sender, "No bots allowed");
        require(msg.value >= price * nMint, "Not enough ETH to mint");
        if (currentMintPhase == MintPhase.WHITELIST)
        {
            require(isRole(whitelistRole, nonce, deadline, v, r, s), "You are not whitelisted");
            require(mints[msg.sender] + nMint <= maxMintWhitelist, "Too much NFT minted");
        }
        else if (currentMintPhase == MintPhase.ALLOWLIST)
        {
            require(isRole(allowlistRole, nonce, deadline, v, r, s), "You are not allowlisted");
            require(mints[msg.sender] + nMint <= maxMintAllowlist, "Too much NFT minted");
        }
        else if (currentMintPhase == MintPhase.PUBLIC)
        {
            require(mints[msg.sender] + nMint <= maxMintPublic, "Too much NFT minted");
        }

        return _mintNFT(nMint, msg.sender);
    }

    /**
    * @notice Team giveway mint entry point
    */
    function giveaway(uint256 nMint, address recipient)
        external
        onlyApprovedOrOwner(msg.sender)
    {
        return _mintNFT(nMint, recipient);
    }

    /**
    * @notice Burn function
    */
    function burnNFT(uint256 tokenId)
        external
        onlyOwnerOfOrApproved(msg.sender, tokenId)
    {
        _burn(tokenId);
    }

    // Attributes getters
    ////////////////////

    /**
    * @notice Get metadatas of the given <tokenId>
    */
    function tokenURI(uint256 tokenId)
        public view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory tokenIdURI = tokenURIs[tokenId];
        string memory emptyString = "";

        if (keccak256(abi.encodePacked(tokenIdURI)) == keccak256(abi.encodePacked(emptyString)))
        {
            return string(abi.encodePacked(abi.encodePacked(abi.encodePacked(baseURI, "/"), Strings.toString(tokenId)), ".json"));
        }
        else
        {
            return tokenIdURI;
        }        
    }

    // Attributes setters
    ////////////////////

    /**
    * @notice If <addr> is an approved caller, remove it from the list.
    * otherwise, add it to the list of approved callers
    */
    function toggleApprovedCaller(address addr)
        external
        onlyOwner
    {
        if (approvedCallers[addr] == 1)
        {
            approvedCallers[addr] = 0;
        }
        else
        {
            approvedCallers[addr] = 1;
        }
    }
    
    /**
    * @notice Set a specific <tokenIdURI> for a given <tokenId>
    */
    function setTokenUri(uint8 tokenId, string memory tokenIdURI)
        external
        onlyApprovedOrOwner(msg.sender)
    {
        tokenURIs[tokenId] = tokenIdURI;
    }

    /**
    * @notice Set the current mint phase (Whitelist, Allowlist or Public)
    */
    function setMintPhase(MintPhase _mintPhase)
        external
        onlyOwner
    {
        require(uint256(_mintPhase) >= 0 && uint256(_mintPhase) <= 3, "_mintPhase have to be between 0 and 3");
        require(_mintPhase > currentMintPhase, "new mint phase must be strictly greater than current one");
        currentMintPhase = _mintPhase;
    }
    
    /**
    * @notice Set the mint price
    */
    function setPrice(uint256 priceGwei)
        external
        onlyOwner
    {
        price = priceGwei * 10**9;
    }

    /**
    * @notice Set the base tokenURI, on which metadatas are stored like <_baseURI>/<token_id>.json
    */
    function setBaseUri(string memory _baseURI)
        external
        onlyOwner
    {
        baseURI = _baseURI;
    }

    /**
    * @notice Set the max mintable NFTs by Whitelisted address
    */
    function setMaxPerWalletWhitelist(uint8 maxMint)
        external
        onlyOwner
    {
        maxMintWhitelist = maxMint;
    }

    /**
    * @notice Set the max mintable NFTs by Allowlisted address
    */
    function setMaxPerWalletAllowlist(uint8 maxMint)
        external
        onlyOwner
    {
        maxMintAllowlist = maxMint;
    }

    /**
    * @notice Set the max mintable NFTs by Public (neither Whitelist or Allowlist) address
    */
    function setMaxPerWalletPublic(uint8 maxMint)
        external
        onlyOwner
    {
        maxMintPublic = maxMint;
    }

    /**
    * @notice Set the main team wallet
    */
    function setMainAddress(address _mainAddress)
        external
        onlyOwner
    {
        mainAddress = _mainAddress;
    }

    /**
    * @notice Set the address of the signer
    */
    function setSignerAddress(address addr)
        external
        onlyOwner
    {
        signerAddress = addr;
    }

    // Helpers function
    //////////////////////////

    /**
    * @notice Freeze the <tokenId> metadata, and attribute its key type (Regular, Robot, Ape, Zombie or Spirit)
    */
    function freezeKey(uint256 tokenId, uint8 percent, string calldata nonce, uint256 deadline, uint8 v, bytes32 r, bytes32 s)    
        external
    {
        require(ownerOf(tokenId) == msg.sender || msg.sender == owner(), "Not your NFT nor the owner");
        require(isAllowed(nonce, deadline, v, r, s), "You are not allowed");
        require(keyTypes[tokenId] == KeyType.REGULAR, "Key have already been frozen");
        require(percent >= 0 && percent <= 100, "Percent have to be between 0 and 100");

        keyPercents[tokenId] = percent;

        if (percent < 25)
        {
            revert("Nothing to claim");
        }
        else if (percent < 50 && (currentCountKeyTypes[KeyType.ROBOT] < maxCountKeyTypes[KeyType.ROBOT]))
        {
            keyTypes[tokenId] = KeyType.ROBOT;
            currentCountKeyTypes[KeyType.ROBOT]++;
        }
        else if (percent < 75 && (currentCountKeyTypes[KeyType.ZOMBIE] < maxCountKeyTypes[KeyType.ZOMBIE]))
        {
            keyTypes[tokenId] = KeyType.ZOMBIE;
            currentCountKeyTypes[KeyType.ZOMBIE]++;
        }
        else if (percent < 100 && (currentCountKeyTypes[KeyType.APE] < maxCountKeyTypes[KeyType.APE]))
        {
            keyTypes[tokenId] = KeyType.APE;
            currentCountKeyTypes[KeyType.APE]++;
        }
        else if (percent == 100 && (currentCountKeyTypes[KeyType.SPIRIT] < maxCountKeyTypes[KeyType.SPIRIT]))
        {
            keyTypes[tokenId] = KeyType.SPIRIT;
            currentCountKeyTypes[KeyType.SPIRIT]++;
        }
    }

    /**
    * @notice Freeze the Gold keys (1/1 NFTs)
    */
    function freezeGoldKeys(uint256[] calldata tokenIds)
        external
        onlyOwner
    {
        for (uint256 idx = 0; idx < tokenIds.length; idx++)
        {
            unchecked
            {
                keyPercents[tokenIds[idx]] = 100;
                keyTypes[tokenIds[idx]] = KeyType.GOLD;
            }
        }
    }

    /**
    * @notice Check the given signature params against signer address
        Used to verify signature validity
    */
    function isAllowed(string calldata nonce, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        internal view
        returns (bool)
    {
        require(block.timestamp <= deadline, "Signing too late");
        require(
            recoverSigner(msg.sender, nonce, deadline, v, r, s) == signerAddress,
            "Wrong signer"
        );
        return true;
    }

    /**
    * @notice Check the given signature params against signer address
        Used to verify role validity
    */
    function isRole(bytes32 role, string calldata nonce, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        internal view
        returns (bool)
    {
        require(block.timestamp <= deadline, "Signing too late");
        require(
            recoverRole(role, msg.sender, nonce, deadline, v, r, s) == signerAddress,
            "Wrong signer"
        );
        return true;
    }

    /**
    * @notice Retrieve the signer address induced by the given signature params
    */
    function recoverSigner(address addr, string memory nonce, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        internal pure
        returns (address)
    {
        return ecrecover(sha256(abi.encodePacked(addr, nonce, deadline)), v, r, s);
    }

    function recoverRole(bytes32 role, address addr, string memory nonce, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        internal pure
        returns (address)
    {
        return ecrecover(sha256(abi.encodePacked(role, addr, nonce, deadline)), v, r, s);
    }

    function withdraw()
        external onlyOwner
    {
        uint256 amount = address(this).balance;
        require(amount > 0, "Nothing to withdraw");
        // bool success = payable(mainAddress).send(amount);
        (bool success, ) = payable(mainAddress).call{value: amount}("");
        require(success, "Failed to withdraw");
    }

    receive()
        external payable
    {
    }

    fallback()
        external
    {
    }
}