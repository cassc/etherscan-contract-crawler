//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RandomNFT is Ownable {
    mapping(address => mapping(uint256 => lot)) adrToLotIdToInfo;
    mapping(address => uint256) adrToLotAmount;
    address[] lotOwners;
    mapping(address => mapping(uint256 => bool)) colAdrToId;

    mapping(uint256 => infoLot) idToAdrToLotId;
    uint64 public AllLotsAmount;
    string[] meta;

    struct infoLot {
        address adr;
        uint256 lotId;
    }

    address private signer;
    string private secret;

    uint256 maxAmountPart;

    struct lot {
        address collection;
        uint128 id;
        uint128 maxPart;
        uint256 endDate;
        uint256 stateNumber;
        uint256 minBal;
        address exactCol;
        address winner;
        uint256 winnerId;
        bool done;
        bool closed;
        uint64 AllLotId;
        string follow;
        uint64 age;
        uint64 followers;
        uint128 postId;
        string str;
        uint256 arrayPos;
    }

    constructor(string memory secret_) {
        maxAmountPart = 20;
        signer = msg.sender;
        secret = secret_;
    }

    function changeMaxPart(uint256 newMax) external onlyOwner {
        maxAmountPart = newMax;
    }

    function changeSigner(address newSigner) external onlyOwner {
        signer = newSigner;
    }

    function makeLotery(
        address collection,
        uint128 id,
        uint128 maxPart,
        uint256 endDate,
        uint256 stateNumber,
        uint256 minBal,
        address exactCol,
        string memory follow,
        uint64 age,
        uint64 followers,
        uint128 postId,
        string memory str
    ) external {
        require(
            !colAdrToId[collection][id],
            "Already participating it lottery"
        );
        IERC721 mainToken = IERC721(collection);
        require(mainToken.ownerOf(id) == msg.sender, "not owner of the NFT");
        if (stateNumber == 2 || stateNumber == 3) {
            require(exactCol != address(0), "col == 0");
        }
        AllLotsAmount++;

        adrToLotAmount[msg.sender]++;
        idToAdrToLotId[AllLotsAmount] = infoLot(
            msg.sender,
            adrToLotAmount[msg.sender]
        );

        adrToLotIdToInfo[msg.sender][adrToLotAmount[msg.sender]] = lot(
            collection,
            id,
            maxPart,
            endDate,
            stateNumber,
            minBal,
            exactCol,
            address(0),
            0,
            false,
            false,
            AllLotsAmount,
            follow,
            age,
            followers,
            postId,
            str,
            meta.length
        );

        lotOwners.push(msg.sender);
        colAdrToId[collection][id] = true;
        meta.push(str);
    }

    /*
    function participate(
        address adr,
        uint256 lotId,
        uint256 timestamp,
        bytes memory _sig,
        uint256 twitter
    ) external {
        require(block.timestamp <= timestamp + 480, "Time is over");
        require(lotId <= adrToLotAmount[adr] && lotId > 0, "incorrect lot id");
        require(
            adrToLotIdToInfo[adr][lotId].curParticipant + 1 <=
                adrToLotIdToInfo[adr][lotId].maxParticipant,
            "max amount is exceeded"
        );
        require(
            block.timestamp <= adrToLotIdToInfo[adr][lotId].endDate,
            "not correct time"
        );

        require(adrToLotIdToInfo[adr][lotId].done == false, "Already done");

        bytes32 message = getMessageHash(msg.sender, timestamp);
        require(verify(message, _sig), "It's not a signer");

        if (adrToLotIdToInfo[adr][lotId].stateNumber == 1) {
            require(
                address(msg.sender).balance >=
                    adrToLotIdToInfo[adr][lotId].minBal,
                "not enough money on balance"
            );
        } else if (adrToLotIdToInfo[adr][lotId].stateNumber == 2) {
            IERC721 col = IERC721(adrToLotIdToInfo[adr][lotId].exactCol);
            require(
                col.balanceOf(msg.sender) > 0,
                "you dont have access (nft)"
            );
        } else if (adrToLotIdToInfo[adr][lotId].stateNumber == 3) {
            require(
                address(msg.sender).balance >=
                    adrToLotIdToInfo[adr][lotId].minBal,
                "not enough money on balance"
            );
            IERC721 col = IERC721(adrToLotIdToInfo[adr][lotId].exactCol);
            require(
                col.balanceOf(msg.sender) > 0,
                "you dont have access (nft)"
            );
        }

        adrToLotIdToInfo[adr][lotId].curParticipant++;
    }*/

    function checkTimeNow() external view returns (uint256) {
        return block.timestamp;
    }

    /*function checkTwit(
        address adr,
        uint256 lotId,
        uint256 twitter
    ) external view returns (bool) {
        for (uint256 i; i < adrToLotIdToPartTwit[adr][lotId].length; i++) {
            if (adrToLotIdToPartTwit[adr][lotId][i] == twitter) {
                return true;
            }
        }
        return false;
    }*/

    /*function getMyRegisteredTwit(address adr, uint lotId) external view returns(uint){
        for(uint i; i < adrToLotIdToPartTwit[adr][lotId].length; i++){
            if
        }
    }*/

    function isInArray(address[] memory array, address adr)
        internal
        pure
        returns (bool)
    {
        for (uint256 i; i < array.length; i++) {
            if (array[i] == adr) {
                return true;
            }
        }
        return false;
    }

    function getRandomNumber(
        address adr,
        uint64 lotId,
        uint64 maxCount,
        uint64 timestamp,
        bytes memory _sig
    ) external returns (uint256) {
        bytes32 message = getMessageHash(msg.sender, timestamp);
        require(verify(message, _sig), "It's not a signer");
        require(
            block.timestamp > adrToLotIdToInfo[adr][lotId].endDate,
            "Time is not over"
        );
        uint256 ran = random(maxCount) + 1;
        adrToLotIdToInfo[adr][lotId].winnerId = ran;
        return ran;
    }

    function closeLottery(
        address adr,
        uint64 lotId,
        address winner,
        uint64 timestamp,
        bytes memory _sig
    ) external {
        require(
            block.timestamp >= adrToLotIdToInfo[adr][lotId].endDate,
            "Time is not over yet"
        );
        require(adr == msg.sender, "you are not owner of the lot");
        require(adrToLotIdToInfo[adr][lotId].done == false, "Already done");
        require(isInArray(lotOwners, msg.sender), "you dont have a lot");

        bytes32 message = getMessageHash(msg.sender, timestamp);
        require(verify(message, _sig), "It's not a signer");

        adrToLotIdToInfo[adr][lotId].closed = true;
        adrToLotIdToInfo[adr][lotId].winner = winner;

        IERC721 mainToken = IERC721(adrToLotIdToInfo[adr][lotId].collection);
        mainToken.transferFrom(adr, winner, adrToLotIdToInfo[adr][lotId].id);
        adrToLotIdToInfo[adr][lotId].done = true;
        colAdrToId[adrToLotIdToInfo[adr][lotId].collection][
            adrToLotIdToInfo[adr][lotId].id
        ] = false;
    }

    //if input = 100 then 1-99

    function random(uint256 number) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender
                    )
                )
            ) % number;
    }

    struct mygives {
        uint64 id;
        uint64 isClosed;
        uint64 IdFromAll;
        string myMetaData;
        uint128 maxParticipants;
    }

    mapping(address => mygives[]) myLotsInfoStruct;

    function myGiveaways(address user, uint256 startPoint)
        external
        view
        returns (mygives[] memory myInfo)
    {
        uint64[] memory IdArray = new uint64[](adrToLotAmount[user]);
        uint64[] memory array = new uint64[](adrToLotAmount[user]);
        uint64[] memory IdFromAllArray = new uint64[](adrToLotAmount[user]);
        string[] memory myMeta = new string[](adrToLotAmount[user]);
        uint128[] memory maxPart = new uint128[](adrToLotAmount[user]);
        for (uint16 i = 1; i <= adrToLotAmount[user]; i++) {
            //array[i] = adrToLotIdToInfo[user][i].done;
            if (adrToLotIdToInfo[user][i].done) {
                array[i - 1] = 2; //уже завершен
            } else {
                if (block.timestamp > adrToLotIdToInfo[user][i].endDate) {
                    array[i - 1] = 1; //можно завершить
                } else {
                    array[i - 1] = 0; //нельзя завершить
                }
            }
            IdFromAllArray[i - 1] = adrToLotIdToInfo[user][i].AllLotId;
            IdArray[i - 1] = i;
            myMeta[i - 1] = meta[adrToLotIdToInfo[user][i].arrayPos];
            maxPart[i - 1] = adrToLotIdToInfo[user][i].maxPart;
        }

        uint256 amount = 10;

        require(startPoint % 10 == 0, "startPoint must be 0, 8, 16 ... etc.");
        require(startPoint < uint256(IdArray.length), "startPoint too big");

        uint256 count;
        bool a;

        if (IdArray.length < startPoint + amount) {
            uint256 newStartPoint = startPoint - (startPoint % 8);

            mygives[] memory myStruct = new mygives[](
                IdArray.length - newStartPoint
            );

            for (uint256 i = newStartPoint; i < IdArray.length; i++) {
                myStruct[count].id = IdArray[i];
                myStruct[count].isClosed = array[i];
                myStruct[count].IdFromAll = IdFromAllArray[i];
                myStruct[count].myMetaData = myMeta[i];
                myStruct[count].maxParticipants = maxPart[i];
                count++;
            }
            return (myStruct);
        } else {
            mygives[] memory myStruct = new mygives[](amount);
            for (uint256 i = startPoint; i < startPoint + amount; i++) {
                myStruct[count].id = IdArray[i];
                myStruct[count].isClosed = array[i];
                myStruct[count].IdFromAll = IdFromAllArray[i];
                myStruct[count].myMetaData = myMeta[i];
                myStruct[count].maxParticipants = maxPart[i];

                count++;
                a = true;
            }

            return (myStruct);
        }
    }

    function checkAllIdLot(uint256 id) external view returns (infoLot memory) {
        return idToAdrToLotId[id];
    }

    /*
    function getToken(address adr, uint256 lotId) external {
        require(
            block.timestamp >= adrToLotIdToInfo[adr][lotId].endDate &&
                block.timestamp <
                adrToLotIdToInfo[adr][lotId].claimStart +
                    adrToLotIdToInfo[adr][lotId].claimTime &&
                adrToLotIdToInfo[adr][lotId].claimStart != 0,
            "time is over or not ready yet"
        );
        require(
            adrToLotIdToInfo[adr][lotId].winner == msg.sender,
            "you are not the winner"
        );
        require(adrToLotIdToInfo[adr][lotId].done == false, "Already done");
        IERC721 mainToken = IERC721(adrToLotIdToInfo[adr][lotId].collection);
        mainToken.transferFrom(
            adr,
            msg.sender,
            adrToLotIdToInfo[adr][lotId].id
        );
        adrToLotIdToInfo[adr][lotId].done = true;
    }
*/
    /*
    function getRest(address adr, uint256 lotId) external {
        require(
            block.timestamp >= adrToLotIdToInfo[adr][lotId].endDate,
            "time is over or not ready yet"
        );
        require(adr == msg.sender, "not your lot");
        require(adrToLotIdToInfo[adr][lotId].done == false, "Already done");
        require(adrToLotIdToInfo[adr][lotId].closed == true, "Not closed lot");
        require(
            adrToLotIdToInfo[adr][lotId].winner == address(0x0),
            "winner exists"
        );
        IERC721 mainToken = IERC721(adrToLotIdToInfo[adr][lotId].collection);
        mainToken.transferFrom(
            address(this),
            msg.sender,
            adrToLotIdToInfo[adr][lotId].id
        );
        adrToLotIdToInfo[adr][lotId].done = true;
    }
*/
    function lotInfo(address adr, uint256 lotId)
        external
        view
        returns (lot memory)
    {
        return adrToLotIdToInfo[adr][lotId];
    }

    /*
    function checkParticipants(
        address adr,
        uint256 lotId,
        uint256 startPoint
    ) external view returns (address[] memory, uint256 userCount) {
        uint256 amount = 10;

        require(startPoint % 10 == 0, "startPoint must be 0, 10, 20 ... etc.");
        require(
            startPoint < adrToLotIdToPart[adr][lotId].length,
            "startPoint too big"
        );

        uint256 count;
        bool a;

        if (adrToLotIdToPart[adr][lotId].length < startPoint + amount) {
            uint256 newStartPoint = startPoint - (startPoint % 10);
            address[] memory adrArray = new address[](
                adrToLotIdToPart[adr][lotId].length - newStartPoint
            );
            for (
                uint256 i = newStartPoint;
                i < adrToLotIdToPart[adr][lotId].length;
                i++
            ) {
                if (adrToLotIdToPart[adr][lotId][i] != address(0)) {
                    adrArray[count] = adrToLotIdToPart[adr][lotId][i];
                    count++;
                }
            }
            return (adrArray, adrToLotIdToPart[adr][lotId].length);
        } else {
            address[] memory adrArray = new address[](amount);
            for (uint256 i = startPoint; i < startPoint + amount; i++) {
                if (adrToLotIdToPart[adr][lotId][i] != address(0)) {
                    adrArray[count] = adrToLotIdToPart[adr][lotId][i];
                    count++;
                    a = true;
                }
            }

            return (adrArray, adrToLotIdToPart[adr][lotId].length);
        }
    }
*/
    function checkLotOwners() external view returns (address[] memory) {
        return lotOwners;
    }

    function checkOwnerLotAmount(address adr) external view returns (uint256) {
        return adrToLotAmount[adr];
    }

    function checkMaxPart() external view returns (uint256) {
        return maxAmountPart;
    }

    /*
    function searchMeta(string memory postAddress)
        external
        view
        returns (
            bool exist,
            uint256 state,
            address lotOwner,
            uint256 lotId,
            string memory str
        )
    {
        bool a;
        uint8 state1;
        for (uint16 i = 1; i <= AllLotsAmount; i++) {
            address adr = idToAdrToLotId[i].adr;
            uint256 lotId1 = idToAdrToLotId[i].lotId;
            if (
                keccak256(abi.encodePacked(adrToLotIdToInfo[adr][lotId].str)) ==
                keccak256(abi.encodePacked(postAddress))
            ) {
                a = true;
                if (adrToLotIdToInfo[adr][lotId].done) {
                    state1 = 2;
                } else {
                    if (
                        block.timestamp > adrToLotIdToInfo[adr][lotId].endDate
                    ) {
                        state1 = 1;
                    } else {
                        state1 = 0;
                    }
                }
                return (
                    a,
                    state1,
                    adr,
                    lotId1,
                    adrToLotIdToInfo[adr][lotId].str
                );
            }
        }
        return (a, state1, address(0), 0, "");
    }
*/
    // Проверка
    function verify(bytes32 message, bytes memory _sig)
        public
        view
        returns (
            bool /*, address adr1, address adr2*/
        )
    {
        //bytes32 messageHash = getMessageHash(msg.sender, address(this), amount, nonce, timestamp);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(message);

        return (recover(ethSignedMessageHash, _sig) == signer); /*, recover(ethSignedMessageHash, _sig), signer*/
    }

    function getMessageHash(address user, uint256 timestamp)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(user, timestamp, secret));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recover(bytes32 _ethSignedMessageHash, bytes memory _sig)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = _split(_sig);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function _split(bytes memory _sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(_sig.length == 65, "invalid signature name");

        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }
    }

    function checkSecret() external view onlyOwner returns (string memory) {
        return secret;
    }

    function checkMyState(
        address participant,
        address lotOwner,
        uint32 lotId
    ) external view returns (uint256) {
        if (participant == lotOwner) {
            return 4;
        } else {
            if (block.timestamp > adrToLotIdToInfo[lotOwner][lotId].endDate) {
                if (adrToLotIdToInfo[lotOwner][lotId].winner == participant) {
                    if (adrToLotIdToInfo[lotOwner][lotId].done) {
                        return 4;
                    } else {
                        return 4; //кнопка забрать награду
                    }
                } else {
                    if (adrToLotIdToInfo[lotOwner][lotId].done) {
                        return 4;
                    } else {
                        return 4; //participate
                    }
                }
            } else {
                return 1;
            }
        }
    }

    function isInArrayAdr(address[] memory array, address element)
        internal
        pure
        returns (bool)
    {
        for (uint32 i; i < array.length; i++) {
            if (array[i] == element) {
                return true;
            }
        }
        return false;
    }
}