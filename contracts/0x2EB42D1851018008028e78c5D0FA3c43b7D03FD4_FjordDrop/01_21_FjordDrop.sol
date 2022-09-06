// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;
//OpenZeppelin
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
//AlchemistCoin
import "@alchemist.wtf/token-extensions/contracts/Erc721BurningErc20OnMint.sol";

//   _____    _ _   ______                     _____ _               _
//  |  ___|__| | |_|__  (_)_ __   ___  __  __ |  ___(_) ___  _ __ __| |
//  | |_ / _ \ | __| / /| | '_ \ / _ \ \ \/ / | |_  | |/ _ \| '__/ _` |
//  |  _|  __/ | |_ / /_| | | | |  __/  >  <  |  _| | | (_) | | | (_| |
//  |_|  \___|_|\__/____|_|_| |_|\___| /_/\_\ |_|  _/ |\___/|_|  \__,_|
//                                                |__/

/*
 @title Lost Echoes | FELT Zine x Fjord Drop 1
 @notice FELT Zine & Fjord present a series of experimental NFT collections
 @artist Ina Vare with executive production by Mark Sabb of Felt Zine
 @dev javvvs.eth
 */

contract FjordDrop is Erc721BurningErc20OnMint, ReentrancyGuard, IERC2981 {
/*//////////////////////////////////////////////////////////////
                        ERRORS
//////////////////////////////////////////////////////////////*/

    error FJORD_TotalMinted();
    error FJORD_InexactPayment();
    error FJORD_MaxMintExceeded();
    error FJORD_WhitelistMaxSupplyExceeded();
    error FJORD_WhitelistMintEnded();
    error FJORD_PublicMintisNotActive();

/*//////////////////////////////////////////////////////////////
                        EVENTS
//////////////////////////////////////////////////////////////*/

    event MintedAnNFT(address indexed to, uint256 indexed tokenId);

/*//////////////////////////////////////////////////////////////
                        STATE VARIABLES
//////////////////////////////////////////////////////////////*/

    uint16 public mintCounter;
    uint16 public constant TOTAL_SUPPLY = 525;
    string public customBaseURI;
    string public contractURI =
        "ipfs://QmdyYCtUsVsC5ymr7b4txQ6hXHpLXtJU7JXCDuHEJdXnRe";
    address private mainnetFjordAddress =
        0x6f435948d9ad4cA0a73a3257743528469899ceec;
    uint256 public whitelistEndDate;
    uint256 private constant PRICE_PER_WHITELIST_NFT = 0.02 ether;
    bytes32 public whiteListSaleMerkleRoot;
    uint32 private constant MAX_MINT_PER_WHITELIST_WALLET = 2;
    mapping(address => uint32) public mintPerWhitelistedWallet;

    uint256 private PRICE_PER_PUBLIC_MINT;
    bool public isPublicMintActive;

/*//////////////////////////////////////////////////////////////
                        INIT/CONSTRUCTOR
//////////////////////////////////////////////////////////////*/

    constructor(
        string memory customBaseURI_,
        bytes32 whiteListSaleMerkleRoot_,
        uint256 mintQtyToOwner
    ) ERC721("Fjord Collection #1", "FJORD") {
        customBaseURI = customBaseURI_;
        whiteListSaleMerkleRoot = whiteListSaleMerkleRoot_;
        for (uint i = 0; i < mintQtyToOwner; i++) {
            unchecked {
                mintCounter++;
            }
            uint256 tokenId = mintCounter;
            _mint(msg.sender, tokenId);
        }
    }

/*//////////////////////////////////////////////////////////////
                        MODIFIERS
//////////////////////////////////////////////////////////////*/

    modifier isValidMerkleProof(bytes32[] calldata _proof, bytes32 root) {
        require(
            MerkleProof.verify(
                _proof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address is not whitelisted"
        );
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        ONLY OWNER
//////////////////////////////////////////////////////////////*/

    /// @notice set _time in  Unix Time Stamp to end the whitelist sale
    function setEndDateWhitelist(uint256 time_) public {
        whitelistEndDate = block.timestamp + time_;
    }

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        customBaseURI = customBaseURI_;
    }

    function setFjordContractAddress(address mainnetFjordAddress_) external onlyOwner {
        mainnetFjordAddress = mainnetFjordAddress_;
    }

    function setIsPublicMintActive(bool isPublicMintActive_)
        external
        onlyOwner
    {
        isPublicMintActive = isPublicMintActive_;
    }

    function setPublicMintPrice(uint256 price) external onlyOwner {
        PRICE_PER_PUBLIC_MINT = price;
    }

/*//////////////////////////////////////////////////////////////
                            MINT
//////////////////////////////////////////////////////////////*/

    /// @notice mint implementation interfacing w Erc721BurningErc20OnMint contract

    function mint() public override nonReentrant returns (uint256) {
        if (mintCounter == TOTAL_SUPPLY) {
            revert FJORD_TotalMinted();
        } else {
            unchecked {
                mintCounter++;
            }
            uint256 tokenId = mintCounter;
            _mint(msg.sender, tokenId);
            return tokenId;
        }
    }

    /// @notice mint implementation for the whitelisted wallets

    function whitelistMint(uint256 amount, bytes32[] calldata merkleProof)
        public
        payable
        isValidMerkleProof(merkleProof, whiteListSaleMerkleRoot)
    {
        //cache the current minted amount by the wallet address
        uint256 totalMinted = mintPerWhitelistedWallet[msg.sender];
        if (msg.value != PRICE_PER_WHITELIST_NFT * amount) {
            revert FJORD_InexactPayment();
        } else if (block.timestamp >= whitelistEndDate) {
            revert FJORD_WhitelistMintEnded();
        } else {
            require(
                totalMinted + amount <= MAX_MINT_PER_WHITELIST_WALLET,
                "Max mint exceeded"
            );
            uint256 i;
            for (i = 0; i < amount; i++) {
                unchecked {
                    mintCounter++;
                    mintPerWhitelistedWallet[msg.sender]++;
                }
                // cache the minteCounter as the tokenId to mint
                uint256 tokenId = mintCounter;
                _mint(msg.sender, tokenId);
                emit MintedAnNFT(msg.sender, tokenId);
            }
        }
    }

    /// @notice public mint implementation.
    /// @dev max mint per wallet is 4
    function publicMint(uint256 _amount) public payable {
        if (!isPublicMintActive) {
            revert FJORD_PublicMintisNotActive();
        } else if (mintCounter == TOTAL_SUPPLY) {
            revert FJORD_TotalMinted();
        } else if (msg.value != PRICE_PER_PUBLIC_MINT * _amount) {
            revert FJORD_InexactPayment();
        } else {
            uint256 i;
            for (i = 0; i < _amount; i++) {
                unchecked {
                    mintCounter++;
                }
                uint256 tokenId = mintCounter;
                _mint(msg.sender, tokenId);
                emit MintedAnNFT(msg.sender, tokenId);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(Erc721BurningErc20OnMint) {
        // check if it's a mint through the Copper's contract
        if (to == mainnetFjordAddress) {
            Erc721BurningErc20OnMint._beforeTokenTransfer(from, to, amount);
        } else {
            ERC721._beforeTokenTransfer(from, to, amount);
        }
    }

/*//////////////////////////////////////////////////////////////
                            READ
//////////////////////////////////////////////////////////////*/

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(super.tokenURI(tokenId)));
    }

    function totalSupply() public view returns (uint256) {
        return mintCounter;
    }

    /*//////////////////////////////////////////////////////////////
                WITHDRAW AND ROYALTIES FUNCTIONS
//////////////////////////////////////////////////////////////*/

    ///@notice sets the royalties for secondary sales.
    ///Override function gets royalty information for a token (EIP-2981)
    ///@param salePrice as an input to calculate the royalties
    ///@dev conforms to EIP-2981

    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), (salePrice * 10) / 100);
    }

    //PAYOUT ADDRESSES
    address private constant feltzine = 0x5e080D8b14c1DA5936509c2c9EF0168A19304202;
    address private constant artist = 0xb012A1bDCA34E1d0c2267bb50e6c53C8042eB4b6;
    address private constant dev = 0x52aA63A67b15e3C2F201c9422cAC1e81bD6ea847;
    //@notice : withdraws the royalties to the addresses above
    function withdraw() public nonReentrant onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(feltzine), (balance * 375) / 1000);
        Address.sendValue(payable(artist), (balance * 375) / 1000);
        Address.sendValue(payable(dev), (balance * 250) / 1000);
    }
    //Fallback
    receive() external payable {}
}