// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract VCXNFT is ERC721A, Ownable, ReentrancyGuard {
    using Strings for string;
    using EnumerableSet for EnumerableSet.AddressSet;

    constructor() ERC721A("Venture Capital X", "VCX") {}

    /// @notice Absolute maximum number of tokens that can be minted.
    uint public constant MAX_TOKENS = 2088;

    /// @notice Maximum number of reserved tokens that can be minted
    uint public constant MAX_RESERVED_TOKENS = 168;

    /// @notice Absolute maximum number of tokens that can be minted per wallet
    uint public constant MAX_TOKENS_PER_WALLET = 5;

    /// @notice Maximum number of tokens that can be minted for whale spots
    uint public constant MAX_WHALE_TOKENS = 500;

    /// @notice Number of reserved tokens that have been minted
    uint public reservedTokensMinted = 0;

    /// @notice Number of whale tokens that have been minted
    uint public whaleTokensMinted = 0;

    /// @notice Sale phase of the contract
    /// @dev 1 = Whale Spot Pledge, 2 = Whale Spot Mint, 3 = Platinum Presale, 4 = Gold Presale, 5 = Public Sale
    uint public salePhase = 1;

    /// @notice Move to the next sale phase
    function nextSalePhase() public onlyOwner {
        require(salePhase < 5, "Sale phase is already at the end");
        salePhase += 1;
    }

    /// @notice Change the sale phase manually
    /// @param phase The new sale phase
    /// @dev Only owner can call this function
    function setSalePhase(uint phase) public onlyOwner {
        require(phase >= 1 && phase <= 5, "Invalid sale phase");
        salePhase = phase;
    }

    /// @notice Number of tokens that have been minted for each wallet
    mapping(address => uint) public addressMintCount;

    /// @notice Price per token minted
    uint256 public price = 0.5 ether;

    /// @notice This function sets the price per token minted in wei
    /// @param newPrice The new price per token minted in wei
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    /// @notice Crossmint minter account (could be a contract)
    address public crossmintMinter;

    /// @notice Set the crossmint minter account
    /// @param minter The new crossmint minter account
    function setCrossmintMinter(address minter) public onlyOwner {
        crossmintMinter = minter;
    }

    /// @notice This mapping checks checks the address count for Platinum Presale
    mapping(address => uint) public addressPlatinumCount;

    /// @notice Mint tokens during Platinum, Gold, & public sales states
    /// @param to Address to mint to
    /// @param quantity Quantity to mint. should be only 2 for Platinum & Gold, and up to 5 wallet max in public
    /// @param merkleProof Merkle proof
    function crossMint(
        address to,
        uint quantity,
        bytes32[] calldata merkleProof
    ) public payable nonReentrant {
        require(crossmintMinter != address(0), "Crossmint minter not set");
        require(msg.sender == crossmintMinter, "Not crossmint minter");
        require(salePhase >= 3, "Wrong sale phase (should be 3 or higher)");

        if (salePhase == 3 || salePhase == 4) {
            require(
                addressPlatinumCount[to] + addressGoldCount[to] + quantity <= 2,
                "Address already purchased 2 Cards during platinum or gold presale"
            );

            require(
                verifyCrossmintWhitelist(merkleProof, to),
                "Invalid merkle proof for crossmint whitelist"
            );
        }

        require(
            addressMintCount[to] + quantity <= MAX_TOKENS_PER_WALLET,
            "Exceeds max tokens per wallet"
        );

        require(totalSupply() + quantity <= MAX_TOKENS, "Exceeds max tokens");

        require(msg.value >= quantity * price, "Not enough ETH sent");

        _mint(to, quantity);
        addressMintCount[to] += quantity;
        if (salePhase == 3) {
            addressPlatinumCount[to] += quantity;
        } else if (salePhase == 4) {
            addressGoldCount[to] += quantity;
        }
    }

    /// @notice Mint function for platinum group presale
    /// @param merkleProof Merkle proof
    /// @dev Only addresses on the platinum presale whitelist can mint
    function mintPlatinum(bytes32[] calldata merkleProof, uint quantity)
        public
        payable
        nonReentrant
    {
        require(salePhase == 3, "Wrong sale phase (should be 3)");
        require(
            addressMintCount[msg.sender] + quantity <= MAX_TOKENS_PER_WALLET,
            "Exceeds max tokens per wallet"
        );
        require(totalSupply() + quantity <= MAX_TOKENS, "Exceeds max tokens");
        require(msg.value >= quantity * price, "Not enough ETH sent");
        require(
            verifyPlatinumWhitelist(merkleProof, msg.sender),
            "Invalid merkle proof"
        );
        require(
            addressPlatinumCount[msg.sender] + quantity <= 2,
            "Already minted max limit of 2"
        );

        _mint(msg.sender, quantity);
        addressPlatinumCount[msg.sender] += quantity;
        addressMintCount[msg.sender] += quantity;
    }

    /// @notice This mapping checks checks the address count for Gold Presale
    mapping(address => uint) public addressGoldCount;

    /// @notice Mint function for gold group presale
    /// @param merkleProof Merkle proof
    /// @dev Only addresses on the platinum and gold presale whitelists can mint
    function mintGold(bytes32[] calldata merkleProof, uint quantity)
        public
        payable
        nonReentrant
    {
        require(salePhase == 4, "Wrong sale phase (should be 4)");
        require(
            addressMintCount[msg.sender] + quantity <= MAX_TOKENS_PER_WALLET,
            "Exceeds max tokens per wallet"
        );
        require(totalSupply() + quantity <= MAX_TOKENS, "Exceeds max tokens");
        require(msg.value >= quantity * price, "Not enough ETH sent");

        bool whitelistedOnPlatinum = verifyPlatinumWhitelist(
            merkleProof,
            msg.sender
        );
        bool whitelistedOnGold = verifyGoldWhitelist(merkleProof, msg.sender);

        require(
            whitelistedOnPlatinum || whitelistedOnGold,
            "Invalid merkle proof"
        );

        require(
            addressPlatinumCount[msg.sender] +
                addressGoldCount[msg.sender] +
                quantity <=
                2,
            "Address already purchased 2 Cards during platinum or gold presale"
        );

        _mint(msg.sender, quantity);
        addressGoldCount[msg.sender] += quantity;
        addressMintCount[msg.sender] += quantity;
    }

    /// @notice Mint function for public sale
    /// @param quantity Quantity to mint
    function mintPublic(uint quantity) public payable nonReentrant {
        require(salePhase == 5, "Wrong sale phase (should be 5)");
        require(
            addressMintCount[msg.sender] + quantity <= MAX_TOKENS_PER_WALLET,
            "Exceeds max tokens per wallet"
        );
        require(totalSupply() + quantity <= MAX_TOKENS, "Exceeds max tokens");
        require(msg.value >= quantity * price, "Not enough ETH sent");

        _mint(msg.sender, quantity);
        addressMintCount[msg.sender] += quantity;
    }

    /// @notice Mint reserved tokens
    /// @param to The address to mint the tokens to
    /// @param amount The number of tokens to mint
    /// @dev Only callable by owner, ignores max tokens per wallet
    function mintReservedTokens(address to, uint amount)
        public
        onlyOwner
        nonReentrant
    {
        require(totalSupply() + amount <= MAX_TOKENS, "Exceeds max supply");
        require(
            reservedTokensMinted + amount <= MAX_RESERVED_TOKENS,
            "Exceeds maximum reserved tokens"
        );

        _mint(to, amount);
        reservedTokensMinted += amount;
        addressMintCount[to] += amount;
    }

    /// @notice pledgemint.io contract address
    address public pledgeContractAddress = address(0);

    /// @notice This function sets the pledgemint contract address
    /// @param contractAddress The new pledgemint contract address
    function setPledgeContractAddress(address contractAddress)
        public
        onlyOwner
    {
        pledgeContractAddress = contractAddress;
    }

    /// @notice Mint function for pledgemint.io integration
    /// @param to The address to mint the tokens to
    /// @param quantity The number of tokens to mint
    function pledgeMint(address to, uint8 quantity)
        public
        payable
        nonReentrant
    {
        require(
            msg.sender == pledgeContractAddress || msg.sender == owner(),
            "Only pledgemint or owner can call this function"
        );
        require(totalSupply() + quantity <= MAX_TOKENS, "Exceeds max supply");
        require(
            whaleTokensMinted + quantity <= MAX_WHALE_TOKENS,
            "Exceeds max whale tokens"
        );
        require(
            addressMintCount[to] + quantity <= MAX_TOKENS_PER_WALLET,
            "Exceeds max tokens per wallet"
        );

        whaleTokensMinted += quantity;
        addressMintCount[to] += quantity;
        _mint(to, quantity);
    }

    /// @dev payment splitter (please double check this address)
    address payable private devguy =
        payable(0x7ea9114092eC4379FFdf51bA6B72C71265F33e96);

    /// @notice Withdraw funds from the contract
    /// @dev This function can only be called by either owner or devguy. The split is hard-coded at 97% to owner and 3% to devguy.
    function withdraw() external nonReentrant {
        require(
            msg.sender == devguy || msg.sender == owner(),
            "Invalid sender"
        );
        (bool success, ) = devguy.call{
            value: (address(this).balance / 100) * 3
        }("");
        (bool success2, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer 1 failed");
        require(success2, "Transfer 2 failed");
    }

    /// @dev Merkle tree roots (these are test values which should be replaced on deploy)
    bytes32 public crossmintRoot = bytes32(0);
    bytes32 private platinumRoot = bytes32(0);
    bytes32 private goldRoot = bytes32(0);

    /// @notice This function sets the crossmint merkle root (callable only by contract owner)
    /// @param root The new crossmint merkle root
    function setCrossmintRoot(bytes32 root) public onlyOwner {
        crossmintRoot = root;
    }

    /// @notice Verify a proof for the crossmint platinum group merkle tree
    /// @param proof The proof to verify
    /// @param addressToVerify The address to verify
    /// @return True if the proof is valid which means the address is on the crossmint platinum group whitelist, otherwise false
    function verifyCrossmintWhitelist(
        bytes32[] memory proof,
        address addressToVerify
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addressToVerify));
        return MerkleProof.verify(proof, crossmintRoot, leaf);
    }

    /// @notice Set the platinum group merkle root (callable only by contract owner)
    /// @param root The new merkle root
    function setPlatinumRoot(bytes32 root) public onlyOwner {
        platinumRoot = root;
    }

    /// @notice Verify a proof for the platinum group merkle tree
    /// @param proof The proof to verify
    /// @param addressToVerify The address to verify
    /// @return True if the proof is valid which means the address is on the platinum group whitelist, otherwise false
    function verifyPlatinumWhitelist(
        bytes32[] memory proof,
        address addressToVerify
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addressToVerify));
        return MerkleProof.verify(proof, platinumRoot, leaf);
    }

    /// @notice Set the gold group merkle root (callable only by contract owner)
    /// @param root The new merkle root
    function setGoldRoot(bytes32 root) public onlyOwner {
        goldRoot = root;
    }

    /// @notice Verify a proof for the gold group merkle tree
    /// @param proof The proof to verify
    /// @param addressToVerify The address to verify
    /// @return True if the proof is valid which means the address is on the gold group whitelist, otherwise false
    function verifyGoldWhitelist(
        bytes32[] memory proof,
        address addressToVerify
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addressToVerify));
        return MerkleProof.verify(proof, goldRoot, leaf);
    }

    /// @dev The Base URI is the link copied from your IPFS Folder holding your collections json
    string private _baseTokenURI;

    /// @notice placeholder URI to add an image, gif, or video prior to reveal
    string public notRevealedUri;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice Set the base URI (callable only by contract owner)
    /// @param baseURI The new base URI
    function setBaseURI(string calldata baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /// @notice Get the token URI for a given token ID
    /// @param tokenId The token ID
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = super.tokenURI(tokenId);
        return
            bytes(_tokenURI).length > 0
                ? string(abi.encodePacked(_tokenURI, ".json"))
                : "";
    }
}