// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./chainlink/AggregatorV3Interface.sol";

import "./ERC2981.sol";
import "./MintpassValidator.sol";
import "./LibMintpass.sol";

/**
 * @dev This is a ERC721 Contract.
 * The minting process is processed in a public and an allow list sale
 * sale.
 */
contract AcesFantasyFootballPass is MintpassValidator, ERC721A, ERC2981, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    AggregatorV3Interface internal priceFeed;

    // Token Limit and Mint Limits
    uint256 public TOKEN_LIMIT = 504;
    uint256 public MAX_TOKEN_PER_WALLET = 8;
    uint256 public allowlistMintLimitPerWallet = 4;

    // Sale Stages Enabled / Disabled
    bool public allowlistMintEnabled = false;
    bool public publicMintEnabled = false;

    // Mint Prices
    int256 public publicMintUSDPrice = 15000000000; // = 150 USD
    int256 public allowlistMintUSDPrice = 14000000000; // = 140 USD

    // Transfer Permissions
    mapping(uint256 => bool) public inSeasonTransferPermit;
    bool public seasonTransferWindowActive = false;
    address public COMISSIONER_WALLET;

    mapping(address => uint256) public boughtAllowlistAmounts;

    string public _baseTokenURI;

    /**
     * @dev ERC721A Constructor
     */
    constructor(string memory name, string memory symbol)
        ERC721A(name, symbol)
    {
        _setDefaultRoyalty(msg.sender, 2000);
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        ); // Chainlink ETH/USD
        COMISSIONER_WALLET = msg.sender;
        SIGNER_WALLET = 0x113b34712bC6Eb20628D457652B8186AF8DF8D8B;
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
     * @dev Overwrite Token ID Start to skip Token with ID 0
     *
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev Public Mint Function.
     *
     * @param minter amount of tokens to be minted
     *
     * Requirements:
     * - `minter` user that should receive the token
     * - `quantity` user that should receive the token
     */
    function mint(address minter, uint256 quantity) public payable {
        require(
            publicMintEnabled == true,
            "AcesFantasyFootballPass: Public Minting is not Enabled"
        );

        require(
            balanceOf(minter) < MAX_TOKEN_PER_WALLET,
            "AcesFantasyFootballPass: Limit is 8 Tokens per Wallet"
        );
        uint256 mintPrice = publicMintPrice();
        require(
            msg.value >= (mintPrice * quantity * 199) / 200, // 0.5% treshold due to conversion rate swings
            "AcesFantasyFootballPass: Insufficient Amount"
        );

        require(
            TOKEN_LIMIT >= _nextTokenId(),
            "AcesFantasyFootballPass: Token Limit reached"
        );
        _mint(minter, quantity);
    }

    /**
     * @dev Function to mint Tokens during Allowlist Sale. This function is
     * should only be called on minting app to ensure signature validity.
     *
     * @param quantity amount of tokens to be minted
     * @param mintpass issued by the minting app
     * @param mintpassSignature issued by minting app and signed by SIGNER_WALLET
     *
     * Requirements:
     * - `quantity` can't be higher than {allowlistMintLimitPerWallet}
     * - `mintpass` needs to match the signature contents
     * - `mintpassSignature` needs to be obtained from minting app and
     *    signed by SIGNER_WALLET
     */
    function allowlistMint(
        uint256 quantity,
        LibMintpass.Mintpass memory mintpass,
        bytes memory mintpassSignature
    ) public payable {
        require(
            allowlistMintEnabled == true,
            "AcesFantasyFootballPass: Allowlist Minting is not Enabled"
        );
        uint256 mintPrice = allowlistMintPrice();
        require(
            msg.value >= (mintPrice * quantity * 199) / 200, // 0.5% treshold due to conversion rate swings
            "AcesFantasyFootballPass: Insufficient Amount"
        );

        require(
            balanceOf(mintpass.wallet) < MAX_TOKEN_PER_WALLET,
            "AcesFantasyFootballPass: Limit is 8 Tokens per Wallet"
        );

        require(
            TOKEN_LIMIT >= _nextTokenId(),
            "AcesFantasyFootballPass: Token Limit reached"
        );

        require(
            boughtAllowlistAmounts[mintpass.wallet] + quantity <=
                allowlistMintLimitPerWallet,
            "AcesFantasyFootballPass: Maximum Allowlist per Wallet reached"
        );

        validateMintpass(mintpass, mintpassSignature);
        _mint(mintpass.wallet, quantity);
        boughtAllowlistAmounts[mintpass.wallet] =
            boughtAllowlistAmounts[mintpass.wallet] +
            quantity;
    }

    function publicMintPrice() public view returns (uint256) {
        return convertFiatToEth(publicMintUSDPrice);
    }

    function allowlistMintPrice() public view returns (uint256) {
        return convertFiatToEth(allowlistMintUSDPrice);
    }

    /**
     * Returns the latest price
     */
    function convertFiatToEth(int256 fiatPrice)
        internal
        view
        returns (uint256)
    {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/
            ,
            ,

        ) = /*uint timeStamp*/
            /*uint80 answeredInRound*/
            priceFeed.latestRoundData();
        return
            uint256(
                (((fiatPrice * 1000000000) / price) * 1000000000) * (1 wei)
            );
    }

    /**
     * @dev Function to be called by contract owner to enable / disable
     * different mint stages
     *
     * @param _allowlistMintEnabled true/false
     * @param _publicMintEnabled true/false
     */
    function setMintingEnabled(
        bool _allowlistMintEnabled,
        bool _publicMintEnabled
    ) public virtual onlyOwner {
        allowlistMintEnabled = _allowlistMintEnabled;
        publicMintEnabled = _publicMintEnabled;
    }

    /**
     * @dev Function to permit a Token Transfer during a season
     * this only allows a transfer for one token
     *
     * @param _tokenId Token ID that should have a one time in season transfer
     * @param transferPermitted true/false
     */
    function permitInSeasonTokenTransfer(
        uint256 _tokenId,
        bool transferPermitted
    ) public virtual onlyOwnerOrComissioner {
        inSeasonTransferPermit[_tokenId] = transferPermitted;
    }

    /**
     * @dev Function to set the Token Transfers Active
     *
     * @param _seasonTransferWindowActive true/false
     */
    function setSeasonTransferWindowActive(bool _seasonTransferWindowActive)
        public
        virtual
        onlyOwnerOrComissioner
    {
        seasonTransferWindowActive = _seasonTransferWindowActive;
    }

    /**
     * @dev Function to set the Token Transfers Active
     *
     * @param _commissionerWallet address
     */
    function setComissionerWallet(address _commissionerWallet)
        public
        virtual
        onlyOwner
    {
        COMISSIONER_WALLET = _commissionerWallet;
    }

    /**
     * @dev Function to change the signer Wallet
     *
     * @param _signerWallet address
     */
    function setSignerWallet(address _signerWallet) public virtual onlyOwner {
        SIGNER_WALLET = _signerWallet;
    }

    /**
     * @dev This NFT is the membership to a game. Token Transfers during
     * a season are only allowed if an admin approves it. Also we need to
     * enforce only one token per wallet.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 _tokenId,
        uint256 quantity
    ) internal view override {
        if (address(0) != from) {
            if (!seasonTransferWindowActive) {
                for (uint256 i; i < quantity; i++) {
                    require(
                        (inSeasonTransferPermit[_tokenId + i]),
                        "AcesFantasyFootballPass: Transfers are not allowed during Season"
                    );
                }
            }
        }
        require(
            balanceOf(to) < MAX_TOKEN_PER_WALLET,
            "AcesFantasyFootballPass: Limit is 8 Tokens per Wallet"
        );
    }

    /**
     * @dev After a Token Transfer we invalidate the inSeasonTransferPermit
     */
    function _afterTokenTransfers(
        address from,
        address,
        uint256 _tokenId,
        uint256 quantity
    ) internal virtual override {
        if (address(0) != from) {
            for (uint256 i; i < quantity; i++) {
                inSeasonTransferPermit[_tokenId + i] = false;
            }
        }
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwnerOrComissioner() {
        require(
            owner() == _msgSender() || COMISSIONER_WALLET == _msgSender(),
            "AcesFantasyFootballPass: caller is not the owner or comissioner"
        );
        _;
    }

    /**
     * @dev Helper to replace _baseURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        if (bytes(_baseTokenURI).length > 0) {
            return _baseTokenURI;
        }
        return
            string(
                abi.encodePacked(
                    "https://meta.bowline.app/",
                    Strings.toHexString(uint256(uint160(address(this))), 20),
                    "/"
                )
            );
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
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

/** created with bowline.app **/