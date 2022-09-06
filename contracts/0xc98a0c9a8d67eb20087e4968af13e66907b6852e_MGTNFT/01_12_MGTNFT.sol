// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MGTNFT is ERC721Upgradeable, OwnableUpgradeable {
    //  receive ETH
    address public copyright;
    address public project;

    uint64 public maxSupply;
    uint64 public totalSupply;

    struct BatchConfig {
        uint256 startID;
        uint256 endID;
        uint256 price;
        uint64 startTime;
        uint64 endTime;
        uint64 amountPerUser;
        bool forPublic;
    }

    // batch index => config
    mapping(uint256 => BatchConfig) public batchConfigs;
    // batch index => current tokenID
    mapping(uint256 => uint256) public batchCurrentTokenID;
    // batch index => user address => ok
    mapping(uint256 => mapping(address => bool)) public whitelist;
    // user address => batch index => minted amount
    mapping(address => mapping(uint256 => uint64)) public minted;

    // reveal
    string private baseURI;
    string public blindBoxBaseURI;
    string private contractURI_;
    uint256[] public stageIDs;
    mapping(uint256 => string) public revealedBaseURI;

    mapping(address => bool) public whitelistNoBatch;

    // constructor
    function initialize(
        string memory _name,
        string memory _symbol,
        address _project,
        address _copyright
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        project = _project;
        copyright = _copyright;
        maxSupply = 1270;
    }

    event BlindBoxOpen(uint256 tokenId);

    /* --------------- sale config owner set --------------- */

    function setBatchConfig(BatchConfig calldata config, uint256 batchIndex)
        public
        onlyOwner
    {
        require(
            batchConfigs[batchIndex].endTime == 0,
            "can not set some index batch twice"
        );
        require(
            config.startID <= config.endID,
            "startID must be smaller then endID"
        );
        require(
            config.startTime < config.endTime,
            "startTime must be smaller then endTime"
        );
        batchConfigs[batchIndex] = config;
        batchCurrentTokenID[batchIndex] = config.startID;
    }

    function setBatchPrice(uint256 price, uint256 batchIndex) public onlyOwner {
        batchConfigs[batchIndex].price = price;
    }

    function setBatchStartAndEndID(
        uint256 startID,
        uint256 endID,
        uint256 batchIndex
    ) public onlyOwner {
        require(startID <= endID, "startID must be smaller then endID");
        batchConfigs[batchIndex].startID = startID;
        batchConfigs[batchIndex].endID = endID;
    }

    function setBatchStartAndEndTime(
        uint64 startTime,
        uint64 endTime,
        uint256 batchIndex
    ) public onlyOwner {
        require(startTime < endTime, "startTime must be smaller then endTime");
        batchConfigs[batchIndex].startTime = startTime;
        batchConfigs[batchIndex].endTime = endTime;
    }

    function setBatchAmountPerUser(uint64 amountPerUser, uint256 batchIndex)
        public
        onlyOwner
    {
        batchConfigs[batchIndex].amountPerUser = amountPerUser;
    }

    function setBatchForPublic(bool forPublic, uint256 batchIndex)
        public
        onlyOwner
    {
        batchConfigs[batchIndex].forPublic = forPublic;
    }

    function setBatchWhitelist(address[] calldata wls, uint256 batchIndex)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < wls.length; i++) {
            whitelist[batchIndex][wls[i]] = true;
        }
    }

    function setNoBatchWhitelist(address[] calldata wls) public onlyOwner {
        for (uint256 i = 0; i < wls.length; i++) {
            whitelistNoBatch[wls[i]] = true;
        }
    }

    /* --------------- mint --------------- */

    /**
     * @dev The TokenID of NFT minted in each batch is in a specific interval.
     * @dev While the batch is on public sale, the quantity will be unlimited.
     */
    function mint(uint64 amount, uint256 batchIndex)
        external
        payable
        callerIsUser
    {
        BatchConfig memory config = batchConfigs[batchIndex];
        uint64 mintedAmount = minted[_msgSender()][batchIndex];
        // forPublic
        if (!config.forPublic) {
            // white list
            require(whitelistNoBatch[_msgSender()], "Is not whitelist");
            // confirm amount
            if (mintedAmount + amount > config.amountPerUser)
                amount = config.amountPerUser - mintedAmount;
        }
        // startID and endID
        // eg: 0-10 and current id is 5, so the max amount is 10 + 1 - 5 = 6
        if (batchCurrentTokenID[batchIndex] + amount - 1 > config.endID) {
            amount = uint64(config.endID + 1 - batchCurrentTokenID[batchIndex]);
        }

        // time
        require(
            block.timestamp <= config.endTime &&
                block.timestamp >= config.startTime,
            "Wrong time"
        );
        require(msg.value >= config.price * amount, "Insufficient value");

        // mint
        for (uint64 i = 0; i < amount; i++) {
            _safeMint(_msgSender(), batchCurrentTokenID[batchIndex] + i);
        }
        batchCurrentTokenID[batchIndex] += amount;
        minted[_msgSender()][batchIndex] += amount;

        // refund
        if (msg.value > config.price * amount) {
            payable(_msgSender()).transfer(msg.value - config.price * amount);
        }
    }

    function ownerMint(
        uint256 startID,
        uint256 amount,
        address receiver
    ) public onlyOwner {
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenID = startID + i;
            _safeMint(receiver, tokenID);
        }
    }

    /* --------------- reveal --------------- */

    function setBlindBoxURI(string memory _blindBoxBaseURI) public onlyOwner {
        blindBoxBaseURI = _blindBoxBaseURI;
    }

    function setBaseURI(uint256 id, string memory baseURI_) public onlyOwner {
        if (stageIDs.length != 0) {
            require(
                stageIDs[stageIDs.length - 1] < id,
                "id should be self-incrementing"
            );
        }
        stageIDs.push(id);
        revealedBaseURI[id] = baseURI_;
        emit BlindBoxOpen(id);
    }

    function changeURI(uint256 id, string memory baseURI_) public onlyOwner {
        require(
            bytes(revealedBaseURI[id]).length != 0,
            "URI corresponding to id should not be empty"
        );
        revealedBaseURI[id] = baseURI_;
    }

    // binary search
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "token id is not exist.");
        string memory baseURI_;
        uint256 len = stageIDs.length;
        if (len == 0) {
            baseURI_ = blindBoxBaseURI;
        } else {
            uint256 left;
            uint256 right = len - 1;

            // (x,y]
            for (; left <= right; ) {
                uint256 midIndex = (left + right) / 2;
                if (midIndex == 0) {
                    if (tokenId <= stageIDs[0]) {
                        baseURI_ = revealedBaseURI[stageIDs[0]];
                        break;
                    } else if (len == 1) {
                        baseURI_ = blindBoxBaseURI;
                        break;
                    } else {
                        if (tokenId <= stageIDs[1]) {
                            baseURI_ = revealedBaseURI[stageIDs[1]];
                            break;
                        } else {
                            baseURI_ = blindBoxBaseURI;
                            break;
                        }
                    }
                }

                if (tokenId <= stageIDs[midIndex]) {
                    if (tokenId > stageIDs[midIndex - 1]) {
                        baseURI_ = revealedBaseURI[stageIDs[midIndex]];
                        break;
                    }
                    right = midIndex - 1;
                } else {
                    left = midIndex;
                    if (midIndex == right - 1) {
                        if (tokenId > stageIDs[right]) {
                            baseURI_ = blindBoxBaseURI;
                            break;
                        }
                        left = right;
                    }
                }
            }
        }

        return
            bytes(baseURI_).length > 0
                ? string(abi.encodePacked(baseURI_, toString(tokenId)))
                : string(abi.encodePacked(blindBoxBaseURI, toString(tokenId)));
    }

    function contractURI() public view returns (string memory) {
        return contractURI_;
    }

    function setContractURI(string memory uri_) public onlyOwner {
        contractURI_ = uri_;
    }

    /* --------------- ETH receiver --------------- */

    function setProject(address _project) public onlyOwner {
        project = _project;
    }

    function setCopyright(address _copyright) public onlyOwner {
        copyright = _copyright;
    }

    // copyrights 5% and project 95%
    function withdraw() public {
        require(
            msg.sender == copyright || msg.sender == project,
            "have no rights do this"
        );
        uint256 copyrights = (address(this).balance * 5) / 100;
        payable(project).transfer(address(this).balance - copyrights);
        payable(copyright).transfer(copyrights);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (from == address(0)) {
            totalSupply++;
            require(totalSupply <= maxSupply, "All nft sold out");
        }
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
}