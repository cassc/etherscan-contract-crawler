// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract EthBcnTickets is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    string _baseTokenURI;
    string public baseExtension = ".json";

    uint256 public totalTicketsMinted;

    IERC20 private tokenUSDC;

    struct TicketWave {
        string name;
        uint256 price;
        uint256 supply;
        uint256 minted;
        bool active;
    }

    TicketWave[] public waves;

    struct Royalty {
        string category;
        address walletAddress;
        uint256 percentage;
    }

    Royalty[] public royalties;

    constructor(
        string memory _baseUri,
        address usdcAddress,
        address _qfWallet,
        address _ethBcnWallet
    ) ERC721("ETH BCN Tickets", "ETHBCN") {
        setBaseURI(_baseUri);
        tokenUSDC = IERC20(usdcAddress);
        royalties.push(
            Royalty({category: "QF", walletAddress: _qfWallet, percentage: 5})
        );
        royalties.push(
            Royalty({
                category: "ETHBCN",
                walletAddress: _ethBcnWallet,
                percentage: 95
            })
        );
    }

    function burn(uint256 _tokenId) public {
        _burn(_tokenId);
    }

    function startANewWave(
        string memory _name,
        uint256 _price,
        uint256 _supply
    ) public onlyOwner {
        waves.push(
            TicketWave({
                name: _name,
                price: _price,
                supply: _supply,
                minted: 0,
                active: true
            })
        );
    }

    function pauseWaveTicketSale(uint256 _waveNum) public onlyOwner {
        TicketWave storage wave = waves[_waveNum];
        wave.active = false;
    }

    function mintTicket(
        uint256 _waveNum,
        uint256 _numberOfTokens
    ) public payable {
        TicketWave storage wave = waves[_waveNum];
        require(wave.active, "Wave ticket sale is not active");
        require(_numberOfTokens > 0, "Atleast mint 1 token");
        require(
            wave.minted + _numberOfTokens <= wave.supply,
            "Purchase exceeds maximum supply of tickets in this wave"
        );

        bool success = tokenUSDC.transferFrom(
            msg.sender,
            address(this),
            wave.price * _numberOfTokens
        );

        require(success, "USDC transfer failed, missing approval?");

        for (uint256 i = 1; i <= _numberOfTokens; i++) {
            _safeMint(_msgSender(), ++totalTicketsMinted);
            wave.minted++;
        }
    }

    function walletQuery(
        address _owner
    ) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseTokenURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function withdrawUSDC() public onlyOwner {
        uint256 balance = tokenUSDC.balanceOf(address(this));

        for (uint256 i = 0; i < royalties.length; i++) {
            Royalty storage royalty = royalties[i];
            uint256 toCollect = ((balance * royalty.percentage) / 100);
            tokenUSDC.transfer(royalty.walletAddress, toCollect);
        }
    }
}