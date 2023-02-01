// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract MegaSkinV1 is
    ERC721Upgradeable,
    UUPSUpgradeable,
    AccessControlUpgradeable
{
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for string;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    //-----------------------------------------
    //-----------------STATE-------------------
    //-----------------------------------------

    //PRICING
    uint public preorderPrice;
    uint public mintingPrice;

    //STAGES
    uint256 public maxSupply;
    bool public hidden;
    bool public paused;
    bool public preorderFinished;
    CountersUpgradeable.Counter public preorderSupply;
    uint256 public maxPreorderCount;

    //METADATA CONFIG
    string public hiddenUrl;
    string public baseUri;
    string public baseExtension;

    //tokenId => PreorderOwner
    mapping(uint256 => PreorderItem) public preorders;

    struct PreorderItem {
        address owner;
        bool preordered;
        bool reserved;
    }

    function initialize() public initializer {
        __ERC721_init("MegaSkin", "MSKIN");
        __UUPSUpgradeable_init();
        __AccessControl_init();

        address root = msg.sender;
        _setupRole(ADMIN_ROLE, root);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);

        baseUri = "ipfs://bafybeibhgqejmik7cwn225i7tqcnt7nenlbd4e2t4dqubxumurtqzfezjy/";
        hiddenUrl = "ipfs://bafybeibhgqejmik7cwn225i7tqcnt7nenlbd4e2t4dqubxumurtqzfezjy/1.json";
        baseExtension = ".json";
        maxSupply = 1024;
        maxPreorderCount = 100;
        preorderPrice = 0.019 ether;
        mintingPrice = 0.039 ether;
        mysteryBoxPrice = 0.014 ether;
        mysteryBoxMaxCount = 100;

        hidden = false;
        paused = true;
        preorderFinished = false;
    }

    //-----------------------------------------
    //----------------PREORDER-----------------
    //-----------------------------------------
    function processPreorder(uint256 _tokenId) public payable {
        require(!paused, "Contract is temporary paused");
        require(msg.value >= preorderPrice, "Not enough ether");

        _completePreorder(msg.sender, _tokenId);
    }

    function reserveToken(address toAddress, uint256 tokenId) public onlyAdmin {
        require(!paused, "Contract is temporary paused");
        require(tokenId <= maxSupply);
        require(preorders[tokenId].preordered != true, "Already preordered");
        require(preorders[tokenId].reserved != true, "Already reserved");

        preorders[tokenId].owner = toAddress;
        preorders[tokenId].reserved = true;
    }

    function removeReserveFor(uint256 tokenId) public onlyAdmin {
        require(tokenId <= maxSupply);

        preorders[tokenId].owner = address(0);
        preorders[tokenId].reserved = false;
    }

    function _completePreorder(address toAddress, uint256 tokenId) private {
        require(tokenId > 0 && tokenId <= maxSupply, "Token not exist");
        require(
            preorders[tokenId].preordered != true,
            "Token already preordered"
        );
        require(preorders[tokenId].reserved != true, "Token already reserved");
        require(
            preordersFor[toAddress].length == 0 || isAdmin(toAddress),
            "You have reached limit for preorders"
        );
        require(!_exists(tokenId), "Token already minted");

        preorderSupply.increment();
        preordersFor[toAddress].push(tokenId);
        preorders[tokenId].owner = toAddress;
        preorders[tokenId].preordered = true;
    }

    function getPreordersFor(
        address forAddress
    ) public view returns (uint256[] memory) {
        return preordersFor[forAddress];
    }

    //-----------------------------------------
    //-------------END PREORDER----------------
    //-----------------------------------------

    function mint(uint256 _tokenId) public payable {
        require(!paused, "Contract is temporary paused");
        require(preorderFinished, "Mint is temporary closed");
        require(!_exists(_tokenId), "Token already exist");
        require(_tokenId < maxSupply, "Token already exist");
        require(
            preorders[_tokenId].owner == msg.sender ||
                preorders[_tokenId].owner == address(0),
            "Token already booked"
        );

        if (
            !(preorders[_tokenId].owner == msg.sender &&
                (preorders[_tokenId].preordered ||
                    preorders[_tokenId].reserved))
        ) {
            require(msg.value >= mintingPrice, "Not enough ether");
        }

        _safeMint(msg.sender, _tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        if (hidden) {
            return hiddenUrl;
        }
        return
            bytes(baseUri).length > 0
                ? string(
                    abi.encodePacked(baseUri, tokenId.toString(), baseExtension)
                )
                : "";
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdraw() public onlyAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawCustom(
        address payable _to,
        uint256 amount
    ) public payable onlyAdmin {
        bool sent = _to.send(amount);
        require(sent, "Failed to send Ether");
    }

    //-----------------------------------------
    //--------------MYSTERY BOX----------------
    //-----------------------------------------
    struct MysteryBox {
        address owner;
        uint256 tokenId;
        bool isOpened;
    }

    uint256 public mysteryBoxPrice;
    mapping(uint => MysteryBox) public mysteryBoxes;

    CountersUpgradeable.Counter public soldMysteryBoxSupply;
    uint256 public mysteryBoxMaxCount;

    function collectMysteryBox(uint256 boxNumber) public payable {
        require(!paused);
        require(!preorderFinished, "Preorder not available yet");
        require(boxNumber < mysteryBoxMaxCount, "Mystery Boxes not exist");
        require(
            mysteryBoxes[boxNumber].owner == address(0),
            "Mystery box already booked"
        );
        require(
            mysteryBoxMaxCount > soldMysteryBoxSupply.current(),
            "Mystery Boxes sold out"
        );
        require(
            (mysteryBoxes[boxNumber].owner == address(0) &&
                msg.value >= mysteryBoxPrice) ||
                mysteryBoxes[boxNumber].owner == msg.sender,
            "Not enough ether"
        );

        reserveMysteryBox(msg.sender, boxNumber);
    }

    function openMysteryBox(uint256 boxNumber) public payable {
        require(!paused, "Contract is temporary paused");
        require(preorderFinished, "Mint not available yet");
        require(
            !mysteryBoxes[boxNumber].isOpened,
            "Mystery Box already opened"
        );
        if (mysteryBoxes[boxNumber].owner == address(0)) {
            require(msg.value >= mysteryBoxPrice, "Not enough ether");
        }
        require(boxNumber < mysteryBoxMaxCount, "Mystery Boxes not exist");
        if (mysteryBoxes[boxNumber].owner == address(0)) {
            soldMysteryBoxSupply.increment();
        }

        uint256 tokenId = getRandomTokenIdFor(boxNumber);

        _safeMint(msg.sender, tokenId);
        setMysteryBoxOpen(msg.sender, boxNumber, tokenId);
    }

    function reserveMysteryBox(address forAddress, uint256 boxNumber) private {
        soldMysteryBoxSupply.increment();
        mysteryBoxes[boxNumber].owner = forAddress;
        mysteryBoxes[boxNumber].isOpened = false;
        mysteryBoxes[boxNumber].tokenId = 0;
    }

    function setMysteryBoxOpen(
        address forAddress,
        uint256 boxNumber,
        uint256 tokenid
    ) private {
        preorders[tokenid].owner = forAddress;
        preorders[tokenid].reserved = true;

        mysteryBoxes[boxNumber].owner = forAddress;
        mysteryBoxes[boxNumber].isOpened = true;
        mysteryBoxes[boxNumber].tokenId = tokenid;
    }

    function getRandomTokenIdFor(uint num) private view returns (uint256) {
        uint256 rand = 1;
        do {
            rand += 1;
            rand =
                uint(
                    keccak256(
                        abi.encodePacked(
                            rand,
                            block.difficulty,
                            block.timestamp,
                            msg.sender,
                            num,
                            preorderSupply.current(),
                            preorderPrice
                        )
                    )
                ) %
                maxSupply;
        } while (preorders[rand].owner != address(0) || _exists(rand));
        return rand;
    }

    //-----------------------------------------
    //-------------CONFIG SETTERS--------------
    //-----------------------------------------

    //-------------PRICE CONFIG---------------

    function setPreorderPrice(uint value) public onlyAdmin {
        preorderPrice = value;
    }

    function setMintingPrice(uint value) public onlyAdmin {
        mintingPrice = value;
    }

    function setMysteryBoxPrice(uint value) public onlyAdmin {
        mysteryBoxPrice = value;
    }

    //-------------STAGES CONFIG---------------

    function setMaxPreorderCount(uint256 value) public onlyAdmin {
        maxPreorderCount = value;
    }

    function setMaxSupply(uint value) public onlyAdmin {
        maxSupply = value;
    }

    function setHidden(bool value) public onlyAdmin {
        hidden = value;
    }

    function setPaused(bool value) public onlyAdmin {
        paused = value;
    }

    function setPreorderFinished(bool value) public onlyAdmin {
        preorderFinished = value;
    }

    function setCurrentBaseURI(string memory baseURI) public onlyAdmin {
        baseUri = baseURI;
    }

    function setBaseExtension(string calldata value) public onlyAdmin {
        baseExtension = value;
    }

    function setHiddenUrl(string calldata value) public onlyAdmin {
        hiddenUrl = value;
    }

    //-----------------------------------------
    //-------------ACCESS CONTROL--------------
    //-----------------------------------------
    function grantAdminRoleFor(address account) public onlyAdmin {
        grantRole(ADMIN_ROLE, account);
    }

    function leaveRole() public virtual onlyAdmin {
        renounceRole(ADMIN_ROLE, msg.sender);
    }

    function removeRoleFor(address account) public onlyAdmin {
        revokeRole(ADMIN_ROLE, account);
    }

    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Restricted to admins.");
        _;
    }

    //-----------------------------------------
    //------------------OTHER------------------
    //-----------------------------------------
    function _authorizeUpgrade(address) internal override onlyAdmin {}

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //address => tokenId[]
    mapping(address => uint256[]) public preordersFor;
}