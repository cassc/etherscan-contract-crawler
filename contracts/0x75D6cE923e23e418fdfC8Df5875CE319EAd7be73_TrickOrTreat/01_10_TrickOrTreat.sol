// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/******************************************************************************\
* Trick or Treat
* An on-chain game of trick or treat by Michael Hirsch
* 1 Golly Ghost = 1 entry
* By staking your NFT you are gambling it for a chance to win more
* 1 winner: 0.5 ETH + up to 20 Golly Ghosts (if there are enough)
* 10 winners: up to 10 Golly Ghosts (if there are enough)
* 20 winners: up to 5 Golly Ghosts (if there are enough)
* X winners: 1 Golly Ghost (amount left will determine how many can win)
* All remaining entries will leave with nothing
/******************************************************************************/

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract TrickOrTreat is ERC721Holder, ReentrancyGuard, Ownable, Pausable {
    /* ========== STATE VARIABLES ========== */

    IERC721 public stakingToken;

    mapping(address => uint[]) public tokensByEntrant;
    mapping(uint => address) public tokenEntrant;
    mapping(address => uint) public claimed;

    address[] public entrants;
    uint[] public allTokenIds;

    uint private totalSupplyAtPause;
    uint public randomData;
    uint private constant PRIME_NUMBER = 107839786668602559178668060348078522694548577690162289924414440996859;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _stakingToken) {
        stakingToken = IERC721(_stakingToken);
    }

    /* ========== VIEWS ========== */

    function totalSupply() public view returns (uint) {
        return allTokenIds.length;
    }

    function winningPosition(uint tokenId) internal view returns (uint) {
        require(randomData != 0, "Winners have not been selected");
        return ((tokenId + (randomData % totalSupplyAtPause)) * PRIME_NUMBER) % totalSupplyAtPause;
    }

    function amountOfNFTsWonByTokenId(uint tokenId) public view returns (uint) {
        uint position = winningPosition(tokenId);
        int intTotalSupply = int(totalSupplyAtPause);
        int amount;

        if (position == 0) {
            bool areEnoughStaked = intTotalSupply > int(20);
            amount = areEnoughStaked ? int(20) : intTotalSupply;
        } else if (position < 11) {
            bool areEnoughStaked = intTotalSupply - int(20) >= int(10 * position);
            amount = areEnoughStaked ? int(10) : intTotalSupply - int(20) - int(10 * (position - 1));
        } else if (position < 31) {
            bool areEnoughStaked = intTotalSupply - int(120) >= int(5 * (position - 10));
            amount = areEnoughStaked ? int(5) : intTotalSupply - int(120) - int(5 * (position - 11));
        } else if (intTotalSupply - int(220) > int(0)) {
            bool areEnoughStaked = intTotalSupply - int(220) >= int(position - 30);
            amount = areEnoughStaked ? int(1) : int(0);
        }
        return amount > int(0) ? uint(amount) : 0;
    }

    function amountOfNFTsWon(address entrant) public view returns (uint) {
        uint amountWon;

        for (uint i = 0; i < tokensByEntrant[entrant].length; i += 1) {
            amountWon += amountOfNFTsWonByTokenId(tokensByEntrant[entrant][i]);
        }
        return amountWon;
    }

    function amountOfEthWon(address entrant) public view returns (uint) {
        uint amountWon;

        for (uint i = 0; i < tokensByEntrant[entrant].length; i += 1) {
            uint position = winningPosition(tokensByEntrant[entrant][i]);
            if (position == 0) {
                return address(this).balance;
            }
        }
        return amountWon;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _enter(uint tokenId, address from) internal whenNotPaused {
        require(randomData == 0, "Winners have been selected");

        // Save who is the staker/depositor of the token
        tokenEntrant[tokenId] = from;

        if (tokensByEntrant[from].length == 0) {
            entrants.push(from);
        }
        tokensByEntrant[from].push(tokenId);
        allTokenIds.push(tokenId);
    }

    /// @notice By staking your Golly Ghost you could lose it or win more
    /// @param tokenIds The tokenIds of the NFTs wish to gamble
    function enter(uint[] memory tokenIds) external nonReentrant whenNotPaused {
        require(tokenIds.length != 0, "Staking: No tokenIds provided");

        for (uint i = 0; i < tokenIds.length; i += 1) {
            // Transfer user's NFTs to the contract
            stakingToken.safeTransferFrom(msg.sender, address(this), tokenIds[i]);
            // Save who is the staker/depositor of the token
            _enter(tokenIds[i], msg.sender);
        }
    }

    /// @notice Claim all your winnings
    function claim() external nonReentrant {
        uint amountWon = amountOfNFTsWon(msg.sender);
        uint amountAvailable = amountWon - claimed[msg.sender];
        require(amountWon > 0, "You did not win anything");
        require(amountAvailable > 0, "You already claimed");

        claimed[msg.sender] += amountAvailable;

        for (uint i = 0; i < amountAvailable; i += 1) {
            // Transfer user's NFTs to them
            stakingToken.safeTransferFrom(address(this), msg.sender, allTokenIds[allTokenIds.length - 1]);
            // Remove token id from array
            allTokenIds.pop();
        }

        if (amountOfEthWon(msg.sender) > 0) {
            address payable receiver = payable(msg.sender);
            Address.sendValue(receiver, amountOfEthWon(msg.sender));
        }
    }

    /// @notice This is only here as a fail safe
    function sendBackToOwners() external onlyOwner nonReentrant {
        uint numberOfTokens = allTokenIds.length;
        for (uint i = 0; i < numberOfTokens; i += 1) {
            // Transfer user's NFTs to them
            stakingToken.safeTransferFrom(
                address(this),
                tokenEntrant[allTokenIds[allTokenIds.length - 1]],
                allTokenIds[allTokenIds.length - 1]
            );
            // Remove token id from array
            allTokenIds.pop();
        }
    }

    /// @notice This is only here as a fail safe
    function withdraw() external onlyOwner nonReentrant {
        uint balance = address(this).balance;
        address payable receiver = payable(owner());
        Address.sendValue(receiver, balance);
    }
        
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) public override returns (bytes4) {
        _enter(tokenId, from);
        return this.onERC721Received.selector;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setRandomData() external onlyOwner {
        _pause();
        randomData = uint(
            keccak256(
                abi.encodePacked(
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - 1),
                    msg.sender
                )
            )
        );
        totalSupplyAtPause = allTokenIds.length;
    }

    function clearRandomData() external onlyOwner {
        randomData = 0;
    }

    /* ========== EVENTS ========== */

    event Received(address, uint);
}