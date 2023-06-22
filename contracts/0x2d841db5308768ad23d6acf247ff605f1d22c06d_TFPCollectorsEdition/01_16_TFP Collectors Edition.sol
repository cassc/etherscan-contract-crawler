// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/*
		 			                        ╔██████████▌
                                            ▓██████▀╨▓███▌
                                           ║████▀`    ╫███▄
                                            ╚╙└        ▀█▀`
                                                  Æ▀▓√  ╟▌
                                              å▓╦  `    `▒≤▌
                                                         ░⌐╙
                                                " #ª5δ  φ╝
                                                 `╚╓ε  φ▓ ▄▓██,
                                                   ⁿφ#╬╨ ╓▓███████▓▄
                                                    █▓▓██████████████▓                                     
                                                  ▄é████████████████████▄
                                                ▄████▄████████████████████,
                                              ,████████████████████████████
                                              ████████████████████████████▌
                                             ║████████████████████████████▌
                                             ╟█████████████████████████████
                                             ╟█████████████████████████████
                                             ║█████████████████████████████
                                             ╫█████████████████████████████µ
                                            ,██████████████████████████████▌
                                            ███████████████████████████████▌
                                           ]████████████████████████████████▄
                                           █████╟███████████████████████████
                                           ╚╙███████████████████████████████
                                           ░░╟███████████████████╙▀█████▌`
                                           ░░╫█████████████████╩    ,╚█▀
                                          ╠░╠█████████████████▒=  .,φ
                                          ░φ╟███████████████╩╙^ \φ▐█▌
                                         φ░╟██████████████╙    .╓███▌
                                        ╔≤▐██████████████     ]█████⌐
                                      ┌░; ╠██████████████    ▄█████
                                      '`▓Γ╟███████████████∩░▓█████▌
                                       \╙▓███████████████████████▌
                                         ╬██████████████████████
                                        ║██████████████████████▌
                                        ████████████████████████
                                        ███████████████████████▌
                                       ╟███████████████████████▌
                                       ████████████████████████▌
                                      ╟█████████████████████████
                                      ██████████████████████████
                                      ██████████████████████████
*/

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

pragma solidity ^0.8.0;


contract TFPCollectorsEdition is ERC1155, Ownable, Pausable, ERC1155Supply, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256;

    AggregatorV3Interface internal priceFeed;

    string public name       = "TFP Collectors Edition";
    string public symbol     = "TFP Collectors Edition";
    uint256 public maxSupply = 100;

    string public notRevealedURI;
    string public baseURI;        
    int public priceC;
    int public priceOldC;

    bool public revealed = false;

    constructor() ERC1155(baseURI) {
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); // mainnet
        pause();
    }

    function airDrop(address[] memory _address) external onlyOwner {
        uint mintIndex = totalSupply(0).add(1);
        require(mintIndex.add(_address.length) <= maxSupply, 'NFT: airdrop would exceed total supply');
        for(uint index = 0; index < _address.length; index++) {
            _mint(_address[index], 0, 1, "0x0");
        }
    }

    function setURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function chainLinkData() public {
        uint80 roundId;
        int priceOld;
        uint timeStamp;

        (roundId, priceC,, timeStamp,) = priceFeed.latestRoundData();

        uint timeStampOld = timeStamp;
        timeStamp -= 86400; // 1 day = 86400

        while (timeStampOld > timeStamp) {
            roundId -= 1;
            (,priceOld,, timeStampOld,) = priceFeed.getRoundData(roundId);
        }

        priceOldC = priceOld;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "ERC1155 uri: NONEXISTENT_TOKEN"); 
        if(!revealed){
            return notRevealedURI;
        }
        uint256 tokenId = checkDeviation();

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function checkDeviation() internal view returns(uint256) {
        uint80 roundId;
        int price;
        int priceOld;
        uint timeStamp;
        uint256 deviation;
        uint256 priceDifference;

        (roundId, price,, timeStamp,) = priceFeed.latestRoundData();

        uint timeStampOld = timeStamp;
        timeStamp -= 86400; // 1 day = 86400

        while (timeStampOld > timeStamp) {
            roundId -= 1;
            (,priceOld,, timeStampOld,) = priceFeed.getRoundData(roundId);
        }

        if(price == priceOld) {
            return 3; // -5%  <= x <  +5% 
        }

        if(price > priceOld) {
            priceDifference = uint256(price - priceOld);
            deviation = priceDifference.mul(100).div(uint256(priceOld));
            if(deviation >= 10) {
                return 1;  // x >= +10%
            }
            if(deviation >= 5 && deviation < 10) {
                return 2; // +5% <= x < +10%
            }
            return 3;     //  0% <= x < +5%  
        }

        priceDifference = uint256(priceOld - price);
        deviation = priceDifference.mul(100).div(uint256(priceOld));

        if(deviation >= 10) {
            return 5; // x <= -10%
        }
        if(deviation > 5 && deviation < 10) {
            return 4; // -10% < x < -5%
        }
        return 3;     // -5% <= x < 0%
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}