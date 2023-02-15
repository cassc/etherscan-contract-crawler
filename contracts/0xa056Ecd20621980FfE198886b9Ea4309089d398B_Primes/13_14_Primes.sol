// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// @title: Primes
// @author: g56d
//
// Primes is an on-chain collection of 1575 unique scalable, animated and interactive digital artworks
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721r.sol";
import "./PrimesUtils.sol";

contract Primes is ERC721r, Ownable {
    using Strings for uint256;
    using PrimesUtils for *;
    uint256 private constant MAX_SUPPLY = 1575 + 1;
    uint256 private constant RESERVE = 56;
    uint256 private constant MAX_PER_ADDRESS = 3;
    uint256 public allowlistPrice;
    uint256 public publicPrice;
    uint256 public start;
    string[81] private pathDefinitions = [
        "M0 0H100V100H0Z",
        "M100 0H200V100H100Z",
        "M200 0H300V100H200Z",
        "M300 0H400V100H300Z",
        "M400 0H500V100H400Z",
        "",
        "M600 0H700V100H600Z",
        "M700 0H800V100H700Z",
        "",
        "M0 100H100V200H0Z",
        "M100 100H200V200H100Z",
        "",
        "M300 100H400V200H300Z",
        "M400 100H500V200H400Z",
        "",
        "M600 100H700V200H600Z",
        "M700 100H800V200H700Z",
        "",
        "M0 200H100V300H0Z",
        "M100 200H200V300H100Z",
        "",
        "M300 200H400V300H300Z",
        "M400 200H500V300H400Z",
        "",
        "M600 200H700V300H600Z",
        "M700 200H800V300H700Z",
        "",
        "M0 300H100V400H0Z",
        "M100 300H200V400H100Z",
        "",
        "M300 300H400V400H300Z",
        "M400 300H500V400H400Z",
        "",
        "M600 300H700V400H600Z",
        "M700 300H800V400H700Z",
        "",
        "M0 400H100V500H0Z",
        "M100 400H200V500H100Z",
        "",
        "M300 400H400V500H300Z",
        "M400 400H500V500H400Z",
        "",
        "M600 400H700V500H600Z",
        "M700 400H800V500H700Z",
        "",
        "M0 500H100V600H0Z",
        "M100 500H200V600H100Z",
        "",
        "M300 500H400V600H300Z",
        "M400 500H500V600H400Z",
        "",
        "M600 500H700V600H600Z",
        "M700 500H800V600H700Z",
        "",
        "M0 600H100V700H0Z",
        "M100 600H200V700H100Z",
        "",
        "M300 600H400V700H300Z",
        "M400 600H500V700H400Z",
        "",
        "M600 600H700V700H600Z",
        "M700 600H800V700H700Z",
        "",
        "M0 700H100V800H0Z",
        "M100 700H200V800H100Z",
        "",
        "M300 700H400V800H300Z",
        "M400 700H500V800H400Z",
        "",
        "M600 700H700V800H600Z",
        "M700 700H800V800H700Z",
        "",
        "M0 800H100V900H0Z",
        "M100 800H200V900H100Z",
        "",
        "M300 800H400V900H300Z",
        "M400 800H500V900H400Z",
        "",
        "M600 800H700V900H600Z",
        "M700 800H800V900H700Z",
        ""
    ];
    string[81] private animationValues = [
        "M50 0H100V50H50Z;M-50 0H100V150H-50Z;M50 0H100V50H50Z;",
        "M100 0H150V50H100Z;M100 0H250V150H100Z;M100 0H150V50H100Z;",
        "M200 0H250V50H200Z;M200 0H350V150H200Z;M200 0H250V50H200Z;",
        "M350 0H400V50H350Z;M250 0H400V150H250Z;M350 0H400V50H350Z;",
        "M400 0H450V50H400Z;M400 0H550V150H400Z;M400 0H450V50H400Z;",
        "",
        "M650 0H700V50H650Z;M550 0H700V150H550Z;M650 0H700V50H650Z;",
        "M700 0H750V50H700Z;M700 0H850V150H700Z;M700 0H750V50H700Z;",
        "",
        "M50 150H100V200H50Z;M-50 50H100V200H-50Z;M50 150H100V200H50Z;",
        "M100 150H150V200H100Z;M100 50H250V200H100Z;M100 150H150V200H100Z;",
        "",
        "M350 150H400V200H350Z;M250 50H400V200H250Z;M350 150H400V200H350Z;",
        "M400 150H450V200H400Z;M400 50H550V200H400Z;M400 150H450V200H400Z;",
        "",
        "M650 150H700V200H650Z;M550 50H700V200H550Z;M650 150H700V200H650Z;",
        "M700 150H750V200H700Z;M700 50H850V200H700Z;M700 150H750V200H700Z;",
        "",
        "M50 200H100V250H50Z;M-50 200H100V350H-50Z;M50 200H100V250H50Z;",
        "M100 200H150V250H100Z;M100 200H250V350H100Z;M100 200H150V250H100Z;",
        "",
        "M350 200H400V250H350Z;M250 200H400V350H250Z;M350 200H400V250H350Z;",
        "M400 200H450V250H400Z;M400 200H550V350H400Z;M400 200H450V250H400Z;",
        "",
        "M650 200H700V250H650Z;M550 200H700V350H550Z;M650 200H700V250H650Z;",
        "M700 200H750V250H700Z;M700 200H850V350H700Z;M700 200H750V250H700Z;",
        "",
        "M50 350H100V400H50Z;M-50 250H100V400H-50Z;M50 350H100V400H50Z;",
        "M100 350H150V400H100Z;M100 250H250V400H100Z;M100 350H150V400H100Z;",
        "",
        "M350 350H400V400H350Z;M250 250H400V400H250Z;M350 350H400V400H350Z;",
        "M400 350H450V400H400Z;M400 250H550V400H400Z;M400 350H450V400H400Z;",
        "",
        "M650 350H700V400H650Z;M550 250H700V400H550Z;M650 350H700V400H650Z;",
        "M700 350H750V400H700Z;M700 250H850V400H700Z;M700 350H750V400H700Z;",
        "",
        "M50 400H100V450H50Z;M-50 400H100V550H-50Z;M50 400H100V450H50Z;",
        "M100 400H150V450H100Z;M100 400H250V550H100Z;M100 400H150V450H100Z;",
        "",
        "M350 400H400V450H350Z;M250 400H400V550H250Z;M350 400H400V450H350Z;",
        "M400 400H450V450H400Z;M400 400H550V550H400Z;M400 400H450V450H400Z;",
        "",
        "M650 400H700V450H650Z;M550 400H700V550H550Z;M650 400H700V450H650Z;",
        "M700 400H750V450H700Z;M700 400H850V550H700Z;M700 400H750V450H700Z;",
        "",
        "M50 550H100V600H50Z;M-50 450H100V600H-50Z;M50 550H100V600H50Z;",
        "M100 550H150V600H100Z;M100 450H250V600H100Z;M100 550H150V600H100Z;",
        "",
        "M350 550H400V600H350Z;M250 450H400V600H250Z;M350 550H400V600H350Z;",
        "M400 550H450V600H400Z;M400 450H550V600H400Z;M400 550H450V600H400Z;",
        "",
        "M650 550H700V600H650Z;M550 450H700V600H550Z;M650 550H700V600H650Z;",
        "M700 550H750V600H700Z;M700 450H850V600H700Z;M700 550H750V600H700Z;",
        "",
        "M50 600H100V650H50Z;M-50 600H100V750H-50Z;M50 600H100V650H50Z;",
        "M100 600H150V650H100Z;M100 600H250V750H100Z;M100 600H150V650H100Z;",
        "",
        "M350 600H400V650H350Z;M250 600H400V750H250Z;M350 600H400V650H350Z;",
        "M400 600H450V650H400Z;M400 600H550V750H400Z;M400 600H450V650H400Z;",
        "",
        "M650 600H700V650H650Z;M550 600H700V750H550Z;M650 600H700V650H650Z;",
        "M700 600H750V650H700Z;M700 600H850V750H700Z;M700 600H750V650H700Z;",
        "",
        "M50 750H100V800H50Z;M-50 650H100V800H-50Z;M50 750H100V800H50Z;",
        "M100 750H150V800H100Z;M100 650H250V800H100Z;M100 750H150V800H100Z;",
        "",
        "M350 750H400V800H350Z;M250 650H400V800H250Z;M350 750H400V800H350Z;",
        "M400 750H450V800H400Z;M400 650H550V800H400Z;M400 750H450V800H400Z;",
        "",
        "M650 750H700V800H650Z;M550 650H700V800H550Z;M650 750H700V800H650Z;",
        "M700 750H750V800H700Z;M700 650H850V800H700Z;M700 750H750V800H700Z;",
        "",
        "M50 800H100V850H50Z;M-50 800H100V950H-50Z;M50 800H100V850H50Z;",
        "M100 800H150V850H100Z;M100 800H250V950H100Z;M100 800H150V850H100Z;",
        "",
        "M350 800H400V850H350Z;M250 800H400V950H250Z;M350 800H400V850H350Z;",
        "M400 800H450V850H400Z;M400 800H550V950H400Z;M400 800H450V850H400Z;",
        "",
        "M650 800H700V850H650Z;M550 800H700V950H550Z;M650 800H700V850H650Z;",
        "M700 800H750V850H700Z;M700 800H850V950H700Z;M700 800H750V850H700Z;",
        ""
    ];
    string[9] private colors = [
        "#fa0",
        "#af0",
        "#0f0",
        "#0fa",
        "#0af",
        "#00f",
        "#a0f",
        "#f0a",
        "#f00"
    ];
    address[] public allowlist;
    bool public paused;
    struct Attributes {
        string numerator;
        string percentage;
    }
    mapping(uint256 => Attributes) private Stats;
    mapping(address => uint256) private addressMintedBalance;
    enum Steps {
        BEFORE,
        PRIVATE_SALE,
        PUBLIC_SALE
    }
    Steps public step;

    function setStatsMap() internal {
        Attributes memory n1 = Attributes("1", "0.06");
        Stats[1] = n1;
        Attributes memory n2 = Attributes("4", "0.25");
        Stats[2] = n2;
        Attributes memory n3 = Attributes("29", "1.84");
        Stats[3] = n3;
        Attributes memory n4 = Attributes("64", "4.06");
        Stats[4] = n4;
        Attributes memory n5 = Attributes("135", "8.57");
        Stats[5] = n5;
        Attributes memory n6 = Attributes("224", "14.22");
        Stats[6] = n6;
        Attributes memory n7 = Attributes("317", "20.13");
        Stats[7] = n7;
        Attributes memory n8 = Attributes("316", "20.06");
        Stats[8] = n8;
        Attributes memory n9 = Attributes("225", "14.29");
        Stats[9] = n9;
        Attributes memory n10 = Attributes("146", "9.27");
        Stats[10] = n10;
        Attributes memory n11 = Attributes("68", "4.32");
        Stats[11] = n11;
        Attributes memory n12 = Attributes("25", "1.59");
        Stats[12] = n12;
        Attributes memory n13 = Attributes("14", "0.89");
        Stats[13] = n13;
        Attributes memory n14 = Attributes("2", "0.13");
        Stats[14] = n14;
        Attributes memory n15 = Attributes("3", "0.19");
        Stats[15] = n15;
        Attributes memory n16 = Attributes("1", "0.06");
        Stats[16] = n16;
        Attributes memory n22 = Attributes("1", "0.06");
        Stats[22] = n22;
    }

    function getNumerator(
        uint256 _k
    ) internal view returns (string memory numerator) {
        numerator = Stats[_k].numerator;
    }

    function getPercentage(
        uint256 _k
    ) internal view returns (string memory percentage) {
        percentage = Stats[_k].percentage;
    }

    function allowlistMint(
        address _address,
        uint256 _quantity
    ) external payable isUser {
        require(!paused, "Contract paused");
        require(step == Steps.PRIVATE_SALE, "Sale has not begun yet");
        uint price = allowlistPrice;
        require(currentTime() >= start, "Presale has not begun yet");
        require(currentTime() < start + 24 hours, "Presale is finished");
        require(_quantity > 0, "Mint at least 1 NFT");
        if (msg.sender != owner()) {
            require(isEligible(msg.sender), "Not eligible to mint");
            require(
                addressMintedBalance[msg.sender] + _quantity <= MAX_PER_ADDRESS,
                "Maximum per address exceeded"
            );
            require(msg.value >= price * _quantity, "Insufficient funds");
        }
        addressMintedBalance[msg.sender] += _quantity;
        _mintRandom(_address, _quantity);
    }

    function publicMint(
        address _address,
        uint256 _quantity
    ) external payable isUser {
        require(!paused, "Contract paused");
        require(step == Steps.PUBLIC_SALE, "Public sale has not begun yet");
        require(
            totalSupply() + _quantity <= MAX_SUPPLY - RESERVE,
            "Maximum sale limit exceeded"
        );
        uint price = publicPrice;
        if (msg.sender != owner()) {
            require(
                addressMintedBalance[msg.sender] + _quantity <= MAX_PER_ADDRESS,
                "Maximum per address exceeded"
            );
            require(msg.value >= price * _quantity, "Insufficient funds");
        }
        addressMintedBalance[msg.sender] += _quantity;
        _mintRandom(_address, _quantity);
    }

    function sendGift(address _address, uint256 _quantity) external onlyOwner {
        require(
            totalSupply() + _quantity <= MAX_SUPPLY,
            "Reach maximum supply"
        );
        _mintRandom(_address, _quantity);
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Primes: non-extistent token ID");

        string memory serial = _tokenId.toString();
        string
            memory description = "Primes is an on-chain collection of 1575 unique scalable, animated and interactive digital artworks";
        string memory dataImage = generateBase64SVG(_tokenId);
        uint primesCount = PrimesUtils.getNumberOfPrimes(_tokenId);
        string memory numerator = getNumerator(primesCount);
        string memory percentage = getPercentage(primesCount);
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                string(abi.encodePacked("Primes #", serial)),
                                '", "description":"',
                                description,
                                '", "image_data": "',
                                "data:image/svg+xml;base64,",
                                dataImage,
                                '", "attributes": [',
                                '{"trait_type":"Numerator", "value":"',
                                numerator,
                                '"},',
                                '{"trait_type":"Percentage", "value":"',
                                percentage,
                                '"}',
                                "]",
                                "}"
                            )
                        )
                    )
                )
            );
    }

    function tokenSVG(
        uint256 _tokenId
    ) public view returns (string memory svg_) {
        require(_exists(_tokenId), "Non-extistent token");
        svg_ = generateSVG(_tokenId);
    }

    function generateBase64SVG(
        uint256 tokenId
    ) internal view returns (string memory) {
        return Base64.encode(bytes(generateSVG(tokenId)));
    }

    function generateSVG(
        uint256 _tokenId
    ) internal view returns (string memory) {
        string memory title = string(
            abi.encodePacked("<title>Primes #", _tokenId.toString(), "</title>")
        );
        string memory paths = generatePaths(_tokenId);
        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 900 900" width="100%" height="100%" style="background:#000">',
                    title,
                    '<rect width="900" height="900" fill="#000"/>',
                    paths,
                    "</svg>"
                )
            );
    }

    function generatePaths(
        uint256 _tokenId
    ) internal view returns (string memory) {
        uint256 count = (_tokenId * 81) - 80;
        uint256 x = 0;
        uint256 y = 0;
        uint256 colorIndex = 0;
        uint256 index = 0;
        string memory paths = "";
        for (y = 0; y <= 800; y += 100) {
            for (x = 0; x <= 800; x += 100) {
                colorIndex = x / 100;
                if (PrimesUtils.isPrime(uint256(count))) {
                    string memory d = pathDefinitions[index];
                    string memory values = animationValues[index];
                    string memory oi = PrimesUtils.setAnimationEvent(
                        index,
                        colorIndex
                    );
                    paths = PrimesUtils.concatenate(
                        paths,
                        string(
                            abi.encodePacked(
                                '<path d="',
                                d,
                                '" fill="',
                                string(colors[colorIndex]),
                                '" shape-rendering="geometricPrecision"><animate attributeName="d" values="',
                                values,
                                '" repeatCount="indefinite" dur="',
                                count.toString(),
                                'ms" ',
                                oi,
                                '="click"></animate></path>'
                            )
                        )
                    );
                }
                count += 1;
                index += 1;
            }
        }
        return paths;
    }

    // test
    modifier isUser() {
        require(tx.origin == msg.sender, "Caller is another contract");
        _;
    }

    function isEligible(address _user) public view returns (bool) {
        for (uint i = 0; i < allowlist.length; i++) {
            if (allowlist[i] == _user) {
                return true;
            }
        }
        return false;
    }

    // setting
    function setAllowlist(address[] calldata _addresses) public onlyOwner {
        delete allowlist;
        allowlist = _addresses;
    }

    function setPrice(uint256 _price) external onlyOwner {
        publicPrice = _price;
    }

    function setAllowlistPrice(uint256 _allowlistPrice) external onlyOwner {
        allowlistPrice = _allowlistPrice;
    }

    function setStart(uint256 _timestamp) external onlyOwner {
        start = _timestamp;
    }

    function setStep(uint _step) external onlyOwner {
        step = Steps(_step);
    }

    function setPause(bool _paused) external onlyOwner {
        paused = _paused;
    }

    function currentTime() internal view returns (uint256) {
        return block.timestamp;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed");
    }

    constructor() ERC721r("Primes", "PRIMES", MAX_SUPPLY) {
        setStatsMap();
        _mintAtIndex(owner(), 0);
    }
}