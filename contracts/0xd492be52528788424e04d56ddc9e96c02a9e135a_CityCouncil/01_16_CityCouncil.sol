// SPDX-License-Identifier: MIT LICENSE
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../interfaces/ITopia.sol";
import "../interfaces/IMetaTopiaCityCouncil.sol";

contract CityCouncil is Ownable, IERC721Receiver, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;

    IERC721 public MetaTopiaCityCouncil = IERC721(0x34b0D1C36512A22b53D4D5435D823DB5FAeB14A6);
    IMetaTopiaCityCouncil private CityCouncilInterface;
    ITopia private TopiaInterface = ITopia(0x41473032b82a4205DDDe155CC7ED210B000b014D);
    address public TOPIA = 0x41473032b82a4205DDDe155CC7ED210B000b014D;
    address payable dev;

    uint256 public PERIOD = 1 days;
    uint256 public DAILY_COUNCIL_RATE = 15 * 10**18;
    uint256 public DEV_FEE = .0018 ether;
    uint256 public totalTOPIAEarned;

    uint80 public claimEndTime;

    mapping(uint16 => Stake) private CouncilStake;
    mapping(address => uint16) public NumberOfStakedCouncilMembers; // the number of NFTs a wallet has staked;
    mapping(address => EnumerableSet.UintSet) StakedCouncilMembersOfWallet; // list of token IDs a user has staked
    
    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
        uint80 stakedAt;
    }

    constructor() {
        dev = payable(msg.sender);
    }

    event CouncilMemberStaked (address indexed staker, uint16[] ids);
    event CouncilMemberUnstaked (address indexed staker, uint16[] ids);

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    function closeSeasonEearnings(uint80 _timestamp) external onlyOwner {
        claimEndTime = _timestamp;
    }

    function updateDevCost(uint256 _cost) external onlyOwner {
        DEV_FEE = _cost;
    }

    function updateDev(address payable _dev) external onlyOwner {
        dev = _dev;
    }

    function setTopia(address _topia) external onlyOwner {
        TopiaInterface = ITopia(_topia);
        TOPIA = _topia;
    }

    function setPayout(uint256 _rate) external onlyOwner {
        DAILY_COUNCIL_RATE = _rate;
    }

    function getStakedCouncilMembers(address _staker) external view returns (uint16[] memory) {
        uint16 length = uint16(StakedCouncilMembersOfWallet[_staker].length());
        uint16[] memory stakedMembers = new uint16[](length);
        for (uint16 i = 0; i < length;) {
            stakedMembers[i] = uint16(StakedCouncilMembersOfWallet[_staker].at(i));
            unchecked { i++; }
        }
        return stakedMembers;
    }

    function stakeCouncilMember(uint16[] calldata _ids) external payable nonReentrant notContract() {
        require(msg.value == DEV_FEE, "invalid eth amount");
        uint16 length = uint16(_ids.length);

        for (uint i = 0; i < length;) {
            require(MetaTopiaCityCouncil.ownerOf(_ids[i]) == msg.sender , "not owner");
            IERC721(MetaTopiaCityCouncil).safeTransferFrom(msg.sender, address(this), _ids[i]);
            CouncilStake[_ids[i]] = Stake({
                owner : msg.sender,
                tokenId : _ids[i],
                value : uint80(block.timestamp),
                stakedAt : uint80(block.timestamp)
            });
            StakedCouncilMembersOfWallet[msg.sender].add(_ids[i]);
            unchecked { i++; }
        }
        NumberOfStakedCouncilMembers[msg.sender] += length;
        dev.transfer(DEV_FEE);
    }

    function claimCouncilMembers(uint16[] calldata _ids, bool unstake) external payable nonReentrant notContract() {
        require(msg.value == DEV_FEE, "invalid eth amount");
        uint16 length = uint16(_ids.length);
        uint256 owed = 0;

        for (uint i = 0; i < length;) {
            require(CouncilStake[_ids[i]].owner == msg.sender , "not owner");

            if(block.timestamp <= claimEndTime) {
                owed += (block.timestamp - CouncilStake[_ids[i]].value) * DAILY_COUNCIL_RATE / PERIOD;
            } else if (CouncilStake[_ids[i]].value < claimEndTime) {
                owed += (claimEndTime - CouncilStake[_ids[i]].value) * DAILY_COUNCIL_RATE / PERIOD;
            } else {
                owed += 0;
            }

            CouncilStake[_ids[i]].value = uint80(block.timestamp); // reset value

            if (unstake) {
                delete CouncilStake[_ids[i]];
                StakedCouncilMembersOfWallet[msg.sender].remove(_ids[i]);
                IERC721(MetaTopiaCityCouncil).safeTransferFrom(address(this), msg.sender, _ids[i]);
            }
            unchecked { i++; }
        }
        if (unstake) {
            NumberOfStakedCouncilMembers[msg.sender] -= length;
        }
        
        if (owed > 0) {
            TopiaInterface.mint(msg.sender, owed);
            totalTOPIAEarned += owed;
        }
        dev.transfer(DEV_FEE);
    }

    function getTotalUnclaimedCouncilTopia(address _staker) external view returns (uint256 owed) {
        uint16 length = uint16(StakedCouncilMembersOfWallet[_staker].length());
        owed = 0;

        for (uint16 i = 0; i < length;) {
            require(CouncilStake[uint16(StakedCouncilMembersOfWallet[_staker].at(i))].owner == _staker , "not owner");

            if(block.timestamp <= claimEndTime) {
                owed += (block.timestamp - CouncilStake[uint16(StakedCouncilMembersOfWallet[_staker].at(i))].value) * DAILY_COUNCIL_RATE / PERIOD;
            } else if (CouncilStake[uint16(StakedCouncilMembersOfWallet[_staker].at(i))].value < claimEndTime) {
                owed += (claimEndTime - CouncilStake[uint16(StakedCouncilMembersOfWallet[_staker].at(i))].value) * DAILY_COUNCIL_RATE / PERIOD;
            } else {
                owed += 0;
            }
            unchecked { i++; }
        }
        return owed;
    }

    function getTopiaPerCouncilMember(uint16 _id) external view returns (uint256 owed) {
        owed = 0;

        if(block.timestamp <= claimEndTime) {
            owed = (block.timestamp - CouncilStake[_id].value) * DAILY_COUNCIL_RATE / PERIOD;
        } else if (CouncilStake[_id].value < claimEndTime) {
            owed = (claimEndTime - CouncilStake[_id].value) * DAILY_COUNCIL_RATE / PERIOD;
        } else {
            owed = 0;
        }

        return owed;
    }
}