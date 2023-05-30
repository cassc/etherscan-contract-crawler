// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WaatcaNFT is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    // incremental ID for each WAATCA NFT
    Counters.Counter private _tokenIdCounter;

    // token used to purchase a WAATCA NFT
    address public immutable purchaseTokenUSDC;

    // tokens you are rewarded in when you burn your WAATCA NFT
    address public immutable rewardTokenPLSD;
    address public immutable rewardTokenPLSB;
    address public immutable rewardTokenASIC;
    address public immutable rewardTokenHEX;
    address public immutable rewardTokenUSDC;
    address public rewardTokenCARN;
    address public immutable carnivalBenevolentAddress;

    // keeps track of how many usdc have been used to purchase WAATCA nft's so far
    // so we can calculate each persons percentage of the entire pool
    uint256 public totalPoints;

    // Track total number of NFT's created.
    uint256 public totalWaatcaNfts;

    uint256 public deploymentTime;
    uint256 public mintDeadline;
    uint256 public mintExpirationDelta;

    mapping(uint256 => uint256) public tokenIdsToPurchaseAmount; // tokenIds to deposited USDC amounts

    event MintWaatcaNFT(
        address indexed minter,
        uint256 indexed purchaseAmount,
        string uri,
        uint256 tokenId,
        uint256 indexed currentTime
    );
    event Burn(
        address indexed burner,
        uint256 indexed currentTime,
        uint256 tokenId,
        uint256 indexed purchaseAmount
    );

    constructor(
        address _purchaseTokenUSDC,
        address _rewardTokenPLSD,
        address _rewardTokenPLSB,
        address _rewardTokenASIC,
        address _rewardTokenHEX,
        address _rewardTokenUSDC,
        address _carnivalBenevolentAddress,
        uint _mintExpirationDelta,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        deploymentTime = block.timestamp;
        mintExpirationDelta = _mintExpirationDelta;
        mintDeadline = deploymentTime + mintExpirationDelta;
        purchaseTokenUSDC = _purchaseTokenUSDC;
        rewardTokenPLSD = _rewardTokenPLSD;
        rewardTokenPLSB = _rewardTokenPLSB;
        rewardTokenASIC = _rewardTokenASIC;
        rewardTokenHEX = _rewardTokenHEX;
        rewardTokenUSDC = _rewardTokenUSDC;
        carnivalBenevolentAddress = _carnivalBenevolentAddress;
    }

    function setCarnAddress(address _rewardTokenCARN) public onlyOwner {
        rewardTokenCARN = _rewardTokenCARN;
    }

    function mintWaatcaNft(uint256 purchaseAmount, string memory uri) public {
        require(block.chainid == 1, "This function can only be called on Ethereum mainnet");
        require(
            block.timestamp <= mintDeadline,
            "Function can only be called within 3 weeks of deployment"
        );
        require(purchaseAmount > 0, "amount can't be zero or less");
        require(
            IERC20(purchaseTokenUSDC).transferFrom(
                msg.sender,
                carnivalBenevolentAddress,
                purchaseAmount
            ),
            "transferFrom failed."
        );

        uint256 tokenId = _tokenIdCounter.current();
        tokenIdsToPurchaseAmount[tokenId] = purchaseAmount;
        totalPoints += purchaseAmount;
        totalWaatcaNfts += 1;
        mint(uri);

        emit MintWaatcaNFT(
            msg.sender,
            purchaseAmount,
            uri,
            tokenId,
            block.timestamp
        );
    }

    function mint(string memory _uri) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _uri);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        require(block.timestamp >= mintDeadline, "Burning is only allowed after the Minting deadline");

        uint256 purchaseAmount = tokenIdsToPurchaseAmount[tokenId];
        tokenIdsToPurchaseAmount[tokenId] = 0;
        super._burn(tokenId);

        uint256 withdrawablePortionOfPLSD = (IERC20(rewardTokenPLSD).balanceOf(address(this)) * purchaseAmount) / totalPoints;
        uint256 withdrawablePortionOfPLSB = (IERC20(rewardTokenPLSB).balanceOf(address(this)) * purchaseAmount) / totalPoints;
        uint256 withdrawablePortionOfASIC = (IERC20(rewardTokenASIC).balanceOf(address(this)) * purchaseAmount) / totalPoints;
        uint256 withdrawablePortionOfHEX  = (IERC20(rewardTokenHEX).balanceOf(address(this))  * purchaseAmount) / totalPoints;
        uint256 withdrawablePortionOfCARN = (IERC20(rewardTokenCARN).balanceOf(address(this)) * purchaseAmount) / totalPoints;
        uint256 withdrawablePortionOfUSDC = (IERC20(rewardTokenUSDC).balanceOf(address(this)) * purchaseAmount) / totalPoints;
        // add hex, maximus, hdrn, icosa?

        IERC20(rewardTokenPLSD).transfer(msg.sender, withdrawablePortionOfPLSD);
        IERC20(rewardTokenPLSB).transfer(msg.sender, withdrawablePortionOfPLSB);
        IERC20(rewardTokenASIC).transfer(msg.sender, withdrawablePortionOfASIC);
        IERC20(rewardTokenHEX).transfer(msg.sender,  withdrawablePortionOfHEX);
        IERC20(rewardTokenCARN).transfer(msg.sender, withdrawablePortionOfCARN);
        IERC20(rewardTokenUSDC).transfer(msg.sender, withdrawablePortionOfUSDC);

        emit Burn(msg.sender, block.timestamp, tokenId, purchaseAmount);

        // whenever someone burns their WAATCA NFT, the 'total points' becomes smaller,
        // this makes everyones percentage of the pool bigger,
        // the last person with a WAATCA NFT will have 100% of the pool
        // (that last purchaseAmount should equal to totalPoints at that point)
        totalPoints -= purchaseAmount;
        totalWaatcaNfts -= 1;

        if (totalWaatcaNfts == 0) {
            // in this scenario, EVERYONE has burned their WAATCA NFT,
            // now there will be another 2 weeks for everyone to mint NEW WAATCAs
            // just like the original launch
            mintDeadline = block.timestamp + mintExpirationDelta;
        }
    }
}