// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BASKETBALLNFT is ERC721AUpgradeable, OwnableUpgradeable {
    enum SetIndex {
        ModelChangeSeries,
        StarCard
    }

    enum RarityIndex {
        Legendary,
        Epic,
        Rare,
        Common
    }

    enum SeriesIndex {
        Basketball_frame_A,
        Basketball_frame_B,
        Bitcoin,
        Mini_Uniform,
        Anime_characters,
        Card_Box,
        Science_fiction,
        Dollars,
        Virtual_Sneakers,
        Figure_box,
        Monkeys,
        Switching_Card,
        Science_Card,
        Gold_Card,
        Card_Circles,
        Card_Red,
        Card_White
    }

    struct Attributes {
        uint8 set;
        uint8 rarity;
        uint32 player;
        uint8 series;
    }

    struct AirdropUser {
        Attributes[] attributes;
        uint256 amount;
        uint256[] tokenIDs;
        address receiver;
    }

    struct AirdropKOL {
        Attributes[] attributes;
        uint256 amount;
        address receiver;
    }

    uint256 public maxSupply;
    // vault
    address public vault;
    address public vaultForDrop;
    // airdrop
    mapping(uint256 => bool) public claimed;

    // reveal
    string public blindBoxBaseURI;
    uint256[] public stageIDs;
    mapping(uint256 => string) public revealedBaseURI;

    string[] public Set;
    string[] public Rarity;
    string[] public Series;
    uint32[] public Player;

    uint32[] public playerList;

    mapping(uint256 => Attributes) public attribute;
    // player => rarity => set => series => number
    mapping(uint32 => mapping(uint8 => mapping(uint8 => mapping(uint8 => uint32))))
        public cardNumber;

    function initialize(
        string memory name,
        string memory symbol,
        address _vault,
        address _vaultForDrop
    ) public initializerERC721A initializer {
        __ERC721A_init(name, symbol);
        __Ownable_init();

        maxSupply = 10000;
        Set = ["Model Change", "Star Card"];
        Rarity = ["Legendary", "Epic", "Rare", "Common"];
        Series = [
            "Basketball_frame_A",
            "Basketball_frame_B",
            "Bitcoin",
            "Mini_Uniform",
            "Anime_characters",
            "Card_Box",
            "Science_fiction",
            "Dollars",
            "Virtual_Sneakers",
            "Figure_box",
            "Monkeys",
            "Switching_Card",
            "Science_Card",
            "Gold_Card",
            "Card_Circles",
            "Card_Red",
            "Card_White"
        ];
        // 210, 212, 213, 214, 215, 217, 2123, 2124 active players 
        // 211, 218, 2110, 2128 transfer player (Can only be used for airdrops)
        Player = [210, 212, 213, 214, 215, 217, 2123, 2124, 211, 218, 2110, 2128];
        // 214 does not belong to this exchange reserve collection
        playerList = [210, 212, 213, 215, 217, 2123, 2124];

        vault = _vault;
        vaultForDrop = _vaultForDrop;

        for (uint256 i = 0; i < playerList.length; i++) {
            cardNumber[playerList[i]][uint8(RarityIndex.Rare)][
                uint8(SetIndex.StarCard)
            ][uint8(SeriesIndex.Gold_Card)] = 133;
        }
    }

    event BlindBoxOpen(uint256 tokenId);
    event ChangeBaseURI(uint256 tokenId);
    event Exchange(
        uint256[] payTokenIDs,
        uint256 payDropTokenID,
        uint256 newTokenID,
        address sender
    );
    event MintBatch(uint256 firstTokenID, uint256 amount, address sender);

    /// @notice The user uses any 3 Star Card Series and common NFTs and 1 transfer player NFT to replace any Rare NFT.
    /// @dev A player will be randomly selected from the Player as the NFT player attribute.
    /// @dev If a player's NFT is exhausted, the player will be skipped.
    /// @dev Approve is not required because there is no external call, msg.sender is owner of NFT.
    /// @param payTokenIDs 3 common NFTs's tokenIDs
    /// @param payDropTokenID transfer player NFT's tokenID
    function exchange(uint256[] calldata payTokenIDs, uint256 payDropTokenID)
        public
    {
        uint256 length = payTokenIDs.length;
        require(length == 3, "param length error");
        require(playerList.length != 0, "has no card");
        // Transfer Player NFT Verification
        uint32 player = attribute[payDropTokenID].player;
        require(
            (player == 211 ||
                player == 218 ||
                player == 2110 ||
                player == 2128) &&
                attribute[payDropTokenID].set == uint8(SetIndex.StarCard) &&
                attribute[payDropTokenID].rarity == uint8(RarityIndex.Common),
            "drop error"
        );
        for (uint256 i = 0; i < length; i++) {
            // must be common and StarCard NFT
            require(
                attribute[payTokenIDs[i]].set == uint8(SetIndex.StarCard) &&
                    attribute[payTokenIDs[i]].rarity ==
                    uint8(RarityIndex.Common),
                "pay token error"
            );
            transferFrom(msg.sender, vault, payTokenIDs[i]);
        }
        transferFrom(msg.sender, vaultForDrop, payDropTokenID);

        // Pick a player at random
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    blockhash(block.number - 1),
                    payDropTokenID,
                    msg.sender
                )
            )
        );
        uint256 index = randomNumber % playerList.length;
        uint32 plyer = playerList[index];

        // Determine if the player's backup NFT has been exhausted.
        // The number of players' spare NFTs is reduced by one.
        cardNumber[plyer][uint8(RarityIndex.Rare)][uint8(SetIndex.StarCard)][uint8(SeriesIndex.Gold_Card)]--;
        if (
            cardNumber[plyer][uint8(RarityIndex.Rare)][
                uint8(SetIndex.StarCard)
            ][uint8(SeriesIndex.Gold_Card)] == 0
        ) {
            playerList[index] = playerList[playerList.length - 1];
            playerList.pop();
        }

        uint256 tokenID = totalSupply();
        attribute[tokenID] = Attributes({
            set: uint8(SetIndex.StarCard),
            rarity: uint8(RarityIndex.Rare),
            player: plyer,
            series: uint8(SeriesIndex.Gold_Card)
        });

        // mint
        _safeMint(msg.sender, 1);
        emit Exchange(payTokenIDs, payDropTokenID, tokenID, msg.sender);
    }

    /* --------------- airdrop --------------- */

    /// @notice According to the NFT data held by the users, the project party subjectively distributes the airdrop to user. Users must hold NFTs that have not been airdropped.
    /// @dev The smaller index in attributes, the smaller the minted NFT's tokenID corresponding to the element.
    /// @param dropData Airdrop data.
    function airdropToUser(AirdropUser[] calldata dropData) public onlyOwner {
        require(dropData.length <= 50, "to much drop");
        for (uint256 i; i < dropData.length; i++) {
            AirdropUser memory data = dropData[i];
            require(data.attributes.length == data.amount, "param error");
            require(data.tokenIDs.length != 0, "tokenIDs error");
            for (uint256 j; j < data.tokenIDs.length; j++) {
                require(
                    ownerOf(data.tokenIDs[j]) == data.receiver,
                    "receiver is not owner of the tokenID"
                );
                require(!claimed[data.tokenIDs[j]], "tokenID has claimed");
                claimed[data.tokenIDs[j]] = true;
            }
            uint256 totalSupply_ = totalSupply();
            for (uint256 j; j < data.amount; j++) {
                attribute[totalSupply_ + j] = data.attributes[j];
            }
            _safeMint(data.receiver, data.amount);
        }
    }

    /// @notice The project party subjectively distributes the airdrop to KOL.
    /// @dev The average number of airdrops per KOL does not exceed 5 because of the block gas limit.
    /// @param dropData Airdrop data.
    function airdropToKOL(AirdropKOL[] calldata dropData) public onlyOwner {
        require(dropData.length <= 50, "to much drop");
        for (uint256 i; i < dropData.length; i++) {
            AirdropKOL memory data = dropData[i];
            require(data.attributes.length == data.amount, "param error");

            uint256 totalSupply_ = totalSupply();
            for (uint256 j; j < data.amount; j++) {
                attribute[totalSupply_ + j] = data.attributes[j];
            }
            _safeMint(data.receiver, data.amount);
        }
    }

    /* --------------- binance --------------- */

    /// @notice The project party mint batch NFTs to binance.
    /// @param amount The number of NFTs minted.
    /// @param receiver Binance's address for receiving NFTs.
    function mintBatch(uint256 amount, address receiver) public onlyOwner {
        uint256 firstTokenID = totalSupply();
        _safeMint(receiver, amount);
        emit MintBatch(firstTokenID, amount, receiver);
    }

    /* --------------- nft card parameters --------------- */

    /// @notice The owner writes the number of NFTs of each player in all subdivision branches.
    /// @dev The length of the two parameters must be the same and cannot exceed 200.
    /// @param attrs List of various types of NFT attributes in business scenarios.
    /// @param numbers The number of NFTs in this branche.
    function setNFTNumber(
        Attributes[] calldata attrs,
        uint32[] calldata numbers
    ) public onlyOwner {
        require(numbers.length <= 200, "too much params");
        require(attrs.length == numbers.length, "params length error");

        for (uint256 i; i < attrs.length; i++) {
            uint32 player_ = attrs[i].player;
            uint8 rarity_ = attrs[i].rarity;
            uint8 set_ = attrs[i].set;
            uint8 serie_ = attrs[i].series;
            uint32 number_ = numbers[i];

            cardNumber[player_][rarity_][set_][serie_] = number_;
        }
    }

    /// @notice The owner reset playerList for new exchange rule.
    /// @param playerList_ New playerList value.
    function setPlayerList(uint32[] calldata playerList_) public onlyOwner {
        playerList = playerList_;
    }

    /* --------------- reveal --------------- */

    /// @notice When opening the blind box, the owner sets the properties of the NFT.
    /// @dev The length of the two parameters must be the same and cannot exceed 200.
    /// @param tokenIDs The TokenID of the NFT to be set.
    /// @param attributes The attributes of the NFT to be set.
    function setAttributes(
        uint256[] calldata tokenIDs,
        Attributes[] calldata attributes
    ) public onlyOwner {
        require(tokenIDs.length <= 200, "too much params");
        require(tokenIDs.length == attributes.length, "params length error");
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            attribute[tokenIDs[i]] = attributes[i];
        }
    }

    /// @notice Get the properties of the NFT and display it in a human readable form.
    /// @param tokenID The tokenID of the NFT to be queried.
    function getTokenAttributes(uint256 tokenID)
        public
        view
        returns (
            string memory set,
            string memory rarity,
            string memory series,
            uint32 player
        )
    {
        Attributes memory attr = attribute[tokenID];
        require(attr.player != 0, "this tokenID has not attribute");
        return (
            Set[attr.set],
            Rarity[attr.rarity],
            Series[attr.series],
            attr.player
        );
    }

    /// @notice The owner set blindbox baseURI.
    function setBlindBoxURI(string memory _blindBoxBaseURI) public onlyOwner {
        blindBoxBaseURI = _blindBoxBaseURI;
    }

    /// @notice Open blind boxes in batches. Each time it is called, (${id last call}, id] baseURI is set.
    /// @param id The maximum tokenID currently opened.
    /// @param baseURI_ The baseURI of the latest set interval.
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

    /// @notice Used to modify the wrong parameters passed in by setBaseURI.
    function changeURI(uint256 id, string memory baseURI_) public onlyOwner {
        require(
            bytes(revealedBaseURI[id]).length != 0,
            "URI corresponding to id should not be empty"
        );
        revealedBaseURI[id] = baseURI_;
        emit ChangeBaseURI(id);
    }

    /// @notice Query the URI of NFT metadata, which conforms to the ERC72 protocol.
    /// @dev Because the baseURI of each interval where the tokenID is located is different, the binary search method is used here to improve the query efficiency.
    /// @dev Except for 0, tokenIDs are divided in the way of opening and closing before, eg: (x,y].
    /// @param tokenId The tokenID of the NFT to be queried.
    /// @return The URI of the NFT to be queried.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "token id is not exist.");
        string memory baseURI_;
        uint256 len = stageIDs.length;
        // binary search
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
                ? string(abi.encodePacked(baseURI_, _toString(tokenId)))
                : string(abi.encodePacked(blindBoxBaseURI, _toString(tokenId)));
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (from == address(0)) {
            require(totalSupply() + quantity <= maxSupply, "exceeded maximum supply");
        }
    }

    /* --------------- modifiers --------------- */
}