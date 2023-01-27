// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC721A/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./chainlink/AggregatorV3Interface.sol";

import "./ERC2981/ERC2981.sol";
import "./MintPass/MintpassValidator.sol";
import "./MintPass/LibMintpass.sol";

/**
 * @dev Learn more about this project on alphafounders.xyz
 *
 *         _          _                ___                          _
 *        | |        | |              / __)                        | |
 *  _____ | |  ____  | |__   _____  _| |__  ___   _   _  ____    __| | _____   ____  ___
 * (____ || | |  _ \ |  _ \ (____ |(_   __)/ _ \ | | | ||  _ \  / _  || ___ | / ___)/___)
 * / ___ || | | |_| || | | |/ ___ |  | |  | |_| || |_| || | | |( (_| || ____|| |   |___ |
 * \_____| \_)|  __/ |_| |_|\_____|  |_|   \___/ |____/ |_| |_| \____||_____)|_|   (___/
 *            |_|
 *
 **/

contract Alphafounder is MintpassValidator, ERC721A, ERC2981, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    AggregatorV3Interface internal ethUsdPriceFeed;
    AggregatorV3Interface internal eurUsdPriceFeed;

    // Token Limit and Mint Limits
    uint256 public TOKEN_LIMIT = 1000;
    uint256 public MAX_TOKEN_PER_WALLET = 1;

    // Transfer Permissions
    mapping(uint256 => bool) public membershipTransferPermit;

    // Signatures Dictionary
    mapping(bytes => bool) public usedSignatures;

    // Sale Stages Enabled / Disabled
    bool public allowlistMintEnabled = true;
    bool public publicMintEnabled = true;

    // Mint Price
    int256 public mintEURPrice = 500000000000; // = 500 EUR

    string public _baseTokenURI;

    /**
     * @dev ERC721A Constructor
     */
    constructor(string memory name, string memory symbol)
        ERC721A(name, symbol)
    {
        _setDefaultRoyalty(msg.sender, 500);
        ethUsdPriceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
        // Chainlink Mainnet ETH/USD 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        eurUsdPriceFeed = AggregatorV3Interface(
            0xb49f677943BC038e9857d61E7d053CaA2C1734C1
        );
        // Chainlink Mainnet EUR/USD 0xb49f677943BC038e9857d61E7d053CaA2C1734C1

        SIGNER_WALLET = 0xa4Daf00b6ca5ce4136269c68Db35288072844f2a;
    }

    /**
     * @dev Withrawal all Funds sent to the contract to Owner
     *
     * Requirements:
     * - `msg.sender` needs to be Beneficiary and payable
     */
    function withdraw() external onlyOwner {
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
            "Alphafounder: Public Minting is not Enabled"
        );

        require(
            msg.value >= (mintPrice() * quantity * 199) / 200, // 0.5% treshold due to conversion rate swings
            "Alphafounder: Insufficient Amount"
        );

        require(
            TOKEN_LIMIT >= _nextTokenId(),
            "Alphafounder: Token Limit reached"
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
     * - `quantity` can't be higher than {mintLimitPerWallet}
     * - `mintpass` needs to match the signature contents
     * - `mintpassSignature` needs to be obtained from minting app and
     *    signed by SIGNER_WALLET
     */
    function allowlistMint(
        uint256 quantity,
        LibMintpass.Mintpass memory mintpass,
        bytes memory mintpassSignature
    ) public {
        require(
            allowlistMintEnabled == true,
            "Alphafounder: Allowlist Minting is not Enabled"
        );

        require(
            TOKEN_LIMIT >= _nextTokenId(),
            "Alphafounder: All Tokens minted"
        );

        require(
            !usedSignatures[mintpassSignature],
            "Alphafounder: Signature already used"
        );

        validateMintpass(mintpass, mintpassSignature);
        _mint(mintpass.wallet, quantity);
        usedSignatures[mintpassSignature] = true;
    }

    function mintPrice() public view returns (uint256) {
        return convertFiatToEth(mintEURPrice);
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
            int256 ethConversionRate, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = ethUsdPriceFeed.latestRoundData();
        (
            ,
            /*uint80 roundID*/
            int256 eurConversionRate, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = eurUsdPriceFeed.latestRoundData();
        return
            uint256(
                (((fiatPrice * eurConversionRate) / ethConversionRate) *
                    1000000000) * (1 wei)
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
     * @dev Function to be called by contract owner to change mintEURPrice
     *
     * @param _mintEURPrice 500000000000 = 500 EUR
     */
    function setMintEURPrice(int256 _mintEURPrice) public virtual onlyOwner {
        mintEURPrice = _mintEURPrice;
    }

    /**
     * @dev Function to be called by contract owner change the available token amount
     *
     * @param _tokenLimit max amount of tokens available
     * @param _maxTokenPerWallet how many tokens can be in one wallet
     */
    function setLimits(uint256 _tokenLimit, uint256 _maxTokenPerWallet)
        public
        virtual
        onlyOwner
    {
        require(
            _tokenLimit >= totalSupply(),
            "Alphafounder: New Token Limit is smaller than already available tokens"
        );
        TOKEN_LIMIT = _tokenLimit;
        MAX_TOKEN_PER_WALLET = _maxTokenPerWallet;
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
            for (uint256 i; i < quantity; i++) {
                require(
                    (membershipTransferPermit[_tokenId + i]),
                    "Alphafounder: Transfer has to be permitted by council"
                );
            }
        }
        require(
            balanceOf(to) + quantity <= MAX_TOKEN_PER_WALLET,
            "Alphafounder: Max Memberships per Wallet"
        );
    }

    /**
     * @dev After a Token Transfer we invalidate the membershipTransferPermit
     */
    function _afterTokenTransfers(
        address from,
        address,
        uint256 _tokenId,
        uint256 quantity
    ) internal virtual override {
        if (address(0) != from) {
            for (uint256 i; i < quantity; i++) {
                membershipTransferPermit[_tokenId + i] = false;
            }
        }
    }

    /**
     * @dev Function to permit a Token Transfer this only allows a transfer for one token
     *
     * @param _tokenId Token ID that should have a one transfer permit
     * @param transferPermitted true/false
     */
    function permitMembershipTransfer(uint256 _tokenId, bool transferPermitted)
        public
        virtual
        onlyOwner
    {
        membershipTransferPermit[_tokenId] = transferPermitted;
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
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}

/** created with bowline.app **/