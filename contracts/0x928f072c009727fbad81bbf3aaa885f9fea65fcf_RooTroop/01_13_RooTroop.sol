// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Signer.sol";

contract RooTroop is ERC721, Ownable, ReentrancyGuard {
    uint16 constant additionalMints = 3;

    constructor(
        uint16 _maxSupply,
        uint16 _maxFree,
        uint16 _maxPresale,
        uint16 _publicTransactionMax,
        uint256 _mintPrice,
        address _signer,
        uint256 _freeMintStart,
        uint256 _freeMintEnd,
        uint256 _presaleMintStart,
        uint256 _presaleMintEnd,
        uint256 _publicMintStart
    ) ERC721("RooTroop", "RT") {
        require(_maxSupply > 0, "Zero supply");

        mintSigner = _signer;
        maxSupply = _maxSupply;
        totalSupply = additionalMints; // additional mints is the number to tack onto the end of the supply for the contract deployer.

        // CONFIGURE FREE MINT
        freeMint.startDate = _freeMintStart;
        freeMint.endDate = _freeMintEnd;
        freeMint.maxMinted = _maxFree;

        // CONFIGURE PRESALE Mint
        presaleMint.mintPrice = _mintPrice;
        presaleMint.startDate = _presaleMintStart;
        presaleMint.endDate = _presaleMintEnd;
        presaleMint.maxMinted = _maxPresale;

        // CONFIGURE PUBLIC MINT
        publicMint.mintPrice = _mintPrice;
        publicMint.startDate = _publicMintStart;
        publicMint.maxPerTransaction = _publicTransactionMax;

        for (uint256 i = 1; i <= additionalMints; i++) {
            _mint(msg.sender, _maxSupply + i);
        }
    }

    event Paid(address sender, uint256 amount);
    event Withdraw(address recipient, uint256 amount);

    struct WhitelistedMint {
        /**
         * The price to mint in that whitelist
         */
        uint256 mintPrice;
        /**
         * The start date in unix seconds
         */
        uint256 startDate;
        /**
         * The end date in unix seconds
         */
        uint256 endDate;
        /**
         * The total number of tokens minted in this whitelist
         */
        uint16 totalMinted;
        /**
         * The maximum number of tokens minted in this whitelist
         */
        uint16 maxMinted;
        /**
         * The minters in this whitelisted mint
         * mapped to the number minted
         */
        mapping(address => uint16) minted;
    }

    struct PublicMint {
        uint256 mintPrice;
        /**
         * The start date in unix seconds
         */
        uint256 startDate;
        /**
         * The maximum per transaction
         */
        uint16 maxPerTransaction;
    }

    string baseURI;

    uint16 public maxSupply;
    uint16 public totalSupply;
    uint16 public minted;

    address private mintSigner;
    mapping(address => uint16) public lastMintNonce;

    /**
     * The free mint
     */
    WhitelistedMint public freeMint;

    /**
     * An exclusive mint for members granted
     * presale from influencers
     */
    WhitelistedMint public presaleMint;

    /**
     * The public mint for everybody.
     */
    PublicMint public publicMint;

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * Sets the base URI for all tokens
     *
     * @dev be sure to terminate with a slash
     * @param _uri - the target base uri (ex: 'https://google.com/')
     */
    function setBaseURI(string calldata _uri) public onlyOwner {
        baseURI = _uri;
    }

    /**
     * Burns the provided token id if you own it.
     * Reduces the supply by 1.
     *
     * @param _tokenId - the ID of the token to be burned.
     */
    function burn(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "You do not own this token");

        totalSupply--;
        _burn(_tokenId);
    }

    /**
     * Allows the contract owner to update the signer used for presale mints.
     * @param _signer the signer's address
     */
    function setSigner(address _signer) external onlyOwner {
        mintSigner = _signer;
    }

    // ------------------------------------------------ MINT STUFFS ------------------------------------------------

    function getWhitelistMints(address _user)
        external
        view
        returns (uint16 free, uint16 presale)
    {
        free = freeMint.minted[_user];
        presale = presaleMint.minted[_user];

        return (free, presale);
    }

    /**
     * Updates the presale mint's characteristics
     *
     * @param _mintPrice - the cost for that mint in WEI
     * @param _startDate - the start date for that mint in UNIX seconds
     * @param _endDate - the end date for that mint in UNIX seconds
     */
    function updatePresaleMint(
        uint256 _mintPrice,
        uint256 _startDate,
        uint256 _endDate,
        uint16 _maxMinted
    ) public onlyOwner {
        presaleMint.mintPrice = _mintPrice;
        presaleMint.startDate = _startDate;
        presaleMint.endDate = _endDate;
        presaleMint.maxMinted = _maxMinted;
    }

    /**
     * Updates the free mint's characteristics
     *
     * @param _startDate - the start date for that mint in UNIX seconds
     * @param _endDate - the end date for that mint in UNIX seconds
     */
    function updateFreeMint(
        uint256 _startDate,
        uint256 _endDate,
        uint16 _maxMinted
    ) public onlyOwner {
        freeMint.startDate = _startDate;
        freeMint.endDate = _endDate;
        freeMint.maxMinted = _maxMinted;
    }

    /**
     * Updates the public mint's characteristics
     *
     * @param _mintPrice - the cost for that mint in WEI
     * @param _maxPerTransaction - the maximum amount allowed in a wallet to mint in the public mint
     * @param _startDate - the start date for that mint in UNIX seconds
     */
    function updatePublicMint(
        uint256 _mintPrice,
        uint16 _maxPerTransaction,
        uint256 _startDate
    ) public onlyOwner {
        publicMint.mintPrice = _mintPrice;
        publicMint.maxPerTransaction = _maxPerTransaction;
        publicMint.startDate = _startDate;
    }

    function getPremintHash(
        address _minter,
        uint16 _quantity,
        uint8 _mintId,
        uint16 _nonce
    ) public pure returns (bytes32) {
        return VerifySignature.getMessageHash(_minter, _quantity, _mintId, _nonce);
    }

    /**
     * Mints in the premint stage by using a signed transaction from a centralized whitelist.
     * The message signer is expected to only sign messages when they fall within the whitelist
     * specifications.
     *
     * @param _quantity - the number to mint
     * @param _mintId - 0 for free mint, 1 for presale mint
     * @param _nonce - a random nonce which indicates that a signed transaction hasn't already been used.
     * @param _signature - the signature given by the centralized whitelist authority, signed by
     *                    the account specified as mintSigner.
     */
    function premint(
        uint16 _quantity,
        uint8 _mintId,
        uint16 _nonce,
        bytes calldata _signature
    ) public payable nonReentrant {
        uint256 remaining = maxSupply - minted;

        require(remaining > 0, "Mint over");
        require(_quantity >= 1, "Zero mint");
        require(_quantity <= remaining, "Not enough");

        require(_mintId == 0 || _mintId == 1, "Invalid mint");
        require(lastMintNonce[msg.sender] < _nonce, "Nonce used");

        WhitelistedMint storage targetMint = _mintId == 0
            ? freeMint
            : presaleMint;

        require(
            targetMint.startDate <= block.timestamp &&
                targetMint.endDate >= block.timestamp,
            "No mint"
        );
        require(
            VerifySignature.verify(
                mintSigner,
                msg.sender,
                _quantity,
                _mintId,
                _nonce,
                _signature
            ),
            "Invalid sig"
        );
        require(targetMint.mintPrice * _quantity == msg.value, "Bad value");
        require(
            targetMint.totalMinted + _quantity <= targetMint.maxMinted,
            "Limit exceeded"
        );

        uint16 lastMinted = minted;
        totalSupply += _quantity;
        minted += _quantity;
        targetMint.minted[msg.sender] += _quantity;
        targetMint.totalMinted += _quantity;
        lastMintNonce[msg.sender] = _nonce; // update nonce

        // DISTRIBUTE THE TOKENS
        for (uint16 i = 1; i <= _quantity; i++) {
            _safeMint(msg.sender, lastMinted + i);
        }
    }

    /**
     * Mints the given quantity of tokens provided it is possible to.
     *
     * @notice This function allows minting in the public sale
     *         or at any time for the owner of the contract.
     *
     * @param _quantity - the number of tokens to mint
     */
    function mint(uint16 _quantity) public payable nonReentrant {
        uint256 remaining = maxSupply - minted;

        require(remaining > 0, "Mint over");
        require(_quantity >= 1, "Zero mint");
        require(_quantity <= remaining, "Not enough");

        if (owner() == msg.sender) {
            // OWNER MINTING FOR FREE
            require(msg.value == 0, "Owner paid");
        } else if (block.timestamp >= publicMint.startDate) {
            // PUBLIC MINT
            require(_quantity <= publicMint.maxPerTransaction, "Exceeds max");
            require(
                _quantity * publicMint.mintPrice == msg.value,
                "Invalid value"
            );
        } else {
            // NOT ELIGIBLE FOR PUBLIC MINT
            revert("No mint");
        }

        // DISTRIBUTE THE TOKENS
        uint16 lastMinted = minted;
        totalSupply += _quantity;
        minted += _quantity;

        for (uint16 i = 1; i <= _quantity; i++) {
            _safeMint(msg.sender, lastMinted + i);
        }
    }

    /**
     * Withdraws balance from the contract to the owner (sender).
     * @param _amount - the amount to withdraw, much be <= contract balance.
     */
    function withdraw(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Invalid amt");

        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Trans failed");
        emit Withdraw(msg.sender, _amount);
    }

    /**
     * The receive function, does nothing
     */
    receive() external payable {
        emit Paid(msg.sender, msg.value);
    }
}