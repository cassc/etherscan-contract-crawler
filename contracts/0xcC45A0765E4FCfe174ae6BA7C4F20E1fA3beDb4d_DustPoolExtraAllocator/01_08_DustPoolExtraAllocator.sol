//SPDX-License-Identifier: Unlicensed

/***
 *            ███████ ██    ██ ███████ ██████  ██    ██  ██████  ███    ██ ███████      ██████  ███████ ████████ ███████     
 *            ██      ██    ██ ██      ██   ██  ██  ██  ██    ██ ████   ██ ██          ██       ██         ██    ██          
 *            █████   ██    ██ █████   ██████    ████   ██    ██ ██ ██  ██ █████       ██   ███ █████      ██    ███████     
 *            ██       ██  ██  ██      ██   ██    ██    ██    ██ ██  ██ ██ ██          ██    ██ ██         ██         ██     
 *            ███████   ████   ███████ ██   ██    ██     ██████  ██   ████ ███████      ██████  ███████    ██    ███████     
 *                                                                                                                           
 *                                                                                                                           
 *                    ███████  ██████  ███    ███ ███████     ██████  ██    ██ ███████ ████████                              
 *                    ██      ██    ██ ████  ████ ██          ██   ██ ██    ██ ██         ██                                 
 *                    ███████ ██    ██ ██ ████ ██ █████       ██   ██ ██    ██ ███████    ██                                 
 *                         ██ ██    ██ ██  ██  ██ ██          ██   ██ ██    ██      ██    ██                                 
 *                    ███████  ██████  ██      ██ ███████     ██████   ██████  ███████    ██                                 
 *                                                                                                                           
 *                                                                                                                           
 *    ETHER.CARDS - DUST TOKEN ALLOCATOR for EXTRA POOLS
 *
 */

pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DustPoolExtraAllocator is Ownable {
    
    using SafeMath for uint256;

    mapping(uint8 => uint256)   public cardTypeAmounts;
    mapping(uint16 => uint8)    internal tokenData;

    IERC721                     public erc721;   // Ether Cards
    IERC20                      public erc20;    // Dust
    bool                        public locked;
    uint256                     public unlockTime;
    
    event Redeemed(uint16 tokenId);
    event Skipped(uint16 tokenId);

    constructor(address _erc721, address _erc20) {
        erc721 = IERC721(_erc721);
        erc20 = IERC20(_erc20);

        // set card type values
        cardTypeAmounts[1] = 21100 ether;
        cardTypeAmounts[2] = 2110 ether;
        cardTypeAmounts[3] = 211 ether;

        // Fri Oct 15 2021 16:00:00 GMT+0300 (Eastern European Summer Time)
        unlockTime = 1634302800;
    }

    function redeem(uint16[] calldata _tokenIds) public {
        require(!locked && getBlockTimestamp() > unlockTime, "Contract locked");

        uint256 totalAmount;
        for(uint8 i = 0; i < _tokenIds.length; i++) {
            uint16 _tokenId = _tokenIds[i];

            require(erc721.ownerOf(_tokenId) == msg.sender, "ERC721: not owner of token");

            if(!isTokenUsed(_tokenId)) {
                totalAmount = totalAmount.add(
                    cardTypeAmounts[getCardTypeFromId(_tokenId)]
                );
                setTokenUsed(_tokenId);
                emit Redeemed(_tokenId);
            } else {
                emit Skipped(_tokenId);
            }
        }
        
        erc20.transfer(msg.sender, totalAmount);
    }

    function getAvailableBalance(uint16[] calldata _tokenIds) external view returns (uint256 balance) {
        for(uint8 i = 0; i < _tokenIds.length; i++) {
            uint16 _tokenId = _tokenIds[i];
            if(!isTokenUsed(_tokenId)) {
                balance = balance.add(
                    cardTypeAmounts[getCardTypeFromId(_tokenId)]
                );
            }
        }
    }

    function getCardTypeFromId(uint16 _tokenId) public pure returns (uint8 _cardType) {
        if(_tokenId < 10) {
            revert("CardType not allowed");
        }
        if(_tokenId < 100) {
            return 1;
        } 
        if (_tokenId < 1000) {
            return 2;
        } 
        if (_tokenId < 10000) {
            return 3;
        }
        revert("CardType not found");
    }

    function toggleLocked () public onlyOwner {
        locked = !locked;
    }

    function removeUnlockTime () public onlyOwner {
        unlockTime = block.timestamp;
    }

    function getBlockTimestamp() public view virtual returns (uint256) {
        return block.timestamp;
    }

    function isTokenUsed(uint16 _position) public view returns (bool result) {
        uint16 byteNum = uint16(_position / 8);
        uint16 bitPos = uint8(_position - byteNum * 8);
        if (tokenData[byteNum] == 0) return false;
        return tokenData[byteNum] & (0x01 * 2**bitPos) != 0;
    }

    function setTokenUsed(uint16 _position) internal {
        uint16 byteNum = uint16(_position / 8);
        uint16 bitPos = uint8(_position - byteNum * 8);
        tokenData[byteNum] = uint8(tokenData[byteNum] | (2**bitPos));
    }

    /// web3 Frontend - VIEW METHODS
    // 0 - 1250 to get all 10k records
    function getUsedTokenData(uint8 _page, uint16 _perPage)
        public
        view
        returns (uint8[] memory)
    {
        _perPage = _perPage / 8;
        uint16 i = _perPage * _page;
        uint16 max = i + (_perPage);
        uint16 j = 0;
        uint8[] memory retValues;

        assembly {
            mstore(retValues, _perPage)
        }

        while (i < max) {
            retValues[j] = tokenData[i];
            j++;
            i++;
        }

        assembly {
            // move pointer to freespace otherwise return calldata gets messed up
            mstore(0x40, msize())
        }
        return retValues;
    }

    // blackhole prevention methods
    function retrieveERC20(address _tracker, uint256 amount) external onlyOwner {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }

}