// SPDX-License-Identifier: UNLICENSED
/*
  __    _____  ___    ______    _______    _______  ________   __     _______   ___       _______
 |" \  (\"   \|"  \  /" _  "\  /"      \  /"     "||"      "\ |" \   |   _  "\ |"  |     /"     "|
 ||  | |.\\   \    |(: ( \___)|:        |(: ______)(.  ___  :)||  |  (. |_)  :)||  |    (: ______)
 |:  | |: \.   \\  | \/ \     |_____/   ) \/    |  |: \   ) |||:  |  |:     \/ |:  |     \/    |
 |.  | |.  \    \. | //  \ _   //      /  // ___)_ (| (___\ |||.  |  (|  _  \\  \  |___  // ___)_
 /\  |\|    \    \ |(:   _) \ |:  __   \ (:      "||:       :)/\  |\ |: |_)  :)( \_|:  \(:      "|
(__\_|_)\___|\____\) \_______)|__|  \___) \_______)(________/(__\_|_)(_______/  \_______)\_______)
        __      _____  ___    __     _______       __      ___      ___        ________
       /""\    (\"   \|"  \  |" \   |   _  "\     /""\    |"  |    |"  |      /"       )
      /    \   |.\\   \    | ||  |  (. |_)  :)   /    \   ||  |    ||  |     (:   \___/
     /' /\  \  |: \.   \\  | |:  |  |:     \/   /' /\  \  |:  |    |:  |      \___  \
    /  '__'  \ |.  \    \. | |.  |  (|  _  \\  //  __'  \  \  |___  \  |___    __/  \\
   /   /  \\  \|    \    \ | /\  |\ |: |_)  :)/   /  \\  \( \_|:  \( \_|:  \  /" \   :)
  (___/    \___)\___|\____\)(__\_|_)(_______/(___/    \___)\_______)\_______)(_______/

https://incredible-aniballs.com
*/
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract IncredibleAniballs is ERC721A, Ownable, Pausable, PaymentSplitter {
    using SafeMath for uint256;

    // ============ Storage ============

    // Max NFTs to mint
    uint256 public constant COLLECTION_SIZE = 5430;
    // Max NFTs per Wallet of current step
    uint256 public maxPerAddress = 54;
    // Max NFTs per free mint
    uint256 public maxPerFree = 1;
    // Max NFTs per transaction of current step
    uint256 public maxPerTransaction = 10;
    // Max supply of current step
    uint256 public maxSupply = 543;
    // NFT price in wei
    uint256 public price = 0.040725 ether;
    // PreSale enable/disable
    bool public presale = true;
    // Reveal enable/disable
    bool public revealed = false;

    // Base URI for metadata
    string private _contractBaseURI;
    // Blind URI before reveal
    string private _hiddenBaseURI =
        "ipfs://bafybeicqnxsxei7nscuxbokswfeknj6dja6pfxztfvycgr4qnt223ujqcy/hidden.json";
    mapping(address => uint256) private _freeMintClaimed;
    // Root of the whitelist
    bytes32 private _merkleRoot;
    // Root of the free mint
    bytes32 private _freeMerkleRoot;

    // ================================================== //
    //                *** CONSTRUCTOR ***
    // ================================================== //

    constructor(
        string memory name,
        string memory symbol,
        address[] memory payees,
        uint256[] memory shares
    ) payable ERC721A(name, symbol) PaymentSplitter(payees, shares) {
        // Pause contract by default
        _pause();
    }

    // ================================================== //
    //                  *** MODIFIERS ***
    // ================================================== //

    /// @dev Modifier to make a function callable only when the presale is disabled.
    modifier whenNotPresale() {
        require(!presale, "Presale enabled");
        _;
    }

    /// @dev Modifier to make a function callable only when the presale is enabled.
    modifier whenPresale() {
        require(presale, "Presale not enabled");
        _;
    }

    /// @dev Modifier to make a mint callable only when amount is valid.
    /// a valid amount must:
    ///  - be greater than 0
    ///  - not exceeds maxSupply of current phase
    ///  - not exceeds collection size
    ///  - not exceeds max NFT allowed per Transaction
    ///  - not conducts to exceed max NFT allowed per Address
    modifier mintCompliance(uint256 quantity) {
        require(
            quantity > 0 &&
                quantity < maxPerTransaction + 1 &&
                _totalMinted() + quantity < maxSupply + 1 &&
                _totalMinted() + quantity < COLLECTION_SIZE + 1,
            "Invalid mint amount"
        );
        require(
            _numberMinted(msg.sender) + quantity <= maxPerAddress,
            "Amount requested will exceed address limit!"
        );
        _;
    }

    /// @dev Modifier to make a free mint callable only when amount is valid.
    /// a valid amount must:
    ///  - be greater than 0
    ///  - not exceeds maxSupply of current phase
    ///  - not exceeds collection size
    ///  - not exceeds max NFT allowed per Free
    ///  - not conducts to exceed max NFT allowed per Address
    modifier mintFreeCompliance(uint256 quantity) {
        require(
            quantity > 0 &&
                quantity < maxPerFree + 1 &&
                _totalMinted() + quantity < maxSupply + 1 &&
                _totalMinted() + quantity < COLLECTION_SIZE + 1,
            "Invalid mint amount"
        );
        require(
            _freeMintClaimed[msg.sender] + quantity < maxPerFree + 1,
            "Amount requested will exceed address free mint limit"
        );
        require(
            _numberMinted(msg.sender) + quantity <= maxPerAddress,
            "Amount requested will exceed address limit!"
        );
        _;
    }

    // ================================================== //
    //                    *** MINT ***
    // ================================================== //

    /// @notice mint, called only by owner
    /// @dev mint new NFTs, it is payable. Amount is calculated as per (price.mul(quantity))
    /// @param quantity, number of NFT a mint
    function mint(uint256 quantity)
        external
        payable
        whenNotPaused
        whenNotPresale
        mintCompliance(quantity)
    {
        require(msg.value >= price * quantity, "Insufficient funds!");

        _mint(msg.sender, quantity);
    }

    /// @notice presaleMint, called only by owner
    /// @dev mint new NFTs during the presale phase, it is payable. Amount is calculated as per (price.mul(quantity))
    /// @param quantity, number of NFT a mint
    /// @param proof, merkle proof for sender
    function presaleMint(uint256 quantity, bytes32[] calldata proof)
        external
        payable
        whenNotPaused
        whenPresale
        mintCompliance(quantity)
    {
        require(msg.value >= price * quantity, "Insufficient funds!");
        require(_verify(msg.sender, proof, false), "Invalid proof");

        _mint(msg.sender, quantity);
    }

    /// @notice freeMint, called only by owner
    /// @dev mint new NFTs for free, it is payable
    /// @param quantity, number of NFT a mint for free
    /// @param proof, merkle proof for sender
    function freeMint(uint256 quantity, bytes32[] calldata proof)
        external
        payable
        whenNotPaused
        mintFreeCompliance(quantity)
    {
        require(_verify(msg.sender, proof, true), "Invalid proof");

        _mint(msg.sender, quantity);

        // Mark Free mint as laready claimed for the address
        _freeMintClaimed[msg.sender] += quantity;
    }

    /// @notice mintForAddresses, called only by owner
    /// @dev mint  new NFTs for a given address (for giveaway and partnerships)
    /// @param quantity, number of NFT a mint
    /// @param addresses, address to mint NFT
    function mintForAddresses(uint256 quantity, address[] calldata addresses)
        external
        onlyOwner
    {
        uint256 aLength = addresses.length;
        uint256 totalQuantity = aLength * quantity;

        require(
            totalQuantity > 0 &&
                _totalMinted() + totalQuantity < COLLECTION_SIZE + 1,
            "Invalid mint amount"
        );

        for (uint256 i = 0; i < aLength; i++) {
            _mint(addresses[i], quantity);
        }
    }

    /// @notice mintForAddress, called only by owner
    /// @dev mint new NFTs for a given address (for giveaway and partnerships)
    /// @param quantity, number of NFT a mint
    /// @param to, address to mint NFT
    function mintForAddress(uint256 quantity, address to)
        public
        mintCompliance(quantity)
        onlyOwner
    {
        require(
            quantity > 0 && _totalMinted() + quantity < COLLECTION_SIZE + 1,
            "Invalid mint amount"
        );

        _mint(to, quantity);
    }

    // ================================================== //
    //                  *** SETTER ***
    //                    ONLY OWNER
    // ================================================== //

    /// @notice setBaseURI, called only by owner
    /// @dev set Base URI for metadata
    /// @param uri, new base URI
    function setBaseURI(string memory uri) external onlyOwner {
        _contractBaseURI = uri;
    }

    /// @notice setHiddenBaseURI, called only by owner
    /// @dev set Base URI before reveal
    /// @param uri, new hidden base URI
    function setHiddenBaseURI(string memory uri) external onlyOwner {
        _hiddenBaseURI = uri;
    }

    /// @notice setMerkleRoot, called only by owner
    /// @dev set the root of merkle tree to check the whitelist
    /// @param merkleRoot, root of merkle tree
    /// @param free, Free mint Merkle root if true
    function setMerkleRoot(bytes32 merkleRoot, bool free) external onlyOwner {
        if (free) {
            _freeMerkleRoot = merkleRoot;
        } else {
            _merkleRoot = merkleRoot;
        }
    }

    /// @notice setMaxPerAddress, called only by owner
    /// @dev set the max amount of NFTs allowed per address
    /// @param newMaxPerAddress, number of NFTs to allow per address
    function setMaxPerAddress(uint256 newMaxPerAddress) external onlyOwner {
        require(newMaxPerAddress > 0, "Max per address must be greater than 0");

        maxPerAddress = newMaxPerAddress;
    }

    /// @notice setMaxPerFree, called only by owner
    /// @dev set the max amount of NFTs allowed per free mint
    /// @param newMaxPerFree, number of NFTs to allow per transaction
    function setMaxPerFree(uint256 newMaxPerFree) external onlyOwner {
        require(newMaxPerFree > 0, "Max per Free must be greater than 0");
        require(
            newMaxPerFree <= maxPerAddress,
            "Max per Free can't be greater than max per Address"
        );

        maxPerFree = newMaxPerFree;
    }

    /// @notice setMaxPerTransaction, called only by owner
    /// @dev set the max amount of NFTs allowed per transaction
    /// @param newMaxPerTransaction, number of NFTs to allow per transaction
    function setMaxPerTransaction(uint256 newMaxPerTransaction)
        external
        onlyOwner
    {
        require(
            newMaxPerTransaction > 0,
            "Max per Transaction must be greater than 0"
        );
        require(
            newMaxPerTransaction <= maxPerAddress,
            "Max per Transaction can't be greater than max per Address"
        );

        maxPerTransaction = newMaxPerTransaction;
    }

    /// @notice setMaxSupply, called only by owner
    /// @dev set supply of the current phase
    /// @param supply, number of NFTs available for Mint in the current phase
    function setMaxSupply(uint256 supply) external onlyOwner {
        require(
            supply < COLLECTION_SIZE + 1,
            "Max supply can't be greater than collection size"
        );

        maxSupply = supply;
    }

    /// @notice setPause, called only by owner
    /// @dev Pause/Unpause the contract
    /// @param pause_, true: pause / false: unpause
    function setPause(bool pause_) external onlyOwner {
        if (pause_) {
            _pause();
        } else {
            _unpause();
        }
    }

    /// @notice setPresale, called only by owner
    /// @dev Enable/Disable PreSale phase
    /// @param presale_, true: open PreSale phase / false: close PreSale phase
    function setPresale(bool presale_) external onlyOwner {
        if (paused()) {
            _unpause();
        }

        if (presale_) {
            presale = true;
        } else {
            presale = false;
        }
    }

    /// @notice setPrice, called only by owner
    /// @dev Set the NFT mint price
    /// @param price_, Mint price in wei
    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    /// @notice setRevealed, called only by owner
    /// @dev Reveal the NFTs
    /// @param reveal, true: Reavel / false: Unreveal
    function setRevealed(bool reveal) external onlyOwner {
        revealed = reveal;
    }

    /// @notice withdrawAllToAddress, called only by owner
    /// @dev claim the raised funds and send it to the given account
    /// @param addr_, wallet to collect funds
    function withdrawAllToAddress(address addr_) external payable onlyOwner {
        require(payable(addr_).send(address(this).balance));
    }

    // ================================================== //
    //                *** VIEW METADATA ***
    // ================================================== //

    /// @notice numberMinted
    /// @dev Get the number of NFT minted by a specific address
    /// @param minter, address to check
    /// @return uint256
    function numberMinted(address minter) public view returns (uint256) {
        return _numberMinted(minter);
    }

    /// @notice tokenURI
    /// @dev Get token URI of given token ID. URI will be the _hiddenBaseURI until reveal enabled
    /// @param tokenId, token ID NFT
    /// @return URI
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (!revealed) {
            return _hiddenBaseURI;
        }

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : "";
    }

    /// @notice walletOfOwner
    /// @dev Get all tokens owned by owner
    /// @param owner, address to check
    /// @return uint256[]
    function walletOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(owner);
        uint256[] memory ownerTokens = new uint256[](ownerTokenCount);
        uint256 ownerTokenIdx = 0;

        for (uint256 tokenIdx = 0; tokenIdx < totalSupply(); tokenIdx++) {
            if (ownerOf(tokenIdx) == owner) {
                ownerTokens[ownerTokenIdx] = tokenIdx;
                ownerTokenIdx++;
            }
        }

        return ownerTokens;
    }

    // ================================================== //
    //             *** INTERNAL FUNCTIONS ***
    // ================================================== //

    /// @notice _baseURI
    /// @dev Get the Base URI for metadata
    /// @return string
    function _baseURI() internal view virtual override returns (string memory) {
        return _contractBaseURI;
    }

    /// @notice _verify
    /// @dev verify the given account is whitelisted
    /// @param account, account address to validate
    /// @param proof, proof of whitelisting
    /// @param free, verify on freemin merkle tree (true) or whitelist (false)
    /// @return boolean, true or false
    function _verify(
        address account,
        bytes32[] memory proof,
        bool free
    ) internal view returns (bool) {
        return
            MerkleProof.verify(
                proof,
                free ? _freeMerkleRoot : _merkleRoot,
                keccak256(abi.encodePacked(account))
            );
    }
}