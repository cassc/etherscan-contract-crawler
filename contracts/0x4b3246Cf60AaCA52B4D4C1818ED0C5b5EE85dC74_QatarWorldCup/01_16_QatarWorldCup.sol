// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721/ERC721.sol";
import "./ERC721/ERC721Enumerable.sol";
import "./libraries/SafeMath.sol";
import "./common/Ownable.sol";
import "./Interface/IRandom.sol";
import "hardhat/console.sol";

contract QatarWorldCup is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    uint256 constant MAX_SUPPLY = 32000;
    uint256 constant MAX_SUPPLY_GOLD = 3200;
    uint256 constant MAX_SUPPLY_SILVER = 9600;
    uint256 constant MAX_SUPPLY_BRONZE = 19200;
    uint256 constant MAX_RANDOM_RANK_GOLD = 10000;
    uint256 constant MAX_RANDOM_RANK_SILVER = 40000;
    uint256 constant RANDOM_RANK_GOLD_AFTER_SILVER_FULL = 14286;
    uint256 constant RANDOM_RANK_GOLD_AFTER_BRONZE_FULL = 25000;
    uint256 constant RANDOM_RANK_SILVER_AFTER_GOLD_FULL = 33333;
    uint256 constant RANDOM_RANK_SILVER_AFTER_BRONZE_FULL = 75000;
    uint256 constant RANDOM_RANK_BRONZE_AFTER_GOLD_FULL = 85714;
    uint256 constant RANDOM_RANK_BRONZE_AFTER_SILVER_FULL = 66666;
    uint256 constant GOLD_TEAM_FULL = 100;
    uint256 constant SILVER_TEAM_FULL = 400;
    uint256 constant BRONZE_TEAM_FULL = 1000;
    uint256[] teamCreating = [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32
    ];

    struct NFTProperty{
        //teamId
        uint256 teams;
        //rank (Gold: 1, Silver: 2, Bronze: 3)
        uint256 rank;
        //index of image
        uint256 imageIndex;
    }

    string _baseTokenURI;
    uint256 public currentTokenId;
    address public random;

    uint256 public  mintPrice = 5000000000000000; //0.0005 ETH

    //mappings amount NFT to rank
    mapping(uint256 => uint256) private _amountNFTByRank;

    //mappings tokenId to teamId
    mapping(uint256 => uint256) private _teams;

    //mappings rounds shuffle teams
    mapping(uint256 => uint256[]) private _rounds;

    // mapping tokenId to imageIndex (_teams -> _rank -> _imageIndex)
    mapping(uint256 => mapping(uint256 => uint256))private _imageIndex;

    //mapping tokenId to nft property
    mapping(uint256 => NFTProperty) private _nftProperty;

    uint256 public maxQWCPurchase = 5;

    bool public saleIsActive = false;

    // address develop operation investment
    address public operationFund;

    // airdrop for winner
    address public airdropPool;

    //rate of transfer fund to airdrop
    uint256 public rateAirdrop = 70000;

    //rate of transfer fund to operation fund
    uint256 public rateOperation = 30000;

    uint256 public denominator = 100000;

    string public baseExtension = ".json";

    constructor() ERC721("QATAR WORLDCUP", "QWC") {
        //init image index for each rank
        for(uint256 i = 0; i < teamCreating.length; i++){
            _imageIndex[teamCreating[i]][1] = 0;
            _imageIndex[teamCreating[i]][2] = 100;
            _imageIndex[teamCreating[i]][3] = 400;
        }
    }

    /**
     * @dev mint new tokenID to address "_to", if there is a secret token URI
     * then setting for the "_tokenSecretURI"
     *
     * "currentTokenId" is autoincreament
     *
     */

    function _mint721Token(address _to) internal{
        /* 
        NOTE: Logic for picking team:
            1. QATAR
            2. Netherland
            3. Ecuador
            4. Senegal
            5. England
            6. Wales 
            7. USA
            8. Iran 
            9. Poland 
            10. Argentina 
            11. Mexico 
            12. Saudi Arabia
            13. Denmark
            14. France 
            15. Tunisia
            16. Autralia
            17. Germany
            18. Spain
            19. Costa-Rica
            20. Japan
            21. Belgium
            22. Croatia
            23. Canada
            24. Morocco
            25. Serbia
            26. Switzerland
            27. Brazil
            28. Cameroon
            29. Portugal
            30. Uruguay
            31. Ghana
            32. South Korea
        */

        // handle the times roll teams
        uint256 rollTeamRound = currentTokenId / teamCreating.length;
        uint256 rollTeamIndex = currentTokenId % teamCreating.length;
        if (rollTeamIndex == 0) {
            _rounds[rollTeamRound] = _shuffle_team(teamCreating);
        }
        _teams[currentTokenId] = _rounds[rollTeamRound][rollTeamIndex];

        // random rank
        uint256 _seed = IRandom(random).random();
        if (
            _amountNFTByRank[1] < MAX_SUPPLY_GOLD &&
            _amountNFTByRank[2] < MAX_SUPPLY_SILVER &&
            _amountNFTByRank[3] < MAX_SUPPLY_BRONZE
        ) {
            if (_seed < MAX_RANDOM_RANK_GOLD) {
                _roll_team(rollTeamRound, GOLD_TEAM_FULL, 1);
            } else if (_seed < MAX_RANDOM_RANK_SILVER) {
                _roll_team(rollTeamRound, SILVER_TEAM_FULL, 2);
            } else {
                _roll_team(rollTeamRound, BRONZE_TEAM_FULL, 3);
            }
        } else if (_amountNFTByRank[1] == MAX_SUPPLY_GOLD) {
            if (
                _amountNFTByRank[2] < MAX_SUPPLY_SILVER &&
                _amountNFTByRank[3] < MAX_SUPPLY_BRONZE
            ) {
                if (_seed < RANDOM_RANK_SILVER_AFTER_GOLD_FULL) {
                    _roll_team(rollTeamRound, SILVER_TEAM_FULL, 2);
                } else {
                    _roll_team(rollTeamRound, BRONZE_TEAM_FULL, 3);
                }
            } else if (_amountNFTByRank[2] == MAX_SUPPLY_SILVER) {
                _roll_team(rollTeamRound, BRONZE_TEAM_FULL, 3);
            } else if (_amountNFTByRank[3] == MAX_SUPPLY_BRONZE) {
                _roll_team(rollTeamRound, SILVER_TEAM_FULL, 2);
            }
        } else if (_amountNFTByRank[2] == MAX_SUPPLY_SILVER) {
            if (
                _amountNFTByRank[1] < MAX_SUPPLY_GOLD &&
                _amountNFTByRank[3] < MAX_SUPPLY_BRONZE
            ) {
                if (_seed < RANDOM_RANK_GOLD_AFTER_SILVER_FULL) {
                    _roll_team(rollTeamRound, GOLD_TEAM_FULL, 1);
                } else {
                    _roll_team(rollTeamRound, BRONZE_TEAM_FULL, 3);
                }
            } else if (_amountNFTByRank[1] == MAX_SUPPLY_GOLD) {
                _roll_team(rollTeamRound, BRONZE_TEAM_FULL, 3);
            } else if (_amountNFTByRank[3] == MAX_SUPPLY_BRONZE) {
                _roll_team(rollTeamRound, GOLD_TEAM_FULL, 1);
            }
        } else if (_amountNFTByRank[3] == MAX_SUPPLY_BRONZE) {
            if (
                _amountNFTByRank[1] < MAX_SUPPLY_GOLD &&
                _amountNFTByRank[2] < MAX_SUPPLY_SILVER
            ) {
                if (_seed < RANDOM_RANK_GOLD_AFTER_BRONZE_FULL) {
                    _roll_team(rollTeamRound, GOLD_TEAM_FULL, 1);
                } else {
                    _roll_team(rollTeamRound, SILVER_TEAM_FULL, 2);
                }
            } else if (_amountNFTByRank[1] == MAX_SUPPLY_GOLD) {
                _roll_team(rollTeamRound, SILVER_TEAM_FULL, 2);
            } else if (_amountNFTByRank[2] == MAX_SUPPLY_SILVER) {
                _roll_team(rollTeamRound, GOLD_TEAM_FULL, 1);
            }
        }

        //set nft property
        _nftProperty[currentTokenId].teams = _teams[currentTokenId];
        _nftProperty[currentTokenId].imageIndex = _imageIndex[_teams[currentTokenId]][_nftProperty[currentTokenId].rank ];

        _safeMint(_to, currentTokenId);
        currentTokenId++;
    }

    function mintBatch721Token(uint256 _numberOfTokens) public payable{
        require(saleIsActive, "Sale must be active to mint QWC");
        require(_numberOfTokens <= maxQWCPurchase, "Mint more than allowed at a time");
        require(totalSupply().add(_numberOfTokens) <= MAX_SUPPLY, "Purchase would exceed max supply of Apes");
        require(mintPrice.mul(_numberOfTokens) <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < _numberOfTokens; i++) {
            _mint721Token(_msgSender());
        }
        uint256 airdropFund = (msg.value * rateAirdrop)/denominator;
        uint256 operationAssetsFund = (msg.value * rateOperation)/denominator;

        // transfer fund to Airdrop Pool
        payable(airdropPool).transfer(airdropFund);
        // transfer fund to 
        payable(operationFund).transfer(operationAssetsFund);
    }

    function burn(uint256 tokenId) external {
        require(
            _msgSender() == ownerOf(tokenId),
            "Only the TokenId holder can burn this tokenId"
        );
        _burn(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }


    //* RENDER TOKEN URI */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, Strings.toString(_nftProperty[tokenId].teams), 
                                                "/",Strings.toString(_nftProperty[tokenId].rank), 
                                                "/",Strings.toString(_nftProperty[tokenId].imageIndex), baseExtension))
                : "";
    }

    /**
     * @dev show all TokenId  of  the `holder`.
     */

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function getNFTProperty(uint256 _tokenId) public view returns (NFTProperty memory){
        return _nftProperty[_tokenId];
    }

    function setRandom(address _random) public onlyOwner {
        random = _random;
    }

    function setOperationFund(address _operationFund) public onlyOwner {
        operationFund = _operationFund;
    }

    function setAirdropPool(address _airdropPool) public onlyOwner {
        airdropPool = _airdropPool;
    }

    function setMintPrice(uint256 _newMintPrice) public onlyOwner {
        mintPrice = _newMintPrice;
    }

    function setMaxQWCPurchase(uint256 _newQWCPurchase) public onlyOwner {
        maxQWCPurchase = _newQWCPurchase;
    }

    function setFundRate(uint256 _newRateAirdrop, uint256 _newRateOperation) public onlyOwner {
        rateAirdrop = _newRateAirdrop;
        rateOperation = _newRateOperation;
    }
    
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }
    /*
    * Pause sale if active, make active if paused
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function _shuffle_team(uint256[] memory _team_creatings)
        internal
        view
        returns (uint256[] memory)
    {
        for (uint256 i = 0; i < _team_creatings.length; i++) {
            uint256 n = i +
                (uint256(keccak256(abi.encodePacked(block.timestamp))) %
                    (_team_creatings.length - i));
            uint256 temp = _team_creatings[n];
            _team_creatings[n] = _team_creatings[i];
            _team_creatings[i] = temp;
        }
        return _team_creatings;
    }

    function _roll_team(
        uint256 rollTeamRound,
        uint256 threshHold,
        uint256 rank
    ) internal {
        //set rank in nft property
        _nftProperty[currentTokenId].rank = rank;
        if (
            _imageIndex[_teams[currentTokenId]][_nftProperty[currentTokenId].rank ] < threshHold
        ) {
            _imageIndex[_teams[currentTokenId]][_nftProperty[currentTokenId].rank ]++;
            _amountNFTByRank[rank]++;
        }   else if (_imageIndex[_teams[currentTokenId]][_nftProperty[currentTokenId].rank ] == threshHold) {
            for(uint8 i= 0; i< teamCreating.length; i++){
                _teams[currentTokenId] = _rounds[rollTeamRound][i];
                if (_imageIndex[_teams[currentTokenId]][_nftProperty[currentTokenId].rank ] < threshHold) {
                    _imageIndex[_teams[currentTokenId]][_nftProperty[currentTokenId].rank ]++;
                    _amountNFTByRank[rank]++;
                    break;
                }
            }
        }
    }
}