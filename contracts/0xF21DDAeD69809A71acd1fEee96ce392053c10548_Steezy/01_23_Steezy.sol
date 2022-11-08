// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "hardhat/console.sol";

contract Steezy is ERC721Enumerable, Pausable, Ownable, ERC721Royalty, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    string baseURI;
    uint256 constant MAX_SUPPLY = 6_969;
    uint64 constant MAX_MINT_AMOUNT = 50;

    bool public presaleActive = true;
    uint256 private presaleCost = 0.016 ether;
    uint256 public cost = 0.018 ether;

    bool public revealed = false;
    string public nonRevealedURI;

    uint96 private immutable royalty = 690; // 6.9%

    // Smoke Token address as reward token on mint
    IERC20 token;


    constructor(
        address _rewardTokenAddress,
        string memory _initBaseURI,
        string memory _initNonRevealedURI
    ) ERC721("Steezy", "STZY") {
        token = IERC20(_rewardTokenAddress);

        setBaseURI(_initBaseURI);
        setNonRevealedURI(_initNonRevealedURI);

        _setDefaultRoyalty(owner(), royalty);
        _tokenIdCounter.increment(); // to start token ids from 1 not 0
    }

    receive() external payable {}

    fallback() external payable {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    modifier beforeMint(uint256 _mintAmount) {
        require(totalSupply().add(_mintAmount) <= MAX_SUPPLY, "I'm sorry we reached the cap");
        require(
            _mintAmount <= MAX_MINT_AMOUNT || _msgSender() == owner(),
            "Max mint amount reached"
        );
        _;
    }

    /**
     * Mint upto max 50 NFTs to msg.sender
     * should be under supply and have enough ETH for each NFT price
     */
    function mint(uint256 mintAmount)
        public
        payable
        nonReentrant
        whenNotPaused
        beforeMint(mintAmount)
    {
        if (_msgSender() != owner()) {
            if (presaleActive) {
                //presale
                require(
                    presaleCost.mul(mintAmount) <= msg.value,
                    "Ether value sent is not correct"
                );
            } else {
                //Public sale
                require(cost.mul(mintAmount) <= msg.value, "Ether value sent is not correct");
            }
        }

        for (uint256 i = 0; i < mintAmount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            if (tokenId < MAX_SUPPLY) {
                _safeMint(_msgSender(), tokenId);
                _tokenIdCounter.increment();
            }
        }

        token.transfer(_msgSender(), mintAmount * 10 ether);
    }

    /**
     * Mint upto max 50 NFTs to the recipient
     * should be under supply and have enough ETH for each NFT price
     * used by useWinter
     */
    function mint(uint256 mintAmount, address _recipient)
        external
        payable
        nonReentrant
        whenNotPaused
        beforeMint(mintAmount)
    {
        if (_msgSender() != owner()) {
            if (presaleActive) {
                //presale
                require(
                    presaleCost.mul(mintAmount) <= msg.value,
                    "Ether value sent is not correct"
                );
            } else {
                //Public sale
                require(cost.mul(mintAmount) <= msg.value, "Ether value sent is not correct");
            }
        }

        for (uint256 i = 0; i < mintAmount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            if (tokenId < MAX_SUPPLY) {
                _safeMint(_recipient, tokenId);
                _tokenIdCounter.increment();
            }
        }

        token.transfer(_recipient, mintAmount * 10 ether);
    }

    /**
     * Hook that is called before any token transfer. This includes minting and burning.
     *
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    /**
     * The denominator with which to interpret the fee
     * Defaults to 10000 so fees are expressed in basis points (one part per ten thousand, 1/10,000)
     */
    function _feeDenominator() internal pure override returns (uint96) {
        return super._feeDenominator();
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    /**
     * @dev tokenURI overides the Openzeppelin's ERC721 implementation for tokenURI function
     * This function returns the URI from where we can extract the metadata for a given tokenId
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        _requireMinted(tokenId);

        if (revealed == false) {
            return nonRevealedURI;
        }

        string memory base = _baseURI();

        return
            bytes(base).length > 0
                ? string(abi.encodePacked(base, tokenId.toString(), ".json"))
                : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setPresaleCost(uint256 _newCost) public onlyOwner {
        presaleCost = _newCost;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNonRevealedURI(string memory _newURI) public onlyOwner {
        nonRevealedURI = _newURI;
    }

    function reveal(bool _reveal) public onlyOwner {
        revealed = _reveal;
    }

    //activate/deactivate presale to public sae
    function setSaleStatus(bool _status) public onlyOwner {
        presaleActive = _status;
    }

    /**
     * Set some Steezy aside
     * no max mint amount limit & cost for owner wallet
     */
    function reserveSteezy(uint256 _mintAmount)
        public
        onlyOwner
        beforeMint(_mintAmount)
        whenNotPaused
    {
        for (uint256 i = 0; i < _mintAmount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            if (tokenId < MAX_SUPPLY) {
                _safeMint(_msgSender(), tokenId);
                _tokenIdCounter.increment();
            }
        }
    }

    function withdraw() public onlyOwner whenPaused {
        // This will payout the owner 100% of the contract balance.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function withdrawContractRewardTokens() public onlyOwner whenPaused returns (bool) {
        bool success = token.transfer(_msgSender(), token.balanceOf(address(this)));
        require(success, "Token Transfer failed.");
        return true;
    }
}