// SPDX-License-Identifier: UNLICENSED
/**
* @Author: Monnet
* THIS IS AN EXPERIMENTAL IMPLEMENTATION OF Monnet: A New NFT Liquidity Mechanism
* Bugs potentially abound. Please handle carefully.
* Arweave transaction: EmgzUeolHrjFvmY-Ltk00UUJ1OqKtY_130F9soCgHIQ
*
* BUGS are NFTs causing climate change
* BUGN is the ERC-721 non-fungible art 
* BUGF is the ERC-20 fungible liquidity provision system
*/
pragma solidity ^0.8.19;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

/**
 * Interface for the BUGF contract
 */
interface IBUGF {
    function mint(address to, uint256 amount) external returns (bool, uint256);
    function totalSupply() external view returns (uint256);
}

/**
 * Interface for the Redemption Calculator
 */
interface IRedemptionCalculator {
    function redeemNFTCost(uint256 nftCount, uint256 erc20Count) external pure returns (uint256);
    function probabilityDecay(uint256 mintCount) external pure returns (uint256, uint256, uint256, uint256, uint256);
}

/**
 * Interface for the Renderer contract
 *  Rendrers can be interchanged but must have a render function
 */
interface IRenderer {
    function save(uint256 tokenId, address contractAddress) external;
    function render(uint256 tokenId) external view returns (string memory);
    function updateRaceProbability(uint256 e, uint256 n, uint256 s, uint256 d, uint256 c) external;
}

/**
 * BUGN Contract
 */
contract BUGN is ERC721, ERC2981, ERC721Enumerable, Ownable, ReentrancyGuard {
    uint256 private _nonce = 0;
    uint256 private _totalMintCount = 0;

    address private _communityAddress;
    address public redemptionCalculatorContractAddress;
    address public renderingContractAddress;
    address public bugfContractAddress;
    uint256 private constant _TOTAL_SUPPLY_BUGN = 10000;
    uint256 private constant _BUGN_FOR_PUBLIC_MINT = 4900;
    uint256 private constant _BUGN_FOR_COMMUNITY = 100;
    uint256 private constant _MINT_PRICE = 0.01 ether;
    uint256 private constant _MAX_PUBLIC_MINT_PER_ADDRESS = 20;
    uint256 private constant _INITIAL_BUGF_PER_BUGN = 1_000_000;

    mapping(address => uint256) private _publicMintCountPerAddress;
    mapping(uint256 => bool) private _isTokenTaken;

    using Counters for Counters.Counter;
    Counters.Counter public publicMintCounter;
    Counters.Counter public communityMintCounter;

    // Event to notify opensea about metadata updates
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    constructor() ERC721("BUGN", "BUGN") {}

    /**
     * publicMint For Special NFT Holders.
     * Easter Egg for NFT communities that have been seminal to the web3 space
     * AZUKI, LOOT, DEGODS, BAYC
     */
    function publicMint(uint256 _count, address _contractAddress) public payable nonReentrant returns (bool) {
        return _theMint(_count, _contractAddress);
    }

    /**
     * Each Address has maximum number of mints _MAX_PUBLIC_MINT_PER_ADDRESS.
     * A mint costs _MINT_PRICE
     * Each Mint of a BUGN mints _INITIAL_BUGF_PER_BUGN BUGF tokens to the calling address.
     */
    function publicMint(uint256 _count) public payable nonReentrant returns (bool) {
        return _theMint(_count, address(0));
    }

    function _theMint(uint256 _count, address _contractAddress) internal returns (bool) {
        require(
            publicMintCounter.current() + _count <= _BUGN_FOR_PUBLIC_MINT, "All Available BUGN tokens Have Been Minted"
        );
        require(_count * _MINT_PRICE == msg.value, "Incorrect amount of ether sent");

        uint256 userMintedAmount = _publicMintCountPerAddress[msg.sender] + _count;
        require(userMintedAmount <= _MAX_PUBLIC_MINT_PER_ADDRESS, "Max Early Access count per address exceeded");

        for (uint256 i = 0; i < _count; i++) {
            publicMintCounter.increment();
            _publicMintCountPerAddress[msg.sender]++;
            _internalMint(msg.sender, _contractAddress);
        }

        _mintBugf(msg.sender, _count * _INITIAL_BUGF_PER_BUGN);
        return true;
    }

    /**
     * CommunityMint allows the community address to mint one NFT per time.
     * The Number of BUGN tokens avalaible for zeroMinnt is limited to _BUGN_FOR_COMMUNITY.
     * Each Mint of a BUGN mints _INITIAL_BUGF_PER_BUGN BUGF tokens to the calling address.
     * Returns the id of the minted BUGN
     */
    modifier onlyCommunity() {
        require(msg.sender == _communityAddress, "Only for the community");
        _;
    }

    function communityMint(uint256 _count) public onlyCommunity nonReentrant returns (bool) {
        require(
            communityMintCounter.current() + _count <= _BUGN_FOR_COMMUNITY,
            "All Available Community BUGN tokens Have Been Minted"
        );

        for (uint256 i = 0; i < _count; i++) {
            communityMintCounter.increment();
            _internalMint(msg.sender, address(0));
        }

        _mintBugf(msg.sender, _count * _INITIAL_BUGF_PER_BUGN);
        return true;
    }

    /**
     * Burns a BUGN token in exchange for BUGF tokens.
     * The tokenId to be burned is freed up and available to be minted again.
     * Redemption is only possible after the public mints
     */
    function redeem(uint256 tokenId) public nonReentrant {
        require(publicMintCounter.current() >= _BUGN_FOR_PUBLIC_MINT, "Public Mint Not Finished");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        uint256 bugfPerBugn = getRedemptionCostNtoF();

        _isTokenTaken[tokenId] = false;
        _burn(tokenId);
        _mintBugf(msg.sender, bugfPerBugn);
    }

    /**
    * Cost to redeem BUGN for BUGF Tokens
    */
    function getRedemptionCostNtoF() public view returns (uint256) {
        require(redemptionCalculatorContractAddress != address(0), "Address cannot be zero");
        require(bugfContractAddress != address(0), "Address cannot be zero");

        if (publicMintCounter.current() <= 5000) {
            return 1_000_000;
        }

        IRedemptionCalculator redemptionCalc = IRedemptionCalculator(redemptionCalculatorContractAddress);
        IBUGF bugf = IBUGF(bugfContractAddress);
        uint256 bugfCount = bugf.totalSupply();
        return redemptionCalc.redeemNFTCost(totalSupply(), bugfCount);
    }

    modifier onlyMinter() {
        require(msg.sender == bugfContractAddress, "Only Minter");
        _;
    }
    /**
     * Mints a new BUGN token to the specified address.
     */
    function mint(address to) external nonReentrant onlyMinter returns (bool, uint256) {
        uint256 tokenId = _internalMint(to, address(0));
        return (true, tokenId);
    }

    /**
     * Returns a Link to The Token URI
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(renderingContractAddress != address(0), "Address cannot be zero");

        IRenderer renderer = IRenderer(renderingContractAddress);
        return renderer.render(tokenId);
    }

    // Set the contract address for the renderer
    function setRenderingContractAddress(address _renderingContractAddress) public onlyOwner {
        renderingContractAddress = _renderingContractAddress;
        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    // Set the contract address for the redemptionCalculator
    function setRedemptionCalculatorContractAddress(address _redemptionCalculatorContractAddress) public onlyOwner {
        redemptionCalculatorContractAddress = _redemptionCalculatorContractAddress;
    }

    // Set the contract address for the BUGF contract and give Mint Access
    function setBugfContractAddress(address _bugfContractAddress) public onlyOwner {
        bugfContractAddress = _bugfContractAddress;
    }

    // Set the Community Address
    function setCommunityAddress(address communityAddress) public onlyOwner {
        _communityAddress = communityAddress;
    }

    function setDefaultRoyaltyInfo(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteRoyaltyInfo() public onlyOwner {
        _deleteDefaultRoyalty();
    }

    function withdraw() public onlyCommunity nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(_communityAddress).transfer(balance);
    }


    /**
     * _mintBugf mints BUGF Tokens to the specified address.
     */
    function _mintBugf(address to, uint256 amount) internal {
        require(bugfContractAddress != address(0), "Address cannot be zero");
        IBUGF bugf = IBUGF(bugfContractAddress);
        (bool success, uint256 intValue) = bugf.mint(to, amount);
        require(success, "Botched Mint");
        require(intValue == amount, "Botched Mint");
    }

    function _updateRaceProbabilityAndSave(uint256 tokenId, address _contractAddress) internal {
        require(redemptionCalculatorContractAddress != address(0), "Address cannot be zero");
        require(renderingContractAddress != address(0), "Address cannot be zero");

        IRedemptionCalculator redemptionCalc = IRedemptionCalculator(redemptionCalculatorContractAddress);
        IRenderer renderer = IRenderer(renderingContractAddress);

        renderer.save(tokenId, _contractAddress);

        if (publicMintCounter.current() > _BUGN_FOR_PUBLIC_MINT && _totalMintCount % 100 == 0) {
            (uint256 d, uint256 c, uint256 e, uint256 n, uint256 s) =
            redemptionCalc.probabilityDecay(_totalMintCount);

            renderer.updateRaceProbability(c, d, e, n, s);
        }
    }

    /**
     * Generates a random unique tokenId
     * Increases the number of BUGN's minted (tokenIds) by 1
     * Calls the _safeMint function
     * This can become problematic as the number of available BUGN's become very small
     */
    function _internalMint(address to, address _contractAddress) internal returns (uint256) {
        require(totalSupply() + 1 <= _TOTAL_SUPPLY_BUGN, "All BUGN's Have Been Minted");
        uint256 tokenId = _getRandomNumber();
        while (_isTokenTaken[tokenId]) {
            _nonce++;
            tokenId = _getRandomNumber();
        }
        _isTokenTaken[tokenId] = true;
        _safeMint(to, tokenId);
        _totalMintCount++;
        _updateRaceProbabilityAndSave(tokenId, _contractAddress);
        return tokenId;
    }

    // Generates a random number
    function _getRandomNumber() internal returns (uint256) {
        _nonce++;
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, _nonce))) % 10001;
        return random;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}