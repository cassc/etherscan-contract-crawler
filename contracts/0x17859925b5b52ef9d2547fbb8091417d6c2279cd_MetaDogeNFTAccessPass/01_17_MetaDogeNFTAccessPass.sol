// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

interface IMetaDoge {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
}

contract MetaDogeNFTAccessPass is
Context,
ERC721Enumerable,
Ownable,
VRFConsumerBase
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdTracker;
    string private baseTokenURI = "https://api.metadogetoken.com/token/metadata/eth/";

    address public metaDogeAddress;
    address public daoAddress;

    uint256 public pricePerOne = 3_000_000_000_000_000_000_000_000_000;
    uint256 public priceIncreaseValue = 3_000_000_000_000_000_000_000_000_000;

    uint256 public saleLimit = 5_000;
    uint256 public saleStartTime = 1638475200;
    uint256 public saleEndTime = 1640718000;

    uint256 public goldTicketCount = 5;

    mapping(uint256 => bool) private goldenTickets;
    bool public goldenTicketRevealed = false;

    bytes32 internal chainlinkKeyHash;
    uint256 internal chainlinkFee;

    uint256 public randomResult = 0;


    constructor(address _metaDogeAddress, address _daoAddress, address _vrfCoordinator, address _linkToken, bytes32 _chainlinkKeyHash, uint256 _chainlinkFee)
    ERC721("Meta Doge NFT Access Pass", "METADOGEPASS")
    VRFConsumerBase(
        _vrfCoordinator,
        _linkToken
    )
    {
        metaDogeAddress = _metaDogeAddress;
        daoAddress = _daoAddress;
        chainlinkKeyHash = _chainlinkKeyHash;
        chainlinkFee = _chainlinkFee;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function isGoldTicket(uint256 tokenId) public view returns (bool) {
        return goldenTickets[tokenId];
    }

    function setBaseUri(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function buyTicket() external {
        //make sure that the start time is reached
        require(block.timestamp >= saleStartTime);

        //make sure that the end time is not passed
        require(block.timestamp <= saleEndTime);

        //make sure that mint limit will not be exceeded after this mint
        require(totalSupply() < saleLimit);

        //make sure that this contract can transfer users erc20
        uint256 allowance = IMetaDoge(metaDogeAddress).allowance(_msgSender(), address(this));
        require(allowance >= pricePerOne);

        //transfer erc20 to dao address
        bool paid = IMetaDoge(metaDogeAddress).transferFrom(_msgSender(), daoAddress, pricePerOne);

        //make sure that erc20 was transferred
        require(paid);

        //mint nft to msgSender
        _mint(_msgSender(), _tokenIdTracker.current() + 1);

        //increase id tracker
        _tokenIdTracker.increment();

        //increase price if another part is sold
        if (totalSupply() % 1000 == 0) {
            pricePerOne += priceIncreaseValue;
        }
    }

    function revealGoldenTickets() external onlyOwner {
        // make sure that random result is fulfilled
        require(randomResult != 0);

        // make sure that total token count is not higher that gold ticket count
        require(goldTicketCount <= totalSupply());

        // make sure that gold ticket is not revealed yet
        require(goldenTicketRevealed == false);

        //set initial number of draws
        uint256 numberOfDraws = goldTicketCount;

        // reveal golden tickets
        for (uint256 i = 0; i < numberOfDraws; i++) {

            // get tokenId for actual drawn
            uint256 tokenId = (uint256(keccak256(abi.encode(randomResult, i))) % totalSupply()) + 1;

            //check if tokenId is already mark as gold
            if (isGoldTicket(tokenId)) {

                // if actual tokenId is already mark as gold - add another draw
                numberOfDraws += 1;
            } else {

                // if actual tokenId is not already mark as gold - mark tokenId as gold
                goldenTickets[tokenId] = true;
            }
        }

        //mark golden ticket as revealed
        goldenTicketRevealed = true;
    }

    function getRandomNumber() public onlyOwner {
        // make sure that random result is not fulfilled before
        require(randomResult == 0);

        // make sure that contract can pay vrf fee
        require(LINK.balanceOf(address(this)) >= chainlinkFee);

        // request random number from vrf
        requestRandomness(chainlinkKeyHash, chainlinkFee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        // make sure that random result is not fulfilled before
        require(randomResult == 0);

        //save random number from vrf
        randomResult = randomness;
    }

    function setChainlinkConfig(uint256 _chainlinkFee, bytes32 _chainlinkKeyHash) external onlyOwner {
        chainlinkFee = _chainlinkFee;
        chainlinkKeyHash = _chainlinkKeyHash;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}