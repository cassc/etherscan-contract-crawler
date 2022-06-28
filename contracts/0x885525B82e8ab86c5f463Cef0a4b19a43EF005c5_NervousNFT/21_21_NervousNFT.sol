// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

// ███╗   ██╗███████╗██████╗ ██╗   ██╗ ██████╗ ██╗   ██╗███████╗
// ████╗  ██║██╔════╝██╔══██╗██║   ██║██╔═══██╗██║   ██║██╔════╝
// ██╔██╗ ██║█████╗  ██████╔╝██║   ██║██║   ██║██║   ██║███████╗
// ██║╚██╗██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██║   ██║██║   ██║╚════██║
// ██║ ╚████║███████╗██║  ██║ ╚████╔╝ ╚██████╔╝╚██████╔╝███████║
// ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝  ╚═══╝   ╚═════╝  ╚═════╝ ╚══════╝
// work with us: nervous.net // [email protected] // [email protected]
//
//                             __  __
//                             \ \/ /
//                              >  <
//                             /_/\_\
//
//      ___           ___           ___           ___           ___
//     /__/\         /__/\         /__/\         /__/|         /  /\
//    |  |::\        \  \:\        \  \:\       |  |:|        /  /::\
//    |  |:|:\        \  \:\        \  \:\      |  |:|       /  /:/\:\
//  __|__|:|\:\   ___  \  \:\   _____\__\:\   __|  |:|      /  /:/  \:\
// /__/::::| \:\ /__/\  \__\:\ /__/::::::::\ /__/\_|:|____ /__/:/ \__\:\
// \  \:\~~\__\/ \  \:\ /  /:/ \  \:\~~\~~\/ \  \:\/:::::/ \  \:\ /  /:/
//  \  \:\        \  \:\  /:/   \  \:\  ~~~   \  \::/~~~~   \  \:\  /:/
//   \  \:\        \  \:\/:/     \  \:\        \  \:\        \  \:\/:/
//    \  \:\        \  \::/       \  \:\        \  \:\        \  \::/
//     \__\/         \__\/         \__\/         \__\/         \__\/
//
//
//
// This is Nervous NFT V3. Gas Friendly, Feature Rich, ERC721 future compatible.
//
//                                                 .|\        .-:.
//                                                / / '._____/ /  '.     :          .
//                    .   .              ________/ /    '.__/ /     '.  :         .:'
//                 .-'-.  |  -----/_/_/_/        /'-.     ',='--.     ':        .:'
//        _ .----""""""-^-^--' ()  __     =     /    '-._   '.==='-.  :====.__.:'
//      .'_/  = _ = .-. =  /""/   /_/   /""/   /"'---._  '--u_:.===="|  __:  :'\
//    .'.'/    / / /  /   /__/       = /__/   /_/'.-.' '.  .  . -.-.:|<:::::'   \
//   ..' /     ""  '"'=        //  =         /  """----'  .  (. ' ./#|######'\   \
//  ..--/   =     =        =     =    =     /            .  __ ' /##.'#######\\   \
//  || (-----N-E-R-V-O-U-S---v3------------(--------.___._ (    ;###|#########)---->-"""" ascii art by mga
//  ''  \  _--.-..   __    =          =     \    __    ___'"""-(---"\########//   /
//   ''.-\ \ \ \  \  '\'   .-------._____.   '         \  "\\"" \\###\######//   /
//    '.'.\ \ \ \  \  '\'  \ \   \   \   \\   '   .-    ""''  "" \\.-.\---='/   /
//      '._\ \ \ \  \  '\'  \ \   \   \   \\ = '         \""'-\".-7-. "\"" /-._/
//          '-^-\_\__\  '\'  \ \   \   \   \\   '   .' .---"""""(__  "-_\__---""--.
//                    """"""""--^---^___\___\\   :._____------""""""""  "-_        "
//                                           """""
//
// -----------------------------------------------------------------------------
//

import "./ERC721S.sol";
import "@nervous-net/nervous-contract-kit/src/WalletMintLimit.sol";
import "@nervous-net/nervous-contract-kit/src/MerkleUtil.sol";
import "@nervous-net/nervous-contract-kit/src/MultiTimedSignedPasses.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract NervousNFT is
    ERC721Sequential,
    ReentrancyGuard,
    PaymentSplitter,
    Ownable,
    WalletMintLimit,
    MultiTimedSignedPasses(3)
{
    using Strings for uint256;
    using ECDSA for bytes32;

    error InvalidMerkleProof();
    error InvalidAccessPass();

    struct MintPassPresale {
        uint64 startTimestamp;
        address signer;
    }

    struct MerkleProofPresale {
        uint64 startTimestamp;
        bytes32 root;
    }

    string public constant R =
        "We are Nervous. Are you? Let us help you with your next NFT Project -> [email protected]";

    string public baseURI;
    string private constant PRESALE_PREFIX = "NERVOUS";
    uint8 public constant MAX_PUBLIC_MINT = 10;
    uint256 public immutable maxSupply;
    uint256 public immutable MINT_PRICE;

    uint256 public startPublicMintDate;

    bytes32 public crossmintMerkleRoot;
    address public crossmint;
    uint64 public crossmintPresaleDate;

    bool public hasVIPSaleStarted = true;
    bool public mintingEnabled = true;

    constructor(
        string memory name,
        string memory symbol,
        string memory _initBaseURI,
        uint256 _maxSupply,
        uint256 _mintPrice,
        uint256 _maxMintsPerWallet,
        address[] memory payees,
        uint256[] memory shares
    ) ERC721Sequential(name, symbol) PaymentSplitter(payees, shares) {
        baseURI = _initBaseURI;
        maxSupply = _maxSupply;
        MINT_PRICE = _mintPrice;
        startPublicMintDate = type(uint256).max;

        _setWalletMintLimit(_maxMintsPerWallet);
    }

    ///////
    /// Presale + Public Minting Dates + Statuses
    ///////

    function mintPassPresale(uint256 index)
        external
        view
        returns (MultiTimedSignedPasses.TimedSigner memory)
    {
        return _timedSigners[index];
    }

    function publicSaleHasStarted() external view returns (bool) {
        return block.timestamp >= startPublicMintDate;
    }

    ///////
    /// Minting
    ///////

    /// @notice Main minting. Requires either valid pass or public sale
    function mint(uint256 numTokens, bytes calldata pass)
        external
        payable
        requireValidMint(numTokens, msg.sender)
        requireValidMintPass(msg.sender, pass)
    {
        _mintTo(numTokens, msg.sender);
    }

    /// @notice Crossmint public minting without a proof
    function crossmintTo(uint256 numTokens, address to)
        external
        payable
        requireCrossmint
        requirePublicSale
        requireValidMint(numTokens, to)
    {
        _mintTo(numTokens, to);
    }

    /// @notice Crossmint presale or public minting. Requires proof if presale
    function crossmintPresaleMintTo(
        uint256 numTokens,
        address to,
        bytes32[] calldata merkleProof
    )
        external
        payable
        requireCrossmint
        requireValidMint(numTokens, to)
        requireValidCrossmintMerkleProof(to, merkleProof)
    {
        _mintTo(numTokens, to);
    }

    /// @notice internal method for minting a number of tokens to an address
    function _mintTo(uint256 numTokens, address to) internal nonReentrant {
        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(to);
        }
    }

    ///////
    /// Magic
    ///////

    /// @notice owner-only minting tokens to the owner wallet
    function magicMint(uint256 numTokens) external onlyOwner {
        require(
            totalMinted() + numTokens <= maxSupply,
            "Exceeds maximum token supply."
        );

        require(
            numTokens > 0 && numTokens <= 100,
            "Machine can dispense a minimum of 1, maximum of 100 tokens"
        );

        _mintTo(numTokens, msg.sender);
    }

    /// @notice owner-only minting tokens to receiver wallets
    function magicGift(address[] calldata receivers) external onlyOwner {
        uint256 numTokens = receivers.length;
        require(
            totalMinted() + numTokens <= maxSupply,
            "Exceeds maximum token supply."
        );

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(receivers[i]);
        }
    }

    /// @notice owner-only minting tokens of varying counts to
    /// receiver wallets
    function magicBatchGift(
        address[] calldata receivers,
        uint256[] calldata mintCounts
    ) external onlyOwner {
        require(receivers.length == mintCounts.length, "Length mismatch");

        for (uint256 i = 0; i < receivers.length; i++) {
            address to = receivers[i];
            uint256 numTokens = mintCounts[i];
            require(
                totalMinted() + numTokens <= maxSupply,
                "Exceeds maximum token supply."
            );
            _mintTo(numTokens, to);
        }
    }

    ///////
    /// Utility
    ///////

    /* URL Utility */

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    /* eth handlers */

    function withdraw(address payable account) external virtual {
        release(account);
    }

    function withdrawERC20(IERC20 token, address to) external onlyOwner {
        token.transfer(to, token.balanceOf(address(this)));
    }

    /* Crossmint */

    function setCrossmint(address _crossmint) external onlyOwner {
        crossmint = _crossmint;
    }

    /* Sale & Minting Control */

    function setPublicSaleStart(uint256 timestamp) external onlyOwner {
        startPublicMintDate = timestamp;
    }

    function startVIPSale() external onlyOwner {
        hasVIPSaleStarted = true;
    }

    function setPublicMintDate(uint256 _startPublicMintDate)
        external
        onlyOwner
    {
        startPublicMintDate = _startPublicMintDate;
    }

    function setCrossMintPresale(uint64 startTimestamp, bytes32 root)
        external
        onlyOwner
    {
        crossmintMerkleRoot = root;
        crossmintPresaleDate = startTimestamp;
    }

    function setMintPassPresale(
        uint256 index,
        uint64 startTimestamp,
        address signer
    ) external onlyOwner {
        _setTimedSigner(index, signer, startTimestamp);
    }

    function toggleMinting() external onlyOwner {
        mintingEnabled = !mintingEnabled;
    }

    ///////
    /// Modifiers
    ///////

    modifier requirePublicSale() {
        if (block.timestamp < startPublicMintDate) {
            revert("Public sale hasn't started");
        }
        _;
    }

    modifier requireValidMint(uint256 numTokens, address to) {
        require(mintingEnabled, "Minting isn't enabled");
        require(totalMinted() + numTokens <= maxSupply, "Sold Out");
        require(
            numTokens > 0 && numTokens <= MAX_PUBLIC_MINT,
            "Machine can dispense a minimum of 1, maximum of 10 tokens"
        );
        require(
            msg.value >= numTokens * MINT_PRICE,
            "Insufficient Payment: Amount of Ether sent is not correct."
        );
        if (block.timestamp < startPublicMintDate) {
            _limitWalletMints(to, numTokens);
        }
        _;
    }

    modifier requireValidMintPass(address to, bytes memory pass) {
        if (block.timestamp < startPublicMintDate) {
            if (!_checkTimedSigners(PRESALE_PREFIX, to, pass)) {
                revert("Invalid presale pass; public sale hasn't started");
            }
        }
        _;
    }

    modifier requireValidCrossmintMerkleProof(
        address to,
        bytes32[] calldata proof
    ) {
        if (block.timestamp < startPublicMintDate) {
            if (proof.length == 0) {
                revert("Public sale hasn't started");
            }
            if (block.timestamp < crossmintPresaleDate) {
                revert("Crossmint access list presale hasn't started");
            }
            if (
                !MerkleUtil.verifyAddressProof(to, crossmintMerkleRoot, proof)
            ) {
                revert("Invalid crossmint access list proof");
            }
        }
        _;
    }

    modifier requireCrossmint() {
        require(msg.sender == crossmint, "Crossmint only");
        _;
    }
}

//                                                                 .:^!7???7!~~~~!!77777!~^:.
//                                                            .:~!77!~^:.   ^!77??JJJ??~.:^~!7!~.
//                                                         :!77!^:.       ^P5YPPGGGGGP5B~     :~??:
//                                                     .~77!^.            ^G#&@@&&&@@&#P:        :J~
//                                                   ^7?~:                 .^7J555Y?7~:            ?^
//                                                .!?!:                                            .Y
//                                              :7?^                                                J!
//                                            ^??^                                                  ^Y
//                                          ^??:                                                     5:
//                                        ^J?:                                                       ?!
//                                      ^J?:                                                         ^5
//                                    :??:                                                            P:
//                                  :?J^                                                              J7
//                                .?J~                                                                ~Y
//                              :?Y~                                                                  :P
//                            :?J~                                                                    :P
//                          ^JJ^                                                                      :G
//                       .!J7:                                                                        :G
//                    .~7?~.                                                                          :G
//                 .~7?!:                                                                             ^G
//              .~??!:                                                                                ~P
//          .^!?7~.                                                                                   JJ
//   ?5?7!7??!^.                                                                                      P~
//    7PPY^.                                                                         ..              !P
//  75Y?J7.                                                                          7Y^            ~P:
//  .^7??!~:.                                                                        7Y.        .^7Y?.
//      .^!7???7!~^:.                                                                ..   .^~!J5?!?B
//            .:~!7??J??7!!~^:.                                                        !?77!~^~5!~?7
//                    .:^^~!!!77???77!~~^^:...                                         ?Y7^.    ::
//                               ..::^~~!777??77777!!!~~^^::.....                    ...:!?P!
//                                              ....::^~~!!777777??????7!!!!!!!!!!!!~~~~~~^:
//