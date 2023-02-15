//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract spacegirlvalentine is ERC1155URIStorage, Ownable, ERC2981 {
    //@param flg of pause
    bool public paused;

    uint256 public totalSupply;

    //@param tokenToLimitNum: minting limitation by user for each tokenid
    mapping(address => mapping(uint256 => uint256))
        public mintLimitByUserForTokneId;

    //STRUCT
    struct input {
        uint256 tokenId;
        address user;
        uint256 num;
    }

    //@param tokenToLimitNum: minting limitation for each tokenID
    mapping(uint256 => uint256) public tokenToLimitNum;

    //CONSTRUCTOR
    constructor() ERC1155("") {
        paused = true;
        _setDefaultRoyalty(0x16903e24dEc25f2C2eB0a3e175A2F29a400B5f30, 1000);
    }

    //MAIN
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    //@notice mint amount should be fixed one by frontend logic
    function mint(
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) public {
        //check
        require(!paused, "The contract is paused");
        require(
            _amount <= mintLimitByUserForTokneId[msg.sender][_tokenId],
            "You have already received"
        );
        require(
            (totalSupply + _amount) <= tokenToLimitNum[_tokenId],
            "Mints num exceeded limit"
        );

        //effect
        mintLimitByUserForTokneId[msg.sender][_tokenId] -= _amount;
        totalSupply += _amount;

        //interaction
        _mint(msg.sender, _tokenId, _amount, _data);
    }

    //SET
    //@notice set BaseURI
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _setBaseURI(_newBaseURI);
    }

    function setURI(uint256 _tokenId, string memory _newTokenURI)
        public
        onlyOwner
    {
        _setURI(_tokenId, _newTokenURI);
    }

    //@notice set Pause
    function setPaused(bool _newPause) external onlyOwner {
        paused = _newPause;
    }

    //@notice set maxMintedNum
    function setMaxMintedNum(uint256 _tokenId, uint256 _newNum)
        external
        onlyOwner
    {
        tokenToLimitNum[_tokenId] = _newNum;
    }

    //@notice set mintNum by user
    function setMintNumByUser(
        address[] memory _users,
        uint256 _tokenId,
        uint256 _num
    ) external onlyOwner {
        uint256 _userNum = _users.length;
        for (uint256 i = 0; i < _userNum; i++) {
            mintLimitByUserForTokneId[_users[i]][_tokenId] = _num;
        }
    }

    function batchSetMintNumByUser(input[] calldata InputArray) external onlyOwner{
        uint256 _num = InputArray.length;
        for (uint256 i = 0; i < _num; i++) {
            mintLimitByUserForTokneId[InputArray[i].user][InputArray[i].tokenId] = InputArray[i].num;
        }
    }

    function getWhitelist(address _user, uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        return mintLimitByUserForTokneId[_user][_tokenId];
    }
}