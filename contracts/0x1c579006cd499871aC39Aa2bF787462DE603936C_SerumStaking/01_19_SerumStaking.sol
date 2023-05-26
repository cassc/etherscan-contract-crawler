// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract SerumStaking is ERC1155, IERC721Receiver, Ownable, ReentrancyGuard, Pausable {
    using EnumerableSet for EnumerableSet.UintSet; 
    using Strings for uint256;

    struct SerumReward {
        uint256 startTime;
        uint256 fishDeposited;
    }
  
    IERC721Enumerable public erc721Token;
    IERC20 public erc20Token;
    string private baseURI;

    uint256 public constant SERUM = 1;

    uint256 public fishFor25Boost = 10 ether;
    uint256 public fishFor50Boost = 25 ether;
    uint256 public fishFor100Boost = 50 ether;

    uint256 public timeToStakeForReward = 60 days;
    uint256 public expiration;
    uint256 public rate;
    bool public pauseRewards;
  
    // address => list of tokenIds staked
    mapping(address => EnumerableSet.UintSet) private _deposits;
    // tokenId => SerumRewards
    mapping(uint256 => SerumReward) public _tokenRewards;

    constructor(string memory _baseURI) ERC1155(_baseURI) {
        baseURI =_baseURI;
        _pause();
    }   

    modifier requireContractsSet() {
        require(address(erc20Token) != address(0) 
          && address(erc721Token) != address(0), "Contracts not set");
        _;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    //check deposit amount. 
    function depositsOf(address account)
      external 
      view 
      returns (uint256[] memory)
    {
      EnumerableSet.UintSet storage depositSet = _deposits[account];
      uint256[] memory tokenIds = new uint256[] (depositSet.length());

      for (uint256 i; i < depositSet.length(); i++) {
        tokenIds[i] = depositSet.at(i);
      }

      return tokenIds;
    }

    function togglePauseRewards() external onlyOwner {
        pauseRewards = !pauseRewards;
    }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    function setContracts(address erc721Address, address erc20Address) external onlyOwner {
      erc721Token = IERC721Enumerable(erc721Address);
      erc20Token = IERC20(erc20Address);
    }

    function setFishBoostAmts(uint256 boost25, uint256 boost50, uint256 boost100) external onlyOwner {
        fishFor25Boost = boost25;
        fishFor50Boost = boost50;
        fishFor100Boost = boost100;
    }

    function feedGorilla(uint256 tokenId, uint256 fishAmt) external {
        _tokenRewards[tokenId].fishDeposited += fishAmt;
        erc20Token.transferFrom(_msgSender(), address(this), fishAmt);
    }

    //deposit function. 
    function deposit(uint256[] calldata tokenIds) external requireContractsSet whenNotPaused {
        
        for (uint256 i; i < tokenIds.length; i++) {
            erc721Token.safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i],
                ""
            );

            _deposits[msg.sender].add(tokenIds[i]);
            _tokenRewards[tokenIds[i]] = SerumReward(block.timestamp, 0);
        }
    }

    //withdrawal function.
    function withdraw(uint256[] calldata tokenIds) external requireContractsSet whenNotPaused {

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                _deposits[msg.sender].contains(tokenIds[i]),
                "Staking: token not deposited"
            );

            _deposits[msg.sender].remove(tokenIds[i]);
            delete _tokenRewards[tokenIds[i]];

            erc721Token.safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i],
                ""
            );
        }
    }

    //withdrawal function.
    function withdrawSerum() external requireContractsSet onlyOwner {
        uint256 tokenSupply = balanceOf(address(this), SERUM);
        safeTransferFrom(address(this), msg.sender, SERUM, tokenSupply, "");
    }

    //withdrawal function.
    function withdrawTokens() external requireContractsSet onlyOwner {
        uint256 tokenSupply = erc20Token.balanceOf(address(this));
        erc20Token.transfer(msg.sender, tokenSupply);
    }

    function claimSerum() external whenNotPaused {
        require(!pauseRewards, "Reward claiming is paused");
        uint256 serums;
        for (uint256 i = 0; i < _deposits[_msgSender()].length(); i++) {
            uint256 curToken = _deposits[_msgSender()].at(i);
            SerumReward storage serum = _tokenRewards[curToken];
            uint256 serumCreationTime = serum.startTime + timeToStakeForReward;
            if(serum.fishDeposited >= fishFor100Boost) {
                // remove 100% of the maximum allowed serum production time reduction.
                // Since the maximum reduction time is 50%, we divide by 2.
                serumCreationTime = serumCreationTime - (timeToStakeForReward / 2);
            }
            else if(serum.fishDeposited >= fishFor50Boost) {
                // remove 50% of the maximum allowed serum production time reduction.
                // We want 1/4 of the total time it takes because
                //  1/2 of 1/2 max production = 1/4
                serumCreationTime = serumCreationTime - (timeToStakeForReward / 4);
            }
            else if(serum.fishDeposited >= fishFor25Boost) {
                // remove 25% of the maximum allowed serum production time reduction.
                // We want 1/8 of the total time it takes because
                //  1/4 of 1/2 max production = 1/8
                serumCreationTime = serumCreationTime - (timeToStakeForReward / 8);
            }
            if(serum.startTime > 0 && block.timestamp >= serumCreationTime) {
                serums += 1;
                // Set the new start time to exactly when the last serum was claimable
                serum.startTime = serumCreationTime;
                // If the gorilla was given more than was needed for 1 serum,
                //  the gorilla didn't eat all of it and will eat them for the next serum
                if(serum.fishDeposited > fishFor100Boost) {
                    serum.fishDeposited -= fishFor100Boost;
                }
                else {
                    serum.fishDeposited = 0;
                }
            }
        }
        require(serums > 0, "No serum to claim");
        _mint( _msgSender(), SERUM, serums, "");
    }

    function getClaimableSerumAmt(address addr) public view returns(uint256 numRewards) {
        for (uint256 i = 0; i < _deposits[addr].length(); i++) {
            uint256 curToken = _deposits[_msgSender()].at(i);
            SerumReward storage serum = _tokenRewards[curToken];
            uint256 serumCreationTime = serum.startTime + timeToStakeForReward;
            if(serum.fishDeposited >= fishFor100Boost) {
                // remove 100% of the maximum allowed serum production time reduction.
                // Since the maximum reduction time is 50%, we divide by 2.
                serumCreationTime = serumCreationTime - (timeToStakeForReward / 2);
            }
            else if(serum.fishDeposited >= fishFor50Boost) {
                // remove 50% of the maximum allowed serum production time reduction.
                // We want 1/4 of the total time it takes because
                //  1/2 of 1/2 max production = 1/4
                serumCreationTime = serumCreationTime - (timeToStakeForReward / 4);
            }
            else if(serum.fishDeposited >= fishFor25Boost) {
                // remove 25% of the maximum allowed serum production time reduction.
                // We want 1/8 of the total time it takes because
                //  1/4 of 1/2 max production = 1/8
                serumCreationTime = serumCreationTime - (timeToStakeForReward / 8);
            }
            if(serum.startTime > 0 && block.timestamp >= serumCreationTime) {
                numRewards += 1;
            }
        }
    }

    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function uri(uint256 typeId)
        public
        view                
        override
        returns (string memory)
    {
        require(typeId == SERUM, "invalid type");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, SERUM.toString())) : baseURI;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}