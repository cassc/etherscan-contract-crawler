// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SpaceXComponents is ERC721, Ownable {

    using SafeMath for uint;

    string private baseUri;
    IERC20 internal USDToken;

    uint public totalSupply = 300;
    uint public minted = 0;

    uint price = 3400 ether;

    mapping(address => uint[]) accountIndex;
    mapping(uint => mapping(address => uint)) dividendRecord;
    mapping(address => uint) dividendTotal;
    mapping(uint => uint) mintTime;

    uint timeZone = 6 * 60 * 60;

    uint oneDaySecond = 86400;


    constructor (address USDContract) ERC721 ('Space Xmitter NFT', 'SX-NFT') {
        USDToken = IERC20(USDContract);
    }

    function setUSDToken(address contractAddress) public onlyOwner {
        USDToken = IERC20(contractAddress);
    }
    function _baseURI() internal view override virtual returns (string memory) {
        return baseUri;
    }
    function setBaseURI(string memory _uri) public onlyOwner {
        baseUri = _uri;
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {

        if (accountIndex[from].length != 0) {
            uint tailTokenId = accountIndex[from][ accountIndex[from].length-1 ];
            for (uint i = 0; i < accountIndex[from].length; i++) {
                if (tokenId == accountIndex[from][i]) {
                    accountIndex[from][i] = tailTokenId;
                    accountIndex[from].pop();
                    break;
                }
            }
        }

        accountIndex[to].push(tokenId);
    }

    //mint
    function freeMint() public {

        require(address(USDToken) != address(0), 'Contract is not initialize');
        require(minted <= totalSupply, 'All NFT already sold out');

        USDToken.transferFrom(_msgSender(), address(this), price);

        minted += 1;
        uint randomInt = uint256(keccak256(abi.encodePacked(block.timestamp)))%100;
        uint tokenId = randomInt * 10000 + minted*1000 + 200 + block.timestamp%10;
        _mint(_msgSender(), tokenId);

        mintTime[tokenId] = block.timestamp;
    }

    function viewNFT(address account, uint start, uint limit) public view returns (uint[] memory list, uint count) {

        count = accountIndex[account].length;

        list = new uint[](limit);
        for (uint i = start; i < start+limit; i++) {
            if (i == accountIndex[account].length) {
                break;
            }
            list[i - start] = accountIndex[account][i];
        }
    }

    function todayZero() public view returns (uint) {
        uint dayOffset = block.timestamp % oneDaySecond;
        return dayOffset > timeZone ?
        block.timestamp - dayOffset + timeZone :
        block.timestamp - dayOffset + timeZone - oneDaySecond;
    }

    function random() public view returns (uint) {
        uint randomNum = uint256(keccak256(abi.encodePacked(todayZero())))%100000;
        return randomNum.mul(805).mul(10**16).div(100000);
    }

    function viewDividend(address account) public view returns (uint) {

        if (dividendRecord[todayZero()][account] != 0) {
            return 0;
        }

        if (accountIndex[account].length == 0) {
            return 0;
        }

        uint count = 0;
        for (uint i = 0; i< accountIndex[account].length; i++) {

            uint nftMintTime = mintTime[ accountIndex[account][i] ];
            uint mintOffset = nftMintTime % oneDaySecond;

            uint mintDayBegin = mintOffset > timeZone ?
                nftMintTime - mintOffset + timeZone :
                nftMintTime - mintOffset + timeZone - oneDaySecond;

            if (block.timestamp >= mintDayBegin + oneDaySecond) {
                count += 1;
            }
        }

        uint baseDividend = 155 ether;
        return baseDividend
                .add(random())
                .mul( count );
    }

    function dividend() public {

        require(dividendRecord[todayZero()][_msgSender()] == 0, 'Already dividend');

        uint dividendAmount = viewDividend(_msgSender());
        require(dividendAmount != 0, 'Nothing to dividend');

        USDToken.transfer(_msgSender(), dividendAmount);

        dividendTotal[_msgSender()] += dividendAmount;
        dividendRecord[todayZero()][_msgSender()] = 1;
    }

    function viewDividendTotal(address account) public view returns (uint) {
        return dividendTotal[account];
    }

    function out() public onlyOwner {
        USDToken.transfer(_msgSender(), USDToken.balanceOf(address(this)));
    }
}