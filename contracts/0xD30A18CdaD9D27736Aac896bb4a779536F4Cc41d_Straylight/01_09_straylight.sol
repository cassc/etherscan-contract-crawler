//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./metadata.sol";
import "./EnumerableMate.sol";

//                           STRAYLIGHT PROTOCOL v.01
//
//                                .         .
//                                  ., ... .,
//                                  \%%&%%&./
//                         ,,.      /@&&%&&&\     ,,
//                            *,   (##%&&%##)  .*.
//                              (,  (#%%%%.)   %,
//                               ,% (#(##(%.(/
//                                 %((#%%%##*
//                 ..**,*/***///*,..,#%%%%*..,*\\\***\*,**..
//                                   /%#%%
//                              /###(/%&%/(##%(,
//                           ,/    (%###%%&%,   **
//                         .#.    *@&%###%%&)     \\
//                        /       *&&%###%&@#       *.
//                      ,*         (%#%###%#?)       .*.
//                                 ./%%###%%#,
//                                  .,(((##,.
//
//

/// @title Straylight
/// @notice The main point of interaction for Straylight - relies on Gamboard, Metadata, Turmitesv4 and EnumerableMate
/// @author @brachlandberlin / plsdlr.net
/// @dev facilitates minting, moving of individual turmites, reprogramming and even external logic of turmites and overwrites tokenUri()

contract Straylight is EnumerableMate, Metadata {
    event TurmiteReprogramm(uint256 indexed tokenId, bytes12 indexed newrule);
    event TurmiteMint(uint256 indexed tokenId, bytes12 indexed rule, uint256 boardId);

    uint256 public boardcounter = 0;
    uint256 private turmitecounter = 0;
    uint256 public maxnumbturmites;
    uint256[4] startx = [36, 72, 72, 108];
    uint256[4] starty = [72, 36, 108, 72];
    address minterContract;
    address haecceityContract;
    address admin;
    mapping(uint256 => bool) public haecceity;

    constructor(
        address _minterContract,
        uint256 maxAmount,
        string memory network
    ) Metadata(network) EnumerableMate("Straylight", "STR") {
        minterContract = _minterContract;
        maxnumbturmites = maxAmount;
        admin = msg.sender;
    }

    /// @dev public Mint function should only be called from external Minter Contract
    /// @param mintTo the address the token should be minted to
    /// @param rule the inital rule the turmite is minted with
    /// @param moves the inital number of rules the turmite is minted with
    function publicmint(
        address mintTo,
        bytes12 rule,
        uint256 moves
    ) external {
        require(turmitecounter < maxnumbturmites, "MINT_OVER");
        require(validateNewRule(rule) == true, "INVALID_RULE");
        require(msg.sender == minterContract, "ONLY_MINTABLE_FROM_MINT_CONTRACT");

        boardcounter = (turmitecounter / 4) + 1;
        uint256 startposx = startx[turmitecounter % 4];
        uint256 startposy = starty[turmitecounter % 4];
        _addTokenToOwnerEnumeration(mintTo, turmitecounter);
        _addTokenToAllTokensEnumeration(turmitecounter);
        _mint(mintTo, turmitecounter);
        createTurmite(turmitecounter, uint8(startposx), uint8(startposy), 1, uint8(boardcounter), rule);
        emit TurmiteMint(turmitecounter, rule, boardcounter);
        if (moves > 0) {
            calculateTurmiteMove(turmitecounter, moves);
        }
        haecceity[turmitecounter] = false;
        turmitecounter = turmitecounter + 1;
    }

    /// @dev overwrites the tokenURI function from ERC721 Solmate
    /// @param id the id of the NFT
    function tokenURI(uint256 id) public view override returns (string memory) {
        return
            fullMetadata(
                id,
                turmites[id].boardnumber,
                turmites[id].rule,
                turmites[id].state,
                turmites[id].turposx,
                turmites[id].turposy,
                turmites[id].orientation
            );
    }

    /// @dev helper Function to render board without turmites
    /// @param number Board number
    function renderBoard(uint8 number) public view returns (string memory) {
        return getSvg(number, 0, 0, false);
    }

    function moveTurmite(uint256[2] calldata idmoves) external {
        require(msg.sender == ownerOf(idmoves[0]), "NOT_AUTHORIZED");
        if (idmoves[1] > 0) {
            calculateTurmiteMove(idmoves[0], idmoves[1]);
        }
    }

    /// @dev function to validate that an new input from user is in the "gramma" of the rules
    /// @param rule a bytes12 rule - to understand the specific gramma of rules take a look at turmitev4 contract
    function validateNewRule(bytes12 rule) public pure returns (bool allowed) {
        //Normal Format Example: 0xff0801ff0201ff0000000001
        //we dont test against direction bc direction never writes
        //bool firstbit = (rule[0] == 0xFF || rule[0] == 0x00);
        //bool secondbit = (rule[3] == 0xFF || rule[3] == 0x00);
        bool colorfieldbit = ((rule[0] == 0xFF || rule[0] == 0x00) &&
            (rule[3] == 0xFF || rule[3] == 0x00) &&
            (rule[6] == 0xFF || rule[6] == 0x00) &&
            (rule[9] == 0xFF || rule[9] == 0x00));
        bool statebit = ((rule[2] == 0x01 || rule[2] == 0x00) &&
            (rule[5] == 0x01 || rule[5] == 0x00) &&
            (rule[8] == 0x01 || rule[8] == 0x00) &&
            (rule[11] == 0x01 || rule[11] == 0x00));
        return bool(statebit && colorfieldbit);
    }

    /// @notice WE EXPECT THAT YOU KNOW WHAT YOU ARE DOING BEFORE CALLING THIS FUNCTION MANUALY
    /// @notice PLEASE CONSULT THE DOCUMENTATION
    /// @dev function to reprogramm your turmite | DANGERZONE | if you don't use the interface consult the documentation before wasting gas
    /// @param id ID of the turmite
    /// @param rule a bytes12 rule - to understand the specific gramma of rules take a look at turmitev4 contract
    function reprogrammTurmite(uint256 id, bytes12 rule) external {
        require(msg.sender == ownerOf(id), "NOT_AUTHORIZED");
        require(validateNewRule(rule) == true, "INVALID_RULE");
        turmites[id].rule = rule;
        emit TurmiteReprogramm(id, rule);
    }

    /// @dev function for the admin to set external HA Contract
    /// @param _haecceityContract address of contract
    function setHaecceityContract(address _haecceityContract) external {
        require(msg.sender == admin, "NOT_AUTHORIZED");
        haecceityContract = _haecceityContract;
    }

    /// @dev get the position(x and y values) and the state of the current field for a turmite (all handy encoded)
    /// @param id the id of the token / turmite
    function getPosField(uint256 id) public view returns (bytes memory encodedData) {
        bytes32 sour;
        uint8 _x;
        uint8 _y;
        bytes memory data = new bytes(32);
        turmite storage dataTurmite = turmites[id];
        assembly {
            sour := sload(dataTurmite.slot)
            _x := and(sour, 0xFF)
            _y := and(shr(8, sour), 0xFF)
        }
        bytes1 stateOfField = getByte(_x, _y, (id / 4) + 1);
        assembly {
            mstore8(add(data, 32), _x)
            mstore8(add(data, 33), _y)
            mstore(add(data, 34), stateOfField)
        }
        return (data);
    }

    //  _   _   _____          _   _  _____ ______ _____   __________  _   _ ______   _   _
    // | | | | |  __ \   /\   | \ | |/ ____|  ____|  __ \ |___  / __ \| \ | |  ____| | | | |
    // | | | | | |  | | /  \  |  \| | |  __| |__  | |__) |   / / |  | |  \| | |__    | | | |
    // | | | | | |  | |/ /\ \ | . ` | | |_ |  __| |  _  /   / /| |  | | . ` |  __|   | | | |
    // |_| |_| | |__| / ____ \| |\  | |__| | |____| | \ \  / /_| |__| | |\  | |____  |_| |_|
    // (_) (_) |_____/_/    \_\_| \_|\_____|______|_|  \_\/_____\____/|_| \_|______| (_) (_)

    /// @notice WE EXPECT THAT YOU KNOW WHAT YOU ARE DOING BEFORE CALLING THIS FUNCTION
    /// @notice PLEASE CONSULT THE DOCUMENTATION
    /// @dev should be called by user to unlock external control
    /// @param id the id of the token / turmite the user what to hand logic control over to external smart contract
    function setHaecceityMode(uint256 id) external {
        require(haecceityContract != address(0), "CONTRACT_IS_ZEROADDRESS");
        require(msg.sender == ownerOf(id), "NOT_AUTHORIZED");
        haecceity[id] = true;
    }

    /// @dev internal deocde function
    ///  @param data data to decode
    function decode(bytes memory data)
        internal
        pure
        returns (
            uint8 x,
            uint8 y,
            bytes1 field
        )
    {
        assembly {
            x := mload(add(data, 1))
            y := mload(add(data, 2))
            field := mload(add(data, 34))
        }
    }

    /// @notice WE EXPECT THAT YOU KNOW WHAT YOU ARE DOING BEFORE CALLING THIS FUNCTION
    /// @notice PLEASE CONSULT THE DOCUMENTATION
    /// @dev function should be called by external haecceity Contract which allows external control of turmites by user deployed smart contracts
    /// @dev this function sets the field
    /// @param id the id of the turmite
    /// @param data the encoded data of the next step
    function setByteHaMode(uint256 id, bytes calldata data) external {
        require(haecceityContract != address(0), "CONTRACT_IS_ZEROADDRESS");
        require(haecceity[id] == true, "CONTRACT_NOT_INITALIZED_BY_NFT_OWNER");
        require(msg.sender == haecceityContract, "CALL_ONLY_FROM_HACONTRACT");
        (uint8 x, uint8 y, bytes1 stateOfField) = decode(data);
        setByte(x, y, stateOfField, turmites[id].boardnumber);
    }

    /// @notice WE EXPECT THAT YOU KNOW WHAT YOU ARE DOING BEFORE CALLING THIS FUNCTION
    /// @notice PLEASE CONSULT THE DOCUMENTATION
    /// @dev function should be called by external haecceity Contract which allows external control of turmites by user deployed smart contracts
    /// @dev this function sets the end position after moving
    /// @param id the id of the turmite
    /// @param data the encoded data of the position
    function setPositionHaMode(uint256 id, bytes calldata data) external {
        require(haecceityContract != address(0), "CONTRACT_IS_ZEROADDRESS");
        require(haecceity[id] == true, "CONTRACT_NOT_INITALIZED_BY_NFT_OWNER");
        require(msg.sender == haecceityContract, "CALL_ONLY_FROM_HACONTRACT");
        (uint8 x, uint8 y, ) = decode(data);
        turmites[id].turposx = x;
        turmites[id].turposy = y;
    }

    /// @dev overwriting transfer functions to add extension from here

    /// @notice after every transfer we reset the permission for external control
    /// @dev resets permission after every transfer
    function _transferResetHAMode(uint256 tokenId) internal {
        if (haecceity[tokenId] == true) {
            haecceity[tokenId] = false;
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transferResetHAMode(tokenId);
        _removeTokenFromOwnerEnumeration(from, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transferResetHAMode(tokenId);
        _removeTokenFromOwnerEnumeration(from, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) public virtual override {
        _transferResetHAMode(tokenId);
        _removeTokenFromOwnerEnumeration(from, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
        super.safeTransferFrom(from, to, tokenId, data);
    }
}