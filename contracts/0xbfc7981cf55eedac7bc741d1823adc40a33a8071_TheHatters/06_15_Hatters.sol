// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./IERC20.sol";

/** @dev Contract definition */
contract TheHatters is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    /** @dev Contract constructor. Defines mapping between index and atributes.*/
    constructor() ERC721("TheHatters", "TH") {
        FreeMintRemaining[0xaF4A5dabb5d922B4CDAA5fDf2EdDABade6895f85] = 125; // Team
        FreeMintRemaining[0x93047a655E7cD6DDfedbE997c72b0B0458049099] = 125; // Team
        FreeMintRemaining[0xD54560d6Bf696632047cAab9135A0601ecE308b1] = 50; // GiveAway
    }

    /** @dev _beforeTokenTransfer must be overriden to make compiler happy.*/
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /** @dev supportsInterface must be overriden to make compiler happy.*/
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /** @dev Will be set to true when reveal is done.*/
    bool public isRevealed = false;

    /** @dev Link to the metadata to display before reveal.*/
    string public beforeRevealMetadata =
        "ipfs://QmaErcRFo85BMrGSSSu76MPpEA1mgiHqzPrufKGqUaUF9R";

    /** @dev Defines if an address can mint for free.*/
    mapping(address => uint16) public FreeMintRemaining;

    /** @dev Devs' addresses. Where token will be sent when withdraw is called.*/
    address payable withdrawAddress =
        payable(0xD54560d6Bf696632047cAab9135A0601ecE308b1);

    /** @dev Price for miniting one NFT, in wei.*/
    uint256 public publicPrice = 25e15;

    /** @dev Extension of base URI. Used to move metadata files if needed.*/
    string private _baseURIextended;

    /** @dev Max number of NFTs to mint.*/
    uint16 public NFTsLimit = 5000;

    /** @dev NFTs minted.*/
    uint16 public NFTsMinted = 0;

    /** @dev Max number of NFT that can be minted at once.*/
    uint16 public maxNumberToMint = 2;

    /** @dev Addressed that had their free mint.*/
    mapping(address => bool) public hasAlreadyMintedForFree;

    /** @dev number of people that has minted for free.*/
    uint16 public nbhasAlreadyMintedForFree = 0;

    /** @dev max number of people that has minted for free.*/
    uint16 public maxMintedForFree = 1500;

    /** @dev Changing baseUri to move metadata files and images if needed.*/
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    /** @dev Changing miniting price if needed.*/
    function setPublicPrice(uint256 newPrice) external onlyOwner {
        publicPrice = newPrice;
    }

    /** @dev Changing path to before reveal metadata if needed.*/
    function setBeforeRevealMetadata(string memory metadata)
        external
        onlyOwner
    {
        beforeRevealMetadata = metadata;
    }

    /** @dev Override of _baseUri().*/
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (isRevealed) {
            return super.tokenURI(tokenId);
        }
        return beforeRevealMetadata;
    }

    /** @dev withdrawing tokens received from miniting price.*/
    function withdraw() public {
        withdrawAddress.transfer(address(this).balance);
    }

    /** @dev withdrawing tokens of an IERC contract.*/
    function withdrawToken(address _tokenContract) public {
        IERC20 tokenContract = IERC20(_tokenContract);
        uint256 balance = tokenContract.balanceOf(address(this));
        tokenContract.transfer(withdrawAddress, balance);
    }

    /** @dev Mint an NFT.*/
    function mint(uint16 numberToMint) public payable nonReentrant {
        require(
            numberToMint <= maxNumberToMint,
            "You can't mint as much tokens at a time."
        );
        require(
            NFTsMinted + numberToMint <= NFTsLimit,
            "All NFTs have already been minted"
        );

        // Deal with free mints
        uint16 numberToPay = numberToMint;
        if (FreeMintRemaining[msg.sender] >= numberToMint) {
            numberToPay = 0;
            FreeMintRemaining[msg.sender] -= numberToMint;
        } else if (FreeMintRemaining[msg.sender] != 0) {
            numberToPay -= FreeMintRemaining[msg.sender];
            FreeMintRemaining[msg.sender] = 0;
        }

        // Deal with overyone else free mints
        if (
            msg.sender != 0xaF4A5dabb5d922B4CDAA5fDf2EdDABade6895f85 && // excludes team from this feature
            msg.sender != 0x93047a655E7cD6DDfedbE997c72b0B0458049099 && // excludes team from this feature
            msg.sender != 0xD54560d6Bf696632047cAab9135A0601ecE308b1 && // excludes team from this feature
            !hasAlreadyMintedForFree[msg.sender] &&
            nbhasAlreadyMintedForFree < maxMintedForFree
        ) {
            numberToPay = numberToMint - 1;
            hasAlreadyMintedForFree[msg.sender] = true;
            nbhasAlreadyMintedForFree += 1;
        }
        require(
            msg.value >= numberToPay * publicPrice,
            string(
                abi.encodePacked(
                    "You must send ",
                    Strings.toString(publicPrice),
                    " wei to mint a token."
                )
            )
        );
        for (uint256 index = 0; index < numberToMint; index++) {
            NFTsMinted += 1;
            _safeMint(msg.sender, NFTsMinted);
        }
    }

    /** @dev reveal tokens by setting the correct baseURI.*/
    function revealNFTs() external onlyOwner {
        isRevealed = true;
    }

    /** @dev disable possibility to mint first token for free.*/
    function disableFreeMints() external onlyOwner {
        maxMintedForFree = nbhasAlreadyMintedForFree;
    }
}
