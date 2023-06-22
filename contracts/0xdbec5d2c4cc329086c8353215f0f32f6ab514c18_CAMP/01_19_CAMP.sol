// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

import {Accountable} from "./Accountable.sol";
import {IGovernance} from "./interfaces/IGovernance.sol";
import {IRandomNumberConsumer} from "./interfaces/IRandomNumberConsumer.sol";
import {IWhitelistedContract} from "./interfaces/IWhitelistedContract.sol";

contract CAMP is ERC721Enumerable, Ownable, ERC721Holder, KeeperCompatibleInterface, Accountable {
    using Strings for uint256;

    string public baseURL;

    IGovernance public governance;

    bool startedGiveaway;
    enum GIVEAWAY_STATE { OPEN, CLOSED, FINDING }
    GIVEAWAY_STATE public giveawayState;

    uint public startingTimeStamp;
    uint256 public GIVEAWAY_CONCLUSION = 1635555600; // Oct. 29 @ 9PM EST
    uint256 public constant GIVEAWAY_WINNERS = 5;

    uint256 public constant MAX_SUPPLY = 10001;
    uint256 public constant RESERVE_SUPPLY = 11;
    uint256 public constant MAX_PER_TX = 21;
    uint256 public constant PRICE = 8 * 10 ** 16;

    address[] public whitelistedContracts;
    DepositedPrize[] public depositedPrizes;

    struct DepositedPrize {
        address contractAddress;
        string ipfsURL;
        uint256 tokenId;
        bool awarded;
    }

    uint public winners;
    mapping(uint256 => uint) tokenIdToWinnerId;
    event WinnerPicked(uint256 tokenId, address winnerAddress);

    constructor(string memory _baseURL, address[] memory _splits, uint256[] memory _splitWeights, address _governance, address[] memory _whitelistedContracts) 
        ERC721("CAMP", "CAMP")
        Accountable(_splits, _splitWeights)
    {
        baseURL = _baseURL;

        governance = IGovernance(_governance);
        require(_whitelistedContracts.length == GIVEAWAY_WINNERS, "Must whitelist the proper number of tokens.");
        whitelistedContracts = _whitelistedContracts;
        giveawayState = GIVEAWAY_STATE.CLOSED;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist");

        string memory url = baseURL;
        uint winnerId = tokenIdToWinnerId[_tokenId];
        if(winnerId > 0) url = depositedPrizes[winnerId - 1].ipfsURL;
        return string(abi.encodePacked('data:application/json;utf8,{"name":"C.A.M.P. BADGE #', uint2str(_tokenId), '","image":"', url, '"}'));
    }

    function deposit(address contractAddress, string memory ipfsURL, uint256 tokenId) external onlyOwner {
        require(depositedPrizes.length < GIVEAWAY_WINNERS, "All the prizes have been deposited.");
        IWhitelistedContract whitelistedContract = IWhitelistedContract(contractAddress);
        whitelistedContract.transferFrom(msg.sender, address(this), tokenId);
        DepositedPrize memory depositedPrize = DepositedPrize(contractAddress, ipfsURL, tokenId, false);
        depositedPrizes.push(depositedPrize);
    }

    function flipSaleState() external onlyOwner {
        require(depositedPrizes.length == GIVEAWAY_WINNERS, "Not enough prizes deposited.");
        startingTimeStamp = block.timestamp;
        giveawayState = GIVEAWAY_STATE.OPEN;
    }

    function mintReserves(address[] calldata addresses) external onlyOwner {
        uint256 totalSupply = totalSupply();
        uint256 count = addresses.length;
        require(totalSupply + count < RESERVE_SUPPLY, "Exceeds reserve supply.");

        uint256 tokenId;
        for(uint256 i; i < count; i++) {
            tokenId = totalSupply + i;
            _safeMint(addresses[i], tokenId);
        }
    }

    function mint(uint256 count) external payable {
        require(startingTimeStamp > 0, "Sale is not active.");
        require(count < MAX_PER_TX, "Exceeds max per tx.");

        uint256 totalSupply = totalSupply();
        require(totalSupply + count < MAX_SUPPLY, "Exceeds max supply.");
        require(msg.value == PRICE * count, "Wrong amount of money.");
        
        for(uint256 i; i < count; i++) {
            uint256 tokenId = totalSupply + i;
            _safeMint(msg.sender, tokenId);
        }

        tallySplits();
    }

    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = block.timestamp >= GIVEAWAY_CONCLUSION && giveawayState == GIVEAWAY_STATE.OPEN;
    }

    function performUpkeep(bytes calldata) external override {
        require(giveawayState == GIVEAWAY_STATE.OPEN, "Giveaway does not need pulled.");
        require(block.timestamp >= GIVEAWAY_CONCLUSION, "Not ready to pick winners.");
        giveawayState = GIVEAWAY_STATE.FINDING;
        
        address randAddress = governance.randomness();
        IRandomNumberConsumer randomNumberConsumer = IRandomNumberConsumer(randAddress);
        for(uint i; i < GIVEAWAY_WINNERS; i++) { 
            randomNumberConsumer.getRandomNumber(i);
        }
    }

    function processPickedWinner(uint winnerId, uint256 randomness) external {
        address randAddress = governance.randomness();
        require(msg.sender == randAddress, "Invalid sender picking winner.");

        require(giveawayState == GIVEAWAY_STATE.FINDING, "Not ready to pick winners.");
        require(randomness > 0, "Random not found.");
        require(winners < GIVEAWAY_WINNERS, "Winners already chosen");

        uint256 tokenId = randomness % totalSupply();

        if(tokenIdToWinnerId[tokenId] == 0) {
            DepositedPrize storage _prize = depositedPrizes[winnerId];
            tokenIdToWinnerId[tokenId] = winnerId + 1;
            IWhitelistedContract _contractInterface = IWhitelistedContract(_prize.contractAddress);

            address winnerAddress = ownerOf(tokenId);
            _contractInterface.transferFrom(address(this), winnerAddress, _prize.tokenId);
            emit WinnerPicked(tokenId, winnerAddress);

            winners += 1;
            if(winners == GIVEAWAY_WINNERS) giveawayState = GIVEAWAY_STATE.CLOSED;
        } else {
            IRandomNumberConsumer randomNumberConsumer = IRandomNumberConsumer(randAddress);
            randomNumberConsumer.getRandomNumber(winnerId);
        }
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) { 
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokenIds = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) return "0";
        
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }

        return string(bstr);
    }
}