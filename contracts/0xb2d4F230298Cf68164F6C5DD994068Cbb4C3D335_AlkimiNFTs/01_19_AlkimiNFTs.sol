// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IStaking.sol";

contract AlkimiNFTs is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 public ethPrice = 0.25 ether;
    bool public saleActive;
    bool public claimingActive;
    IERC20 public ADS;
    IStaking public STAKING;
    string public uri = "";

    mapping(address => bool) claimedADS;
    mapping(address => uint256) claimedNFTs;

    constructor(address _owner, address _adsAddress, address _stakingAddress) ERC721("Alkimi NFTs", "Alkimi NFTs") Ownable() {
        transferOwnership(_owner);
        ADS = IERC20(_adsAddress);
        STAKING = IStaking(_stakingAddress);
    }

    function safeMint(address to) external onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function toggleNFTSale() external onlyOwner {
        saleActive = !saleActive;
    }

    function toggleClaiming() external onlyOwner {
        claimingActive = !claimingActive;
    }

    function changePrice(uint256 _newPrice) external onlyOwner {
        ethPrice = _newPrice;
    }

    function purchaseNFT() external payable {
        require(saleActive, "Sale must be active");
        require(msg.value == ethPrice, "Gotta send the right amount");
        _safeMint(msg.sender, _tokenIdCounter.current());
    }

    // Claiming their free NFT for staking ads
    function claimADS() external {
        require(!claimedADS[msg.sender], "You already claimed your free ADS!");
        require(ADS.balanceOf(address(this)) >= 1E18, "Out of ADS tokens");
        claimedADS[msg.sender] = true;
        ADS.transfer(msg.sender, 1E18);
    }

    function claimNFT() external {
        require(claimingActive, "Claims are not active yet");
        uint256 stakingBalance = STAKING.balanceOfStake(msg.sender);
        uint256 eligibleNFTs = stakingBalance.div(10_000E18);
        require(stakingBalance >= 10_000E18, "You need at least 10k $ADS staked to qualify for an NFT");
        require(claimedNFTs[msg.sender].add(1) <= eligibleNFTs, "You've claimed all eligible NFTs");
        claimedNFTs[msg.sender] = claimedNFTs[msg.sender].add(1);
        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return uri;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        uri = _uri;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}