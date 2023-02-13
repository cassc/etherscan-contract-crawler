// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
error NotOwner();
error NotStakedLongEnough();


contract NerfedStaking is Ownable {
    IERC721Minimal private immutable PANDAS;
    struct Ownership {
        address owner;
        uint96 lastUpdatedTimestamp;
    }
    address constant private vault = 0x2B75A4B81a65cbE2910f72945017064626333970;
    
    // uint public constant MAX_SUPPLY = 6666;

    mapping(uint => Ownership) private ownerships;
    mapping(address => uint) private balances;

    uint private minimumLockupPeriod = 0 hours;


    event UpdateStakeStatus(address indexed staker,bool indexed startingStake,uint16[]  tokenIds);
constructor(address _pandas) {
        PANDAS = IERC721Minimal(_pandas);
    }

    function stakePanda(uint tokenId)  internal {
        if (msg.sender != PANDAS.ownerOf(tokenId)) revert NotOwner();
        ownerships[tokenId] = Ownership(msg.sender, uint96(block.timestamp));
        PANDAS.transferFrom(msg.sender, vault, tokenId);
        
    }

    function unstakePanda(uint tokenId) internal {
        Ownership memory ownership = ownerships[tokenId];
        if(
            ownership.lastUpdatedTimestamp + minimumLockupPeriod > block.timestamp
        ) revert NotStakedLongEnough();
        
        if(msg.sender != ownership.owner) revert NotOwner();
        ownerships[tokenId] = Ownership(address(0), 0);
        PANDAS.transferFrom(vault, msg.sender, tokenId);
    }



    function stakePandas(uint16[] calldata tokenIds) external {
        for (uint i; i < tokenIds.length; ) {
            stakePanda(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        balances[msg.sender] += tokenIds.length;
        emit UpdateStakeStatus(msg.sender,true,tokenIds);
    }

    function unstakePandas(uint16[] calldata tokenIds) external {
        // Staker storage staker = stakers[msg.sender];
        for (uint i; i < tokenIds.length; ) {
            unstakePanda(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        balances[msg.sender] -= tokenIds.length;
        emit UpdateStakeStatus(msg.sender, false,tokenIds);
    }

    function balanceOf(address account) external view returns(uint) {
        return balances[account];
    }

    function stakeOnBehalfOfOther(address account, uint16[] calldata tokenIds) external {
        for (uint i; i < tokenIds.length; ) {
            stakePanda(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        balances[account] += tokenIds.length;
        emit UpdateStakeStatus(account, true,tokenIds);
    }


    function tokensOfOwner(
        address account
    ) external view returns (uint[] memory) {
        unchecked {
            uint tokenIdsIdx;
            uint tokenIdsLength = balances[account];
            uint[] memory tokenIds = new uint256[](tokenIdsLength);
            for (uint i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                address _owner = ownerships[i].owner;
                if (_owner != address(0)) {
                    if (account == _owner) {
                        tokenIds[tokenIdsIdx++] = i;
                    }
                }
            }
            return tokenIds;
        }
    }


    function getOwnershipsOfPandas(uint16[] calldata tokenIds) external view returns (Ownership[] memory) {
        Ownership[] memory ownershipsOfPandas = new Ownership[](tokenIds.length);
        for (uint i; i < tokenIds.length; ) {
            ownershipsOfPandas[i] = ownerships[tokenIds[i]];
            unchecked {
                ++i;
            }
        }
        return ownershipsOfPandas;
    }


    function _startTokenId() internal pure returns (uint) {
        return 1;
    }


    function setMinimumLockupPeriod(uint _minimumLockupPeriod) external onlyOwner {
        minimumLockupPeriod = _minimumLockupPeriod;
    }

}

interface IERC721Minimal {
    function ownerOf(uint tokenId) external view returns (address);

    function transferFrom(address from, address to, uint tokenId) external;
}

interface ITrippieLandMinimal {
    function isMutant(uint tokenId) external view returns (bool);
}