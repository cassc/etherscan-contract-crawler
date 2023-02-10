//MMMMMMMMMMMMMMMMMMMMMMMMMMMWKOdlc,... ..''..   ...,:ldkKWMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMWXOdc,.         :KXNX:           .,cokXWMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMW0d:.              oMMMWc           ..   .;oONMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMWKd,.                 oMMMWc           .:oo:.   ,o0WMMMMMMMMMMMM
//MMMMMMMMMMMMMMNk:. .'.                oMMMWc             .:l'     .;xNMMMMMMMMMM
//MMMMMMMMMMMMNk;  'xXK;                oMMMWc                 .oxc.   ,xNMMMMMMMM
//MMMMMMMMMMW0:   .xMMX;                oMMMWc                 :XMWo     ,kWMMMMMM
//MMMMMMMMMNd.    .xMMX;                oMMMWc                 ;XMMd  .,  .lXMMMMM
//MMMMMMMMK:      .xMMX;                oMMMWc                 ;XMMd. ;0x.  ,0WMMM
//MMMMMMM0,       .xMMX;                oMMMWc                 ;XMMx. ,KM0;  'OWMM
//MMMMMM0,        .xMMX;                oMMMWc                 ;XMMx. ,0MMX:  .kWM
//MMMMMK;         .xMMX;                oMMMWc                 ;XMMx. .OMMMX:  'OM
//MMMMNl          .xMMX;                oMMMWc                 ;XMMx.  cNMMMK;  :X
//MMMMk.          .xMMX;                oMMMWc                 ;XMMx.  .kMMMMk. .d
//MMMWl           .xMMX;                oMMMWc                 ;XMMx.   cNMMMN:  ;
//MMMK,           .xMMX;                oMMMWc                 ;XMMx.   '0MMMMd  .
//MMMO'           .xMMX;                oMMMWc                 ;XMMx.   .OMMMMk. .
//MMMk.           .xMMX;                oMMMWc                 ;XMMx.   .xMMMM0'
//MMMk.           .xMMX;                oMMMWc                 ;XMMx.   .xMMMMK,
//MMMx.           .xMMX;                oMMMWc                 ;XMMx.   .xMMMMK,
//MMMk.           .xMMX;                oMMMWc                 ;XMMx.   .xMMMMK,
//MMMk.           .xMMX;                oMMMWc                 ;XMMx.   .xMMMMK,
//MMMk.           .xMMX;                oMMMWc                 ;XMMx.   .kMMMMK,
//MMMO.           .xMMX;                oMMMWc                 ;XMMx.   .kMMMMK,
//MMMO.           .xMMX;                oMMMWc                 ;XMMx.   .kMMMMK,
//MMMO.           .xMMX;                oMMMWc                 ;XMMx.   .kMMMMK,
//MMMO.           .xMMX;                oMMMWc                 ;XMMx.   .kMMMMK, .
//MMMO.           .xMMX;                oMMMWc                 ;XMMx.   .OMMMMK, .
//MMMO.           .xMMX;                oMMMWl                 ;XMMx.   .kMMMMK,
//MMMO.           .xMMX;                oWMMWc                 ;XMMx.   .kMMMMX;
//MMMO.           .oKKO,                cKKKK:                 ,OKKo.   .oKKKK0,
//MMMK,             ...                  ....                   ...       .....  .
//MMMWl                                                                         .x

//   CELMATES - DEATHROW

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ICelmates {
    function ownerOf(uint256 tokenId) external view returns (address);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function balanceOf(address owner) external view returns (uint256);
}

struct Infos {
    bool status;
    address owner;
    uint256 timestamp;
}

contract Deathrow is Ownable {
    ICelmates private CELMATES;
    mapping(uint256 => Infos) public deathRowInfos;
    mapping(uint256 => uint256) public points;
    mapping(uint256 => uint256) public celmateToType;
    bool private opened;

    // ------------------ External ------------------ //

    function deathRow(uint256 _celId, bool _status) external {
        require(opened, "Deathrow is closed.");
        require(
            CELMATES.ownerOf(_celId) == msg.sender,
            "You don't own this Celmate"
        );
        Infos memory currDeathRow = deathRowInfos[_celId];
        if (_status) {
            Infos memory newDeathRow = Infos(true, msg.sender, block.timestamp);
            deathRowInfos[_celId] = newDeathRow;
        } else {
            require(deathRowInfos[_celId].status, "Not on DeathRow");
            currDeathRow.status = false;
            deathRowInfos[_celId] = currDeathRow;
        }
    }

    // ------------------ Public ------------------ //

    function getDeathrow(uint256 _celId)
        public
        view
        returns (Infos memory infos)
    {
        return deathRowInfos[_celId];
    }

    function getPoints(address _owner)
        public
        view
        returns (uint256 pointsToReturn)
    {
        uint256 totalPoints;
        uint256 balance = CELMATES.balanceOf(_owner);
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = CELMATES.tokenOfOwnerByIndex(_owner, i);
            Infos memory infos = deathRowInfos[tokenId];
            if (infos.owner == _owner && infos.status) {
                uint256 daysStaked = (block.timestamp - infos.timestamp) /
                    60 /
                    60 /
                    24;
                totalPoints += points[celmateToType[tokenId]] * daysStaked;
            }
        }
        return totalPoints;
    }

    // ------------------ Owner ------------------ //

    function setPoints(uint256[] memory _points) external onlyOwner {
        for (uint256 i = 0; i < _points.length; i++) {
            points[i] = _points[i];
        }
    }

    function setTypes(uint256[] memory _types) external onlyOwner {
        for (uint256 i = 0; i < _types.length; i++) {
            celmateToType[i] = _types[i];
        }
    }

    function editStake(
        uint256 _stakeId,
        address _owner,
        uint256 _timestamp,
        bool _status
    ) external onlyOwner {
        Infos memory infoToEdit = deathRowInfos[_stakeId];
        infoToEdit.owner = _owner;
        infoToEdit.timestamp = _timestamp;
        infoToEdit.status = _status;
        deathRowInfos[_stakeId] = infoToEdit;
    }

    function editTypes(uint256[] memory _ids, uint256[] memory _types)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _ids.length; i++) {
            celmateToType[_ids[i]] = _types[i];
        }
    }

    function setOpened(bool _flag) external onlyOwner {
        opened = _flag;
    }

    function setCelmates(address _celmates) external onlyOwner {
        CELMATES = ICelmates(_celmates);
    }
}