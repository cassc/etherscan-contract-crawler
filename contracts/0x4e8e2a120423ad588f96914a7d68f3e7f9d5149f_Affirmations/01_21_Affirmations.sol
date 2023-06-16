// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                     //
//                            OIIIIIIIIII77                                                            //
//                         IIIIIIIII???IIIII77                   NI777777777777$                       //
//                      IIIII?????????????I?7III             O77777777IIIIII77777777                   //
//                     7IIIIIIIII7I?????????III7I          I7777IIIIIIIIIIIIIIIII77777$                //
//                         N8ZIIIIIIII7I??I??II7II       7777IIIIIIIIIIIIIIIIIIIIIIII7777              //
//                                   I77IIIIIIII77I     777IIIIIIIIIIIIIIIIIIIIIIIII777777D            //
//                                       7777IIII77    777IIIIIIIIII7777777777III777777777$7           //
//                      O7III7I77I777      7I7III777  777IIIIII777777777777777777777777777$$$          //
//                 IIIIIIIIIIIIII77IIII77I  N77III77 777IIII77777$              N$77$77$7777$$D        //
//              ?7IIII???????????????III7II77 77II77777II7777I                       8$$$7$77$$N       //
//            IIII???????????????IIIIIIIIII77777IIII7II7777                              $$$$$$$       //
//          N7II??????????????II7III7I7777777IIIIIIIII777                                   7$$$$      //
//         $II???????????I7IIIIIIIIZO888Z7I7777IIIIIII77777777777777777777D                   O$$$     //
//        $II?????????I7IIII8            777777IIIIIIII777IIIIIIIII777777777$$7                 Z$     //     
//       8II???????IIII?          $7777777777IIIIIIIIIIIIIIIIIIIIIIIIII777777$$77$Z                    //
//       7I?????III77         I7777777IIIIIII77777II777777IIIIIIIIIII7777777777777$$$                  //
//      III???IIII        OI7777IIIIIIIIIII777I$77I777$7777777IIIIIII77777777777777$$$7                //
//      7I??IIII        I7I7IIIIIIIIIIIII777Z 777II777$$$  7$777777777777777777777777$$$8              //
//     IIIIII7       OII7I?IIIIIIIIIII7777  $777II777777$$D    777777777777777777777777$$7             //
//     IIIII        7IIIIIIIIIIIIIIII777   777IIII77$$777$$N      $77$777777777777777777$$$            //
//     III        I77IIIIIIIIIIIIII777    777IIII777$$7777$$        8$77$7777777777777777$$7           //
//     I$        II7?IIIIIIIIIIII777$    777IIIII77 $$$777$$$          $$$$777777777777777$$           //
//              77IIIIIIIIIIIIII777     777IIIII777  $$$777$$$           77$$77777777777777$$          //
//             7IIIIIIIIIIIIII777      777IIIIII778  D$$7777$$$            7$$$777777777777$$O         //
//            II7IIIIIIIIIIII777      777IIIIIII77    $$$$$$$$$D             $$$77777777777$$$         //
//           DI7IIIIIIIIIII7778      N77IIIIIII777    8$$$$$$$$$              N$$$7777777777$$         //
//           77IIIIIIIIIII777        777IIIIIII777     $$$7I77$$$               Z$$$77777777$$N        //
//           77IIIIIIIIII777        877IIIIIIII77Z     Z$$$$$$$$$                 $$$7777777$$$        //
//          NI7IIIIIIIII777         777IIIIIIII77       Z$$$$$$$$$                 8$$$$777$$$$        //
//          877IIIIIIII777          77IIIIIIIII77       Z$$$$$$$$$                   $$$777$$$$        //
//          O77IIIIIII77O          O77IIIIIIIII77       Z$$$$$$$$$$                   $$$7$$$$$        //
//          D77IIIIII777           777IIIIIIIII77        $$IIIII$$Z                    8Z$$7$$Z        //
//           77IIIII777            777IIIIIIII777        $$$$7$$$$ZZ                     $$$$$         //
//           77IIII777             777IIIIIII7777        $Z$$$$$$$ZZ                      $$$$         //
//           777II777              7777IIIII777$7Z       ZZZ$$$$$$ZZZ                      $$$         //
//           D77II77               N777III77777777       DZZ$$$$$$$ZZ                       $$         //
//            77I777                77III77777777$        ZZ$$$$II$ZZ                                  //
//            O7777                 7777777777777$        ZZ$$$$IZ$ZZZ                                 //
//             7778                  77777777777$$        ZZZZZZ$ZZZZZ                                 //
//              77                   Z7777777777$77       ZZZZZZZZZZZZ                                 //
//              Z$                    77777777777$$       ZZZZZZZZZZZZ8                                //
//                                     7777777777$$       ZZZIII$ZZZZZZ                                //
//                                      777777777$$$      ZZZZZZZZZZZZZ                                //
//                                        $$$77777$$      ZZZZZZZZZZZZZ                                //
//                                         N7$$$77$$$     ZZZZZZZZZ$ZZZ                                //
//                                            7$$$$$$     ZZZZZZIIIZZZZN                               //
//                                                O$$$    OZZZZZZZZZZZZ8                               //
//                                                        OZZZZZZZZZZZOO                               //
//                                                        OZZZZZZZZZZOOO                               //
//                                                        OOOZZZZZZZZOOO                               //
//                                                        OOOIIIOOZZOOOO                               //
//                                                        OOOOOOOOOOOOOO                               //
//                                                        OOOOOOOOOOOOOO                               //
//                                                        OOOOOOOOOOOOOO                               //
//                                                       NOOOOOOOIIOOOOO                               //
//                                                       OOOOOOOOOOOOOO8                               //
//                                                       OOOOOOOOOOOOOOD                               //
//                                                       OOOOOOOOOOOOOO                                //
//                                                        OOOOOOOOOOOO8                                //
//                                                            D8O8D                                    //
//  nft affirmations                                                                                                   //
/////////////////////////////////////////////////////////////////////////////////////////////////////////                                                                                                     
contract Affirmations is ERC721Enumerable, Ownable, VRFConsumerBase {

    using SafeMath for uint256;
    using Strings for uint256;

    string public _baseTokenURI;

    bytes32 internal keyHash;
    uint256 internal fee;

    bool public saleStarted = false;
    bool public whitelistStarted = false;
    bool public eight88Started = false;
    bool public mintStartIndexDrawn = false;

    ERC1155 eight88contract = ERC1155(0x36d30B3b85255473D27dd0F7fD8F35e36a9d6F06);

    uint256 public mintStartIndex;
    uint256 private price = 77700000000000000; // 0.0777 ETH

    uint256 public totalAffirmations = 10000;
    uint256 public maxAffirmationsPerMint = 7;

    string public provenanceHash = ""; // example

    event randomStartingIndexDrawn(uint256 mintStartIndex);

    address vrfCoordinator = 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952;
    address linkToken = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    uint linkFee = 2 * 10 ** 18;

    constructor() ERC721("NFT Affirmations", "AMINT") VRFConsumerBase(vrfCoordinator, linkToken) {
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = linkFee;
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) override view public returns (string memory) {
        uint256 chosenURI = (tokenId + mintStartIndex) % totalAffirmations;
        return bytes(_baseTokenURI).length > 0 ? string(abi.encodePacked(_baseTokenURI, chosenURI.toString(), ".json")) : "";
    }
    
    function startSale() public onlyOwner {
        require(mintStartIndexDrawn, "Must draw random number.");
        saleStarted = true;
    }
    
    function pauseSale() public onlyOwner {
        saleStarted = false;
    }

    function startWhitelist() public onlyOwner {
        require(mintStartIndexDrawn, "Must draw random number.");
        whitelistStarted = true;
    }
    
    function stopWhitelist() public onlyOwner {
        whitelistStarted = false;
    }

    function start888() public onlyOwner {
        require(mintStartIndexDrawn, "Must draw random number.");
        eight88Started = true;
    }
    
    function stop888() public onlyOwner {
        eight88Started = false;
    }

    function mintGifts(uint256[] memory numberOfMints, address[] memory _mintTo) public onlyOwner {
        require(mintStartIndexDrawn, "Sale hasn't started");

        for (uint i = 0; i < numberOfMints.length; i++) {
            require(totalSupply().add(numberOfMints[i]) <= totalAffirmations, 'Not enough affirmations left');

            for(uint j = 0; j < numberOfMints[i]; j++) {
                uint mintNum = totalSupply() + 1;
                if (mintNum < totalAffirmations) {
                    _safeMint(_mintTo[i], mintNum);
                }
            }
        }
    }

    function manifest(uint256 numberOfMints) public payable {
        require(mintStartIndexDrawn, "Sale hasn't started");

        uint256 newMintCount = totalSupply().add(numberOfMints);
        uint256 myBalance = balanceOf(msg.sender).add(numberOfMints);

        if (whitelistStarted) {
            require(newMintCount <= 1111, "Whitelist period has sold out");
            require(myBalance <= 1, 'Maximum 1 affirmation during presale');
        } else if (eight88Started) {
            require(eight88contract.balanceOf(msg.sender, 888) > 0);
            require(newMintCount <= (1111 + 888), "Whitelist period has sold out");
            require(myBalance <= 1, 'Maximum 1 affirmation during presale');
        }
        else require(saleStarted, "Sale hasn't started");

        require(numberOfMints > 0 && numberOfMints <= maxAffirmationsPerMint, 'Can mint up to 7 affirmations at a time');
        require(myBalance <= 33, 'Maximum 33 affirmations per wallet');
        require(newMintCount <= totalAffirmations, 'Not enough affirmations left');
        require(msg.value == price.mul(numberOfMints), 'Need 0.0777 ETH per affirmation');

        for (uint i = 0; i < numberOfMints; i++) {
            uint mintNum = totalSupply() + 1;
            if (mintNum < totalAffirmations) {
                _safeMint(msg.sender, mintNum);
            }
        }
    }
   
    /** 
     * Requests randomness from Chainlink
     */
    function getRandomStartIndex() public onlyOwner returns (bytes32 requestId) {
        require(!mintStartIndexDrawn , "RNG ALREADY DRAWN");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        mintStartIndex = randomness % totalAffirmations;
        if (mintStartIndex == 0) {
            mintStartIndex = 1;
        }

        emit randomStartingIndexDrawn(mintStartIndex);

        mintStartIndexDrawn = true;
    }

    function withdrawLink() external onlyOwner {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    }

    function withdraw(address _to, uint amount) public onlyOwner {
        payable(_to).call{value:amount, gas:200000}("");
    }

    // COMMENT THIS FUNCTION ON PRODUCTION. ONLY FOR TESTING
    
    function testStartIndex(uint256 index) public onlyOwner {
        mintStartIndex = index;
        mintStartIndexDrawn = true;
    }

    function changeMaxNumber(uint256 totalAff) public onlyOwner {
        totalAffirmations = totalAff;
    }
    
}