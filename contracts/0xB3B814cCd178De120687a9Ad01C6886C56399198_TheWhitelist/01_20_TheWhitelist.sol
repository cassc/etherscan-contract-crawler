// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
Learn more about our project on thewhitelist.io
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxclxddOxcdxllxKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk':O:.:' ';.'lKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXdkXkd0xcdxloxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMXKKKXWMMMNKKKXWMMMWKKKKNXKKKXWMMWXKKKXWWXKKKNNKKKKKKKKKKKKXNNKKKKKKKKKKXWNKKKKNMMMMMMWKkdkKWMMWNKOOOO0XWNXKKKKKKKKKKKNM
MWx...'xWMNo....dWMWd...:Ol...:KMMK:...cX0;...ld'...........,dd..........lXk'..'kMMMMMWx.   .xN0c'.    ..ld,...........xM
MMK,   ,KWk.    '0MO'  .dXc   '0MMK,   ;KO.   cx:,,.    .',;cxl    .,,,,;dNd.  .xWMMMMNl     cx'   .::;''xOc,,.    .',;OM
MMWx.   o0;      l0c   :XNc   .;cl;.   ;KO.   cXWWNd.   oNWWWNo   .;llllxXWd.  .xWMMMMMK;   ;0x.   .codxONWWNNk.   lXWWWM
MMMNc   .,.  ..  .,.  .kWXc            ;XO.   cNMMMx.   oWMMMWo         ;KWd.  .xWMMMMMNl   cNNx,.      .c0WMMO.   oWMMMM
MMMMO'      'ko       lNMNc   .cddl.   ;XO.   cNMMMx.   oWMMMWo   .:ddddkXWd.  .oXNNNNWK;   ;KMXkxxdl;.   cXMMO.   oWMMMM
MMMMWd.    .oNK,     ,KMMNc   '0MMK,   ;XO.   cNMMMx.   oWMMMWo    .'''''lKd.   .'''',xO'   .OK:..';;'   .dWMMO.   oWMMMM
MMMMMXc....cXMWk,...,kWMMNo...:KMMXc...lX0:...oNMMMO,..'xWMMMWx'.........:Kk,........'dk,...,k0c'......':kNMMM0;..'xWMMMM
MMMMMMXK000XWMMWK000KWMMMWX000XWMMWX000XWWK00KXMMMMNK00KNMMMMMNK000000000XWNK00000000KNNK000KNMWXKOOOO0XWMMMMMWK00KNMMMMM
*/

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC2981.sol";
import "./MintpassValidator.sol";
import "./LibMintpass.sol";

/**
 * @dev Learn more about this project on thewhitelist.io.
 *
 * TheWhitelist is a ERC721 Contract that supports Burnable.
 * The minting process is processed in a public and a whitelist
 * sale.
 */
contract TheWhitelist is MintpassValidator, ERC721Burnable, ERC2981, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Token Limit and Mint Limits
    uint256 public TOKEN_LIMIT = 10000;
    uint256 public whitelistMintLimitPerWallet = 2;
    uint256 public publicMintLimitPerWallet = 5;

    // Price per Token depending on Category
    uint256 public whitelistMintPrice = 0.17 ether;
    uint256 public publicMintPrice = 0.19 ether;

    // Sale Stages Enabled / Disabled
    bool public whitelistMintEnabled = false;
    bool public publicMintEnabled = false;

    // Mapping from minter to minted amounts
    mapping(address => uint256) public boughtAmounts;
    mapping(address => uint256) public boughtWhitelistAmounts;

    // Mapping from mintpass signature to minted amounts (Free Mints)
    mapping(bytes => uint256) public mintpassRedemptions;

    // Optional mapping to overwrite specific token URIs
    mapping(uint256 => string) private _tokenURIs;

    // counter for tracking current token id
    Counters.Counter private _tokenIdTracker;

    // _abseTokenURI serving nft metadata per token
    string private _baseTokenURI = "https://api.thewhitelist.io/tokens/";

    event TokenUriChanged(
        address indexed _address,
        uint256 indexed _tokenId,
        string _tokenURI
    );

    /**
     * @dev ERC721 Constructor
     */
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _setDefaultRoyalty(msg.sender, 700);
        ACE_WALLET = 0x8F564ad0FBdf89b4925c91Be37b3891244544Abf;
    }

    /**
     * @dev Withrawal all Funds sent to the contract to Owner
     *
     * Requirements:
     * - `msg.sender` needs to be Owner and payable
     */
    function withdrawalAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    /**
     * @dev Function to mint Tokens for only Gas. This function is used
     * for Community Wallet Mints, Raffle Winners and Cooperation Partners.
     * Redemptions are tracked and can be done in chunks.
     *
     * @param quantity amount of tokens to be minted
     * @param mintpass issued by thewhitelist.io
     * @param mintpassSignature issued by thewhitelist.io and signed by ACE_WALLET
     *
     * Requirements:
     * - `quantity` can't be higher than mintpass.amount
     * - `mintpass` needs to match the signature contents
     * - `mintpassSignature` needs to be obtained from thewhitelist.io and
     *    signed by ACE_WALLET
     */
    function freeMint(
        uint256 quantity,
        LibMintpass.Mintpass memory mintpass,
        bytes memory mintpassSignature
    ) public {
        require(
            whitelistMintEnabled == true || publicMintEnabled == true,
            "TheWhitelist: Minting is not Enabled"
        );
        require(
            mintpass.minterAddress == msg.sender,
            "TheWhitelist: Mintpass Address and Sender do not match"
        );
        require(
            mintpassRedemptions[mintpassSignature] + quantity <=
                mintpass.amount,
            "TheWhitelist: Mintpass already redeemed"
        );
        require(
            mintpass.minterCategory == 99,
            "TheWhitelist: Mintpass not a Free Mint"
        );

        validateMintpass(mintpass, mintpassSignature);
        mintQuantityToWallet(quantity, mintpass.minterAddress);
        mintpassRedemptions[mintpassSignature] =
            mintpassRedemptions[mintpassSignature] +
            quantity;
    }

    /**
     * @dev Function to mint Tokens during Whitelist Sale. This function is
     * should only be called on thewhitelist.io minting page to ensure
     * signature validity.
     *
     * @param quantity amount of tokens to be minted
     * @param mintpass issued by thewhitelist.io
     * @param mintpassSignature issued by thewhitelist.io and signed by ACE_WALLET
     *
     * Requirements:
     * - `quantity` can't be higher than {whitelistMintLimitPerWallet}
     * - `mintpass` needs to match the signature contents
     * - `mintpassSignature` needs to be obtained from thewhitelist.io and
     *    signed by ACE_WALLET
     */
    function mintWhitelist(
        uint256 quantity,
        LibMintpass.Mintpass memory mintpass,
        bytes memory mintpassSignature
    ) public payable {
        require(
            whitelistMintEnabled == true,
            "TheWhitelist: Whitelist Minting is not Enabled"
        );
        require(
            mintpass.minterAddress == msg.sender,
            "TheWhitelist: Mintpass Address and Sender do not match"
        );
        require(
            msg.value >= whitelistMintPrice * quantity,
            "TheWhitelist: Insufficient Amount"
        );
        require(
            boughtWhitelistAmounts[mintpass.minterAddress] + quantity <=
                whitelistMintLimitPerWallet,
            "TheWhitelist: Maximum Whitelist per Wallet reached"
        );

        validateMintpass(mintpass, mintpassSignature);
        mintQuantityToWallet(quantity, mintpass.minterAddress);
        boughtWhitelistAmounts[mintpass.minterAddress] =
            boughtWhitelistAmounts[mintpass.minterAddress] +
            quantity;
    }

    /**
     * @dev Public Mint Function.
     *
     * @param quantity amount of tokens to be minted
     *
     * Requirements:
     * - `quantity` can't be higher than {publicMintLimitPerWallet}
     */
    function mint(uint256 quantity) public payable {
        require(
            publicMintEnabled == true,
            "TheWhitelist: Public Minting is not Enabled"
        );
        require(
            msg.value >= publicMintPrice * quantity,
            "TheWhitelist: Insufficient Amount"
        );
        require(
            boughtAmounts[msg.sender] + quantity <= publicMintLimitPerWallet,
            "TheWhitelist: Maximum per Wallet reached"
        );

        mintQuantityToWallet(quantity, msg.sender);
        boughtAmounts[msg.sender] = boughtAmounts[msg.sender] + quantity;
    }

    /**
     * @dev internal mintQuantityToWallet function used to mint tokens
     * to a wallet (cpt. obivous out). We start with tokenId 1.
     *
     * @param quantity amount of tokens to be minted
     * @param minterAddress address that receives the tokens
     *
     * Requirements:
     * - `TOKEN_LIMIT` should not be reahed
     */
    function mintQuantityToWallet(uint256 quantity, address minterAddress)
        internal
        virtual
    {
        require(
            TOKEN_LIMIT >= quantity + _tokenIdTracker.current(),
            "TheWhitelist: Token Limit reached"
        );

        for (uint256 i; i < quantity; i++) {
            _mint(minterAddress, _tokenIdTracker.current() + 1);
            _tokenIdTracker.increment();
        }
    }

    /**
     * @dev Function to change the ACE_WALLET by contract owner.
     * Learn more about the ACE_WALLET on our Roadmap.
     * This wallet is used to verify mintpass signatures and is allowed to
     * change tokenURIs for specific tokens.
     *
     * @param _ace_wallet The new ACE_WALLET address
     */
    function setAceWallet(address _ace_wallet) public virtual onlyOwner {
        ACE_WALLET = _ace_wallet;
    }

    /**
     */
    function setMintingLimits(
        uint256 _whitelistMintLimitPerWallet,
        uint256 _publicMintLimitPerWallet
    ) public virtual onlyOwner {
        whitelistMintLimitPerWallet = _whitelistMintLimitPerWallet;
        publicMintLimitPerWallet = _publicMintLimitPerWallet;
    }

    /**
     * @dev Function to be called by contract owner to enable / disable
     * different mint stages
     *
     * @param _whitelistMintEnabled true/false
     * @param _publicMintEnabled true/false
     */
    function setMintingEnabled(
        bool _whitelistMintEnabled,
        bool _publicMintEnabled
    ) public virtual onlyOwner {
        whitelistMintEnabled = _whitelistMintEnabled;
        publicMintEnabled = _publicMintEnabled;
    }

    /**
     * @dev Helper to replace _baseURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Can be called by owner to change base URI. This is recommend to be used
     * after tokens are revealed to freeze metadata on IPFS or similar.
     *
     * @param permanentBaseURI URI to be prefixed before tokenId
     */
    function setBaseURI(string memory permanentBaseURI)
        public
        virtual
        onlyOwner
    {
        _baseTokenURI = permanentBaseURI;
    }

    /**
     * @dev _tokenURIs setter for a tokenId. This can only be done by owner or our
     * ACE_WALLET. Learn more about this on our Roadmap.
     *
     * Emits TokenUriChanged Event
     *
     * @param tokenId tokenId that should be updated
     * @param permanentTokenURI URI to OVERWRITE the entire tokenURI
     *
     * Requirements:
     * - `msg.sender` needs to be owner or {ACE_WALLET}
     */
    function setTokenURI(uint256 tokenId, string memory permanentTokenURI)
        public
        virtual
    {
        require(
            (msg.sender == ACE_WALLET || msg.sender == owner()),
            "TheWhitelist: Can only be modified by ACE"
        );
        require(_exists(tokenId), "TheWhitelist: URI set of nonexistent token");
        _tokenURIs[tokenId] = permanentTokenURI;
        emit TokenUriChanged(msg.sender, tokenId, permanentTokenURI);
    }

    function mintedTokenCount() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    /**
     * @dev _tokenURIs getter for a tokenId. If tokenURIs has an entry for
     * this tokenId we return this URL. Otherwise we fallback to baseURI with
     * tokenID.
     *
     * @param tokenId URI requested for this tokenId
     *
     * Requirements:
     * - `tokenID` needs to exist
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
            "TheWhitelist: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];

        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Extends default burn behaviour with deletion of overwritten tokenURI
     * if it exists. Calls super._burn before deletion of tokenURI; Reset Token Royality if set
     *
     * @param tokenId tokenID that should be burned
     *
     * Requirements:
     * - `tokenID` needs to exist
     * - `msg.sender` needs to be current token Owner
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        _resetTokenRoyalty(tokenId);
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        virtual
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}