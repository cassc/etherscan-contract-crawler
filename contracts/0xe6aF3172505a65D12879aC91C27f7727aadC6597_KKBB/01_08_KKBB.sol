//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "lib/ERC721A/contracts/ERC721A.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract KKBB is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event MaxPublicMintUpdated(uint256 prevMax, uint256 newMax);
    event MaxWhitelistMintUpdated(uint256 prevMax, uint256 newMax);
    event BatchSizeUpdated(uint256 prevAmount, uint256 newAmount);
    event BaseURIUpdated(string newURI);
    event UnrevealedURIUpdated(string newURI);
    event SaleStateChanged(Period state);
    event PublicPriceUpdated(uint256 prevPrice, uint256 newPrice);
    event WhitelistPriceUpdated(uint256 prevPrice, uint256 newPrice);
    event FundsWithdrawn(address receiver);

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    enum Period {
        PAUSED,
        WHITELIST,
        PUBLIC
    }

    Period public saleState;

    // @note change to private in production
    address public _signerAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // TESTING ADDRESS

    uint256 public maxSupply = 555;
    uint256 public maxPublicMint = 3;
    uint256 public maxWhitelistMint = 2;
    uint256 public batchSize = 5;
    uint256 public publicPrice = 0.043 ether;
    uint256 public whitelistPrice;

    string public baseURI;
    string public unrevealedURI;

    mapping(address => uint256) publicMinted;
    mapping(address => uint256) whitelistMinted;

    constructor(
        string memory baseURI_,
        string memory unrevealedURI_,
        address newOwner
    ) ERC721A("Kitty Kitty Bang Bang", "KKBB") {
        baseURI = baseURI_;
        unrevealedURI = unrevealedURI_;
        _transferOwnership(newOwner);
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /*
     * @notice mint a quantity of NFTs to the caller
     * @param quantity - the amount of NFTs to mint
     */
    function mint(uint256 quantity) external payable nonReentrant {
        /* Checks */
        require(saleState == Period.PUBLIC, "Sale period not active");
        require(totalSupply() + quantity <= maxSupply, "Max supply reached");
        require(
            publicMinted[msg.sender] + quantity <= maxPublicMint,
            "Max wallet mint reached"
        );
        require(msg.value >= publicPrice * quantity, "Not enough ether");
        require(quantity <= batchSize, "Exceeded max mint per tx");

        /* Effects */
        publicMinted[msg.sender] += quantity;

        /* Interactions */
        _safeMint(msg.sender, quantity);
    }

    /*
     * @notice mints a quantity of NFTs to the caller
     * @param _signature - bytes signature that is used to verify the user is whitelisted
     * @param quantity - the amount of NFTs to mint
     *
     */
    function whitelistMint(bytes memory _signature, uint256 quantity)
        external
        payable
        nonReentrant
    {
        /* Checks */
        require(saleState == Period.WHITELIST, "Sale period not active");
        require(totalSupply() + quantity <= maxSupply, "Max supply reached");
        require(
            whitelistMinted[msg.sender] + quantity <= maxWhitelistMint,
            "Max wallet mint reached"
        );
        require(msg.value >= whitelistPrice * quantity, "Not enough ether");
        require(quantity <= batchSize, "Exceeded max mint per tx");

        bytes32 msgHash = keccak256(
            abi.encode(address(this), uint256(saleState), msg.sender)
        );

        require(
            msgHash.toEthSignedMessageHash().recover(_signature) ==
                _signerAddress,
            "INCORRECT_SIGNATURE"
        );

        /* Effects */
        whitelistMinted[msg.sender] += quantity;

        /* Interactions */
        _safeMint(msg.sender, quantity);
    }

    /*//////////////////////////////////////////////////////////////
                                 VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the starting token ID.
     * @dev Overriden from ERC721A
     */
    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }

    /*
     * @notice returns the token URI to the metadata
     * @param tokenId - the ID of the token
     * @returns the URI of the metadata
     */
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

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : unrevealedURI;
    }

    /*//////////////////////////////////////////////////////////////
                                 ADMIN
    //////////////////////////////////////////////////////////////*/

    /*
     * @notice mints a quantity of tokens to an address
     * @param _user - the address of the receiver
     * @param _quantity - the amount of tokens to mint
     */
    function airdrop(address _user, uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= maxSupply, "Max supply reached");
        _safeMint(_user, _quantity);
    }

    /*
     * @notice mints a quantity of tokens to each user in the users array
     * @param users - array of receiver addresses
     * @param - amount of tokens to be minted to each address
     * @dev each address gets the same amount of tokens, defined by `quantity`
     */
    function airdropBatch(address[] calldata users, uint256 quantity)
        external
        onlyOwner
    {
        require(
            totalSupply() + (users.length * quantity) <= maxSupply,
            "Max supply reached"
        );

        for (uint256 i; i < users.length; i++) {
            _safeMint(users[i], quantity);
        }
    }

    /*
     * @notice sets price per token for the public mint
     * @param _price - the price in wei
     */
    function setPublicPrice(uint256 _price) external onlyOwner {
        uint256 prevPrice = publicPrice;
        publicPrice = _price;

        emit PublicPriceUpdated(prevPrice, _price);
    }

    /*
     * @notice sets price per token for the whitelist mint
     * @param _price - the price in wei
     */
    function setWhitelistPrice(uint256 _price) external onlyOwner {
        uint256 prevPrice = whitelistPrice;
        whitelistPrice = _price;

        emit WhitelistPriceUpdated(prevPrice, _price);
    }

    /*
     * @notice sets maximum mint limit per wallet for public mint
     * @param newMax - non-zero number as the new limit
     */
    function setMaxPublicMint(uint256 newMax) external onlyOwner {
        require(newMax > 0, "Can't be zero");
        uint256 prevMax = maxPublicMint;
        maxPublicMint = newMax;

        emit MaxPublicMintUpdated(prevMax, newMax);
    }

    /*
     * @notice sets maximum mint limit per wallet for whitelist mint
     */
    function setMaxWhitelistMint(uint256 newMax) external onlyOwner {
        require(newMax > 0, "Can't be zero");
        uint256 prevMax = maxWhitelistMint;
        maxWhitelistMint = newMax;

        emit MaxWhitelistMintUpdated(prevMax, newMax);
    }

    /*
     * @notice sets the maximum quantity that can be minted per transaction
     * @param _amount - non-zero number as the batch limit
     */
    function setBatchSize(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Can't be zero");
        uint256 prevAmount = batchSize;
        batchSize = _amount;

        emit BatchSizeUpdated(prevAmount, _amount);
    }

    /*
     * @notice sets the signer address used for verifying WL signatures
     * @param _signer - address of the new signer
     */
    function setSignerAddress(address _signer) external onlyOwner {
        _signerAddress = _signer;
    }

    /*
     * @notice sets the baseURI that points to the metadata
     * @param baseURI_ - new URI ending in `/` (example: `ipfs://CID/`)
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;

        emit BaseURIUpdated(baseURI_);
    }

    /*
     * @notice sets the unrevealedURI that points to the unrevealed metadata
     * @param _uri - new URI
     */
    function setUnrevealedURI(string memory _uri) external onlyOwner {
        unrevealedURI = _uri;

        emit UnrevealedURIUpdated(_uri);
    }

    /*
     * @notice sets the current sale period
     * @param _state - the Period to set
     * 0 - PAUSED
     * 1 - WHITELIST
     * 2 - PUBLIC
     */
    function setSaleState(uint256 _state) external onlyOwner {
        require(_state < 3, "Incorrect state");
        saleState = Period(_state);

        emit SaleStateChanged(Period(_state));
    }

    /*
     * @notice withdraws the contract balance to the owner
     * @dev using .call to support multisigs
     */
    function withdraw() external onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);

        emit FundsWithdrawn(owner());
    }
}