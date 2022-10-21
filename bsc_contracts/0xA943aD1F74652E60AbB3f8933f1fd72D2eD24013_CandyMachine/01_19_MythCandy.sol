// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "ERC721.sol";
import "ERC20.sol";
import "Degen.sol";

contract CandyMachine {
    address public owner;
    address public candyAddress;
    address public mythralAddress;

    constructor(address _candyAddress, address _mythralAddress) {
        owner = msg.sender;
        candyAddress = _candyAddress;
        mythralAddress = _mythralAddress;
    }

    function buyCandy(uint256 _amount) external {
        ERC20 mythralContract = ERC20(mythralAddress);
        mythralContract.transferFrom(msg.sender, owner, _amount * 10**9);
        MythCandys mythCandyContract = MythCandys(candyAddress);
        bool isMinted = mythCandyContract.mint(msg.sender, 1, _amount * 4);
        require(isMinted, "Failed to mint");
    }
}

contract MythCandys is ERC721 {
    address public owner;
    uint256 public tokenCount;
    mapping(address => bool) public whitelistedAddresses;
    mapping(uint256 => string) public candyImageId;
    mapping(uint256 => bool) public candyImageIdExists;
    mapping(uint256 => candyStatStruct) public candyStats;
    struct candyStatStruct {
        address owner;
        CandyState candyState;
        uint256 imageId;
        uint256 statValue;
    }
    address public degenAddress;
    event candyMinted(
        address owner,
        uint256 candyId,
        uint256 candyStat,
        uint256 imageId
    );
    event candyImageAdded(uint256 imageId, string imageURL);
    event candyUpgraded(
        address owner,
        uint256 candyId,
        uint256 degenId,
        uint256 statType,
        uint256 oldStat,
        uint256 newStat
    );

    enum CandyState {
        OWNED,
        UPGRADED
    }

    modifier isWhitelisted() {
        require(
            whitelistedAddresses[msg.sender] || msg.sender == owner,
            "Not white listed"
        );
        _;
    }

    constructor(address _degenAddress) ERC721("Myth City Candys", "MYTHCANDY") {
        owner = msg.sender;
        whitelistedAddresses[msg.sender] = true;
        degenAddress = _degenAddress;
    }

    function setAddresses(address _degenAddress) external {
        require(msg.sender == owner, "only owner");
        if (_degenAddress != address(0)) {
            degenAddress = _degenAddress;
        }
    }

    function setImage(uint256 _imageId, string memory _imageUrl) external {
        require(msg.sender == owner, "only owner");
        candyImageId[_imageId] = _imageUrl;
        candyImageIdExists[_imageId] = true;
        emit candyImageAdded(_imageId, _imageUrl);
    }

    function removeImage(uint256 _imageId, string memory _imageUrl) external {
        require(msg.sender == owner, "only owner");
        candyImageId[_imageId] = _imageUrl;
        candyImageIdExists[_imageId] = false;
        emit candyImageAdded(_imageId, _imageUrl);
    }

    function alterWhitelist(address _address) external isWhitelisted {
        whitelistedAddresses[_address] = !whitelistedAddresses[_address];
    }

    function transfer(uint256 _candyId, address _to) external {
        require(
            candyStats[_candyId].owner == msg.sender,
            "Only the owner can transfer with this method"
        );
        require(
            candyStats[_candyId].candyState == CandyState.OWNED,
            "Cannot transfer when used"
        );
        _transfer(msg.sender, _to, _candyId);
        candyStats[_candyId].owner = _to;
    }

    function transferFrom(
        address from,
        address _to,
        uint256 _candyId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), _candyId),
            "ERC721: caller is not token owner or approved"
        );
        require(
            candyStats[_candyId].candyState == CandyState.OWNED,
            "Cannot transfer when used"
        );
        _transfer(from, _to, _candyId);
        candyStats[_candyId].owner = _to;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );
        require(
            candyStats[tokenId].candyState == CandyState.OWNED,
            "Cannot transfer when used"
        );
        _safeTransfer(from, to, tokenId, data);
        candyStats[tokenId].owner = to;
    }

    function mint(
        address _to,
        uint256 _imageId,
        uint256 _statAmount
    ) external isWhitelisted returns (bool) {
        uint256 tempCount = tokenCount;
        require(
            candyImageIdExists[_imageId],
            "This image id is not available."
        );
        _mint(_to, tempCount);
        candyStats[tempCount].owner = _to;
        candyStats[tempCount].statValue = _statAmount;
        candyStats[tempCount].imageId = _imageId;
        emit candyMinted(_to, tempCount, _statAmount, _imageId);
        tokenCount++;
        return true;
    }

    function activateCandy(
        uint256 _candyId,
        uint256 _upgradeStat,
        uint256 _idOfItem
    ) external {
        require(_upgradeStat >= 1 && _upgradeStat <= 2, "Select correct stat");
        candyStatStruct memory tempStats = candyStats[_candyId];
        require(
            tempStats.owner == msg.sender,
            "Only the owner of the candy can activate it"
        );
        require(tempStats.candyState == CandyState.OWNED, "Already Activated");
        MythDegen tempContract = MythDegen(degenAddress);
        MythDegen.stats memory tempDegenStat = tempContract.getStats(_idOfItem);
        require(tempDegenStat.owner == msg.sender, "You dont own that Degen");
        uint256 oldStat = 0;
        tempStats.candyState = CandyState.UPGRADED;

        candyStats[_candyId] = tempStats;
        if (_upgradeStat == 1) {
            oldStat = tempDegenStat.coreScore;
            tempContract.reGradeDegen(
                _idOfItem,
                oldStat + tempStats.statValue,
                0
            );
        } else if (_upgradeStat == 2) {
            oldStat = tempDegenStat.damageCap;
            tempContract.reGradeDegen(
                _idOfItem,
                0,
                oldStat + tempStats.statValue
            );
        }

        emit candyUpgraded(
            msg.sender,
            _candyId,
            _idOfItem,
            _upgradeStat,
            oldStat,
            oldStat + tempStats.statValue
        );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        candyStatStruct memory tempStats = candyStats[tokenId];
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{ "name": "',
                        Base64.concatenate(
                            "Myth Candy #",
                            Base64.uint2str(tokenId)
                        ),
                        '",',
                        '"attributes": [{"trait_type": "Candy Id", "value": ',
                        Base64.uint2str(tokenId),
                        '},{"trait_type": "Stat Value", "value": ',
                        Base64.uint2str(tempStats.statValue),
                        '},{"trait_type": "Candy Status", "value": ',
                        Base64.uint2str(uint256(tempStats.candyState)),
                        "}",
                        "]",
                        ',"image_data" : "',
                        candyImageId[tempStats.imageId],
                        '","external_url": "mythcity.app","description":"A Sweet Piece of Candy."',
                        "}"
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function toString(bytes memory data) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}