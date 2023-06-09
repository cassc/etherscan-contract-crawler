// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./erc721/ERC721WhitelistEssentials.sol";
import "./erc721/ERC721AOperatorRegistry.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 *
 * :'######:::::'###:::'##:::'##'##::::'##:'######::::'###::::
 * '##... ##:::'## ##::. ##:'##::###::'###'##... ##::'## ##:::
 *  ##:::..:::'##:. ##::. ####:::####'####:##:::..::'##:. ##::
 *  ##::'####'##:::. ##::. ##::::## ### ##:##::::::'##:::. ##:
 *  ##::: ##::#########::: ##::::##. #: ##:##:::::::#########:
 *  ##::: ##::##.... ##::: ##::::##:.:: ##:##::: ##:##.... ##:
 * . ######:::##:::: ##::: ##::::##:::: ##. ######::##:::: ##:
 * :......:::..:::::..::::..::::..:::::..::......::..:::::..::
 * ===========================================================
 *                 LOVERSIDE NETWORK NFT LABS
 * ===========================================================
 * @author null-prophet
 * @dev NFT contract that is based off the Azuki and OS Opensea OperatorRegistry with the EIP2981 added for
 * royalty duties elsewhere.
 *
 * HatTip to SVS for some inspo on the minting side.
 *
 * This impl uses hashed signatures which are more performant than merkle trees and can allow the whitelist
 * to be updated without having to update the tree data into the contract again and again.
 *
 */
contract GaymcaV1NFT is ERC721AOperatorRegistry, ERC721WhitelistEssentials {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public constant GAY_TEAM_TOKENS = 696; // MINTING STARTS AFTER THESE
    uint256 public constant GAY_MAX = 6969;
    uint256 public publicSaleMaxMint = GAY_MAX - GAY_TEAM_TOKENS; // 6273

    uint256 public constant GAY_WL_MAX = 6273; // Allow them to mint the max amount.
    uint256 public constant GAY_PUBLIC_MAX = 6273; // Public sale

    uint256 public wlMintPrice = 0.014 ether;
    uint256 public publicMintPrice = 0.016 ether;
    uint256 public constant WL_MAX_MINT = 10; // WHITE LIST MAX PER ADDR
    uint256 public constant PUBLIC_MAX_MINT = 10; // PUBLIC SALE MAX PER ADDR

    mapping(address => uint256) public whitelistPurchases;
    mapping(address => uint256) public publicPurchases;

    bool public limitedPublicSale = true; // enforce per wallet minting limits

    // minting totals
    uint256 public whitelistAmountMinted;
    uint256 public publicAmountMinted;

    address private _signerAddress;

    event PublicSaleStarted(uint256 publicMaxMint);

    constructor(
        string memory name_,
        string memory symbol_,
        address royaltyReceiver_,
        uint96 feeNumerator_,
        address teamWallet_,
        address signer_
    ) BaseERC721A(name_, symbol_, royaltyReceiver_, feeNumerator_, teamWallet_) {
        // sanity check
        require(GAY_MAX == GAY_TEAM_TOKENS + GAY_WL_MAX, "Invalid Token allocations - WL");
        require(GAY_MAX == GAY_TEAM_TOKENS + GAY_PUBLIC_MAX, "Invalid Token allocations - PUBLIC");
        // metadata servers/config etc.
        _setBaseUri("https://api.glamapes.wtf/gaype/v1/token/");
        _setContractURI("https://api.glamapes.wtf/gaype/v1/contract.json");

        // SETUP STATE AND VARS/WALLETS
        state = ContractState.init;
        _signerAddress = signer_;

        // MINT THE TEAM NFTS
        _mintERC2309(msg.sender, GAY_TEAM_TOKENS);
    }

    /**
     * @dev this changes the state of the contract as we go along ala state machine.
     * please note toggling this past the sale ended will lock the contract
     */
    function toggleContractStatus() external onlyOwner {
        // move to next stage
        if (state < ContractState.saleended) {
            ContractState orig = state;
            // converting the enum to uint will allow us to increment it easily.
            state = ContractState(uint256(state) + 1);
            // if we are moving into the public sale set the limits based on what we have sold and allocated so far.
            if (state == ContractState.publicsale) {
                // we need to set the max public sale amount
                publicSaleMaxMint = GAY_MAX - GAY_TEAM_TOKENS - whitelistAmountMinted;
                emit PublicSaleStarted(publicSaleMaxMint);
            }
            emit ContractStateChanged(orig, state);
        } else {
            revert("SALE_ENDED");
        }
    }

    /**
     * @dev set this flag to make the public sale have a limit or not.
     */
    function toggleLimitedSale() external onlyOwner {
        limitedPublicSale = !limitedPublicSale;
    }

    /**
     * @notice use this to change the wl mint price.
     */
    function setWhitelistMintPrice(uint256 _newPrice) external onlyOwner {
        wlMintPrice = _newPrice;
    }

    /**
     * @notice use this to change the public mint price.
     */
    function setPublicMintPrice(uint256 _newPrice) external onlyOwner {
        publicMintPrice = _newPrice;
    }

    /**
     *  @dev easy check to see if caller is on the whitelist
     */
    function isWhitelister(address addr, bytes calldata _signature) public view returns (bool) {
        address hashSigner = _hashTransaction(addr, WL_MAX_MINT, "whitelist").recover(_signature);
        return hashSigner == _signerAddress;
    }

    /**
     * @dev - whitelist method
     */
    function buyWhitelist(bytes calldata signature, uint256 tokenQuantity) external payable {
        require(state == ContractState.whitelist, "WHITELIST_CLOSED");
        // so this is what we sign on the backside to chek signature is correct.
        require(isWhitelister(msg.sender, signature), "HASH_FAIL");
        require(totalSupply() < GAY_MAX, "OUT_OF_STOCK");
        require(whitelistAmountMinted + tokenQuantity <= GAY_WL_MAX, "EXCEED_WHITELIST");
        require(whitelistPurchases[msg.sender] + tokenQuantity <= WL_MAX_MINT, "EXCEED_ALLOC");
        require(msg.value >= wlMintPrice * tokenQuantity, "INSUFFICIENT_ETH");

        whitelistAmountMinted += tokenQuantity;
        whitelistPurchases[msg.sender] += tokenQuantity;
        _mint(msg.sender, tokenQuantity);
    }

    /**
     * @dev mint some nfts in a public sale. Will mint all available coins up until this point.
     */
    function buy(uint256 tokenQuantity) external payable {
        require(state == ContractState.publicsale, "SALE_CLOSED");
        require(totalSupply() < GAY_MAX, "OUT_OF_STOCK");
        require(publicAmountMinted + tokenQuantity <= publicSaleMaxMint, "EXCEED_PUBLIC");

        // if we have public sale mint limits
        if (limitedPublicSale) {
            require(tokenQuantity <= PUBLIC_MAX_MINT, "EXCEED_PUBLIC_MAX_MINT");
            // they have a max per wallet if we decide to enable this (default)
            require(publicPurchases[msg.sender] + tokenQuantity <= PUBLIC_MAX_MINT, "EXCEED_ALLOC");
        }

        require(publicMintPrice * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");

        publicAmountMinted += tokenQuantity;
        publicPurchases[msg.sender] += tokenQuantity;
        _mint(msg.sender, tokenQuantity);

        // if we have hit the max of the public sale we end it all... sad I know.
        if (publicAmountMinted == publicSaleMaxMint) {
            state = ContractState.saleended;
            emit ContractStateChanged(ContractState.publicsale, state);
        }
    }
}