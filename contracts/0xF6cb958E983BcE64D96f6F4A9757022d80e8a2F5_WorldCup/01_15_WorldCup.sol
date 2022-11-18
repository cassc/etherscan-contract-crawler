// SPDX-License-Identifier: GOFUCKYOURSELF
pragma solidity ^0.8.9;

//  /$$      /$$  /$$$$$$  /$$$$$$$  /$$       /$$$$$$$         /$$$$$$  /$$   /$$ /$$$$$$$   
// | $$  /$ | $$ /$$__  $$| $$__  $$| $$      | $$__  $$       /$$__  $$| $$  | $$| $$__  $$  
// | $$ /$$$| $$| $$  \ $$| $$  \ $$| $$      | $$  \ $$      | $$  \__/| $$  | $$| $$  \ $$  
// | $$/$$ $$ $$| $$  | $$| $$$$$$$/| $$      | $$  | $$      | $$      | $$  | $$| $$$$$$$/  
// | $$$$_  $$$$| $$  | $$| $$__  $$| $$      | $$  | $$      | $$      | $$  | $$| $$____/   
// | $$$/ \  $$$| $$  | $$| $$  \ $$| $$      | $$  | $$      | $$    $$| $$  | $$| $$        
// | $$/   \  $$|  $$$$$$/| $$  | $$| $$$$$$$$| $$$$$$$/      |  $$$$$$/|  $$$$$$/| $$        
// |__/     \__/ \______/ |__/  |__/|________/|_______/        \______/  \______/ |__/        
//      /$$$$$$  /$$   /$$        /$$$$$$  /$$   /$$  /$$$$$$  /$$$$$$ /$$   /$$
//     /$$__  $$| $$$ | $$       /$$__  $$| $$  | $$ /$$__  $$|_  $$_/| $$$ | $$
//    | $$  \ $$| $$$$| $$      | $$  \__/| $$  | $$| $$  \ $$  | $$  | $$$$| $$
//    | $$  | $$| $$ $$ $$      | $$      | $$$$$$$$| $$$$$$$$  | $$  | $$ $$ $$
//    | $$  | $$| $$  $$$$      | $$      | $$__  $$| $$__  $$  | $$  | $$  $$$$
//    | $$  | $$| $$\  $$$      | $$    $$| $$  | $$| $$  | $$  | $$  | $$\  $$$
//    |  $$$$$$/| $$ \  $$      |  $$$$$$/| $$  | $$| $$  | $$ /$$$$$$| $$ \  $$
//     \______/ |__/  \__/       \______/ |__/  |__/|__/  |__/|______/|__/  \__/
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./Serializer.sol";

contract WorldCup is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private counter; // token ids

    string baseURI;
    uint[] public results = new uint[](0);
    bool public saleIsActive = false;
    
    enum RoundType { GROUP, R16, QF, SF, FINAL, COMPLETE }
    
    // new mapping for redeemed NFTs
    mapping(uint => bool) public redeemedGrandPrize;
    mapping(uint => bool) public redeemedMiniPrize;
    // tokenId -> bracket
    // 1        -> [ 1,2,3,4,...]
    mapping(uint => uint[]) public brackets;
    // bracket -> count
    // "1,2,3" -> 5
    mapping(string => uint) public counts;
    // Store prices for minting each round
    mapping(RoundType => uint) public prices;
    // Keep track of prize pools for each round 
    mapping(RoundType => uint) public prizePools;
    // Miniprize for getting part of a group bracket correct 
    mapping(RoundType => uint) public multiples;

    event Mint(uint256 _tokenId);

    // 32 teams, idx 0..31
    string[] public teams = [ 
        "IRN", "ENG", "USA", "QAT",
        "ECU", "SN", "NL", "ARG",
        "KSA", "MEX", "POL", "FRA",
        "AUS", "DEN", "TUN", "ESP",
        "CRC", "GER", "JPN", "BEL",
        "CAN", "MAR", "CRO", "BRA",
        "SRB","SUI","CMR","POR",
        "GHA", "URU", "KOR", "WAL"
    ];

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(
        _name,
        _symbol
    ) {
        baseURI = _initBaseURI;

        // Initialize prices for each stage. 
        prices[RoundType.GROUP] = 0.005 ether;
        prices[RoundType.R16] = 0.008 ether;
        prices[RoundType.QF] = 0.4 ether;

        multiples[RoundType.FINAL] = 40;
        multiples[RoundType.SF] = 20;
        multiples[RoundType.QF] = 5;
        multiples[RoundType.R16] = 1;
        // multiples[RoundType.GROUP] = 0; // 0 by default lol
    }

    // Optional method, we might be able to get rid of this. 
    function _baseURI() internal view override virtual returns(string memory) {
        return baseURI;
    }

    // // Let's override the thirdweb methods here.
    // // we don't need baseuris for each token.
    // function tokenURI(uint _tokenId) public view virtual override returns(string memory) {
    //     return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    // }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function updatePrice(RoundType roundType, uint value) public onlyOwner {
        prices[roundType] = value;
    } 

    function updateMultiple(RoundType roundType, uint value) public onlyOwner {
        multiples[roundType] = value;
    } 

    function inferType(uint[] memory bracket) public pure returns(RoundType) {
        if(bracket.length == 31) {
            return RoundType.GROUP;
        } else if(bracket.length == 15) {
            return RoundType.R16;
        } else if(bracket.length == 7) {
            return RoundType.QF;
        } else {
            revert("Invalid bracket length"); 
        }
    }

    function mint(uint[] calldata _brackets, RoundType bracketType) public payable {
        require(saleIsActive, "Sale not active");

        // Ensure that users cannot mint prior bracket (e.g group after round 16 are in)
        require(bracketType >= currentRound(), "Cannot mint after results are in");

        uint count;
        uint len;

        if(bracketType == RoundType.GROUP) {
            len = 31;
            count = _brackets.length / 31;
        } else if(bracketType == RoundType.R16) {
            len = 15;
            count = _brackets.length / 15;
        } else { // RoundType.QF
            len = 7;
            count = _brackets.length / 7;
        }

        require((prices[bracketType] * count) <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < count; i++) {
            uint tokenId = counter.current();
            counter.increment();
            _safeMint(msg.sender, tokenId);

            uint[] memory bracket = _brackets[i*len:(i+1)*len];
            string memory list = Serializer.toStr(bracket);
            
            brackets[tokenId] = bracket;
            counts[list] += 1;
            prizePools[bracketType] += msg.value;
            emit Mint(tokenId);
        }
    }

    function setResults(uint[] memory _results) public onlyOwner {
        require(_results.length == 31, "results are not correct length");
        results = _results;
    }

    // Need to represent null values until all results are in
    // Can't do 0 because it's a valid index
    // Can't do -1 because bracket is uint
    // Fuck it -> 69 represents null value in array 8====D 

    // GROUP:   []                                                   
    // R16:     [69,69,69,69,69,69,69,69,69,69,69,69,69,69,69][################]
    // QF:      [69,69,69,69,69,69,69][########################]
    // SF:      [69,69,69][############################]
    // FINAL:   [69][##############################]
    // COMPLETE:[][###############################]
    function currentRound() public view returns(RoundType) {
        if(results.length == 0) {
            return RoundType.GROUP;
        }
        if(results[15 - 1] == 69) {
            return RoundType.R16;
        }
        if(results[7 - 1] == 69) {
            return RoundType.QF;
        }
        if(results[3 - 1] == 69) {
            return RoundType.SF;
        }
        if(results[1 - 1] == 69) {
            return RoundType.FINAL;
        }
        return RoundType.COMPLETE;
    }

    // Whether the bracket is a grand prize winner
    function grandPrize(uint[] memory bracket) public view returns(bool) {
        // Check for grand prize: if the bracket matches the results  
        for(uint i = 0; i < bracket.length; i++) {
            if(results[i] != bracket[i]) {  
                return false;
            }
        }
        return true;
    }   

    // [0]     [1,2]  [3..6]  [7..14]  [15..30]  
    // Winner  FINAL   SF      QF       R16
    // Payout  40x     20x     5x       0x
    // Returns amount in wei
    function miniPrize(uint[] memory bracket) public view returns(uint) {
        for (uint i = bracket.length-1; i >= 0; i--) {
            if(results[i] != bracket[i]) {
                // everything up to FINAL is right (winner is wrong).
                if(i == 0) {
                    return multiples[RoundType.FINAL];
                } 
                // everything up to SF is right (final and winner are wrong).
                if(i < 3) {
                    return multiples[RoundType.SF];
                } 
                // everything up to QF is right (final, winner, and SF are wrong).
                else if(i < 7) {
                    return multiples[RoundType.QF];
                }
                // everything up to R16 is right (final, winner, SF, and QF are wrong).
                else if(i < 15) {
                    return multiples[RoundType.R16];
                }
                // nothings right 
                if(i >= 15) {
                    return 0;    
                }
            }
        }
        return 0;
    }

    function payout(uint tokenId) public {
        // TODO: require(msg.sender == ownerOf(tokenId), "Only token owner can call this method");

        uint[] memory bracket = brackets[tokenId];
        RoundType bracketType = inferType(bracket);

        require(currentRound() > bracketType, "We don't have any results yet");

        uint pool = prizePools[bracketType];
        uint winners = counts[Serializer.toStr(bracket)];

        uint amt = 0;
        bool isMiniPrize = false;

        // Grand prize is shared across all winners in the pool
        if(grandPrize(bracket)) {
            require(redeemedGrandPrize[tokenId] == false, "Already withdrew winnings");
            amt = pool / winners;
        } 
        // Only group brackets are eligible for mini prizes
        else if(bracketType == RoundType.GROUP) {
            require(redeemedMiniPrize[tokenId] == false, "Already withdrew winnings");
            uint mintPrice = prices[RoundType.GROUP];
            amt = miniPrize(bracket) * mintPrice;
            isMiniPrize = true;
        }
   
        require(amt > 0, "This bracket is not a winning bracket");
        // TODO: Check that balance of contract is more than the expected payout 

        payable(ownerOf(tokenId)).transfer(amt);
        if(isMiniPrize) {
            // Pay out multiples before distributing grand prize pool
            prizePools[bracketType] -= amt;
            redeemedMiniPrize[tokenId] = true;
        } else {
            // Grand prize does not deduct from pool
            redeemedGrandPrize[tokenId] = true;
        }
    }

    function deposit(RoundType bracketType) public payable {
        prizePools[bracketType] += msg.value;
    }

    function moveFunds(RoundType from, RoundType to, uint amt) public onlyOwner {
        require(prizePools[from] >= amt, "Prize pool does not have enough funds");
        prizePools[from] -= amt;
        prizePools[to] += amt;
    }
}