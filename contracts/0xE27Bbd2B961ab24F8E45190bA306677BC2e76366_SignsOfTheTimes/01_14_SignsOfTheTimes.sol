// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// @title: Signs of the Times
// @creator: Brendan North
// @author: @pepperonick, with a massive amount of help from @andrewjiang

// Thank you to @jeffreyraefan for amazing site designs, @andrewjiang for the best guidance and review on the code,
// @yungwknd for many helpful pointers, and @sneakerdad_ for all the project tips and guidance.

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                         //
//                                                                                                                         //
//    .dP"Y8 88  dP""b8 88b 88 .dP"Y8      dP"Yb  888888     888888 88  88 888888     888888 88 8b    d8 888888 .dP"Y8     //
//    `Ybo." 88 dP   `" 88Yb88 `Ybo."     dP   Yb 88__         88   88  88 88__         88   88 88b  d88 88__   `Ybo."     //
//    o.`Y8b 88 Yb  "88 88 Y88 o.`Y8b     Yb   dP 88""         88   888888 88""         88   88 88YbdP88 88""   o.`Y8b     //
//    8bodP' 88  YboodP 88  Y8 8bodP'      YbodP  88           88   88  88 888888       88   88 88 YY 88 888888 8bodP'     //
//                                                                                                                         //
//                                                                                                                         //
//                                              We all start our journey                                                   //
//                                              a book of blank pages,                                                     //
//                                              quickly adding lines of ink                                                //
//                                              and slower, the lines of ages.                                             //
//                                                                                                                         //
//                                              Our time for story living                                                  //
//                                              will turn to story telling.                                                //
//                                              So put your pen to paper                                                   //
//                                              and live a life compelling.                                                //
//                                                                                                                         //
//                                              The youth may echo tales                                                   //
//                                              from the tapestry you’ve sewn.                                             //
//                                              Your impact on this earth                                                  //
//                                              is yours to etch in stone.                                                 //
//                                                                                                                         //
//                                              Life is an endless novel                                                   //
//                                              for those at the beginning                                                 //
//                                              and far too short a story                                                  //
//                                              by the time the light is dimming.                                          //
//                                                                                                                         //
//                                              - Brendan North                                                            //
//                                                                                                                         //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////vF

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SignsOfTheTimes is AdminControl, ICreatorExtensionTokenURI {
    enum ContractStatus {
        Paused,
        Premint,
        Open
    }

    enum TokenType {
        Beginning,
        End,
        Composite
    }

    using Strings for uint16;

    ContractStatus public contractStatus = ContractStatus.Paused;
    address private _creator;
    uint256 public _price;
    string public _beginningUri;
    string public _endUri;
    string public _compositeUri;
    uint16 public beginningCount = 0;
    uint16 public endCount = 0;
    uint16 private compositeCount = 0;
    bytes32 public _merkleRoot;

    struct TokenIdInfo {
        // 0 = Beginning; 1 = End; 2 = Composite
        TokenType tokenType;
        // stores a different token count, beginningCount or endCount or compositeCount, depending on the tokenType
        uint16 tokenTypeCount;
    }

    mapping(uint16 => TokenIdInfo) public tokenIdToTokenInfo;

    // Used to make sure user gets only 1 gas-only mint
    mapping(address => bool) public addressToGasOnlyMint;

    constructor(
        address creator,
        string memory beginningUri,
        string memory endUri,
        string memory compositeUri,
        uint256 price
    ) {
        _creator = creator;
        _beginningUri = beginningUri;
        _endUri = endUri;
        _compositeUri = compositeUri;
        _price = price;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier isPaused() {
        require(
            contractStatus == ContractStatus.Paused,
            "Contract cannot be in premint or open for minting"
        );
        _;
    }

    modifier isOpen() {
        require(
            contractStatus == ContractStatus.Open,
            "Contract must be open for minting"
        );
        _;
    }

    modifier isOpenOrPremint() {
        require(
            contractStatus == ContractStatus.Open ||
                contractStatus == ContractStatus.Premint,
            "Contract must be open for premint or public mint"
        );
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AdminControl, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            AdminControl.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function approvedForMintGasOnly(address account, bytes32[] calldata proof)
        public
        view
        returns (bool)
    {
        return
            MerkleProof.verify(proof, _merkleRoot, generateMerkleLeaf(account));
    }

    function canMintGasOnly(address account) public view returns (bool) {
        return !addressToGasOnlyMint[account];
    }

    function changeTokenInfo(
        uint16 tokenId,
        TokenType tokenType,
        uint256 count
    ) public adminRequired {
        tokenIdToTokenInfo[tokenId] = TokenIdInfo(tokenType, uint16(count));
    }

    function incrementBeginningOrEndCounts(bool beginningOrEnd, uint16 tokenId)
        private
    {
        if (beginningOrEnd) {
            beginningCount += 1;
        } else {
            endCount += 1;
        }

        tokenIdToTokenInfo[tokenId] = TokenIdInfo(
            beginningOrEnd ? TokenType.Beginning : TokenType.End,
            beginningOrEnd ? beginningCount : endCount
        );
    }

    function incrementCompositeCounts(uint16 tokenId) private {
        compositeCount += 1;

        tokenIdToTokenInfo[tokenId] = TokenIdInfo(
            TokenType.Composite,
            compositeCount
        );
    }

    function mintGasOnly(bool beginningOrEnd, bytes32[] calldata proof)
        public
        isOpenOrPremint
    {
        require(
            approvedForMintGasOnly(msg.sender, proof),
            "Not on the approved gas-only address list"
        );

        require(canMintGasOnly(msg.sender), "Can only mint 1 gas-free token");

        uint256 tokenId;
        tokenId = IERC721CreatorCore(_creator).mintExtension(msg.sender);
        addressToGasOnlyMint[msg.sender] = true;
        incrementBeginningOrEndCounts(beginningOrEnd, uint16(tokenId));
    }

    function mint(uint256 quantity, bool beginningOrEnd)
        public
        payable
        callerIsUser
        isOpen
    {
        require(msg.value == _price * quantity, "Wrong quantity of ETH sent");

        uint256[] memory tokenIds = IERC721CreatorCore(_creator)
            .mintExtensionBatch(msg.sender, uint16(quantity));

        for (uint16 i = 0; i < uint16(quantity); i++) {
            incrementBeginningOrEndCounts(beginningOrEnd, uint16(tokenIds[i]));
        }
    }

    function mintComposite(uint16[] calldata tokenIds) public isPaused {
        require(tokenIds.length == 2, "Requires 2 Beginning or End tokens");

        require(
            IERC721(_creator).ownerOf(tokenIds[0]) == msg.sender,
            "Tokens must be owned by message sender"
        );

        require(
            IERC721(_creator).ownerOf(tokenIds[1]) == msg.sender,
            "Tokens must be owned by message sender"
        );

        require(
            tokenIdToTokenInfo[tokenIds[0]].tokenType != TokenType.Composite,
            "Tokens must be a Beginning or End token"
        );

        require(
            tokenIdToTokenInfo[tokenIds[1]].tokenType != TokenType.Composite,
            "Tokens must be a Beginning or End token"
        );

        require(
            IERC721(_creator).getApproved(tokenIds[0]) == address(this),
            "Contract must be given approval to burn NFT"
        );

        require(
            IERC721(_creator).getApproved(tokenIds[1]) == address(this),
            "Contract must be given approval to burn NFT"
        );

        try
            IERC721(_creator).transferFrom(
                msg.sender,
                address(0xdEaD),
                tokenIds[0]
            )
        {} catch (bytes memory) {
            revert("Could not burn token");
        }

        try
            IERC721(_creator).transferFrom(
                msg.sender,
                address(0xdEaD),
                tokenIds[1]
            )
        {} catch (bytes memory) {
            revert("Could not burn token");
        }

        uint256 tokenId = IERC721CreatorCore(_creator).mintExtension(
            msg.sender
        );
        incrementCompositeCounts(uint16(tokenId));
    }

    function setImages(
        string memory beginningUri,
        string memory endUri,
        string memory compositeUri
    ) public adminRequired {
        _beginningUri = beginningUri;
        _endUri = endUri;
        _compositeUri = compositeUri;
    }

    function setContractStatus(ContractStatus status) public adminRequired {
        contractStatus = status;
    }

    function setPrice(uint256 price) public adminRequired {
        _price = price;
    }

    function generateMerkleLeaf(address account)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }

    function setMerkleRoot(bytes32 merkleRoot) public adminRequired {
        _merkleRoot = merkleRoot;
    }

    function withdraw(address to, uint256 amount) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance >= amount, "Cannot withdraw more than balance");

        address creator = payable(to);

        bool success;
        (success, ) = creator.call{value: amount}("");
        require(success, "Transaction Unsuccessful");
    }

    function getName(uint16 tokenId) private view returns (string memory) {
        string memory name;

        if (tokenIdToTokenInfo[tokenId].tokenType == TokenType.Beginning) {
            name = "The Beginning is Near";
        } else if (tokenIdToTokenInfo[tokenId].tokenType == TokenType.End) {
            name = "The End is Near";
        } else {
            name = "The Signs of the Times";
        }

        return
            string(
                abi.encodePacked(
                    name,
                    " #",
                    tokenIdToTokenInfo[tokenId].tokenTypeCount.toString()
                )
            );
    }

    function getImage(uint16 tokenId) private view returns (string memory) {
        string memory image;
        if (tokenIdToTokenInfo[tokenId].tokenType == TokenType.Beginning) {
            image = _beginningUri;
        } else if (tokenIdToTokenInfo[tokenId].tokenType == TokenType.End) {
            image = _endUri;
        } else {
            image = _compositeUri;
        }
        return
            string(
                abi.encodePacked(
                    '"image":"',
                    image,
                    '","image_url":"',
                    image,
                    '"'
                )
            );
    }

    function tokenURI(address creator, uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        require(creator == _creator, "Invalid creator proxy address");
        return
            string(
                abi.encodePacked(
                    "data:application/json;utf8,",
                    '{"name":"',
                    getName(uint16(tokenId)),
                    '",',
                    '"created_by":"Brendan North",',
                    '"description":"Signs of the Times\\n\\nArtist: Brendan North",',
                    getImage(uint16(tokenId)),
                    "}"
                )
            );
    }
}