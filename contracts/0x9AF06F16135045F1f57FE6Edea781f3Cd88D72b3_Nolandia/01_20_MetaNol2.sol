// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

contract Nolandia is
    ERC721Royalty,
    Ownable
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public weiCostPerPx = 1000000000000000; // 0.001 ether per px
    uint8 pxInParcel = 64;
    uint8 valsPerPixel = 4;
    bool preMintOpen = true;

    struct plot {
        uint8 x1;
        uint8 y1;
        uint8 x2;
        uint8 y2;
        uint256 plotId;
        address plotOwner;
    }

    event PlotPixelsSet(uint256 indexed plotId, uint32 startIndex, uint8[] imageData);

    event PlotPurchased(
        uint256 indexed plotId,
        address plotOwner,
        uint8 x1,
        uint8 y1,
        uint8 x2,
        uint8 y2,
        uint256 sparkles,
        string resources,
        string landType,
        string megafaunaType
    );

    uint256[128][128] public parcels;
    mapping(uint256 => plot) public plots;
    string internal _baseUriVal;

    uint256 randCounter = 0;

    string[] landTypes = [
        "rainforrest",
        "rainforrest",
        "rainforrest",
        "desert",
        "desert",
        "desert",
        "desert",
        "taiga",
        "taiga",
        "taiga",
        "taiga",
        "wetland",
        "wetland",
        "wetland",
        "wetland",
        "snow",
        "mountain",
        "savanah",
        "snow",
        "mountain",
        "savanah",
        "lunar regolith",
        "prarie",
        "prarie",
        "prarie",
        "prarie",
        "prarie",
        "space",
        "candyland",
        "artificial island",
        "artificial island"
    ];

    string[] resources = [
        "gold",
        "silver",
        "gold",
        "silver",
        "silver",
        "coper",
        "wood",
        "coper",
        "coper",
        "iron",
        "iron",
        "iron",
        "iron",
        "iron",
        "platinum",
        "unobtainium",
        "sand",
        "sand",
        "sand",
        "ruby",
        "ruby",
        "boron",
        "boron",
        "salt",
        "salt",
        "salt",
        "salt",
        "tiberium",
        "wood",
        "wood",
        "oil",
        "oil",
        "coal",
        "coal",
        "coal",
        "tin",
        "cobalt",
        "cobalt",
        "onyx"
    ];

    string[] dominantMegafauna = [
        "dinosaurs",
        "mammals",
        "mammals",
        "mammals",
        "mammals",
        "mammals",
        "marsupials",
        "marsupials"
    ];

    address[] payees;
    uint256[] shares;

    constructor(
        address[] memory _payees,
        uint256[] memory _shares,
        string memory initialBaseUri,
        address newOwner
    )
        payable
        ERC721("Nolandia", "NOLAND")
    {
        _baseUriVal = initialBaseUri;
        setPayees(_payees, _shares);
        _transferOwnership(newOwner);
    }

    function setPayees (address[] memory _payees, uint256[] memory _shares) public onlyOwner {
        require(_payees.length == _shares.length, "bad payment info");
        require(_payees.length > 0, "no payee info");
        payees = _payees;
        shares = _shares;
    }

    function sendPayment() internal {
        uint256 totalShares = 0;
        uint amount = address(this).balance;
        for (uint8 i = 0; i < shares.length; i++) {
            totalShares += shares[i];
        }
        for (uint8 i = 0; i < payees.length - 1; i++) {
            uint256 payment = (amount * shares[i]) / totalShares;
            address payable addy = payable(payees[i]);
            (bool success, ) = addy.call{value: payment}("");
            require(success, "Failed to send paymeny");
        }
        address payable lastAaddy = payable(payees[payees.length - 1]);
        uint rest = address(this).balance;
        (bool finalSuccess, ) = lastAaddy.call{value: rest}("");
        require(finalSuccess, "Failed to send paymeny");
    }

    function randomNum() private returns (uint256) {
        randCounter++;
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        randCounter
                    )
                )
            );
    }

    function randomItem(string[] memory arr) private returns (string memory) {
        return arr[randomNum() % arr.length];
    }

    function allParcelsAvailable(
        uint8 x1,
        uint8 y1,
        uint8 x2,
        uint8 y2
    ) internal view returns (bool) {
        for (uint8 i = x1; i < x2; i++) {
            for (uint8 j = y1; j < y2; j++) {
                uint256 ijParcel = parcels[i][j];
                if (ijParcel > 0) return false;
            }
        }
        return true;
    }

    function setParcelsOwned(
        uint8 x1,
        uint8 y1,
        uint8 x2,
        uint8 y2,
        uint256 plotId
    ) internal {
        for (uint8 x = x1; x < x2; x++) {
            for (uint8 y = y1; y < y2; y++) {
                parcels[x][y] = plotId;
            }
        }
    }

    function buyPlot(
        uint8 x1,
        uint8 y1,
        uint8 x2,
        uint8 y2
    ) external payable returns (uint256) {
        require(x1 >= 0 && y1 >= 0, "first coord 0 or bigger");
        require(x2 <= 128 && y2 <= 128, "second coord 128 or smaller");
        require(x1 < x2 && y1 < y2, "2nd coord smaller than first coord");
        uint256 totalAmt = (x2 - x1) * (y2 - y1);
        require(totalAmt * weiCostPerPx * pxInParcel == msg.value, "wrong amount");
        _tokenIds.increment();
        uint256 plotId = _tokenIds.current();
        require(
            allParcelsAvailable(x1, y1, x2, y2) == true,
            "a selected parcel is already owned"
        );
        sendPayment();
        setParcelsOwned(x1, y1, x2, y2, plotId);
        _safeMint(msg.sender, plotId);
        plots[plotId] = plot({
            x1: x1,
            y1: y1,
            x2: x2,
            y2: y2,
            plotId: plotId,
            plotOwner: msg.sender
        });

        uint256 sparkles = totalAmt * (randomNum() % 4);
        string memory mineral = randomItem(resources);
        string memory landType = randomItem(landTypes);
        string memory megafaunaType = randomItem(dominantMegafauna);

        emit PlotPurchased(
            plotId,
            msg.sender,
            x1,
            y1,
            x2,
            y2,
            sparkles,
            mineral,
            landType,
            megafaunaType
        );
        return plotId;
    }

    function preMintPlot(
        uint8 x1,
        uint8 y1,
        uint8 x2,
        uint8 y2
    ) external onlyOwner returns (uint256) {
        require(preMintOpen == true, "Pre-Mint is Closed");
        require(x1 >= 0 && y1 >= 0, "first coord 0 or bigger");
        require(x2 <= 128 && y2 <= 128, "second coord 128 or smaller");
        require(x1 < x2 && y1 < y2, "2nd coord smaller than first coord");
        require(
            allParcelsAvailable(x1, y1, x2, y2) == true,
            "a selected parcel is already owned"
        );
        _tokenIds.increment();
        uint256 plotId = _tokenIds.current();
        setParcelsOwned(x1, y1, x2, y2, plotId);
        _safeMint(msg.sender, plotId);
        plots[plotId] = plot({
            x1: x1,
            y1: y1,
            x2: x2,
            y2: y2,
            plotId: plotId,
            plotOwner: msg.sender
        });

        uint256 totalAmt = (x2 - x1) * (y2 - y1);
        uint256 sparkles = totalAmt * (randomNum() % 4);
        string memory mineral = randomItem(resources);
        string memory landType = randomItem(landTypes);
        string memory megafaunaType = randomItem(dominantMegafauna);
        emit PlotPurchased(
            plotId,
            msg.sender,
            x1,
            y1,
            x2,
            y2,
            sparkles,
            mineral,
            landType,
            megafaunaType
        );
        return plotId;
    }

    function setPixels (uint8[] calldata pixels, uint32 startIndex, uint256 plotId) external {
        require(ownerOf(plotId) == msg.sender, "u dont own this");
        plot memory myPlot = plots[plotId];
        uint32 xdiff = myPlot.x2 - myPlot.x1;
        uint32 ydiff = myPlot.y2 - myPlot.y1;
        uint32 totalPxInPlot = (xdiff * ydiff * pxInParcel * valsPerPixel);
        require(totalPxInPlot - startIndex == pixels.length, "wrong amount of px");
        emit PlotPixelsSet(plotId, startIndex, pixels);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUriVal;
    }

    function setBaseURI(string calldata newBaseUri) public onlyOwner {
        _baseUriVal = newBaseUri;
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "contract-meta"));
    }

    function setWeiPerPx(
        uint256 newPrice
    ) external onlyOwner {
        require(preMintOpen == true, "premint already closed");
        weiCostPerPx = newPrice;
    }

    function closePreMint() external onlyOwner {
        preMintOpen = false;
    }
}