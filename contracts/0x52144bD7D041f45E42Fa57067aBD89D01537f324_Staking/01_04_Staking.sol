// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "erc721a/contracts/IERC721A.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

enum TicketTypes {
    SILVER,
    GOLD
}

interface ITicket {
    function mint(address accountAddress, TicketTypes ticketType) external;
    function burn(uint256 tokenId) external;
    function nextTokenId() external view returns (uint);
}

contract Staking {
    using EnumerableSet for EnumerableSet.UintSet;

    IERC721A private _mainContract = IERC721A(0x7CF98020Edf5F8FB2A4b490f2ad51168FD4Bc36E);
    ITicket _ticketContract = ITicket(0x302eABd74847CF3723EA633FACe518eC3D4e064A);

    mapping(uint => address) private _tokenIdToOwner;
    mapping(address => EnumerableSet.UintSet) private _addressToStakedTokensSet;
    mapping(uint => uint) private _tokenIdToStakedTimestamp;
    mapping(uint => TicketTypes) private _tokenIdToStakedTicketType;
    mapping(uint => uint) private _tokenIdToTicketTokenId;
    mapping(TicketTypes => uint) private _stakingTimes;

    event Stake(uint tokenId, address owner);
    event Unstake(uint tokenId, address owner);

    constructor() {
         _stakingTimes[TicketTypes.SILVER] = 15768000;
         _stakingTimes[TicketTypes.GOLD] = 31536000;
    }

    function stake(uint[] memory tokenIds, TicketTypes ticketType) external {
        require(ticketType == TicketTypes.SILVER || ticketType == TicketTypes.GOLD, "invalid ticket type");

        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];

            // Assign token to his owner
            _tokenIdToOwner[tokenId] = msg.sender;

            // Transfer token to this smart contract
            _mainContract.safeTransferFrom(msg.sender, address(this), tokenId);

            // Add this token to user staked tokens
            _addressToStakedTokensSet[msg.sender].add(tokenId);

            // Save stake timestamp
            _tokenIdToStakedTimestamp[tokenId] = block.timestamp;

            // Save stake ticket type
            _tokenIdToStakedTicketType[tokenId] = ticketType;

            // Generate ticket to this sender
            uint ticketTokenId = _ticketContract.nextTokenId();
            _ticketContract.mint(msg.sender, ticketType);
            _tokenIdToTicketTokenId[tokenId] = ticketTokenId;

            emit Stake(tokenId, msg.sender);
        }
    }

    function unstake(uint[] memory tokenIds) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];

            require(_addressToStakedTokensSet[msg.sender].contains(tokenId), "token is not staked");
            require(block.timestamp - _tokenIdToStakedTimestamp[tokenId] >= _stakingTimes[_tokenIdToStakedTicketType[tokenId]], "token is not unstakable");

            // Transfer token to his owner
            _mainContract.safeTransferFrom(address(this), msg.sender, tokenId);

            // Remove this token from user staked tokens
            _addressToStakedTokensSet[msg.sender].remove(tokenId);

            // Burn the ticket
            _ticketContract.burn(_tokenIdToTicketTokenId[tokenId]);

            // Remove owner of this token
            delete _tokenIdToOwner[tokenId];

            // Remove ticket token id
            delete _tokenIdToTicketTokenId[tokenId];

            // Remove ticket type
            delete _tokenIdToStakedTicketType[tokenId];

            // Remove stake timestamp
            delete _tokenIdToStakedTimestamp[tokenId];

            emit Unstake(tokenId, msg.sender);
        }
    }

    function stakedTokenTimestamp(uint tokenId) public view returns (uint) {
        require(_tokenIdToOwner[tokenId] != address(0), "token is not staked");
        return _tokenIdToStakedTimestamp[tokenId];
    }

    function stakedTokenTicketType(uint tokenId) public view returns (TicketTypes) {
        require(_tokenIdToOwner[tokenId] != address(0), "token is not staked");
        return _tokenIdToStakedTicketType[tokenId];
    }

    function stakedTokenTimestampLeft(uint tokenId) public view returns (uint) {
        require(_tokenIdToOwner[tokenId] != address(0), "token is not staked");
        TicketTypes ticketType = _tokenIdToStakedTicketType[tokenId];
        uint stakingTime = _stakingTimes[ticketType];

        if (stakingTime < (currentTimestamp() - stakedTokenTimestamp(tokenId))) {
            return 0;
        }

        return stakingTime - (currentTimestamp() - stakedTokenTimestamp(tokenId));
    }

    function stakedTokensOfOwner(address owner) public view returns (uint[] memory) {
        EnumerableSet.UintSet storage userTokens = _addressToStakedTokensSet[owner];
        return _uintSetToUintArray(userTokens);
    }

    function stakedTokenTimestamps(address owner) public view returns (uint[] memory) {
        uint[] memory tokenIds = stakedTokensOfOwner(owner);
        uint[] memory timestamps = new uint[](tokenIds.length);

        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];

            timestamps[i] = stakedTokenTimestamp(tokenId);
        }

        return timestamps;
    }

    function stakedTokenTicketTypes(address owner) public view returns (TicketTypes[] memory) {
        uint[] memory tokenIds = stakedTokensOfOwner(owner);
        TicketTypes[] memory ticketTypes = new TicketTypes[](tokenIds.length);

        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];

            ticketTypes[i] = stakedTokenTicketType(tokenId);
        }

        return ticketTypes;
    }

    function stakedTokenTimestampsLeft(address owner) public view returns (uint[] memory) {
        uint[] memory tokenIds = stakedTokensOfOwner(owner);
        uint[] memory timestampsLeft = new uint[](tokenIds.length);

        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];

            timestampsLeft[i] = stakedTokenTimestampLeft(tokenId);
        }

        return timestampsLeft;
    }

    function stakingTimes() public view returns (uint[2] memory) {
        return [
            _stakingTimes[TicketTypes.SILVER],
            _stakingTimes[TicketTypes.GOLD]
        ];
    }

    function currentTimestamp() public view returns (uint) {
        return block.timestamp;
    }

    function _uintSetToUintArray(EnumerableSet.UintSet storage values) internal view returns (uint[] memory) {
        uint[] memory result = new uint[](values.length());

        for (uint i = 0; i < values.length(); i++) {
            result[i] = values.at(i);
        }

        return result;
    }

    function onERC721Received(address operator, address, uint256, bytes calldata) external view returns(bytes4) {
        require(operator == address(this), "token must be staked over stake method");
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}