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
    error FJORD_FjordIsNotActive();

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
    uint256 public whitelistEndDate;
    uint256 private constant PRICE_PER_WHITELIST_NFT = 0.02 ether;
    bytes32 public whiteListSaleMerkleRoot;
    uint32 private constant MAX_MINT_PER_WHITELIST_WALLET = 2;
    mapping(address => uint32) public mintPerWhitelistedWallet;
    uint256 private PRICE_PER_PUBLIC_MINT= 0.02 ether;
    
    enum MintPhase {
    ONLY_MINT_OWNER,    
    NOT_ACTIVE,
    WHITELIST,
    FJORD,
    PUBLIC
}
    MintPhase public stage = MintPhase.ONLY_MINT_OWNER;
/*//////////////////////////////////////////////////////////////
                        INIT/CONSTRUCTOR
//////////////////////////////////////////////////////////////*/
    constructor(
        string memory customBaseURI_,
        bytes32 whiteListSaleMerkleRoot_,
        uint256 mintQtyToOwner
    ) ERC721("Lost Echoes by Felt Zine", "FFLE") {
        customBaseURI = customBaseURI_;
        whiteListSaleMerkleRoot = whiteListSaleMerkleRoot_;
        for (uint256 i = 0; i < mintQtyToOwner; i++) {
            unchecked {
                mintCounter++;
            }
            uint256 tokenId = mintCounter;
            _mint(msg.sender, tokenId);
        }
        stage = MintPhase.NOT_ACTIVE;
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
    function setEndDateWhitelist(uint256 time_) external onlyOwner {
        whitelistEndDate = block.timestamp + time_;
    }
    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        customBaseURI = customBaseURI_;
    }
    //@notice: owner set the different states of the minting phase
    // 0 = ONLY_MINT_OWNER, 1 = NOT_ACTIVE, 2 = WHITELIST, 3 = FJORD, 4 = PUBLIC
    function setMintStage(MintPhase val_) external onlyOwner {
        stage = val_;
    }
    function setPublicMintPrice(uint256 price) external onlyOwner {
        PRICE_PER_PUBLIC_MINT = price;
    }

/*//////////////////////////////////////////////////////////////
                            MINT
//////////////////////////////////////////////////////////////*/

    /// @notice mint implementation interfacing w Erc721BurningErc20OnMint contract

    function mint() public override nonReentrant returns (uint256) {
        require(stage == MintPhase.FJORD, "Fjord drop is not active");
       if (mintCounter >= TOTAL_SUPPLY) {
            revert FJORD_TotalMinted();
        }  else  {
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
        uint256 whitelistAllocation = 100;
          require(stage == MintPhase.WHITELIST, "Whitelist Mint is disabled");
        if (msg.value != PRICE_PER_WHITELIST_NFT * amount) {
            revert FJORD_InexactPayment();
        } else if(mintCounter + amount > whitelistAllocation ){
            revert('whitelist mint  exceeded');
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

    
    function publicMint(uint256 _amount) public payable {
        require(stage == MintPhase.PUBLIC, "Public Mint is disabled");
         if (msg.value != PRICE_PER_PUBLIC_MINT * _amount) {
            revert FJORD_InexactPayment();
        } else if (mintCounter + _amount > TOTAL_SUPPLY){
            revert FJORD_MaxMintExceeded();
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
        require(stage != MintPhase.NOT_ACTIVE, "Minting is not active");
        if (stage == MintPhase.FJORD) {
            Erc721BurningErc20OnMint._beforeTokenTransfer(from, to, amount);
        } else if(stage == MintPhase.PUBLIC || stage == MintPhase.ONLY_MINT_OWNER || stage == MintPhase.WHITELIST) {
            ERC721._beforeTokenTransfer(from, to, amount);
        } else{
        revert('Minting error');
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