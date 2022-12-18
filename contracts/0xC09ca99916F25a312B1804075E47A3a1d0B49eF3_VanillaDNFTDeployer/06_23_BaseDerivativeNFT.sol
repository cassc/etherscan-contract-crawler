// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@spanning/contracts/token/ERC721/extensions/SpanningERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Base64.sol";
import "./interfaces/IVanillaDNFTDeployer.sol";

//import "../node_modules/hardhat/console.sol";

/*, IERC721Receiver*/
abstract contract BaseDerivativeNFT is SpanningERC721Enumerable {
    using Counters for Counters.Counter;

    address public factory;
    address public originNFTAddress;
    uint256 public originNFTTokenID;
    string public originNFTMediaUri;

    uint256 public totalMintType = 0;
    uint256 public maxDerivativeNFTNum = 100000000000;
    uint256[] public mintPrice;

    Counters.Counter _tokenCounter;

    event SaleEnabled(uint mintType);
    event SaleDisabled(uint mintType);
    event NewItem(uint256 indexed mintType, uint256 indexed tokenId);

    // set contract name, ticker, and delegate address
    constructor(string memory name,
                string memory ticker,
                address delegate_)
                SpanningERC721(name, ticker, delegate_)
    { }

    function getCounterValue() public view returns (uint256) {
        return _tokenCounter.current();
    }

    function _mintItem(uint256 mintType) internal returns (uint256) {
        require(msg.value >= mintPrice[mintType], "No enough fund");
        uint256 newTokenId = _tokenCounter.current();
        require(
            newTokenId < maxDerivativeNFTNum,
            "new tokenId reach the max limit, invalid"
        );
        _mint(spanningMsgSender(), newTokenId);
        _tokenCounter.increment();
        return newTokenId;
    }
}