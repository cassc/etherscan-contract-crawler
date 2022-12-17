// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.16;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "./libs/tokensHandler.sol";

//                          &&&&&%%%%%%%%%%#########*
//                      &&&&&&&&%%%%%%%%%%##########(((((
//                   @&&&&&&&&&%%%%%%%%%##########((((((((((
//                @@&&&&&&&&&&%%%%%%%%%#########(((((((((((((((
//              @@@&&&&&&&&%%%%%%%%%%##########((((((((((((((///(
//            %@@&&&&&&               ######(                /////.
//           @@&&&&&&&&&           #######(((((((       ,///////////
//          @@&&&&&&&&%%%           ####((((((((((*   .//////////////
//         @@&&&&&&&%%%%%%          ##((((((((((((/  ////////////////*
//         &&&&&&&%%%%%%%%%          *(((((((((//// //////////////////
//         &&&&%%%%%%%%%####          .((((((/////,////////////////***
//        %%%%%%%%%%%########.          ((/////////////////***********
//         %%%%%##########((((/          /////////////****************
//         ##########((((((((((/          ///////*********************
//         #####((((((((((((/////          /*************************,
//          #(((((((((////////////          *************************
//           (((((//////////////***          ***********************
//            ,//////////***********        *************,*,,*,,**
//              ///******************      *,,,,,,,,,,,,,,,,,,,,,
//                ******************,,    ,,,,,,,,,,,,,,,,,,,,,
//                   ****,,*,,,,,,,,,,,  ,,,,,,,,,,,,,,,,,,,
//                      ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
//                          .,,,,,,,,,,,,,,,,,,,,,,,

/// @notice     This is an ERC721 collection that allows deposits of two specific ERC20 tokens
///             that are shared equally among the current holders at the moment of deposit.
///             The two allowed ERC20 tokens are USDC and WETH.
///             Any wallet can make deposits to the holders.
///             These deposits are referred here as dividends sometimes.
///             Deposited tokens are associated with tokenIds and only the owners of such tokenIds
///             are entitled to claim the share of the deposits. If a token is transferred before
///             the associated ERC20 tokens are claimed, these are moved to an address-based
///             mapping deposit. Effectively, at any given time, a user can have claimable tokens
///             associated to the owned tokenIds or associated to the address.
contract KarmaHeadNFT is Ownable, ERC721Royalty, ReentrancyGuard, TokenHandler {
    using Strings for uint256;

    // max supply is fixed at deployment
    uint256 public immutable maxSupply;
    uint256 public totalSupply;

    address public constant ARTIST_ADDRESS = 0xaf19eE3caFB771c3AD4feBb7fF913b0DebbD71A5;
    address public constant VINCI_ADDRESS = 0x82319438d8a2411B996aC142add18467b9a75424;

    uint256 public constant MINT_PRICE = 5.8 ether;
    // fees are expressed in basis points (100% = 10000)
    uint256 internal constant VINCI_FEE_POINTS = 1500; // 15%
    uint256 internal constant BASIS_POINTS = 10000; // 100%
    // as mint price is fixed, all fees are fixed, so set them as constants to save gas
    uint256 internal constant VINCI_FEE = (MINT_PRICE * VINCI_FEE_POINTS) / BASIS_POINTS;
    uint256 internal constant ARTIST_PAYOUT_PER_MINT = MINT_PRICE - VINCI_FEE;

    // fees for secondary sales (handled by decentralized marketplaces)
    uint96 public constant ARTIST_ROYALTY_FEE = 1000; // 10%

    // how much dividend tokens correspond to each NFT (tokenId)
    mapping(address => uint256) public claimablePerNFT;

    // how much has already been claimed per tokenId (tokenId => (Erc20tokenAddress => amount))
    mapping(uint256 => mapping(address => uint256)) internal claimed;

    // address-based mapping for erc20 that have not been claimed before the NFT was transferred
    // for reference: (user => (tokenAddress => claimableAmount))
    mapping(address => mapping(address => uint256)) internal bufferByAddress;

    string internal tokenBaseURI;
    string public contractURI;

    error PaymentFailed();
    error NonExistingToken();
    error NotTokenOwner();
    error InvalidAddress();
    error InvalidTokenAddress();

    event Deposited(address indexed depositor, address erc20Token, uint256 amount);
    event Buffered(address indexed originOwner, uint256 indexed tokenId, address tokenAddress, uint256 amount);
    event Claimed(uint256 indexed tokenId, address indexed holder, address erc20Token, uint256 amount);
    event ClaimedBuffer(address indexed holder, address erc20Token, uint256 amount);
    event WithdrawnEth(uint256 amount);
    event EmergencySplit(address erc20Token, uint256 amount);
    event ArtistMintPayout(uint256 tokenId, uint256 amount);

    constructor(uint256 _maxSupply, address _usdcAddress, address _wethAddress, string memory _tokenBaseURI)
        ERC721("KARMAHEAD", "KARMH")
        TokenHandler(_usdcAddress, _wethAddress)
    {
        maxSupply = _maxSupply;
        tokenBaseURI = _tokenBaseURI;

        contractURI = "https://storage.googleapis.com/nft.byvinci.io/karmahead/collection.json";

        // Standard royalties info (Rarible, and others). Opensea is handled by contractURI()
        _setDefaultRoyalty(ARTIST_ADDRESS, ARTIST_ROYALTY_FEE);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // public & extrenal functions

    /// @notice Mints a specific `tokenId` to `msg.sender`.
    /// @dev Required: msg.value == MINT_PRICE
    ///      Required: `totalSupply` must be lower than `maxSupply` to avoid exceeding `maxSupply`
    ///      Requried: `tokenId` must be within the boundaries (1,12), both inclusive
    ///      Required: `tokenId` must not exist yet (ERC721 will revert otherwise)
    ///      We let the buyer choose the `tokenId` because they are pre-revealed
    ///      Reentrancy guard added to avoid mint being called after transfers or others
    function mint(uint256 tokenId) external payable nonReentrant {
        if (msg.value != MINT_PRICE) revert("KH: Wrong value");
        // here checks if LESS than maxSupply, because it will be increased +1 right after it
        // this line has become redundant because only tokens from 1-12 can be minted
        require(totalSupply < maxSupply, "KH: Max supply reached");
        // tokenIds reperesent album tracks so they mist be in a specific range
        if ((tokenId == 0) || (tokenId > maxSupply)) revert("Invalid tokenId (valid: 1-12)");

        // supply is capped by the requirement statement above
        // unchecked to save about 80 gas
        unchecked {
            totalSupply++;
        }
        _mint(_msgSender(), tokenId);

        // it is a bit unnecessary to print the amount here...
        emit ArtistMintPayout(tokenId, ARTIST_PAYOUT_PER_MINT);

        // every necessary state variable has already been modified. External call is safe now
        // besides, the `ARTIST_ADDRESS` address is known
        (bool success,) = payable(ARTIST_ADDRESS).call{value: ARTIST_PAYOUT_PER_MINT}("");
        if (!success) revert("KH: Payment to Artist failed");
        // remaining eth stays in the contract for Vinci to be withdrawn with withdrawEther
    }

    /// @notice Deposits an `amount` of USDC from `msg.sender` into the contract and splits it into
    ///         the corresponding `claimablePerNFT` dividends for all current NFT holders
    ///         Posterior mints are not entitled to old deposits.
    /// @dev    Required: USDC approved by sender (this contract as spender)
    ///         Required: `amount` must be higher than `totalSupply` to avoid division-by-0 errors
    ///         Required: current `totalSupply` must be non-zero for the same reason
    ///         Reentrancy guard added to avoid deposits in between external calls
    function depositUsdc(uint256 amount) external nonReentrant {
        _depositErc20(usdcAddress, amount);
    }

    /// @dev     Similar to depositUsdc
    function depositWeth(uint256 amount) external nonReentrant {
        _depositErc20(wethAddress, amount);
    }

    /// @notice Transfers USDC dividends associated to the owner of `tokenId`
    /// @dev    Requires: `tokenId` must exist and `msg.sender` must be the owner of the `tokenId`
    function claimUsdc(uint256 tokenId) external nonReentrant {
        _claimErc20(tokenId, usdcAddress);
    }

    /// @dev    Similar to claimUsdc
    function claimWeth(uint256 tokenId) external nonReentrant {
        _claimErc20(tokenId, wethAddress);
    }

    /// @notice Allows to claim the buffered WETH/USDC for a specific address. Tokens are buffered
    ///         when an NFT owner transfers a token with unclaimed USDC/WETH. The original owner
    ///         is still entitled to claim those tokens, so they are buffered in a mapping per
    ///         address. Note that when the original deposit occurs, the USDC/WETH are claimable
    ///         per `tokenId`. It is only when they are transferred that the unclaimed tokens become
    ///         claimabe per address.
    function claimUsdcBufferedPerAddress() external nonReentrant {
        _claimBufferedErc20(usdcAddress);
    }

    /// @dev    Similar to claimUsdcBufferedPerAddress
    function claimWethBufferedPerAddress() external nonReentrant {
        _claimBufferedErc20(wethAddress);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // read only functions

    /// @notice Avilable USDC tokens to be claimed by the owner of `tokenId`
    function claimableUsdc(uint256 tokenId) public view returns (uint256) {
        return _claimableTokensPerTokenId(tokenId, usdcAddress);
    }

    /// @notice Avilable WETH tokens to be claimed by the owner of `tokenId`
    function claimableWeth(uint256 tokenId) public view returns (uint256) {
        return _claimableTokensPerTokenId(tokenId, wethAddress);
    }

    /// @notice Avilable buffered USDC to be claimed by `account`
    function claimableUsdcByAddress(address account) public view returns (uint256) {
        return bufferByAddress[account][usdcAddress];
    }

    /// @notice Avilable buffered WETH to be claimed by `account`
    function claimableWethByAddress(address account) public view returns (uint256) {
        return bufferByAddress[account][wethAddress];
    }

    /// @notice Returns the metadata `uri` for `tokenId`
    /// @dev    Required: `tokenId` must exist
    function tokenURI(uint256 tokenId) public view override returns (string memory uri) {
        if (!_exists(tokenId)) revert NonExistingToken();
        uri = bytes(tokenBaseURI).length > 0 ? string(abi.encodePacked(tokenBaseURI, tokenId.toString(), ".json")) : "";
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // OnlyOwner functions

    /// @notice Sets the Fees in basis points, max is 100%, which corresponds to 10_000 basis points
    function setDefaultRoyalty(address receiver, uint96 numerator) public onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    /// @notice Sets a new BaseURI pointer for the tokens metadata
    function setBaseURI(string memory newTokenBaseURI) public onlyOwner {
        tokenBaseURI = newTokenBaseURI;
    }

    /// @notice Sets a new ContractURI for the collection metadata
    function setContractURI(string memory newContractURI) public onlyOwner {
        contractURI = newContractURI;
    }

    /// @notice Withdraws the contract ether `balance` and sends it to `to`. The ether balance
    ///         is collected from the mints
    /// @dev    Reentrancy protection might be redundant as state changes only happen at the end.
    ///         but... Better be safe than sorry
    function withdrawEther() external nonReentrant {
        require(_msgSender() == VINCI_ADDRESS, "Only VINCI_ADDRESS can withdraw fees");

        uint256 amount = address(this).balance;
        emit WithdrawnEth(amount);

        (bool success,) = payable(VINCI_ADDRESS).call{value: amount}("");
        if (!success) revert PaymentFailed();
    }

    /// @notice This allows the contract owner to rescue lost ERC20 tokens sent to the NFT contract
    ///         Although this is generally unlikely, as this contract is intended to be a dividend
    ///         splitter for the NFT holders, it is not so unlikely that a depositor sends the
    ///         tokens by mistake, although they should be only deposit using the deposit functions.
    /// @dev    Only to be used with well known ERC20 tokens!!!
    ///         Required: `tokenAddress` should not be one of the validTokens (USDC, WETH).
    ///         Otherwise this function would give dangerous power to the contractOwner
    function dangerousTokenRecovery(address tokenAddress, address to) external onlyOwner {
        _recoverTokens(tokenAddress, to);
    }

    /// @notice     In case valid tokens (USDC/WETH) are sent by mistake to the contract using the
    ///             standard ERC20 transfer function, this function allows a split of the current
    ///             contract balance of such ERC20 tokens. This method is not the preferred one,
    ///             and should only be used in case of emergency. Depositors should only use the
    ///             designed functions depositUsdc() and depositWeth().
    ///             Without this function in place, sent USDC/WETH would be lost forever in the
    ///             contract.
    function emergencySplitTokenBalanceInContract(address tokenAddress) external onlyOwner {
        if (!_validToken(tokenAddress)) revert InvalidTokenAddress();

        // save some gas by saving variables into memory
        uint256 supply = totalSupply;
        uint256 amount = IERC20(tokenAddress).balanceOf(address(this));

        require(supply > 0, "KH: Split not allowed (supply=0)");
        require(amount > supply * 1e4, "KH: Deposit too small");

        // dividend per NFT = amount / totalSupply
        // the lost decimals are neglectible given the low supply and the number of token decimals
        claimablePerNFT[tokenAddress] += (amount / supply);

        emit EmergencySplit(tokenAddress, amount);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // internal fuctions with state change

    /// @dev     no need to use reentrancyGuard here because there is no calls to external contraxts
    function _afterTokenTransfer(address from, address, uint256 tokenId, uint256) internal override {
        _clearPendingClaims(tokenId, from, usdcAddress);
        _clearPendingClaims(tokenId, from, wethAddress);
    }

    /// @notice Converts whatever pending claimable amount a `tokenId` has of `erc20TokenAddress`
    ///         into a claimable for the `originOwner` of `tokenId`. This will be triggered only
    ///         when a `tokenId` with unclaimed erc20 tokens transfers the NFT before claiming
    /// @dev    If it is a new mint, the new tokenId is not entitled to the existing claimablePerNFT
    ///         so the claimed amount is set to the current claimable.
    function _clearPendingClaims(uint256 tokenId, address originOwner, address erc20TokenAddress) internal {
        if ((originOwner == address(0)) && (claimablePerNFT[erc20TokenAddress] > 0)) {
            claimed[tokenId][erc20TokenAddress] = claimablePerNFT[erc20TokenAddress];
        } else {
            uint256 pendingAmount = _claimableTokensPerTokenId(tokenId, erc20TokenAddress);
            if (pendingAmount > 0) {
                // unchecked to save about 160 gas in NFT transfers
                // there is not enough USDC/WETH in circulation to overflow these balances
                // [pendingAmount = claimable - claimed], and [claimable >= claimed] always holds
                unchecked {
                    // mark the pending amount as claimed by the tokenId
                    claimed[tokenId][erc20TokenAddress] += pendingAmount;
                    // and buffer it to the original owner, who can claim at any time
                    bufferByAddress[originOwner][erc20TokenAddress] += pendingAmount;
                }
                emit Buffered(msg.sender, tokenId, erc20TokenAddress, pendingAmount);
            }
        }
    }

    function _depositErc20(address tokenAddress, uint256 amount) internal {
        if (!_validToken(tokenAddress)) revert InvalidTokenAddress();

        address sender = _msgSender();

        // save some gas by saving variable into memory
        uint256 supply = totalSupply;

        require(supply > 0, "KH: deposit not allowed (supply=0)");
        require(amount > supply * 1e6, "KH: Deposit too small");

        // Equally distributed among holders: dividend per NFT = amount / totalSupply
        // `amount` > 1e6 and totalSupply <= 12 so the lost decimals are neglectible
        // supply cannot be zero (required above), and the minimum value of supply is 1.
        // upper bound for amount/totalSupply is amount. Amount is capped by the total supply of
        // well known tokens (USDC, WETH) which is capped by uint256.
        // If `amount` was set to an insanely large number to overflow, ERC20.transferFrom would fail
        unchecked {
            // saves about 100 gas to calculate it unchecked
            claimablePerNFT[tokenAddress] += (amount / supply);
        }

        emit Deposited(sender, tokenAddress, amount);

        bool success = IERC20(tokenAddress).transferFrom(sender, address(this), amount);
        if (!success) revert PaymentFailed();
    }

    /// @dev     requires: only token owner can claim pending dividends from tokenId
    function _claimErc20(uint256 tokenId, address tokenAddress) internal {
        if (!_validToken(tokenAddress)) revert InvalidTokenAddress();
        address sender = _msgSender();

        if (ownerOf(tokenId) != sender) revert NotTokenOwner();
        uint256 amount = _claimableTokensPerTokenId(tokenId, tokenAddress);

        if (amount > 0) {
            // saves about 80 gas
            // the claimed amount is bounded by the existing supply of USDC and WETH
            unchecked {
                // This always holdes: amount == claimable - claimed
                // so the line below brings `claimed` up to `claimablePerNFT`
                claimed[tokenId][tokenAddress] += amount;
            }
            emit Claimed(tokenId, sender, tokenAddress, amount);

            bool success = IERC20(tokenAddress).transfer(sender, amount);
            if (!success) revert PaymentFailed();
        } else {
            revert("KH: nothing to claim");
        }
    }

    function _claimBufferedErc20(address tokenAddress) internal {
        if (!_validToken(tokenAddress)) revert InvalidTokenAddress();

        address sender = _msgSender();
        uint256 bufferedAmount = bufferByAddress[sender][tokenAddress];

        if (bufferedAmount > 0) {
            delete bufferByAddress[sender][tokenAddress];

            emit ClaimedBuffer(sender, tokenAddress, bufferedAmount);

            bool success = IERC20(tokenAddress).transfer(sender, bufferedAmount);
            if (!success) revert PaymentFailed();
        } else {
            revert("KH: no tokens for this address");
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // internal ready only functions

    function _claimableTokensPerTokenId(uint256 tokenId, address tokenAddress)
        internal
        view
        returns (uint256 remaining)
    {
        if (!_exists(tokenId)) revert NonExistingToken();
        // This enforces that [claimable >= claimed] always holds
        remaining = claimablePerNFT[tokenAddress] - claimed[tokenId][tokenAddress];
    }
}