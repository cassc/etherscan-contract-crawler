// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;
//OpenZeppelin
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
//AlchemistCoin
import "@alchemist.wtf/token-extensions/contracts/Erc721BurningErc20OnMint.sol";


//    ▄█    █▄       ▄████████  ▄█        ▄█               ▄█    █▄     ▄██████▄  ███    █▄     ▄████████    ▄████████ 
//   ███    ███     ███    ███ ███       ███              ███    ███   ███    ███ ███    ███   ███    ███   ███    ███ 
//   ███    ███     ███    █▀  ███       ███              ███    ███   ███    ███ ███    ███   ███    █▀    ███    █▀  
//  ▄███▄▄▄▄███▄▄  ▄███▄▄▄     ███       ███             ▄███▄▄▄▄███▄▄ ███    ███ ███    ███   ███         ▄███▄▄▄     
// ▀▀███▀▀▀▀███▀  ▀▀███▀▀▀     ███       ███            ▀▀███▀▀▀▀███▀  ███    ███ ███    ███ ▀███████████ ▀▀███▀▀▀     
//   ███    ███     ███    █▄  ███       ███              ███    ███   ███    ███ ███    ███          ███   ███    █▄  
//   ███    ███     ███    ███ ███▌    ▄ ███▌    ▄        ███    ███   ███    ███ ███    ███    ▄█    ███   ███    ███ 
//   ███    █▀      ██████████ █████▄▄██ █████▄▄██        ███    █▀     ▀██████▀  ████████▀   ▄████████▀    ██████████ 
//                             ▀         ▀                                                                             

/*
 @title Hell House | FELT Zine x Fjord Drop 2
 @notice FELT Zine & Fjord present a series of experimental NFT collections
 @artist Mark Sabb of Felt Zine
 @dev javvvs.eth
 */

contract HellHouse is Erc721BurningErc20OnMint, ReentrancyGuard, IERC2981{

/*//////////////////////////////////////////////////////////////
                        ERRORS
//////////////////////////////////////////////////////////////*/

    error FJORD_TotalMinted();
    error FJORD_InexactPayment();
    error FJORD_MaxMintExceeded();

/*//////////////////////////////////////////////////////////////
                        EVENTS
//////////////////////////////////////////////////////////////*/

    event MintedAnNFT(address indexed to, uint256 indexed tokenId);

/*//////////////////////////////////////////////////////////////
                        STATE VARIABLES
//////////////////////////////////////////////////////////////*/

    uint16 public mintCounter;
    uint16 public constant TOTAL_SUPPLY = 777;
    string public customBaseURI;
    string public contractURI =
        "ipfs://QmZvf1ZS2nnFh6sj8G61TmzLetvB82458SXU1TCNqLZD6u";
    uint256 private PRICE_PER_PUBLIC_MINT;

    enum MintPhase {
        INACTIVE,
        FJORD,
        PUBLIC
    }
    MintPhase public stage = MintPhase.INACTIVE;

/*//////////////////////////////////////////////////////////////
                        INIT/CONSTRUCTOR
//////////////////////////////////////////////////////////////*/
    constructor(string memory customBaseURI_) ERC721("HellHouse", "HHOUSE") {
        customBaseURI = customBaseURI_;
        stage = MintPhase.INACTIVE;
    }

/*//////////////////////////////////////////////////////////////
                        ONLY OWNER
//////////////////////////////////////////////////////////////*/

    //@notice: owner set the different states of the minting phase
    // 0 = INACTIVE  1 = FJORD  2 = PUBLIC
    function setMintStage(MintPhase val_) external onlyOwner {
        stage = val_;
    }

    function setPublicMintPrice(uint256 price) external onlyOwner {
        PRICE_PER_PUBLIC_MINT = price;
    }
    function updateMetadata(string memory newURI) external onlyOwner {
        customBaseURI = newURI;
    }

/*//////////////////////////////////////////////////////////////
                            MINT
//////////////////////////////////////////////////////////////*/

    /// @notice mint implementation interfacing w Erc721BurningErc20OnMint contract

    function mint() public override nonReentrant returns (uint256) {
        require(stage == MintPhase.FJORD, "Fjord drop is not active");
        if (mintCounter >= TOTAL_SUPPLY) {
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

    function publicMint(uint256 _amount) public payable {
        require(stage == MintPhase.PUBLIC, "Public Mint is disabled");
        if (msg.value != PRICE_PER_PUBLIC_MINT * _amount) {
            revert FJORD_InexactPayment();
        } else if (mintCounter + _amount > TOTAL_SUPPLY) {
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
        require(stage != MintPhase.INACTIVE, "Minting is not active");
        if (stage == MintPhase.FJORD) {
            Erc721BurningErc20OnMint._beforeTokenTransfer(from, to, amount);
        } else if (stage == MintPhase.PUBLIC) {
            ERC721._beforeTokenTransfer(from, to, amount);
        } else {
            revert("Minting error");
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
    address private constant feltzine =
        0x5e080D8b14c1DA5936509c2c9EF0168A19304202;
    address private constant dev = 0x52aA63A67b15e3C2F201c9422cAC1e81bD6ea847;

    //@notice : withdraws the royalties to the addresses above
    function withdraw() public nonReentrant onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(feltzine), (balance * 750) / 1000);
        Address.sendValue(payable(dev), (balance * 250) / 1000);
    }

    //Fallback
    receive() external payable {}
}